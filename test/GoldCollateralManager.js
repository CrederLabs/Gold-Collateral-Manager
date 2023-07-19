const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("GoldCollateralManager", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployFixture() {
        const tokenId = 1;
        const goldType = 1;
        const gpcRepaymentAmount = "5000000000000000000";

        const COLLATERAL_STATUS_RECEIVED = 1;
        const COLLATERAL_STATUS_RETURNED = 2;

        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();

        const DevNFT = await ethers.getContractFactory("DevNFT");
        const devNFT = await DevNFT.deploy();

        await devNFT.mintTheMiningClub(owner.address, tokenId, goldType);

        const GoldCollateralManager = await ethers.getContractFactory("GoldCollateralManager");
        const goldCollateralManager = await GoldCollateralManager.deploy(devNFT.target);

        return { tokenId, goldType, gpcRepaymentAmount, devNFT, goldCollateralManager, owner, otherAccount, COLLATERAL_STATUS_RECEIVED, COLLATERAL_STATUS_RETURNED };
    }

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            const { goldCollateralManager, owner } = await loadFixture(deployFixture);

            expect(await goldCollateralManager.owner()).to.equal(owner.address);
        });

        it("Should receive NFT", async function () {
            const { devNFT, tokenId, owner } = await loadFixture(deployFixture);

            expect(await devNFT.ownerOf(tokenId)).to.equal(owner.address);
        });

        describe("Validations", function () {
            it("Should exchange 0.05g to 5000000000000000000 GPC", async function () {
                const { goldCollateralManager } = await loadFixture(deployFixture);

                expect(await goldCollateralManager.collateralExchangeAmount(1)).to.equal("5000000000000000000");
            });

            it("Should exchange 1g to 100000000000000000000 GPC", async function () {
                const { goldCollateralManager } = await loadFixture(deployFixture);

                expect(await goldCollateralManager.collateralExchangeAmount(2)).to.equal("100000000000000000000");
            });

            it("Should exchange 5g to 500000000000000000000 GPC", async function () {
                const { goldCollateralManager } = await loadFixture(deployFixture);

                expect(await goldCollateralManager.collateralExchangeAmount(3)).to.equal("500000000000000000000");
            });

            it("Should exchange 10g to 1000000000000000000000 GPC", async function () {
                const { goldCollateralManager } = await loadFixture(deployFixture);

                expect(await goldCollateralManager.collateralExchangeAmount(4)).to.equal("1000000000000000000000");
            });

            it("Should exchange 50g to 5000000000000000000000 GPC", async function () {
                const { goldCollateralManager } = await loadFixture(deployFixture);

                expect(await goldCollateralManager.collateralExchangeAmount(5)).to.equal("5000000000000000000000");
            });

            it("Should exchange 100g to 10000000000000000000000 GPC", async function () {
                const { goldCollateralManager } = await loadFixture(deployFixture);

                expect(await goldCollateralManager.collateralExchangeAmount(6)).to.equal("10000000000000000000000");
            });

            it("Should exchange 200g to 20000000000000000000000 GPC", async function () {
                const { goldCollateralManager } = await loadFixture(deployFixture);

                expect(await goldCollateralManager.collateralExchangeAmount(7)).to.equal("20000000000000000000000");
            });
        });
    });

    describe("CreateNewCollateral", function () {
        it("Should be CollateralStatus.RECEIVED", async function () {
            const { devNFT, goldCollateralManager, tokenId, COLLATERAL_STATUS_RECEIVED } = await loadFixture(deployFixture);

            await devNFT.approve(goldCollateralManager.target, tokenId);
            await goldCollateralManager.createNewCollateral(tokenId);

            let resultCollaterals = await goldCollateralManager.collaterals(tokenId);
            expect(parseInt(resultCollaterals[3])).to.equal(COLLATERAL_STATUS_RECEIVED);
        });

        it("Should transfer NFT to GoldCollateralManager Contract", async function () {
            const { devNFT, goldCollateralManager, tokenId } = await loadFixture(deployFixture);
            
            await devNFT.approve(goldCollateralManager.target, tokenId);
            await goldCollateralManager.createNewCollateral(tokenId);

            expect(await devNFT.ownerOf(tokenId)).to.equal(goldCollateralManager.target);
        });

        it("Should transfer GPC to the owner", async function () {
            const { devNFT, goldCollateralManager, tokenId, owner } = await loadFixture(deployFixture);
            
            await devNFT.approve(goldCollateralManager.target, tokenId);
            await goldCollateralManager.createNewCollateral(tokenId);

            expect(await goldCollateralManager.balanceOf(owner)).to.equal("5000000000000000000");
        });

        it("Should find owner's collateral token ids", async function () {
            const { devNFT, goldCollateralManager, tokenId } = await loadFixture(deployFixture);

            await devNFT.approve(goldCollateralManager.target, tokenId);
            await goldCollateralManager.createNewCollateral(tokenId);
            let resultCollaterals = await goldCollateralManager.findCollateralsByAddress();

            expect(parseInt(resultCollaterals[0])).to.equal(tokenId);
        });
    });

    describe("OnChainTransactionFee", function () {
        it("Should charge a 0.02% fee the amount of GPC sent on the blockchain", async function () {
            const { devNFT, goldCollateralManager, tokenId, otherAccount } = await loadFixture(deployFixture);

            await devNFT.approve(goldCollateralManager.target, tokenId);
            await goldCollateralManager.createNewCollateral(tokenId);

            await goldCollateralManager.transfer(otherAccount, "1000000000000000000");

            // Principle
            expect(await goldCollateralManager.balanceOf(otherAccount)).to.equal("999800000000000000");
        });
    });

    describe("Repay", function () {
        it("Should be CollateralStatus.RETURNED", async function () {
            const { devNFT, goldCollateralManager, tokenId, gpcRepaymentAmount, COLLATERAL_STATUS_RETURNED } = await loadFixture(deployFixture);

            await devNFT.approve(goldCollateralManager.target, tokenId);
            await goldCollateralManager.createNewCollateral(tokenId);

            await goldCollateralManager.approve(goldCollateralManager.target, gpcRepaymentAmount);
            await goldCollateralManager.repay(tokenId, {
                value: "1000000000000000000"
            });

            let resultCollaterals = await goldCollateralManager.collaterals(tokenId);

            expect(parseInt(resultCollaterals[3])).to.equal(COLLATERAL_STATUS_RETURNED);
        });

        it("Should burn GPC by GoldCollateralManager Contract", async function () {
            const { devNFT, goldCollateralManager, tokenId, gpcRepaymentAmount, owner } = await loadFixture(deployFixture);

            await devNFT.approve(goldCollateralManager.target, tokenId);
            await goldCollateralManager.createNewCollateral(tokenId);

            // await goldCollateralManager.approve(goldCollateralManager.target, gpcRepaymentAmount);
            await goldCollateralManager.repay(tokenId, {
                value: "1000000000000000000"
            });

            // expect(await goldCollateralManager.balanceOf("0x000000000000000000000000000000000000dEaD")).to.equal("5000000000000000000");
            expect(await goldCollateralManager.balanceOf(owner)).to.equal(0);
        });
        
        it("Should give back NFT to the owner", async function () {
            const { devNFT, goldCollateralManager, tokenId, owner, gpcRepaymentAmount } = await loadFixture(deployFixture);
            
            await devNFT.approve(goldCollateralManager.target, tokenId);
            await goldCollateralManager.createNewCollateral(tokenId);

            await goldCollateralManager.approve(goldCollateralManager.target, gpcRepaymentAmount);
            await goldCollateralManager.repay(tokenId, {
                value: "1000000000000000000"
            });

            expect(await devNFT.ownerOf(tokenId)).to.equal(owner.address);
        });

        it("Should delete owner's collateral token ids", async function () {
            const { devNFT, goldCollateralManager, tokenId, gpcRepaymentAmount } = await loadFixture(deployFixture);

            await devNFT.approve(goldCollateralManager.target, tokenId);
            await goldCollateralManager.createNewCollateral(tokenId);

            await goldCollateralManager.approve(goldCollateralManager.target, gpcRepaymentAmount);
            await goldCollateralManager.repay(tokenId, {
                value: "1000000000000000000"
            });

            let resultCollaterals = await goldCollateralManager.findCollateralsByAddress();

            expect(parseInt(resultCollaterals.length)).to.equal(0);
        });
    });

    describe("UserLock", function () {
        it("LockUser should not transfer GPC", async function () {
            const { devNFT, goldCollateralManager, tokenId, owner, otherAccount } = await loadFixture(deployFixture);

            await devNFT.approve(goldCollateralManager.target, tokenId);
            await goldCollateralManager.createNewCollateral(tokenId);
            await goldCollateralManager.transfer(otherAccount, "1000000000000000000");

            await goldCollateralManager.lockUser(owner);
            await expect(goldCollateralManager.transfer(otherAccount, "1000000000000000000")).to.be.reverted;

            await goldCollateralManager.unlockUser(owner);
            await goldCollateralManager.transfer(otherAccount, "1000000000000000000");
            expect(await goldCollateralManager.balanceOf(otherAccount)).to.equal("1999600000000000000");
        });
    });

    describe("Physical Gold", function () {
        it("Only minter should mint GPC", async function () {
            const { goldCollateralManager, owner, otherAccount } = await loadFixture(deployFixture);

            await expect(goldCollateralManager.mintBackedByPhysicalGold("7000000000000000000", otherAccount)).to.be.reverted;

            await goldCollateralManager.addPhysicalGoldMinter(owner);
            await goldCollateralManager.mintBackedByPhysicalGold("7000000000000000000", otherAccount);
            expect(await goldCollateralManager.balanceOf(otherAccount)).to.equal("7000000000000000000");

            // burn
            await goldCollateralManager.mintBackedByPhysicalGold("7000000000000000000", owner);
            await goldCollateralManager.approve(goldCollateralManager.target, "5000000000000000000");
            await goldCollateralManager.burnBackedByPhysicalGold("5000000000000000000");

            await goldCollateralManager.deletePhysicalGoldMinter(owner);
            await expect(goldCollateralManager.mintBackedByPhysicalGold("2000000000000000000", otherAccount)).to.be.reverted;
        });
    });
});