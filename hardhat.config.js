require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  // solidity: "0.8.18",
  solidity: {
    compilers: [
      {
        version: "0.8.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      }
    ]
  },
  networks: {
    baobab: {
      url: process.env.BAOBAB_URL,
      gasPrice: 250000000000,
      accounts: [
        process.env.DEPLOYER || ''
      ],
      chainId: 1001,
      gas: 50000000,
    },
    cypress: {
      url: process.env.CYPRESS_URL,
      gasPrice: 250000000000,
      accounts: [
        process.env.DEPLOYER || ''
      ],
      chainId: 8217,
      gas: 50000000,
    }
  }
};
