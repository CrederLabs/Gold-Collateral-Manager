// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event OnChainTransactionFeeTransfer(address indexed from, address indexed to, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, UserLock {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // On-Chain Transaction fees(Decimals: 6): 200 -> 0.02%, 195 -> 0.0195%, 10000 -> 1%
    uint24 public onChainTransactionfee = 200;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual permissionCheck {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 fee = amount.mul(onChainTransactionfee).div(1000000);
        uint256 principle = amount.sub(fee);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(principle);
        emit Transfer(sender, recipient, principle);
        if (fee > 0) {
            _balances[address(0x000000000000000000000000000000000000dEaD)] = _balances[address(0x000000000000000000000000000000000000dEaD)].add(fee);
            emit OnChainTransactionFeeTransfer(sender, address(0x000000000000000000000000000000000000dEaD), fee);
        }
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface TheMiningClubInterface {
    function getGoldTypeOfTokenId(uint256 tokenId) external view returns (uint16);
}

contract GoldCollateralManager is ERC20, AccessControl, Pausable {
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

    /**
     * @dev unit: GPC(wei)
     */
    uint256 public totalCreatedGold = 0;
    uint256 public totalBurnedGold = 0;

    // ----------------------- Physical Gold -----------------------

    /**
    * @dev unit: GPC(wei)
    */
    uint256 public totalCreatedPhysicalGold = 0;
    uint256 public totalBurnedPhysicalGold = 0;

    struct PhysicalGoldHistory {
        address physicalGoldMinter;
        address userAccount;
        uint256 gpcAmount;
        uint256 timestamp;
    }

    mapping(address => PhysicalGoldHistory[]) public mintAllPhysicalGoldHistory;
    mapping(address => PhysicalGoldHistory[]) public burnAllPhysicalGoldHistory;

    constructor(IERC721 _goldNFTContract) ERC20("Gold Pegged Coin", "GPC") {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

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
        // for repay
        repaymentFeeAmount[1] = 1 * 10**18;
        repaymentFeeAmount[2] = 5 * 10**18;
        repaymentFeeAmount[3] = 10 * 10**18;
        repaymentFeeAmount[4] = 15 * 10**18;
        repaymentFeeAmount[5] = 20 * 10**18;
        repaymentFeeAmount[6] = 25 * 10**18;
        repaymentFeeAmount[7] = 30 * 10**18;
    }

    // ---------------------------------- Gold NFT ----------------------------------
    
    function createNewCollateral(uint256 _tokenId) public whenNotPaused {
        require(goldNFTContract.ownerOf(_tokenId) == msg.sender, "You don't own!");

        uint16 goldType = TheMiningClubInterface(address(goldNFTContract)).getGoldTypeOfTokenId(_tokenId);
        require(goldType > 0, "Invalid goldType");
        
        goldNFTContract.transferFrom(msg.sender, address(this), _tokenId);

        collaterals[_tokenId] = CollateralData(
            msg.sender,
            _tokenId,
            goldType,
            CollateralStatus.RECEIVED,
            block.timestamp
        );
        
        collateralIndexByAddress[msg.sender].push(_tokenId);

        uint256 gpcSupplyAmount = collateralExchangeAmount[goldType];
        require(gpcSupplyAmount > 0, "Invalid gpcSupplyAmount");

        // mint KIP-7(ERC-20)
        _mint(msg.sender, gpcSupplyAmount);

        // Info record (overflow check function added since 0.8.x or later. No need to use SafeMath)
        totalCreatedGold += gpcSupplyAmount;
        collateralTokenIds.push(_tokenId);

        // Leave a record for history inquiry
        userAllCollateralHistory[msg.sender].push(CollateralHistory(
            msg.sender,
            _tokenId,
            goldType,
            CollateralStatus.RECEIVED,
            block.timestamp
        ));

        emit CreateNewCollateral(msg.sender, _tokenId, goldType, gpcSupplyAmount, CollateralStatus.RECEIVED, block.timestamp);
    }

    // 1g -> 100 GPC
    function registerCollateralExchangeAmount(uint16 _goldType, uint256 _gpcAmount) public onlyOwner {
        collateralExchangeAmount[_goldType] = _gpcAmount;
        emit RegisterCollateralExchangeAmount(_goldType, _gpcAmount);
    }

    function deleteCollateralExchangeAmount(uint16 _goldType) public onlyOwner {
        delete collateralExchangeAmount[_goldType];
        emit DeleteCollateralExchangeAmount(_goldType);
    }

    function registerRepaymentFeeAmount(uint16 _goldType, uint256 _klayAmount) public onlyOwner {
        repaymentFeeAmount[_goldType] = _klayAmount;
        emit RegisterRepaymentFeeAmount(_goldType, _klayAmount);
    }

    function deleteRepaymentFeeAmount(uint16 _goldType) public onlyOwner {
        delete repaymentFeeAmount[_goldType];
        emit DeleteRepaymentFeeAmount(_goldType);
    }

    function findCollateralsByAddress() public view returns (uint256[] memory) {
        return collateralIndexByAddress[msg.sender];
    }

    function getCollateralsLengthByAddress(address _account) public view returns (uint256) {
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
    
    function repay(uint256 _tokenId) payable public whenNotPaused {
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
        
        // Burn
        IERC20(this).transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, gpcRepaymentAmount);
        
        collaterals[_tokenId].collateralStatus = CollateralStatus.RETURNED;

        // Delete the collateral information from the user's address
        uint256 indexOfTokenId = findCollateralIndexByAddressAndTokenId(_tokenId);
        removeForCollateralIndexByAddress(msg.sender, indexOfTokenId);
        
        // Give back NFTs
        goldNFTContract.transferFrom(address(this), msg.sender, _tokenId);

        // Info record (overflow check function added since 0.8.x or later. No need to use SafeMath)
        totalBurnedGold += gpcRepaymentAmount;

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

        emit Repay(msg.sender, _tokenId, goldType, gpcRepaymentAmount, CollateralStatus.RETURNED, block.timestamp);
    }

    function getTotalGPCSupply() public view returns(uint256) {
        return totalCreatedGold - totalBurnedGold;
    }

    // ---------------------------------- Physical Gold ----------------------------------
    
    function addPhysicalGoldMinter(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(PHYSICAL_GOLD_MINTER_ROLE, _account);
    }

    function deletePhysicalGoldMinter(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(PHYSICAL_GOLD_MINTER_ROLE, _account);
    }

    function mintBackedByPhysicalGold(uint256 _gpcAmount, address _recipient) public onlyRole(PHYSICAL_GOLD_MINTER_ROLE) {
        require(_gpcAmount > 0, "Invalid _gpcAmount");

        _mint(_recipient, _gpcAmount);

        totalCreatedPhysicalGold += _gpcAmount;
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

        // Burn
        IERC20(this).transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _gpcAmount);

        totalBurnedPhysicalGold += _gpcAmount;
        burnAllPhysicalGoldHistory[msg.sender].push(PhysicalGoldHistory(
            msg.sender,
            address(0),
            _gpcAmount,
            block.timestamp
        ));
        emit BurnBackedByPhysicalGold(msg.sender, _gpcAmount, block.timestamp);
    }

    function getPhysicalGoldTotalSupply() public view returns(uint256) {
        return totalCreatedPhysicalGold - totalBurnedPhysicalGold;
    }

    function recoverERC20(address _tokenAddress, uint256 _amount) public onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
        emit RecoverERC20(_tokenAddress, _amount);
    }

    function recoverERC721(address _tokenAddress, uint256 _tokenId) public onlyOwner {
        IERC721(_tokenAddress).transferFrom(address(this), msg.sender, _tokenId);
        emit RecoverERC721(_tokenAddress, _tokenId);
    }

    function recoverKLAY() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        emit RecoverKLAY(address(this).balance);
    }

    /* ========== EVENTS ========== */
    event CreateNewCollateral(address userAccount, uint256 tokenId, uint16 goldType, uint256 gpcSupplyAmount, CollateralStatus collateralStatus, uint256 timestamp);
    event RegisterCollateralExchangeAmount(uint16 _goldType, uint256 _gpcAmount);
    event DeleteCollateralExchangeAmount(uint16 _goldType);
    event RegisterRepaymentFeeAmount(uint16 _goldType, uint256 _klayAmount);
    event DeleteRepaymentFeeAmount(uint16 _goldType);
    event Repay(address userAccount, uint256 tokenId, uint16 goldType, uint256 gpcRepaymentAmount, CollateralStatus collateralStatus, uint256 timestamp);
    event MintBackedByPhysicalGold(address account, uint256 gpcAmount, uint256 timestamp);
    event BurnBackedByPhysicalGold(address account, uint256 gpcAmount, uint256 timestamp);
    event RecoverERC20(address _tokenAddress, uint256 _amount);
    event RecoverERC721(address _tokenAddress, uint256 _tokenId);
    event RecoverKLAY(uint256 _amount);
}