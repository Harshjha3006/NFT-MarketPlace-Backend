const { network } = require("hardhat");
const { devChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");
require("dotenv").config();
module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deployer } = await getNamedAccounts();
    const { deploy, log } = deployments;

    const args = [];
    const contract = await deploy("NftMarketPlace", {
        from: deployer,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
        args: args
    })
    if (!devChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying ..");
        await verify(contract.address, args);
    }
}
module.exports.tags = ["all", "nftmarketplace"];