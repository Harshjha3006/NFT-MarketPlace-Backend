const { ethers } = require("hardhat");

async function mintAndList() {
    const nftMarketPlace = await ethers.getContract("NftMarketPlace");
    const basicNft = await ethers.getContract("BasicNft");
    const PRICE = ethers.utils.parseEther("0.1");
    console.log("Minting ...");
    const mintTx = await basicNft.mintNft();
    const mintTxReceipt = await mintTx.wait(1);
    const tokenId = mintTxReceipt.events[0].args.tokenId;
    console.log("Approving ...");
    const approveTx = await basicNft.approve(nftMarketPlace.address, tokenId);
    await approveTx.wait(1);
    console.log("Listing ...");
    const listTx = await nftMarketPlace.listItem(basicNft.address, tokenId, PRICE);
    await listTx.wait(1);
    console.log("NFT Listed ...");
}

mintAndList().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(1);
})