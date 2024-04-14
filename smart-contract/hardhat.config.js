/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-ethers");
require("hardhat-gas-reporter");

module.exports = {
  solidity: "0.8.20",
  esm: {
    nodeInterop: true,
  },
  gasReporter: {
    enabled: true,
    currency: "ETH",
    outputFile: "gas-report.txt",
    noColors: false,
    // You can customize the gas reporter settings here
    // Check the Hardhat Gas Reporter documentation for more options
  },
};
