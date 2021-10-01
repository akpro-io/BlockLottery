require("@nomiclabs/hardhat-waffle");

const ALCHEMY_API_URL = "https://eth-rinkeby.alchemyapi.io/v2/CV-yjeQdG6iop33B4UE5LhABZ2sOMaTr"

const RINKEBY_PRIVATE_KEY = "adc6ee694b6566bd0e3df007edfbe1612ae45f3577c8801c4d28fdc8834abccf"

module.exports = {
  solidity: "0.8.0",
  networks: {
    rinkeby: {
      url: `${ALCHEMY_API_URL}`,
      accounts: [`0x${RINKEBY_PRIVATE_KEY}`],
    },
  },
};
