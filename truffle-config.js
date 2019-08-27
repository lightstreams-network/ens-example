module.exports = {
  networks: {
    ganache: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      gasPrice: "500000000000"
    },

    sirius: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "162",
      gasPrice: "500000000000",
      from: "0xd119b8b038d3a67d34ca1d46e1898881626a082b"
    },

    standalone: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "161",
      gasPrice: "500000000000",
      from: "0xc916cfe5c83dd4fc3c3b0bf2ec2d4e401782875e"
    }
  },
  compilers: {
    solc: {
      settings: {
        version: "0.5.1",    // Fetch exact version from solc-bin (default: truffle's version)
        // optimizer: {
        //   enabled: true, // Default: false
        //   runs: 200      // Default: 200
        // },
      }
    }
  }
};