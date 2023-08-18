
const hre = require("hardhat");

async function sleep(ms){
  return new Promise((resolve)=>setTimeout(resolve,ms))
}

async function main() {
  //deploy nft contract
  const nftContract = await hre.ethers.deployContract("CryptoDevsNFT")
  await nftContract.waitForDeployment()
  console.log("CryptoDevsNFT deployed to:",nftContract.target)

  //deploy the fake nft market place
  const fakeNftmarketplaceContract = await hre.ethers.deployContract("FakeNFTMarketplace")
  await fakeNftmarketplaceContract.waitForDeployment()

  console.log("FakeNFTMarketPlace deployed to :",fakeNftmarketplaceContract.target)

  //deploy DAO contract
  const amount = hre.ethers.parseEther("1");
  const daoContract = await hre.ethers.deployContract("CryptoDevsDAO",[fakeNftmarketplaceContract.target,nftContract.target,],{value:amount,})
  await daoContract.waitForDeployment()

  console.log("CryptoDevsDao Contract deployed to :",daoContract.target)

  await sleep(30 * 1000)

  //verify the NFT contract
  await hre.run("verify:verify",{
    address: nftContract.target,
    constructorArguments:[],
  })

  //verify the fake nft marketplace contract
  await hre.run("verify:verify",{
    address: fakeNftmarketplaceContract.target,
    constructorArguments:[],
  })

  //verify the Dao contract
  await hre.run("verify:verify",{
    address: daoContract.target,
    constructorArguments:[
      fakeNftmarketplaceContract.target,
      nftContract.target,
    ],
  })

}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
