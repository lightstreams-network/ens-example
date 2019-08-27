const ENS = artifacts.require('@ensdomains/ens/ENSRegistry');
const FIFSRegistrar = artifacts.require('@ensdomains/ens/FIFSRegistrar');
const ReverseRegistrar = artifacts.require('@ensdomains/ens/ReverseRegistrar');
const PublicResolver = artifacts.require('@ensdomains/resolver/PublicResolver');

const utils = require('web3-utils');
const namehash = require('eth-ens-namehash');

const tld = 'test';

module.exports = function(deployer, network, accounts) {
  let ens;
  let resolver;
  let registrar;

  // Registry
  deployer.deploy(ENS)
  // Resolver
  .then(function(ensInstance) {
    ens = ensInstance;
    return deployer.deploy(PublicResolver, ens.address);
  })
  .then(function(resolverInstance) {
    resolver = resolverInstance;
    return setupResolver(ens, resolver, accounts);
  })
  // Registrar
  .then(function() {
    return deployer.deploy(FIFSRegistrar, ens.address, namehash.hash(tld));
  })
  .then(function(registrarInstance) {
    registrar = registrarInstance;
    return setupRegistrar(ens, registrar);
  })
  // Reverse Registrar
  .then(function() {
    return deployer.deploy(ReverseRegistrar, ens.address, resolver.address);
  })
  .then(function(reverseRegistrarInstance) {
    return setupReverseRegistrar(ens, resolver, reverseRegistrarInstance, accounts);
  })
  .then(() => {
		return setupLightstreamsTld(ens, registrar, resolver)
  })
};

async function setupResolver(ens, resolver, accounts) {
  const resolverNode = namehash.hash('resolver');
  const resolverLabel = utils.sha3('resolver');

  await ens.setSubnodeOwner('0x0000000000000000000000000000000000000000', resolverLabel, accounts[0]);
  await ens.setResolver(resolverNode, resolver.address);
  await resolver.setAddr(resolverNode, resolver.address);
}

async function setupRegistrar(ens, registrar) {
  await ens.setSubnodeOwner('0x0000000000000000000000000000000000000000', utils.sha3(tld), registrar.address);
}

async function setupReverseRegistrar(ens, resolver, reverseRegistrar, accounts) {
  await ens.setSubnodeOwner('0x0000000000000000000000000000000000000000', utils.sha3('reverse'), accounts[0]);
  await ens.setSubnodeOwner(namehash.hash('reverse'), utils.sha3('addr'), reverseRegistrar.address);
}

async function setupLightstreamsTld(ens, registrar, resolver) {
  await ens.setSubnodeOwner('0x0000000000000000000000000000000000000000', utils.sha3('lsn'), '0xc916cfe5c83dd4fc3c3b0bf2ec2d4e401782875e');
  await ens.setResolver(namehash.hash('lsn'), resolver.address);
  await resolver.setAddr(namehash.hash('lsn'), resolver.address);
}