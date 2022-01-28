require('dotenv').config()

const HDWalletProvider = require("@truffle/hdwallet-provider");
const privateKey = process.env.PRIVATEKEY;

module.exports = {
  networks: {
    development: {
      provider: () =>
        new HDWalletProvider(privateKey, `http://127.0.0.1:8545`),
        network_id: "*", // Any network (default: none)
    },
    mainnet: {
      provider: () => new HDWalletProvider(privateKey, `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`),
      network_id: 1,
      gas: 8000000,
      gasPrice: 518000000000,
      confirmations: 0,   // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 50,  // # of blocks before a deployment times out  (minimum/default: 50)
      websockets: true
    },
    rinkeby: {
      provider: () => new HDWalletProvider(privateKey, `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMYAPI_KEY}`),
      network_id: 4,
      gas: 8000000,
      gasPrice: 20000000000,
      confirmations: 0,   // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 50,  // # of blocks before a deployment times out  (minimum/default: 50)
      websockets: true
    },
    polytest: {
      provider: () => new HDWalletProvider(privateKey, `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMYAPI_KEY}`),
      network_id: 80001,
      confirmations: 0, // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 50, // # of blocks before a deployment times out  (minimum/default: 50)
      websockets: false,
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.4", // Fetch exact version from solc-bin (default: truffle's version)
      docker: false, // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {
        // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: "",
      },
    },
  },
  plugins: ["truffle-plugin-verify"],
  api_keys: {
    bscscan: process.env.BSCSCAN_API,
    etherscan: process.env.ETHERSCAN_API,
    polygonscan: process.env.POLYSCAN_API
  },
};