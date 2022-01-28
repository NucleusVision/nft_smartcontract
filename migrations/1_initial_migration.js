const Migrations = artifacts.require("Migrations");
const Pass = artifacts.require("Pass");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Pass);
};
