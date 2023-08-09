// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// If MCGB NFT is deposited as collateral, 1g:100GPC pegged tokens are issued. (KIP-7 minting)
// If you pay off the 1g:100 GPC pegged token, you will get your collateral back. KIP-7 tokens received after that will be burned.
// Only one Gold NFT is dealt with. Other RWA assets such as palladium and copper should be handled by other contracts such as PCP and CCP, not GPC.

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

// ----------------------------------------------------------------------------
// Limit users in blacklist
// ----------------------------------------------------------------------------
contract UserLock is Ownable {
    mapping(address => bool) blacklist;
        
    event LockUser(address indexed who);
    event UnlockUser(address indexed who);

    modifier permissionCheck {
        require(!blacklist[msg.sender], "Blocked user");
        _;
    }
    
    function lockUser(address who) public onlyOwner {
        blacklist[who] = true;
        
        emit LockUser(who);
    }

    function unlockUser(address who) public onlyOwner {
        blacklist[who] = false;
        
        emit UnlockUser(who);
    }
}

contract GoldCollateralManager is ERC20, UserLock, AccessControl, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant PHYSICAL_GOLD_MINTER_ROLE = keccak256("PHYSICAL_GOLD_MINTER_ROLE");

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
        uint256 timestamp;
    }

    // exchange ratio
    mapping(uint16 => uint256) public collateralExchangeAmount;
    // repay fee
    mapping(uint16 => uint256) public repaymentFeeAmount;

    /**
     * @dev Mapping of Token Id to collateral data.
     */
    mapping(uint256 => CollateralData) public collaterals;

    struct CollateralHistory {
        address userAccount;
        uint256 tokenId;
        uint16 goldType;
        CollateralStatus collateralStatus;
        uint256 timestamp;
    }

    mapping(address => CollateralHistory[]) public userAllCollateralHistory;

    // In order to easily find the collateral that the user has
    mapping(address => uint256[]) public collateralIndexByAddress;

    // For checking the total number of collateral token ids
    uint256[] public collateralTokenIds;

    // ----------------------- Physical Gold -----------------------

    struct PhysicalGoldHistory {
        address physicalGoldMinter;
        address userAccount;
        uint256 gpcAmount;
        uint256 timestamp;
    }

    mapping(address => PhysicalGoldHistory[]) public mintAllPhysicalGoldHistory;
    mapping(address => PhysicalGoldHistory[]) public burnAllPhysicalGoldHistory;

    // 10kg
    uint256 public maxMintingAmount = 1000000 * 10**18;

    constructor(IERC721 _goldNFTContract) ERC20("Gold Pegged Coin", "GPC") {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        goldNFTContract = _goldNFTContract;

        // * (1g -> 100 GPC)
        // 1: 0.05g -> 5 GPC
        // 2: 1g -> 100 GPC
        // 3: 5g -> 500 GPC
        // 4: 10g -> 1000 GPC
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
        // KLAY fees for repay
        repaymentFeeAmount[1] = 1 * 10**18;
        repaymentFeeAmount[2] = 5 * 10**18;
        repaymentFeeAmount[3] = 10 * 10**18;
        repaymentFeeAmount[4] = 15 * 10**18;
        repaymentFeeAmount[5] = 20 * 10**18;
        repaymentFeeAmount[6] = 25 * 10**18;
        repaymentFeeAmount[7] = 30 * 10**18;
    }

    mapping (address => bool) private _locks;

    modifier nonReentrant {
        require(_locks[msg.sender] != true, "ReentrancyGuard: reentrant call");

        _locks[msg.sender] = true;

        _;
    
        _locks[msg.sender] = false;
    }

    function addAdminRole(address _account) public onlyOwner() {
        _grantRole(DEFAULT_ADMIN_ROLE, _account);
    }

    function deleteAdminRole(address _account) public onlyOwner() {
        _revokeRole(DEFAULT_ADMIN_ROLE, _account);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override permissionCheck {
        super._transfer(sender, recipient, amount);
    }

    // ---------------------------------- Gold NFT ----------------------------------
    
    function createNewCollateral(uint256 _tokenId) public whenNotPaused nonReentrant {
        require(goldNFTContract.ownerOf(_tokenId) == msg.sender, "You don't own!");

        uint16 goldType = TheMiningClubInterface(address(goldNFTContract)).getGoldTypeOfTokenId(_tokenId);
        require(goldType > 0, "Invalid goldType");

        uint256 gpcSupplyAmount = collateralExchangeAmount[goldType];
        require(gpcSupplyAmount > 0, "Invalid gpcSupplyAmount");

        goldNFTContract.transferFrom(msg.sender, address(this), _tokenId);

        collaterals[_tokenId] = CollateralData(
            msg.sender,
            _tokenId,
            goldType,
            CollateralStatus.RECEIVED,
            block.timestamp
        );
        
        collateralIndexByAddress[msg.sender].push(_tokenId);
        collateralTokenIds.push(_tokenId);

        // Leave a record for history inquiry
        userAllCollateralHistory[msg.sender].push(CollateralHistory(
            msg.sender,
            _tokenId,
            goldType,
            CollateralStatus.RECEIVED,
            block.timestamp
        ));

        // mint KIP-7(ERC-20)
        _mint(msg.sender, gpcSupplyAmount);

        emit CreateNewCollateral(msg.sender, _tokenId, goldType, gpcSupplyAmount, CollateralStatus.RECEIVED, block.timestamp);
    }

    // 1g -> 100 GPC
    function registerCollateralExchangeAmount(uint16 _goldType, uint256 _gpcAmount) public onlyOwner {
        require(_gpcAmount > 0, "Invalid _gpcAmount");
        collateralExchangeAmount[_goldType] = _gpcAmount;
        emit RegisterCollateralExchangeAmount(_goldType, _gpcAmount);
    }

    function deleteCollateralExchangeAmount(uint16 _goldType) public onlyOwner {
        delete collateralExchangeAmount[_goldType];
        emit DeleteCollateralExchangeAmount(_goldType);
    }

    function registerRepaymentFeeAmount(uint16 _goldType, uint256 _klayAmount) public onlyOwner {
        require(_klayAmount > 0, "Invalid _klayAmount");
        repaymentFeeAmount[_goldType] = _klayAmount;
        emit RegisterRepaymentFeeAmount(_goldType, _klayAmount);
    }

    function deleteRepaymentFeeAmount(uint16 _goldType) public onlyOwner {
        delete repaymentFeeAmount[_goldType];
        emit DeleteRepaymentFeeAmount(_goldType);
    }

    function findCollateralsByAddress() external view returns (uint256[] memory) {
        return collateralIndexByAddress[msg.sender];
    }

    function getCollateralsLengthByAddress(address _account) external view returns (uint256) {
        return collateralIndexByAddress[_account].length;
    }

    function findCollateralIndexByAddressAndTokenId(uint256 _tokenId) public view returns (uint256) {
        uint256 length = collateralIndexByAddress[msg.sender].length;
        uint256 indexOfTokenId;
        for (uint256 i = 0; i < length; i++) {
            if (collateralIndexByAddress[msg.sender][i] == _tokenId) {
                indexOfTokenId = i;
                break;
            }
        }
        return indexOfTokenId;
    }

    function removeForCollateralIndexByAddress(address _account, uint256 _index) private {
        require(_index < collateralIndexByAddress[_account].length, "index out of bound");

        for (uint256 i = _index; i < collateralIndexByAddress[_account].length - 1; i++) {
            collateralIndexByAddress[_account][i] = collateralIndexByAddress[_account][i + 1];
        }
        collateralIndexByAddress[_account].pop();
    }

    function findCollateralIndexByTokenId(uint256 _tokenId) public view returns (uint256) {
        uint256 length = collateralTokenIds.length;
        uint256 indexOfTokenId;
        for (uint256 i = 0; i < length; i++) {
            if (collateralTokenIds[i] == _tokenId) {
                indexOfTokenId = i;
                break;
            }
        }
        return indexOfTokenId;
    }

    function removeForCollateralTokenIds(uint256 _index) private {
        require(_index < collateralTokenIds.length, "index out of bound");

        for (uint256 i = _index; i < collateralTokenIds.length - 1; i++) {
            collateralTokenIds[i] = collateralTokenIds[i + 1];
        }
        collateralTokenIds.pop();
    }
    
    function getCollateralHistoryByAddress(address account) public view returns(CollateralHistory[] memory) {
        return userAllCollateralHistory[account];
    }
    
    function repay(uint256 _tokenId) payable public whenNotPaused nonReentrant {
        require(collaterals[_tokenId].userAccount == msg.sender, "Not matched userAccount");
        require(collaterals[_tokenId].collateralStatus == CollateralStatus.RECEIVED, "No received collateral");

        uint16 goldType = TheMiningClubInterface(address(goldNFTContract)).getGoldTypeOfTokenId(_tokenId);
        require(goldType > 0, "Invalid goldType");

        uint256 gpcRepaymentAmount = collateralExchangeAmount[goldType];
        require(gpcRepaymentAmount > 0, "Invalid gpcRepaymentAmount");

        // 0.05g: 1 KLAY
        // 1g: 5 KLAY
        // 5g: 10 KLAY
        // 10g: 15 KLAY
        // 50g: 20 KLAY
        // 100g: 25 KLAY
        // 200g: 30 KLAY
        require(msg.value == repaymentFeeAmount[goldType], "Insufficient KLAY Fee"); 
        
        _burn(msg.sender, gpcRepaymentAmount);

        collaterals[_tokenId].collateralStatus = CollateralStatus.RETURNED;

        // Delete the collateral information from the user's address
        uint256 indexOfTokenId = findCollateralIndexByAddressAndTokenId(_tokenId);
        removeForCollateralIndexByAddress(msg.sender, indexOfTokenId);

        uint256 indexOfTokenId2 = findCollateralIndexByTokenId(_tokenId);
        removeForCollateralTokenIds(indexOfTokenId2);

        // Leave a record for history inquiry
        userAllCollateralHistory[msg.sender].push(CollateralHistory(
            msg.sender,
            _tokenId,
            goldType,
            CollateralStatus.RETURNED,
            block.timestamp
        ));

        // Give back NFTs
        goldNFTContract.transferFrom(address(this), msg.sender, _tokenId);

        emit Repay(msg.sender, _tokenId, goldType, gpcRepaymentAmount, CollateralStatus.RETURNED, block.timestamp);
    }

    // ---------------------------------- Physical Gold ----------------------------------
    
    function addPhysicalGoldMinter(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(PHYSICAL_GOLD_MINTER_ROLE, _account);
    }

    function deletePhysicalGoldMinter(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(PHYSICAL_GOLD_MINTER_ROLE, _account);
    }

    function setMaxMintingAmount(uint256 _maxMintingAmount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_maxMintingAmount > 0, "Invalid _maxMintingAmount");
        maxMintingAmount = _maxMintingAmount;
        emit SetMaxMintingAmount(maxMintingAmount);
    }

    function mintBackedByPhysicalGold(uint256 _gpcAmount, address _recipient) public onlyRole(PHYSICAL_GOLD_MINTER_ROLE) {
        require(_recipient != address(0), "Invalid _recipient address");
        require(_gpcAmount > 0, "Invalid _gpcAmount");
        require(totalSupply() <= maxMintingAmount, "totalSupply amount should be lower than maxMintingAmount or equal maxMintingAmount.");

        _mint(_recipient, _gpcAmount);

        mintAllPhysicalGoldHistory[msg.sender].push(PhysicalGoldHistory(
            msg.sender,
            _recipient,
            _gpcAmount,
            block.timestamp
        ));
        emit MintBackedByPhysicalGold(msg.sender, _gpcAmount, block.timestamp);
    }

    function burnBackedByPhysicalGold(uint256 _gpcAmount) public onlyRole(PHYSICAL_GOLD_MINTER_ROLE) {
        require(_gpcAmount > 0, "Invalid _gpcAmount");

        _burn(msg.sender, _gpcAmount);

        burnAllPhysicalGoldHistory[msg.sender].push(PhysicalGoldHistory(
            msg.sender,
            address(0),
            _gpcAmount,
            block.timestamp
        ));
        emit BurnBackedByPhysicalGold(msg.sender, _gpcAmount, block.timestamp);
    }

    function recoverERC20(address _tokenAddress, uint256 _amount) public onlyOwner {
        IERC20(_tokenAddress).safeTransfer(msg.sender, _amount);
        emit RecoverERC20(_tokenAddress, _amount);
    }

    function recoverERC721(address _tokenAddress, uint256 _tokenId) public onlyOwner {
        require(_tokenAddress != address(goldNFTContract), "_tokenAddress cannot be goldNFTContract address.");

        IERC721(_tokenAddress).transferFrom(address(this), msg.sender, _tokenId);
        emit RecoverERC721(_tokenAddress, _tokenId);
    }

    function recoverKLAY() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        emit RecoverKLAY(address(this).balance);
    }

    /* ========== EVENTS ========== */
    event CreateNewCollateral(address indexed userAccount, uint256 tokenId, uint16 goldType, uint256 gpcSupplyAmount, CollateralStatus collateralStatus, uint256 timestamp);
    event RegisterCollateralExchangeAmount(uint16 _goldType, uint256 _gpcAmount);
    event DeleteCollateralExchangeAmount(uint16 _goldType);
    event RegisterRepaymentFeeAmount(uint16 _goldType, uint256 _klayAmount);
    event DeleteRepaymentFeeAmount(uint16 _goldType);
    event Repay(address indexed userAccount, uint256 tokenId, uint16 goldType, uint256 gpcRepaymentAmount, CollateralStatus collateralStatus, uint256 timestamp);
    event MintBackedByPhysicalGold(address account, uint256 gpcAmount, uint256 timestamp);
    event BurnBackedByPhysicalGold(address account, uint256 gpcAmount, uint256 timestamp);
    event RecoverERC20(address _tokenAddress, uint256 _amount);
    event RecoverERC721(address _tokenAddress, uint256 _tokenId);
    event RecoverKLAY(uint256 _amount);
    event SetMaxMintingAmount(uint256 _maxMintingAmount);
}