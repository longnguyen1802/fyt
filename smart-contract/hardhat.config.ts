import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  gasReporter: {
    enabled: true,
    currency: "ETH",
    outputFile: "gas-report.txt",
    noColors: false,
    // You can customize the gas reporter settings here
    // Check the Hardhat Gas Reporter documentation for more options
  },
};

export default config;
