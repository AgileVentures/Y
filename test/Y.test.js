const Y = artifacts.require("Y");
const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiAsPromised);

const assert = chai.assert;

contract("Y", accounts => {
  const payer = accounts[1];
  const payee = accounts[2];
  const donee = accounts[3];

  const oneEtherInWei = web3.toWei(1, "ether");

  beforeEach(async function() {
    y = await Y.new(25, 100, { from: payee });
  });

  // The donation proportion can only be between 0 and 100% exclusive.
  // If all the functions that can change the donation proportion throw if they're passed an invalid donation proportion, we can be sure that the donation proportion cannot be invalid.

  it("throws if you try to deploy with a donation proportion of 0%", () => {
    assert.isRejected(Y.new(0, 100));
  });

  it("throws if you try to deploy with a donation proportion of >= 100%", () => {
    assert.isRejected(Y.new(100, 100));
  });

  it("throws if the payee tries to set a donation proportion of 0%", () => {
    assert.isRejected(y.setDonationProportion(0, 100, { from: payee }));
  });

  it("throws if the payee tries to set a donation proportion of >= 100%", () => {
    assert.isRejected(y.setDonationProportion(100, 100, { from: payee }));
  });

  // Both payer and payee can get the donation proportion.

  it("lets the payer read the donation proportion", async () => {
    const [num, denom] = await y.donationProportion({ from: payer });
    assert.isTrue(num.equals(25) && denom.equals(100));
  });

  it("lets the payee read the donation proportion", async () => {
    const [num, denom] = await y.donationProportion({ from: payee });
    assert.isTrue(num.equals(25) && denom.equals(100));
  });

  // Only the payee can set the proportion of the payment that will be donated.

  it("lets the payee set the donation proportion", async () => {
    const result = await y.setDonationProportion(10, 100, { from: payee }); // TODO different proportion to what's already on the contract
    const [num, denom] = await y.donationProportion();
    assert.isTrue(num.equals(10) && denom.equals(100));
  });

  it("throws if someone other than the payee tries to set the donation proportion", () => {
    assert.isRejected(y.setDonationProportion(1, 100, { from: payer }));
  });

  // The donation is what the payer expected it would be.
  // (The donation proportion can be changed between the payer calling to pay and the function executing.)

  it("throws if the donation proportion is not what payer is expecting", async () => {
    // Payer is expecting 30% but the contract is set at 25% on creation
    assert.isRejected(y.payAndDonate(30, 100));
  });

  // Verify payAndDonate changes balances on payee and donee/s as expected
  // TODO random amounts and donation proportions
  it("transfers 75% of payment to payee and 25% to donee", async () => {
    const balances = async () => {
      return {
        payee: await web3.eth.getBalance(payee),
        donee: await web3.eth.getBalance(donee)
      };
    };
    const donation = web3.toWei(0.25, "ether");
    const balancesBefore = await balances();

    await y.payAndDonate(25, 100, donee, { from: payer, value: oneEtherInWei });

    const balancesAfter = await balances();
    assert.isTrue(
      balancesAfter.payee.equals(
        balancesBefore.payee.plus(oneEtherInWei - donation)
      ), // TODO BigNumber arithmetic
      "payee"
    );
    assert.isTrue(
      balancesAfter.donee.equals(balancesBefore.donee.plus(donation)),
      "donee"
    );
  });

  it("throws if msg.value * num overflows", async () => {
    const maxSolidityNum = 2 ** 256 - 1;

    const num = maxSolidityNum / 4;
    const denom = maxSolidityNum / 2;
    await y.setDonationProportion(num, denom, { from: payee });

    assert.isRejected(
      y.payAndDonate(num, denom, donee, { from: payer, value: 5 })
    );
  });

  // The only way Ether can get stuck in a contract is via its payable functions.
  // The only payable function on Y is payAndDonate.
  // If money gets stuck in the contract, there must be some chance that it can be unstuck, rather than lost forever.
  // The Ether stuck in a contract does not say who it came from. The caller of the unstick function will have to specify the address to send the Ether to.
  // More than one person's Ether could get stuck in the contract at once, and it gets lumped together. The caller of the unstick function will have to specify how much to send.

  // it("returns money to single buyer", async () => {
  //   // Get balances
  //   const balances = async () => {
  //     return {
  //       payer: await web3.eth.getBalance(payer),
  //       contract: await web3.eth.getBalance(y.address)
  //     };
  //
  //     // Return balance to payer
  //     const balancesBefore = await balances();
  //     await y.unstickWei(balancesBefore.contract);
  //     const balancesAfter = await balances();
  //
  //     assert.equal(balancesBefore.payer + contract, balancesAfter.payer);
  //
  //     // Assert balance was returned
  //   };
  // });

  it("sends specified amount of stuck wei to specified address", async () => {
    const wei = oneEtherInWei;

    const balances = async () => ({
      contract: await web3.eth.getBalance(y.address),
      payer: await web3.eth.getBalance(payer)
    });

    await y.stickWei({ value: wei });

    const balancesBefore = await balances();

    await y.unstickWei(payer, wei, { from: payee });

    const balancesAfter = await balances();

    assert.isTrue(
      balancesAfter.contract.equals(balancesBefore.contract.minus(wei)),
      "contract balance only decreases by wei"
    );
    assert.isTrue(
      balancesAfter.payer.equals(balancesBefore.payer.plus(wei)),
      "payer balance increases by wei"
    );
  });

  it("throws if someone other than the payee tries to unstick stuck wei", async () => {
    await y.stickWei({ value: oneEtherInWei });

    assert.isRejected(y.unstickWei(payer, oneEtherInWei, { from: payer }));
  });

  // it("does something", async () => {
  //   y.xyz; // truffle test: "ReferenceError: xyz is not defined"
  // });
});
