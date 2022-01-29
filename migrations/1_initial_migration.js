const Migrations = artifacts.require("Migrations");
const NitroCollection = artifacts.require("NitroCollection");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(
    NitroCollection,
    "0xB81B872780468DD3361Cfed259369B4c4Bc2BDb8",
    "0xC7D928ce79B872BebBefbEa62b56663Ad08A4012",
    "0x46115978B77B9D20E9e1A9Ed74E12CA8C0fA8E3A",
    1,
    "450",
    "#",
    "0x4d09c1eBa78c6f8EC4bB443F949118C9c5C2ad3B"
  );
};
