/**
* @type import('hardhat/config').HardhatUserConfig
*/

require('dotenv').config()
require('@nomiclabs/hardhat-ethers')
require('@nomiclabs/hardhat-etherscan')

module.exports = {
  solidity: {
    version: '0.8.6',
    settings: {
      optimizer: {
        enabled: true,
        runs: 10_000,
      },
    },
  },
  defaultNetwork: "rinkeby",
  networks: {
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },
    hardhat: {
      forking: {
        // `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`
        url: `https://polygon-mumbai.infura.io/v3/${process.env.INFURA_PROJECT_ID}`
      }
    },
    arbitrum: {
      url: 'https://rinkeby.arbitrum.io/rpc',
      accounts: [process.env.WALLET_PRIVATE_KEY]
    },
    mumbai: {
      url: `https://polygon-mumbai.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: [process.env.WALLET_PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY
  }
}
