require('dotenv').config();
const ENS = require('ethereum-ens');
const Web3 = require('web3');
const ensRegistry = require('../build/contracts/ENSRegistry.json').networks;
const publicResolver = require('../build/contracts/PublicResolver.json').networks;
const truffleConfig = require('../truffle-config');
const networkId = truffleConfig.networks.standalone.network_id;

const provider = new Web3.providers.HttpProvider('http://localhost:8545');
const ens = new ENS(provider, ensRegistry[networkId].address);
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

        console.log('Set public resolver for alice.lsn');
        await ens.setResolver('alice.lsn', publicResolver[networkId].address, { from: process.env.LSN_ACCOUNT_ADDRESS })

        console.log('Set address for alice.lsn')
        await ens.resolver('alice.lsn').setAddr(process.env.LSN_ACCOUNT_ADDRESS, { from: process.env.LSN_ACCOUNT_ADDRESS });
        const resolvedAlice = await ens.resolver('alice.lsn').addr();
        console.log(`alice.lsn points to: ${resolvedAlice}`);

        console.log('check that alice.lsn has an owner');
        const alice = await ens.owner('alice.lsn');
        console.log(`alice: ${alice}`);

        console.log('check that bob.lsn does not have an owner');
        const bob = await ens.owner('bob.lsn');
        console.log(`bob: ${bob}`);

        // The following would throw because bob.lsn is not resolved
        // const resolvedBob = await ens.resolver('bob.lsn').addr();
        // console.log(`bob.lsn points to: ${resolvedBob}`);

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
