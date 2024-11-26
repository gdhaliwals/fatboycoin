// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("Fatboy", (m) => {

  const charityWallet = m.getParameter("charityWallet", "0x0874a6df5bcabe616b988d57c2e81ea499851a90");  
  const initialOwner = m.getParameter("initialOwner", "0xE6Aa61C88BC4a178E53aD2d2A3BC0b07Fcfd576a");   

  const fatboy = m.contract("FatboyCoin", [charityWallet, initialOwner]);

  return { fatboy };
});
