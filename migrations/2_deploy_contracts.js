var Splitter = artifacts.require("./Splitter.sol");
var Remitance = artifacts.require("./Remitance.sol");

module.exports = function(deployer) {
  deployer.deploy(Splitter);
  deployer.deploy(Remitance);
};
