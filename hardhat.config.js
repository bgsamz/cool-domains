require('dotenv').config();
require("@nomiclabs/hardhat-waffle");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.10",
  networks: {
    mumbai: {
      url: process.env.ALCHEMY_URL,
      accounts: [process.env.TEST_ACCOUNT_PRIVATE_KEY],
    }
  }
};
