// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();

async function main() {
  let goldNFTAddress;
  if (process.env.NETWORK == "baobab") {
    console.log("baobab 환경 배포를 시작합니다.");
    goldNFTAddress = "0x270Aa1e899C6f96a2e954CA5c6FD5823Ae5a163C";
  } else if (process.env.NETWORK == "cypress") {
    console.log("cypress 환경 배포를 시작합니다.");
    goldNFTAddress = "0xCcC587f9c123cF0a2F2D51EC7e6033Ae94bFf4Ca";
  } else {
    console.log("local 환경 배포를 시작합니다.");

    const devNFT = await hre.ethers.deployContract("DevNFT");
    await devNFT.waitForDeployment();
    console.log("NFT 컨트랙트 배포 완료");
    goldNFTAddress = devNFT.target;
  }

  const goldCollateralManager = await hre.ethers.deployContract("GoldCollateralManager", [goldNFTAddress]);
  await goldCollateralManager.waitForDeployment();
  console.log("GoldCollateralManager 컨트랙트 배포 완료");
  console.log("goldCollateralManager Address: ", goldCollateralManager.target);

  

  // const [owner, otherAccount] = await ethers.getSigners();
  // console.log("owner: ", owner.address);

  // let tokenId = 1;
  // let goldType = 1;

  // // NFT 컨트랙트
  // const devNFT = await hre.ethers.deployContract("DevNFT");
  // await devNFT.waitForDeployment();
  // console.log("NFT 컨트랙트 배포 완료");

  // await devNFT.mintTheMiningClub(owner.address, tokenId, goldType);
  // console.log("NFT 민팅 완료");

  // const goldCollateralManager = await hre.ethers.deployContract("GoldCollateralManager", [devNFT.target]);
  // await goldCollateralManager.waitForDeployment();
  // console.log("GoldCollateralManager 컨트랙트 배포 완료");
  // console.log("goldCollateralManager Address: ", goldCollateralManager.target);

  // // goldCollateralManager 에 GPC 교환 수량 등록(1g -> 100 GPC)
  // // 0.05g -> 5 GPC
  // await goldCollateralManager.registerCollateralExchangeAmount(1, "5000000000000000000");
  
  // // approve
  // await devNFT.approve(goldCollateralManager.target, tokenId);
  // console.log("approve 완료");

  // // createNewCollateral
  // await goldCollateralManager.createNewCollateral(tokenId);
  
  // let collateral = await goldCollateralManager.collaterals(tokenId);
  // console.log("collateral: ", collateral);

  // let balance = await goldCollateralManager.balanceOf(owner);
  // console.log("balance: ", balance + " GPC");

  // // 담보 상황 조회
  // let collateralTokenIds = await goldCollateralManager.findCollateralsByAddress();
  // console.log("담보 상황 조회: ", collateralTokenIds);

  // console.log("GPC 상환 및 담보 돌려받기 시작");

  // await goldCollateralManager.approve(goldCollateralManager.target, balance);
  // await goldCollateralManager.repay(tokenId);

  // balance = await goldCollateralManager.balanceOf(owner);
  // console.log("balance: ", balance + " GPC");

  // // NFT 소유 확인
  // let nftOwnerAddress = await devNFT.ownerOf(tokenId);
  // console.log("nftOwnerAddress: ", nftOwnerAddress);

  // collateralTokenIds = await goldCollateralManager.findCollateralsByAddress();
  // console.log("담보 상황 조회: ", collateralTokenIds);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
