/**
 *Submitted for verification at Etherscan.io on 2020-09-09
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/managment/Constants.sol

pragma solidity 0.5.17;


contract Constants {
    // Permissions bit constants
    uint256 public constant CAN_MINT_TOKENS = 0;
    uint256 public constant CAN_BURN_TOKENS = 1;
    uint256 public constant CAN_UPDATE_STATE = 2;
    uint256 public constant CAN_LOCK_TOKENS = 3;
    uint256 public constant CAN_UPDATE_PRICE = 4;
    uint256 public constant CAN_INTERACT_WITH_ALLOCATOR = 5;
    uint256 public constant CAN_SET_ALLOCATOR_MAX_SUPPLY = 6;
    uint256 public constant CAN_PAUSE_TOKENS = 7;
    uint256 public constant ECLIUDED_ADDRESSES = 8;
    uint256 public constant WHITELISTED = 9;
    uint256 public constant SIGNERS = 10;
    uint256 public constant EXTERNAL_CONTRIBUTORS = 11;
    uint256 public constant CAN_SEE_BALANCE = 12;
    uint256 public constant CAN_CANCEL_TRANSACTION = 13;
    uint256 public constant CAN_ALLOCATE_REFERRAL_TOKENS = 14;
    uint256 public constant CAN_SET_REFERRAL_MAX_SUPPLY = 15;
    uint256 public constant MANUAL_TOKENS_ALLOCATION = 16;
    uint256 public constant CAN_SET_WHITELISTED = 17;

    // Contract Registry keys
    uint256 public constant CONTRACT_TOKEN = 1;
    uint256 public constant CONTRACT_PRICING = 2;
    uint256 public constant CONTRACT_CROWDSALE = 3;
    uint256 public constant CONTRACT_ALLOCATOR = 4;
    uint256 public constant CONTRACT_AGENT = 5;
    uint256 public constant CONTRACT_FORWARDER = 6;
    uint256 public constant CONTRACT_REFERRAL = 7;
    uint256 public constant CONTRACT_STATS = 8;
    uint256 public constant CONTRACT_LOCKUP = 9;

    uint256 public constant YEAR_IN_SECONDS = 31556952;
    uint256 public constant SIX_MONTHS =  15778476;
    uint256 public constant MONTH_IN_SECONDS = 2629746;

    string public constant ERROR_ACCESS_DENIED = "ERROR_ACCESS_DENIED";
    string public constant ERROR_WRONG_AMOUNT = "ERROR_WRONG_AMOUNT";
    string public constant ERROR_NO_CONTRACT = "ERROR_NO_CONTRACT";
    string public constant ERROR_NOT_AVAILABLE = "ERROR_NOT_AVAILABLE";
}

// File: contracts/managment/Management.sol

pragma solidity 0.5.17;




contract Management is Ownable, Constants {

    // Contract Registry
    mapping (uint256 => address payable) public contractRegistry;

    // Permissions
    mapping (address => mapping(uint256 => bool)) public permissions;

    event PermissionsSet(
        address subject, 
        uint256 permission, 
        bool value
    );

    event ContractRegistered(
        uint256 key,
        address source,
        address target
    );

    function setPermission(
        address _address, 
        uint256 _permission, 
        bool _value
    )
        public
        onlyOwner
    {
        permissions[_address][_permission] = _value;
        emit PermissionsSet(_address, _permission, _value);
    }

    function registerContract(
        uint256 _key, 
        address payable _target
    ) 
        public 
        onlyOwner 
    {
        contractRegistry[_key] = _target;
        emit ContractRegistered(_key, address(0), _target);
    }

    function setWhitelisted(
        address _address,
        bool _value
    )
        public
    {
        require(
            permissions[msg.sender][CAN_SET_WHITELISTED] == true,
            ERROR_ACCESS_DENIED
        );

        permissions[_address][WHITELISTED] = _value;

        emit PermissionsSet(_address, WHITELISTED, _value);
    }

}

// File: contracts/managment/Managed.sol

pragma solidity 0.5.17;






contract Managed is Ownable, Constants {

    using SafeMath for uint256;

    Management public management;

    modifier requirePermission(uint256 _permissionBit) {
        require(
            hasPermission(msg.sender, _permissionBit),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier canCallOnlyRegisteredContract(uint256 _key) {
        require(
            msg.sender == management.contractRegistry(_key),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier requireContractExistsInRegistry(uint256 _key) {
        require(
            management.contractRegistry(_key) != address(0),
            ERROR_NO_CONTRACT
        );
        _;
    }

    constructor(address _managementAddress) public {
        management = Management(_managementAddress);
    }

    function setManagementContract(address _management) public onlyOwner {
        require(address(0) != _management, ERROR_NO_CONTRACT);

        management = Management(_management);
    }

    function hasPermission(address _subject, uint256 _permissionBit)
        internal
        view
        returns (bool)
    {
        return management.permissions(_subject, _permissionBit);
    }

}

// File: contracts/LockupContract.sol

pragma solidity 0.5.17;




contract LockupContract is Managed {
    using SafeMath for uint256;

    uint256 public constant PERCENT_ABS_MAX = 100;
    bool public isPostponedStart;
    uint256 public postponedStartDate;

    mapping(address => uint256[]) public lockedAllocationData;

    mapping(address => uint256) public manuallyLockedBalances;

    event Lock(address holderAddress, uint256 amount);

    constructor(address _management) public Managed(_management) {
        isPostponedStart = true;
    }

    function isTransferAllowed(
        address _address,
        uint256 _value,
        uint256 _time,
        uint256 _holderBalance
    )
    external
    view
    returns (bool)
    {
        uint256 unlockedBalance = getUnlockedBalance(
            _address,
            _time,
            _holderBalance
        );
        if (unlockedBalance >= _value) {
            return true;
        }
        return false;
    }

    function allocationLog(
        address _address,
        uint256 _amount,
        uint256 _startingAt,
        uint256 _lockPeriodInSeconds,
        uint256 _initialUnlockInPercent,
        uint256 _releasePeriodInSeconds
    )
        public
        requirePermission(CAN_LOCK_TOKENS)
    {
        lockedAllocationData[_address].push(_startingAt);
        if (_initialUnlockInPercent > 0) {
            _amount = _amount.mul(uint256(PERCENT_ABS_MAX)
                .sub(_initialUnlockInPercent)).div(PERCENT_ABS_MAX);
        }
        lockedAllocationData[_address].push(_amount);
        lockedAllocationData[_address].push(_lockPeriodInSeconds);
        lockedAllocationData[_address].push(_releasePeriodInSeconds);
        emit Lock(_address, _amount);
    }

    function getUnlockedBalance(
        address _address,
        uint256 _time,
        uint256 _holderBalance
    )
        public
        view
        returns (uint256)
    {
        uint256 blockedAmount = manuallyLockedBalances[_address];

        if (lockedAllocationData[_address].length == 0) {
            return _holderBalance.sub(blockedAmount);
        }
        uint256[] memory  addressLockupData = lockedAllocationData[_address];
        for (uint256 i = 0; i < addressLockupData.length / 4; i++) {
            uint256 lockedAt = addressLockupData[i.mul(4)];
            uint256 lockedBalance = addressLockupData[i.mul(4).add(1)];
            uint256 lockPeriodInSeconds = addressLockupData[i.mul(4).add(2)];
            uint256 _releasePeriodInSeconds = addressLockupData[
                i.mul(4).add(3)
            ];
            if (lockedAt == 0 && true == isPostponedStart) {
                if (postponedStartDate == 0) {
                    blockedAmount = blockedAmount.add(lockedBalance);
                    continue;
                }
                lockedAt = postponedStartDate;
            }
            if (lockedAt > _time) {
                blockedAmount = blockedAmount.add(lockedBalance);
                continue;
            }
            if (lockedAt.add(lockPeriodInSeconds) > _time) {
                if (lockedBalance == 0) {
                    blockedAmount = _holderBalance;
                    break;
                } else {
                    uint256 tokensUnlocked;
                    if (_releasePeriodInSeconds > 0) {
                        uint256 duration = (_time.sub(lockedAt))
                            .div(_releasePeriodInSeconds);
                        tokensUnlocked = lockedBalance.mul(duration)
                            .mul(_releasePeriodInSeconds)
                            .div(lockPeriodInSeconds);
                    }
                    blockedAmount = blockedAmount
                        .add(lockedBalance)
                        .sub(tokensUnlocked);
                }
            }
        }

        return _holderBalance.sub(blockedAmount);
    }

    function setManuallyLockedForAddress (
        address _holder,
        uint256 _balance
    )
        public
        requirePermission(CAN_LOCK_TOKENS)
    {
        manuallyLockedBalances[_holder] = _balance;
    }

    function setPostponedStartDate(uint256 _postponedStartDate)
        public
        requirePermission(CAN_LOCK_TOKENS)
    {
        postponedStartDate = _postponedStartDate;

    }
}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;



contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Mintable.sol

pragma solidity ^0.5.0;



/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

// File: contracts/allocator/TokenAllocator.sol

pragma solidity 0.5.17;



/// @title TokenAllocator
/// @author Applicature
/// @notice Contract responsible for defining distribution logic of tokens.
/// @dev Base class
contract TokenAllocator is Managed {

    uint256 public maxSupply;

    constructor(uint256 _maxSupply, address _management)
        public
        Managed(_management)
    {
        maxSupply = _maxSupply;
    }

    function allocate(
        address _holder,
        uint256 _tokens,
        uint256 _allocatedTokens
    )
        public
        requirePermission(CAN_INTERACT_WITH_ALLOCATOR)
    {
        require(
            tokensAvailable(_allocatedTokens) >= _tokens,
            ERROR_WRONG_AMOUNT
        );
        internalAllocate(_holder, _tokens);
    }

    function updateMaxSupply(uint256 _maxSupply)
        internal
        requirePermission(CAN_INTERACT_WITH_ALLOCATOR)
    {
        maxSupply = _maxSupply;
    }

    /// @notice Check whether contract is initialised
    /// @return true if initialized
    function isInitialized() public view returns (bool) {
        if (
            address(management) == address(0) ||
            management.contractRegistry(CONTRACT_TOKEN) == address(0) ||
            management.contractRegistry(CONTRACT_ALLOCATOR) != address(this)
        ) {
            return false;
        }
        return true;
    }

    /// @return available tokens
    function tokensAvailable(uint256 _allocatedTokens)
        public
        view
        returns (uint256)
    {
        return maxSupply.sub(_allocatedTokens);
    }

    function internalAllocate(
        address _holder,
        uint256 _tokens
    )
        internal;
}

// File: contracts/allocator/MintableTokenAllocator.sol

pragma solidity 0.5.17;




/// @title MintableTokenAllocator
/// @author Applicature
/// @notice Contract responsible for defining distribution logic of tokens.
/// @dev implementation
contract MintableTokenAllocator is TokenAllocator {

    constructor(uint256 _maxSupply, address _management)
        public
        TokenAllocator(_maxSupply, _management)
    {}

    /// @notice Check whether contract is initialised
    /// @return true if initialized
    function isInitialized() public view returns (bool) {
        return (
            super.isInitialized() &&
            hasPermission(address(this), CAN_MINT_TOKENS)
        );
    }


    function decreaseCap(uint256 _valueToSubtract)
        public
        requirePermission(CAN_INTERACT_WITH_ALLOCATOR)
        requireContractExistsInRegistry(CONTRACT_TOKEN)
    {
        require(
            maxSupply.sub(_valueToSubtract) >= ERC20Mintable(
                management.contractRegistry(CONTRACT_TOKEN)
            ).totalSupply(),
            ERROR_WRONG_AMOUNT
        );
        updateMaxSupply(maxSupply.sub(_valueToSubtract));
    }

    function internalAllocate(
        address _holder,
        uint256 _tokens
    )
        internal
        requireContractExistsInRegistry(CONTRACT_TOKEN)
        requirePermission(CAN_INTERACT_WITH_ALLOCATOR)
    {
        ERC20Mintable(management.contractRegistry(CONTRACT_TOKEN))
            .mint(_holder, _tokens);
    }

}

// File: contracts/CLIAllocator.sol

pragma solidity 0.5.17;




contract CLIAllocator is MintableTokenAllocator {

    /* solium-disable */
    address public constant strategicPartners = 0xd5249aB86Ef7cE0651DF1b111E607f59950514c3;
    address public constant promotionsBounty = 0x38069DD2C6D385a7dE7dbB90eF74E23B12D124e3;
    address public constant shareholders = 0xA210F19b4C1c52dB213f88fdCA76fD83859052FA;
    address public constant advisors = 0x5d6019C130158FC00bc4Dc1edc949Fa84b8ad098;
    address public constant pharmaIndustrialTrials = 0x880574A5b701e017C254840063DFBd1f59dF9a15;
    address public constant managementTeam = 0x1e2Ce74Bc0a9A9fB2D6b3f630d585E0c00FF66B0;
    address public constant teamIncentive = 0xD4184B19170af014c595EF0b0321760d89918B95;
    address public constant publicSaleTokensHolder = 0x9ED362b5A8aF29CBC06548ba5C2f40978ca48Ec1;
    address public constant applicature = 0x63e638d15462037161003a6083A9c4AeD50f8F73;

    uint256 public constant strategicPartnersTokensAmount = 20000000e18;
    uint256 public constant promotionsBountyTokensAmount = 5200000e18;
    uint256 public constant shareholdersTokensAmount = 25000000e18;
    uint256 public constant advisorsTokensAmount = 8000000e18;
    uint256 public constant applicatureTokensAmount = 2000000e18;
    uint256 public constant pharmaIndustrialTrialsTokensAmount = 10000000e18;
    uint256 public constant managementTeamTokensAmount = 25000000e18;
    uint256 public constant teamIncentiveTokensAmount = 24000000e18;
    uint256 public constant publicSaleTokensAmount = 60000000e18;
    /* solium-enable */

    bool public isAllocated;

    constructor(uint256 _maxSupply, address _management)
        public
        MintableTokenAllocator(_maxSupply, _management)
    {

    }

    function increasePublicSaleCap(uint256 valueToAdd)
        external
        canCallOnlyRegisteredContract(CONTRACT_CROWDSALE)
    {
        internalAllocate(publicSaleTokensHolder, valueToAdd);
    }

    function unlockManuallyLockedBalances(address _holder)
        public
        requirePermission(CAN_LOCK_TOKENS)
    {
        LockupContract lockupContract = LockupContract(
            management.contractRegistry(CONTRACT_LOCKUP)
        );
        lockupContract.setManuallyLockedForAddress(
            _holder,
            0
        );
    }

    function allocateRequiredTokensToHolders() public {
        require(isAllocated == false, ERROR_NOT_AVAILABLE);
        isAllocated = true;
        allocateTokensWithSimpleLockUp();
        allocateTokensWithComplicatedLockup();
        allocateTokensWithManualUnlock();
        allocatePublicSale();
    }

    function allocatePublicSale() private {
        internalAllocate(publicSaleTokensHolder, publicSaleTokensAmount);
    }

    function allocateTokensWithSimpleLockUp() private {
        LockupContract lockupContract = LockupContract(
            management.contractRegistry(CONTRACT_LOCKUP)
        );
        internalAllocate(strategicPartners, strategicPartnersTokensAmount);

        internalAllocate(promotionsBounty, promotionsBountyTokensAmount);
        lockupContract.allocationLog(
            promotionsBounty,
            promotionsBountyTokensAmount,
            0,
            SIX_MONTHS,
            0,
            SIX_MONTHS
        );
        internalAllocate(advisors, advisorsTokensAmount);
        lockupContract.allocationLog(
            advisors,
            advisorsTokensAmount,
            0,
            SIX_MONTHS,
            0,
            SIX_MONTHS
        );
        internalAllocate(applicature, applicatureTokensAmount);
        // 25% each  6 months
        lockupContract.allocationLog(
            applicature,
            applicatureTokensAmount,
            0,
            SIX_MONTHS.mul(4),
            0,
            SIX_MONTHS
        );
    }

    function allocateTokensWithComplicatedLockup() private {
        LockupContract lockupContract = LockupContract(
            management.contractRegistry(CONTRACT_LOCKUP)
        );

        internalAllocate(shareholders, shareholdersTokensAmount);
        lockupContract.allocationLog(
            shareholders,
            shareholdersTokensAmount.div(5),
            0,
            SIX_MONTHS,
            0,
            SIX_MONTHS
        );
        lockupContract.allocationLog(
            shareholders,
            shareholdersTokensAmount.sub(shareholdersTokensAmount.div(5)),
            0,
            uint256(48).mul(MONTH_IN_SECONDS),
            0,
            YEAR_IN_SECONDS
        );

        internalAllocate(managementTeam, managementTeamTokensAmount);
        lockupContract.allocationLog(
            managementTeam,
            managementTeamTokensAmount.mul(2).div(5),
            0,
            SIX_MONTHS,
            50,
            SIX_MONTHS
        );
        lockupContract.allocationLog(
            managementTeam,
            managementTeamTokensAmount.sub(
                managementTeamTokensAmount.mul(2).div(5)
            ),
            0,
            uint256(36).mul(MONTH_IN_SECONDS),
            0,
            YEAR_IN_SECONDS
        );
    }

    function allocateTokensWithManualUnlock() private {
        LockupContract lockupContract = LockupContract(
            management.contractRegistry(CONTRACT_LOCKUP)
        );

        internalAllocate(
            pharmaIndustrialTrials,
            pharmaIndustrialTrialsTokensAmount
        );
        lockupContract.setManuallyLockedForAddress(
            pharmaIndustrialTrials,
            pharmaIndustrialTrialsTokensAmount
        );
        internalAllocate(teamIncentive, teamIncentiveTokensAmount);
        lockupContract.setManuallyLockedForAddress(
            teamIncentive,
            teamIncentiveTokensAmount
        );
    }
}

