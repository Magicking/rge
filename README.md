# ReapersGambit Epitaph

 - __BEST NFT FOREVER__

Contract address: [0x46d0d00e847ed9C2756cfD941E70D99e9152A22f](etherscan link) (deployed source code[link][etherscan dev])

## Description

This EVM on-chain dynamic NFT offer the possibility to paint graffiti on the Ethereum Blockchain

### On-chain

Stored in data of the Ethereum Blockchain, it lives forever rent free (link to rent problem) on the state storage of all the Ethereum mainnet RPC providers.
 - __Blessed be the free RPC providers__

### Dynamic

The legitimatte way to view the NFT is through an eth_call on the proxy deployed at [0x46d0d00e847ed9C2756cfD941E70D99e9152A22f](etherscan link) at the latest blockheight.


#### Upgreades
 - MCOPY opcode for future
### NFT
- Unique

## UI
#### Art work
 - Gift
 - Rebirth
 - Revocation of fees
project that allows users to create a NFT with its own engraving.
It's based on the Reaper Gambit project, as it allows for dead accounts to be revived with style.

It's composed of a smart contract and a web interface.

## Local Development

If you have not already installed the dependencies, go to the [Installation](#installation) section.
A local development environment requires a local Ethereum node and a local web server.
Follow the network and web server instructions below to setup a local development environment.

1. Start the local blockchain fork with 10 seconds block time

If you don't have an Alchemy account, you can create one [here](https://www.alchemy.com/).
Then export your Alchemy API key and start the anvil fork.

```bash
export ALCHEMY_RPC=https://eth-mainnet.g.alchemy.com/v2/<key>
anvil --fork-url ${ALCHEMY_RPC} -b 10
```

Then in another terminal, deploy the smart contract.

2. Deploy the smart contract

```bash
source .env.local
forge script scripts/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast --private-key=${PRIVATE_KEY0}
```

3. Start the web server

Go to [Front repository](https://github.com/Magicking/nft-epitaph-front) to
install and build on the front.

## Render the BMP Epitaph

```bash
export ALCHEMY_RPC=https://eth-mainnet.g.alchemy.com/v2/<key>
anvil --fork-url ${ALCHEMY_RPC} -b 10
```

Then in another terminal, run the write BMP contract script.
(Replace feh with your favorite image viewer).

```bash
forge "script" scripts/WriteBMP.sol:Write --rpc-url http://127.0.0.1:8545 --private-key=${PRIVATE_KEY0} && \
feh -Z out.bmp
```

### Smart Contract Update

When the [ABI](https://docs.soliditylang.org/en/latest/abi-spec.html) of the smart contract changes (e.g: functions signatures modification), you'll need to update it for the web interface.
To do so, you need to compile the smart contract and copy the ABI to the web interface.
The compilation is done with the Foundry CLI when deploying the smart contract or running the following command:

```bash
forge compile
```

The ABI is located in the `out/ReaperGambitEpitaph.sol/ReaperGambitEpitaph.json` file.
You need to copy the content of the `abi` field and paste it in the [https://github.com/Magicking/nft-epitaph-front/blob/main/src/lib/rge.abi.json](https://github.com/Magicking/nft-epitaph-front/blob/main/src/lib/rge.abi.json) replacing the old `abi` field.

## Installation

### Smart Contract

The developement framework used is [Foundry](https://book.getfoundry.sh/) and the smart contract is written in [Solidity](https://docs.soliditylang.org/en/latest/).

Follow the instructions at [Foundry installation manual](https://book.getfoundry.sh/getting-started/installation#using-foundryup) to install the Foundry CLI.

If you're on MacOs be sure to install libusb for Foundry tooling to work properly.

### Web Interface

The web interface is written in Svelte and uses [SvelteKit](https://kit.svelte.dev/) as a framework for static site generation.

Go to [Front repository](https://github.com/Magicking/nft-epitaph-front) to
install and build on the front.

## Coupon reduction generation

To generate reduction coupon, you need to generate them using the following command:

`cd coupon && npm run generate`
