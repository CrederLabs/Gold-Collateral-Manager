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

        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();

        const DevNFT = await ethers.getContractFactory("DevNFT");
        const devNFT = await DevNFT.deploy();

        await devNFT.mintTheMiningClub(owner.address, tokenId, goldType);

        const GoldCollateralManager = await ethers.getContractFactory("GoldCollateralManager");
        const goldCollateralManager = await GoldCollateralManager.deploy(devNFT.target);

        return { tokenId, goldType, devNFT, goldCollateralManager, owner, otherAccount };
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
});