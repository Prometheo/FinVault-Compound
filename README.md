# Simple Vault Contract

This contract demonstrates a simple vault system that allows the deposit of Usdc from users and then lends this funds to Compound, users can withdraw their deposits anytime with interests if any, this project was built using solidity, hardhat and yarn as the package manager.

## How to run
clone this repo by doing `git clone https://github.com/Prometheo/FinVault-Compound.git`
cd into the directory and run `yarn install` to install dependencies
to deploy with hardhat, create a .env and fill the variables with the .env.sample file.
run `npx hardhat run --network rinkeby scripts/deploy.js` to deploy on rinkeby or use the hardhat mainnet fork network.
