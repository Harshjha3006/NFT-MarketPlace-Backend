const { ethers } = require("hardhat");

async function mint() {
    const basicNft = await ethers.getContract("BasicNft");
    console.log("Minting ...");
    const mintTx = await basicNft.mintNft();
    const mintTxReceipt = await mintTx.wait(1);
    const tokenId = mintTxReceipt.events[0].args.tokenId;
    console.log(`Token Id : ${tokenId}`);
    console.log(`Nft Address : ${basicNft.address}`);
}
mint().then(() => {
    process.exit(0);
}).catch((e) => {
    console.log(e);
    process.exit(1);
})