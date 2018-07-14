const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:8545"));
const bigInt = require("big-integer");
const BigNumber = require("bignumber.js");

const YJSON = require("../build/contracts/Y2.json");

const yDeployed = new web3.eth.Contract(YJSON.abi).deploy({
  data: YJSON.bytecode
});

(async () => {
  const accounts = await web3.eth.getAccounts();
  const gasEstimate = await yDeployed.estimateGas();

  const owner = accounts[0],
    payee = accounts[1],
    payer = accounts[2],
    donee = accounts[3];

  // Tests which alter balances (global blockchain state) race against each other, leading to erratic results (sometimes fail, sometimes pass). Ideally, each test would happen on its own blockchain with its own balances. But, without this, the next best thing is to make sure those tests run one after the other, rather than in parallel. So, some tests can be run in parallel (parallelTests), others only in series (seriesTests).

  const parallelTests = [
    // anyone can read the donation proportion
    // getDonationProportion(payee) returns [num, denom]?
    // getDonationProportion(payee) throws if unset (0/0)
    // setDonationProportion(num, denom, {from: payee}) has effect of changing donationProportion(payee) to Proportion(num, denom)
    {
      description: "setDonationProportion changes proportion",
      test: async contract => {
        const user = accounts[1],
          num = "1",
          denom = "100";

        await contract.methods
          .setDonationProportion(num, denom)
          .send({ from: user });

        const proportion = await contract.methods
          .getDonationProportion(user)
          .call();

        return proportion.num === num && proportion.denom === denom;
      }
    },
    // setDonationProportion throws if num and/or denom are invalid
    // 0%
    {
      description: "setDonationProportion throws with 0%",
      test: async contract => {
        try {
          await contract.methods
            .setDonationProportion(0, 100)
            .send({ from: accounts[1] });
          return false;
        } catch (err) {
          return true;
        }
      }
    },
    // 100%
    {
      description: "setDonationProportion throws with 100%",
      test: async contract => {
        try {
          await contract.methods
            .setDonationProportion(100, 100)
            .send({ from: accounts[1] });
          return false;
        } catch (err) {
          return true;
        }
      }
    },
    // payAndDonate throws if donation proportion is not what payer is expecting (from getting proportion before)
    {
      description: "payAndDonate throws if proportion unexpected",
      test: async contract => {
        // set contract up with a different donation proportion than the one the payer is expecting
        await contract.methods
          .setDonationProportion("2", "100")
          .send({ from: payee });

        try {
          await contract.methods
            .payAndDonate(payee, donee, "1", "100")
            .send({ from: payer });
          return false;
        } catch (err) {
          return true;
        }
      }
    },
    // payAndDonate throws if payment * num overflows
    {
      description: "payAndDonate throws if overflows",
      test: async contract => {
        const maxSolidityNum = BigNumber(2 ** 256 - 1); // Using BigNumber as, without it, you get "Error: [number-to-bn] while converting number 2.894802230932905e+76 to BN.js instance, error: invalid number value. Value must be an integer, hex string, BN or BigNumber instance." (BN.js doesn't accept numbers in e notation... TODO make feature request)

        const num = maxSolidityNum.dividedBy(4);
        const denom = maxSolidityNum.dividedBy(2);

        // set that donation proportion
        await contract.methods
          .setDonationProportion(num, denom)
          .send({ from: payee });

        // call payAndDonate with a payment that will make payment * num overflow
        try {
          await contract.methods
            .payAndDonate(payee, donee, num, denom)
            .send({ from: payer, value: 5 });
          return false;
        } catch (err) {
          return true;
        }
      }
    },
    // unstickWei throws if someone other than the owner tries to use it
    {
      description: "unstickWei throws (fails if stickWei commented out)",
      test: async contract => {
        try {
          await contract.methods.stickWei().send({ from: payer, value: 1 });

          // someone other than the owner (and the payer, because it's the payer's money that's stuck and someone else is trying to steal it)
          const nonOwner = accounts[6]; // TODO make random selection algorithm

          try {
            await contract.methods
              .unstickWei(nonOwner, 1)
              .send({ from: nonOwner });
            return false;
          } catch (err) {
            return true;
          }
        } catch (err) {
          return false;
        }
      }
    }

    // make pausable, in case wei gets stuck and you don't want any more piling up
    // translate all the other tests from Y.test.js
  ];

  // these tests alter global state (e.g. balances), so must run in series (or ideally in parallel blockchains)
  const seriesTests = [
    // payAndDonate(payee, donee, num, denom, {value: payment}) has effect of paying payee payment - donation and donating donation ((payment * num) / denom) to donee
    {
      description: "payAndDonate pays and donates",
      test: async contract => {
        const payment = web3.utils.toWei("0.1", "ether"),
          num = "1",
          denom = "100";

        // set contract up
        await contract.methods
          .setDonationProportion(num, denom)
          .send({ from: payee });

        const balanceBefore = {
          payee: bigInt(await web3.eth.getBalance(payee)),
          donee: bigInt(await web3.eth.getBalance(donee))
        };

        // unit under test
        await contract.methods
          .payAndDonate(payee, donee, num, denom)
          .send({ from: payer, value: payment });

        const balanceAfter = {
          payee: bigInt(await web3.eth.getBalance(payee)),
          donee: bigInt(await web3.eth.getBalance(donee))
        };

        const donation = payment * num / denom;
        return (
          balanceAfter.payee.equals(
            balanceBefore.payee.plus(payment - donation)
          ) && balanceAfter.donee.equals(balanceBefore.donee.plus(donation))
        );
      }
    },

    // unstickWei sends wei to specified recipient
    {
      description: "unstickWei works (fails if stickWei commented out)",
      test: async contract => {
        const value = web3.utils.toWei("0.1", "ether");
        const recipient = accounts[Math.floor(Math.random() * accounts.length)];
        try {
          // get wei stuck on contract
          await contract.methods
            .stickWei()
            .send({ from: recipient, value: value });

          // get recipient balance before
          const balanceBefore = bigInt(await web3.eth.getBalance(recipient));
          // unstick wei
          await contract.methods
            .unstickWei(recipient, value)
            .send({ from: owner }); // ERROR here

          // get recipient balance after
          const balanceAfter = bigInt(await web3.eth.getBalance(recipient));

          // check that recipient balance has increased
          return balanceAfter.equals(balanceBefore.plus(value));
        } catch (err) {
          return false;
        }
      }
    }
  ];

  // Note on the unstickWei tests:
  // The only way Ether can get stuck in a contract is via its payable functions.
  // The only payable function on Y is payAndDonate.
  // If money gets stuck in the contract, there must be some chance that it can be unstuck, rather than lost forever.
  // The Ether stuck in a contract does not say who it came from. The caller of the unstick function will have to specify the address to send the Ether to.
  // More than one person's Ether could get stuck in the contract at once, and it gets lumped together. The caller of the unstick function will have to specify how much to send.

  let seriesResults = [];

  for (let i = 0; i < seriesTests.length; i += 1) {
    seriesResults.push({
      description: seriesTests[i].description,
      result: await seriesTests[i].test(
        await yDeployed.send({
          from: owner,
          gas: gasEstimate
        })
      )
    });
  } // if this doesn't work, try for await of loop (https://youtu.be/I5oDbp_U-fQ), or any other way of calling these tests in series

  const results = (await Promise.all(
    parallelTests.map(async ({ description, test }) => ({
      description,
      result: await test(
        await yDeployed.send({
          from: owner,
          gas: gasEstimate
        }) // fresh contract
      )
    }))
  )).concat(seriesResults);

  // warn me if results.length !== tests.length
  console.log(
    results.length !== parallelTests.length + seriesTests.length
      ? "STOP! results.length and tests.length aren't the same"
      : ""
  );

  console.log(
    results.every(({ description, result }) => result === true)
      ? "all tests passed"
      : "some tests failed: " +
        JSON.stringify(
          results
            .filter(({ result }) => result === false)
            .map(({ description }) => description)
        )
  );
})();
