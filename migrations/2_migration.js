var Y = artifacts.require("Y");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(Y, 1, 100);
};
