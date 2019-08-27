require('dotenv').config();
const ENS = require('ethereum-ens');
const Web3 = require('web3');
const { networks } = require('../build/contracts/ENSRegistry.json');
const truffleConfig = require('../truffle-config');
const networkId = truffleConfig.networks.standalone.network_id;

const provider = new Web3.providers.HttpProvider('http://localhost:8545');
const ens = new ENS(provider, networks[networkId].address);
const web3 = new Web3(provider);

function main() {
    checkTldResolver();
    registerDomain();
}

function checkTldResolver() {
    console.log('.lsn domains have a resolver addr')
    ens.resolver('lsn').addr()
    .then(addr => console.log(addr))
    .catch(error => console.error(error));
}

async function registerDomain() {
    web3.eth.personal.unlockAccount(process.env.LSN_ACCOUNT_ADDRESS, process.env.LSN_ACCOUNT_PASSWORD, 1000)
    .then(async () => {
        console.log('create alice.lsn domain');
        const subowner = await ens.setSubnodeOwner(
            'alice.lsn',
            process.env.LSN_ACCOUNT_ADDRESS,
            { from: process.env.LSN_ACCOUNT_ADDRESS }
        );
        console.log(subowner);
        console.log('check that alice.lsn has an owner');
        const alice = await ens.owner('alice.lsn');
        console.log(`alice: ${alice}`);
        console.log('check that bob.lsn does not have an owner');
        const bob = await ens.owner('bob.lsn');
        console.log(`bob: ${bob}`);
    })
    .catch((err) => {
        console.log(err);
    });
}

try {
    main();
} catch (err) {
    console.log(err);
}
