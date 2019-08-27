# ens-lightstreams

A simple example to show how to deploy ENS on the Lightstreams Network.

## Pre-requisites

Truffle v5.0.5 (core: 5.0.5)
Solidity v0.5.0 (solc-js)
Node v10.16.0
lightchain v1.2.0

## Getting started

### Install dependencies & copy config

```
npm install
```

### Copy config

```
cp .env.sample .env
```

### Run lightchain in standalone

```
lightchain run --datadir="${HOME}/.lightchain_standalone" --rpc --rpcapi web3,eth,personal,miner,net,txpool
```

### Deploy contracts

```
npm run deploy
```

### Start

```
npm start
```