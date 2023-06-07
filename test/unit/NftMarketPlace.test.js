const { network, getNamedAccounts, ethers, deployments } = require("hardhat");
const { devChains } = require("../../helper-hardhat-config");
const { assert } = require("chai");

!devChains.includes(network.name) ?
    describe.skip :
    describe("Nft MarketPlace", function () {
        let nftMarketPlace, basicNft, deployer, user;
        const TOKEN_ID = 0;
        const PRICE = ethers.utils.parseEther("0.1");
        beforeEach(async function () {
            deployer = (await getNamedAccounts()).deployer;
            const accounts = await ethers.getSigners();
            user = accounts[1];
            await deployments.fixture(["all"]);
            nftMarketPlace = await ethers.getContract("NftMarketPlace");
            basicNft = await ethers.getContract("BasicNft");
            await basicNft.mintNft();
            await basicNft.approve(nftMarketPlace.address, TOKEN_ID);
        })
        it("lists item and can be bought", async function () {
            await nftMarketPlace.listItem(basicNft.address, TOKEN_ID, PRICE);
            const userConnectedContract = await nftMarketPlace.connect(user);
            await userConnectedContract.buyItem(basicNft.address, TOKEN_ID, { value: PRICE });
            const newOwner = await basicNft.ownerOf(TOKEN_ID);
            const proceeds = await userConnectedContract.getProceeds(deployer);
            assert.equal(newOwner, user.address);
            assert.equal(proceeds.toString(), PRICE.toString());
        })
    })