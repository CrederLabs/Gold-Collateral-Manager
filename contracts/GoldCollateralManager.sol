// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 역할: MCGB NFT를 담보로 맡기면 1:1 페깅 토큰을 빌려준다. (KIP-7 민팅) 
// 1:1 페깅 토큰을 갚으면 담보물을 다시 돌려준다. 이후 받은 KIP-7 토큰은 소각.
// Gold NFT 하나만 취급한다. 팔라듐, 구리 등 다른 RWA 자산은 PCP, CCP 등 다른 컨트랙트가 취급해야 한다.

// roller, pause

// GoldType
// 1: 0.05g
// 2: 1g
// 3: 5g
// 4: 10g
// 5: 50g
// 6: 100g 
// 7: 200g

interface TheMiningClubInterface {
    function getGoldTypeOfTokenId(uint256 tokenId) external view returns (uint16);
}

contract GoldCollateralManager is ERC20, Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC721 public immutable goldNFTContract;

    enum CollateralStatus {
        WAITING,
        RECEIVED,
        RETURNED
    }

    struct CollateralData {
        address userAccount;
        uint256 tokenId;
        uint16 goldType;
        CollateralStatus collateralStatus;
    }

    /**
     * @dev Mapping of Token Id to collateral data.
     */
    mapping(uint256 => CollateralData) public collaterals;

    // 유저가 갖고 있는 담보물을 쉽게 찾기 위해
    mapping(address => uint256[]) public collateralIndexByAddress;

    mapping(uint16 => uint256) public collateralExchangeAmount;

    /**
     * @dev unit: gram
     */
    uint256 public totalCollateralGold;

    constructor(IERC721 _goldNFTContract) ERC20("Gold Pegged Coin", "GPC") {
        goldNFTContract = _goldNFTContract;

        // * (1g -> 100 GPC)
        // 1: 0.05g -> 5 GPC
        // 2: 1g -> 100 GPC
        // 3: 5g -> 500 GPC
        // 4: 10g -> 1000 GPC;
        // 5: 50g -> 5000 GPC
        // 6: 100g -> 10000 GPC
        // 7: 200g -> 20000 GPC
        collateralExchangeAmount[1] = 5 * 10**18;
        collateralExchangeAmount[2] = 100 * 10**18;
        collateralExchangeAmount[3] = 500 * 10**18;
        collateralExchangeAmount[4] = 1000 * 10**18;
        collateralExchangeAmount[5] = 5000 * 10**18;
        collateralExchangeAmount[6] = 10000 * 10**18;
        collateralExchangeAmount[7] = 20000 * 10**18;
    }
    
    function createNewCollateral(uint256 _tokenId) public whenNotPaused {
        require(goldNFTContract.ownerOf(_tokenId) == msg.sender, "You don't own!");

        uint16 goldType = TheMiningClubInterface(address(goldNFTContract)).getGoldTypeOfTokenId(_tokenId);
        require(goldType > 0, "Invalid goldType");
        
        goldNFTContract.transferFrom(msg.sender, address(this), _tokenId);

        collaterals[_tokenId] = CollateralData(
            msg.sender,
            _tokenId,
            goldType,
            CollateralStatus.RECEIVED
        );

        collateralIndexByAddress[msg.sender].push(_tokenId);

        uint256 gpcSupplyAmount = collateralExchangeAmount[goldType];
        require(gpcSupplyAmount > 0, "Invalid gpcSupplyAmount");

        // mint KIP-7(ERC-20)
        _mint(msg.sender, gpcSupplyAmount);

        // TODO: hisotry 조회용 기록 남기기

        // TODO: emit event
        
    }

    // goldType 에 따른 교환비는 owner 가 추가 등록
    // 1g -> 100 GPC
    function registerCollateralExchangeAmount(uint16 _goldType, uint256 _gpcAmount) public onlyOwner {
        collateralExchangeAmount[_goldType] = _gpcAmount;
        // TODO: emit event
    }

    function deleteCollateralExchangeAmount(uint16 _goldType) public onlyOwner {
        delete collateralExchangeAmount[_goldType];
        // TODO: emit event
    }

    // TODO: find token id
    // 

    function repay(uint256 _tokenId) public whenNotPaused {
        require(collaterals[_tokenId].userAccount == msg.sender, "Not matched userAccount");
        require(collaterals[_tokenId].collateralStatus == CollateralStatus.RECEIVED, "No received collateral");

        uint16 goldType = TheMiningClubInterface(address(goldNFTContract)).getGoldTypeOfTokenId(_tokenId);
        require(goldType > 0, "Invalid goldType");

        uint256 gpcRepaymentAmount = collateralExchangeAmount[goldType];
        require(gpcRepaymentAmount > 0, "Invalid gpcRepaymentAmount");

        IERC20(this).transferFrom(msg.sender, address(this), gpcRepaymentAmount);
        
        // update 담보 status
        // collaterals[_tokenId] = CollateralData(
        //     msg.sender,
        //     _tokenId,
        //     goldType,
        //     CollateralStatus.RECEIVED
        // );
        collaterals[_tokenId].collateralStatus = CollateralStatus.RETURNED;
        
        // NFT 돌려주기
        goldNFTContract.transferFrom(address(this), msg.sender, _tokenId);

        

        // TODO: hisotry 조회용 기록 남기기

        // TODO: emit event

    }




}
