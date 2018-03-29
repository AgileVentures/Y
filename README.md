# Y

Y is a new way to fund public services: you choose which services are funded, and where they are funded (i.e. not just in your own country, but anywhere in the world). There are no tax returns to do.

Y could raise enough money to take over from the tax system, and let enough people decide how public money should be spent to take over from centralised government. Enough money could cross national borders that national borders would be obsolete.

## How it works

Rather than waiting for a seller (say, a global corporation) to make sales before taxing them, Y takes tax (actually, a voluntary donation set by the seller) from the sale. The more a seller donates from the sale, the more sales they'll make, right? And you, the buyer/member of the public, get to set where the donation will go to.

As it stands, Y is a smart contract that handles this process out in the open (on the blockchain), so the buyer doesn't have to trust the seller to make the donation. The same idea could be implemented by a bank, but a smart contract is more resilient than a bank.

## Development

Right now, Y is an Ethereum smart contract. That may change as better blockchains come out.

There are two layers: the core smart contract, written in Solidity, and the interface around it, so that it's nicer to use (for example, Solidity can't handle decimals). The interface happens to be written in JavaScript, so that it can be called from a web app, but it could be written in any language that calls Ethereum.
