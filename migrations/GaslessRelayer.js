const GaslessRelayer = artifacts.require("GaslessRelayer");

module.exports = function (deployer) {
  deployer.deploy(GaslessRelayer, deployer.networks[deployer.network].accounts[0], web3.utils.toWei('10', 'gwei'));
};
