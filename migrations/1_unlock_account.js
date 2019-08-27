
module.exports = (deployer) => {
  deployer.then(function() {
    return web3.eth.personal.unlockAccount('0xc916cfe5c83dd4fc3c3b0bf2ec2d4e401782875e', 'WelcomeToSirius', 1000)
      .then(console.log('Account unlocked!'))
      .catch((err) => {
        console.log(err);
      });
  });
};
