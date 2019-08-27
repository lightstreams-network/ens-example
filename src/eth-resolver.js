require('dotenv').config();
const ENS = require('ethereum-ens');
const Web3 = require('web3');

const provider = new Web3.providers.HttpProvider(process.env.INFURA_HTTP_RPC_ENDPOINT);

function main() {
    resolveEthereumEns();
    resolveWeb3Ens();
}

function resolveEthereumEns() {
    const ens = new ENS(provider);
    ens.resolver('ethereum.eth').addr()
    .then(addr => console.log(addr))
    .catch(error => console.error(error));
}

function resolveWeb3Ens() {
    const web3 = new Web3(provider);
    const ens = web3.eth.ens;
    ens.getAddress('ethereum.eth')
    .then(address => console.log(address))
    .catch(error => console.log(error));
}

main();