// File: contracts/CLIToken.sol

pragma solidity 0.5.17;







contract CLIToken is ERC20, ERC20Detailed, Managed {

    modifier requireUnlockedBalance(
        address _address,
        uint256 _value,
        uint256 _time,
        uint256 _holderBalance
    ) {

        require(
            LockupContract(
                management.contractRegistry(CONTRACT_LOCKUP)
            ).isTransferAllowed(
                _address,
                _value,
                _time,
                _holderBalance
            ),
            ERROR_NOT_AVAILABLE
        );
        _;
    }

    constructor(
        address _management
    )
        public
        ERC20Detailed("ClinTex", "CTI", 18)
        Managed(_management)
    {
        _mint(0x8FAE27b50457C10556C45798c34f73AE263282a6, 151000000000000000);
    }

    function mint(
        address _account,
        uint256 _amount
    )
        public
        requirePermission(CAN_MINT_TOKENS)
        canCallOnlyRegisteredContract(CONTRACT_ALLOCATOR)
        returns (bool)
    {
        require(
            _amount <= CLIAllocator(
                management.contractRegistry(CONTRACT_ALLOCATOR)
            ).tokensAvailable(totalSupply()),
            ERROR_WRONG_AMOUNT
        );
        _mint(_account, _amount);
        return true;
    }

    function transfer(
        address _to,
        uint256 _tokens
    )
        public
        requireUnlockedBalance(
            msg.sender,
            _tokens,
            block.timestamp,
            balanceOf(msg.sender)
        )
        returns (bool)
    {
        super.transfer(_to, _tokens);

        return true;
    }

    function transferFrom(
        address _holder,
        address _to,
        uint256 _tokens
    )
        public
        requireUnlockedBalance(
            _holder,
            _tokens,
            block.timestamp,
            balanceOf(_holder)
        )
        returns (bool)
    {
        super.transferFrom(_holder, _to, _tokens);

        return true;
    }

    function burn(uint256 value)
        public
        requirePermission(CAN_BURN_TOKENS)
        requireUnlockedBalance(
            msg.sender,
            value,
            block.timestamp,
            balanceOf(msg.sender)
        )
    {
        require(balanceOf(msg.sender) >= value, ERROR_WRONG_AMOUNT);
        super._burn(msg.sender, value);
    }
}