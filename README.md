# ReapersGambit Epitaph

 _BEST NFT FOREVER_ (+†+)

Contract address: [0x46d0d00e847ed9C2756cfD941E70D99e9152A22f](https://etherscan.io/address/0x46d0d00e847ed9c2756cfd941e70d99e9152a22f) ([deployed source code](https://vscode.blockscan.com/ethereum/0x46d0d00e847ed9c2756cfd941e70d99e9152a22f))

# Roadmap
 - 2023
   - [ReapersGambit ERC20](https://reapersgambit.com/)
     - Hourglass
     - [Wrapped Reaper](https://immortality.reapersgambit.com/) ([collection](https://opensea.io/collection/wrapped-reaper))
   - [BBScore Website](https://bb.reapersgambit.com/)
   - RG DAO
     - [Multisig](https://dappradar.com/hub/wallet/eth/0x89261878977b5a01c4fd78fc11566abe31bbc14e)
     - Start collecting LP RG/WETH & ETH
   - RG Epitaph
     - R&D
       - [Nym](https://nymtech.net/) mixnet [Epitaph transmission](https://github.com/Magicking/37c3-rg-epitaph-nym-service)
     - Paint dApp v1
     - RG Epitaph v1 (rc1)
 - 2024
   - Paint dApp v2
     - [ ] Using Ordinal storage for ethernal UI storage
   - RG Epitaph v2 (rc2)
   - [ ] NFT Market places integration
   - RG DAO
     - ENS [rgepitaph.eth](https://app.ens.domains/rgepitaph.eth) subscribe for 50 years (Jan 14, 2075)
     - [ ] Define transition from multisig to voting system for RG holders
   - Start making/collecting soul & emotions

## Description

128x24 pixels with an unique 32Bits color for each minted NFT.

This EVM on-chain dynamic NFT offer the possibility to paint graffiti on the Ethereum Blockchain.

Paid in ETH, it uses the [ReapersGambit](https://reapersgambit.com/) token for the minting process.

### On-chain

Stored within the state of the Ethereum Blockchain, it lives forever rent free (link to rent problem) alongs the data of all the Ethereum mainnet RPC providers.

_Blessed be the free RPC providers_

### Dynamic

The NFT is rendered each time it is viewed.

It begins with the birth of the account making it invisible for anyone except the owner for 9 days.

Full cycle ![](./docs/life.gif)

#### Ephemeral view

Every 15 secs the rendering of the artwork is slighty modified such that is almost immobile from the perception of few minutes observation of an human but complety different from the point of view of the digital worlds where it lives and rely.

To retreive the current view, a function call `tokenURI(NFT_ID)` with an `eth_call` to an Ethereum mainnet RPC provider at the latest blockheight must be made to render, encode and return the graphic to view the NFT.

_Artifact living in its own realm_

#### Futur updates

 - MCOPY opcode for future ([discussion](https://eips.ethereum.org/EIPS/eip-5656))

### NFT

#### Rarity

 - Each color can be taken once.

 - Each message require an human touch.

 - Minting will last as long as there is enough RG tokens to be bought on the Uniswap V2 market.

#### Tokenomics

 - 80% goes to the RG DAO Multisig, the funds are used to buy back RG tokens and provide liquidity to the [RG/WETH](https://v2.info.uniswap.org/pair/0x8ab0ff3106bf37b2db685aafd458baee2128d648) pair on Uniswap v2.

 - 20% goes as an artist commission.

## User Interface

 Pixel Art Paint decentralized Application (dApp)

 It is a retro terminal themed web application allowing to both paint and vizualize the painted epitaph.

#### Art work

 - Gift

 - Rebirth

Project that allows users to create a NFT with its own engraving.
It's based on the Reaper's Gambit project, as it allows for dead accounts to be honored with style.

It's composed of a set of smart-contract and a [web interface](https://github.com/Magicking/nft-epitaph-front), no third party is required to see the NFT.

### Local Experimentation

Lorem ipsum TODO bellow

## Render the BMP Epitaph

```bash
forge "script" scripts/WriteBMP.sol:Write --rpc-url http://127.0.0.1:8545 --private-key=${PRIVATE_KEY0} && \
feh -Z out.bmp
```

## Installation

### Smart Contract

The developement framework used is [Foundry](https://book.getfoundry.sh/) and the smart contract is written in [Solidity](https://docs.soliditylang.org/en/latest/).

Follow the instructions at [Foundry installation manual](https://book.getfoundry.sh/getting-started/installation#using-foundryup) to install the Foundry CLI.

If you're on MacOs be sure to install libusb for Foundry tooling to work properly.

# [SkyLight](https://sky-light-sl.com/)