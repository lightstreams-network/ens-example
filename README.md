# ens-lightstreams

A simple example to show how to deploy ENS on the Lightstreams Network.

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