// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  // const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  // const unlockTime = currentTimestampInSeconds + 60;

  // lock 예제
  // const lockedAmount = hre.ethers.parseEther("0.001");
  // const lock = await hre.ethers.deployContract("Lock", [unlockTime], {
  //   value: lockedAmount,
  // });

  // await lock.waitForDeployment();

  // console.log(
  //   `Lock with ${ethers.formatEther(
  //     lockedAmount
  //   )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
  // );

  // 

  const [owner, otherAccount] = await ethers.getSigners();
  console.log("owner: ", owner);
  // console.log("otherAccount: ", otherAccount);

  let tokenId = 1;
  let goldType = 1;

  // NFT 컨트랙트
  const devNFT = await hre.ethers.deployContract("DevNFT");
  await devNFT.waitForDeployment();
  console.log("NFT 컨트랙트 배포 완료");

  await devNFT.mintTheMiningClub(owner.address, tokenId, goldType);
  console.log("NFT 민팅 완료");

  const goldCollateralManager = await hre.ethers.deployContract("GoldCollateralManager", [devNFT.target]);
  await goldCollateralManager.waitForDeployment();
  console.log("GoldCollateralManager 컨트랙트 배포 완료");

  // goldCollateralManager 에 GPC 교환 수량 등록(1g -> 100 GPC)
  // 0.05g -> 5 GPC
  await goldCollateralManager.registerCollateralExchangeAmount(1, "5000000000000000000");
  
  // approve
  await devNFT.approve(goldCollateralManager.target, tokenId);
  console.log("approve 완료");

  // createNewCollateral
  await goldCollateralManager.createNewCollateral(tokenId);
  
  let collateral = await goldCollateralManager.collaterals(tokenId);
  console.log("collateral: ", collateral);

  let balance = await goldCollateralManager.balanceOf(owner);
  console.log("balance: ", balance);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
