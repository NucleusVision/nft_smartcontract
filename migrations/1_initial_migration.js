const NitroCollection = artifacts.require("NitroCollection");

module.exports = async function (deployer) {
  await deployer.deploy(
    NitroCollection,
    "0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664",
    "0xd586E7F844cEa2F87f50152665BCbc2C279D8d70",
    1,
    "750",
    "#",
    "0x13F6CaB2FFe949715467AD4C4D2D2A9cC2F2b982",
    "0x13F6CaB2FFe949715467AD4C4D2D2A9cC2F2b982"
  );

  await deployer.deploy(
    NitroCollection,
    "0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664",
    "0xd586E7F844cEa2F87f50152665BCbc2C279D8d70",
    2,
    "650",
    "#",
    "0x13F6CaB2FFe949715467AD4C4D2D2A9cC2F2b982",
    "0x13F6CaB2FFe949715467AD4C4D2D2A9cC2F2b982"
  );

  await deployer.deploy(
    NitroCollection,
    "0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664",
    "0xd586E7F844cEa2F87f50152665BCbc2C279D8d70",
    3,
    "550",
    "#",
    "0x13F6CaB2FFe949715467AD4C4D2D2A9cC2F2b982",
    "0x13F6CaB2FFe949715467AD4C4D2D2A9cC2F2b982"
  );
};
