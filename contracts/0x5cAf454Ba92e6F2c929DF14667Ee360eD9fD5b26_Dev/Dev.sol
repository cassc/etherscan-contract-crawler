/**
 *Submitted for verification at Etherscan.io on 2020-02-04
*/

pragma solidity ^0.5.0;

// prettier-ignore


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
// prettier-ignore



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
// prettier-ignore


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

// prettier-ignore



contract IGroup {
	function isGroup(address _addr) public view returns (bool);

	function addGroup(address _addr) external;

	function getGroupKey(address _addr) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("_group", _addr));
	}
}


contract AddressValidator {
	string constant errorMessage = "this is illegal address";

	function validateIllegalAddress(address _addr) external pure {
		require(_addr != address(0), errorMessage);
	}

	function validateGroup(address _addr, address _groupAddr) external view {
		require(IGroup(_groupAddr).isGroup(_addr), errorMessage);
	}

	function validateGroups(
		address _addr,
		address _groupAddr1,
		address _groupAddr2
	) external view {
		if (IGroup(_groupAddr1).isGroup(_addr)) {
			return;
		}
		require(IGroup(_groupAddr2).isGroup(_addr), errorMessage);
	}

	function validateAddress(address _addr, address _target) external pure {
		require(_addr == _target, errorMessage);
	}

	function validateAddresses(
		address _addr,
		address _target1,
		address _target2
	) external pure {
		if (_addr == _target1) {
			return;
		}
		require(_addr == _target2, errorMessage);
	}
}


contract UsingValidator {
	AddressValidator private _validator;

	constructor() public {
		_validator = new AddressValidator();
	}

	function addressValidator() internal view returns (AddressValidator) {
		return _validator;
	}
}




contract Killable {
	address payable public _owner;

	constructor() internal {
		_owner = msg.sender;
	}

	function kill() public {
		require(msg.sender == _owner, "only owner method");
		selfdestruct(_owner);
	}
}

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
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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


contract AddressConfig is Ownable, UsingValidator, Killable {
	address public token = 0x98626E2C9231f03504273d55f397409deFD4a093;
	address public allocator;
	address public allocatorStorage;
	address public withdraw;
	address public withdrawStorage;
	address public marketFactory;
	address public marketGroup;
	address public propertyFactory;
	address public propertyGroup;
	address public metricsGroup;
	address public metricsFactory;
	address public policy;
	address public policyFactory;
	address public policySet;
	address public policyGroup;
	address public lockup;
	address public lockupStorage;
	address public voteTimes;
	address public voteTimesStorage;
	address public voteCounter;
	address public voteCounterStorage;

	function setAllocator(address _addr) external onlyOwner {
		allocator = _addr;
	}

	function setAllocatorStorage(address _addr) external onlyOwner {
		allocatorStorage = _addr;
	}

	function setWithdraw(address _addr) external onlyOwner {
		withdraw = _addr;
	}

	function setWithdrawStorage(address _addr) external onlyOwner {
		withdrawStorage = _addr;
	}

	function setMarketFactory(address _addr) external onlyOwner {
		marketFactory = _addr;
	}

	function setMarketGroup(address _addr) external onlyOwner {
		marketGroup = _addr;
	}

	function setPropertyFactory(address _addr) external onlyOwner {
		propertyFactory = _addr;
	}

	function setPropertyGroup(address _addr) external onlyOwner {
		propertyGroup = _addr;
	}

	function setMetricsFactory(address _addr) external onlyOwner {
		metricsFactory = _addr;
	}

	function setMetricsGroup(address _addr) external onlyOwner {
		metricsGroup = _addr;
	}

	function setPolicyFactory(address _addr) external onlyOwner {
		policyFactory = _addr;
	}

	function setPolicyGroup(address _addr) external onlyOwner {
		policyGroup = _addr;
	}

	function setPolicySet(address _addr) external onlyOwner {
		policySet = _addr;
	}

	function setPolicy(address _addr) external {
		addressValidator().validateAddress(msg.sender, policyFactory);
		policy = _addr;
	}

	function setToken(address _addr) external onlyOwner {
		token = _addr;
	}

	function setLockup(address _addr) external onlyOwner {
		lockup = _addr;
	}

	function setLockupStorage(address _addr) external onlyOwner {
		lockupStorage = _addr;
	}

	function setVoteTimes(address _addr) external onlyOwner {
		voteTimes = _addr;
	}

	function setVoteTimesStorage(address _addr) external onlyOwner {
		voteTimesStorage = _addr;
	}

	function setVoteCounter(address _addr) external onlyOwner {
		voteCounter = _addr;
	}

	function setVoteCounterStorage(address _addr) external onlyOwner {
		voteCounterStorage = _addr;
	}
}


contract UsingConfig {
	AddressConfig private _config;

	constructor(address _addressConfig) public {
		_config = AddressConfig(_addressConfig);
	}

	function config() internal view returns (AddressConfig) {
		return _config;
	}

	function configAddress() external view returns (address) {
		return address(_config);
	}
}

// prettier-ignore



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}



library Decimals {
	using SafeMath for uint256;
	uint120 private constant basisValue = 1000000000000000000;

	function outOf(uint256 _a, uint256 _b)
		internal
		pure
		returns (uint256 result)
	{
		if (_a == 0) {
			return 0;
		}
		uint256 a = _a.mul(basisValue);
		require(a > _b, "the denominator is too big");
		return (a.div(_b));
	}

	function basis() external pure returns (uint120) {
		return basisValue;
	}
}

// prettier-ignore



contract IAllocator {
	function allocate(address _metrics) external;

	function calculatedCallback(address _metrics, uint256 _value) external;

	function beforeBalanceChange(address _property, address _from, address _to)
		external;

	function getRewardsAmount(address _property)
		external
		view
		returns (uint256);

	function allocation(
		uint256 _blocks,
		uint256 _mint,
		uint256 _value,
		uint256 _marketValue,
		uint256 _assets,
		uint256 _totalAssets
	)
		public
		pure
		returns (
			// solium-disable-next-line indentation
			uint256
		);
}





contract EternalStorage {
	address private currentOwner = msg.sender;

	mapping(bytes32 => uint256) private uIntStorage;
	mapping(bytes32 => string) private stringStorage;
	mapping(bytes32 => address) private addressStorage;
	mapping(bytes32 => bytes32) private bytesStorage;
	mapping(bytes32 => bool) private boolStorage;
	mapping(bytes32 => int256) private intStorage;

	modifier onlyCurrentOwner() {
		require(msg.sender == currentOwner, "not current owner");
		_;
	}

	function changeOwner(address _newOwner) external {
		require(msg.sender == currentOwner, "not current owner");
		currentOwner = _newOwner;
	}

	// *** Getter Methods ***
	function getUint(bytes32 _key) external view returns (uint256) {
		return uIntStorage[_key];
	}

	function getString(bytes32 _key) external view returns (string memory) {
		return stringStorage[_key];
	}

	function getAddress(bytes32 _key) external view returns (address) {
		return addressStorage[_key];
	}

	function getBytes(bytes32 _key) external view returns (bytes32) {
		return bytesStorage[_key];
	}

	function getBool(bytes32 _key) external view returns (bool) {
		return boolStorage[_key];
	}

	function getInt(bytes32 _key) external view returns (int256) {
		return intStorage[_key];
	}

	// *** Setter Methods ***
	function setUint(bytes32 _key, uint256 _value) external onlyCurrentOwner {
		uIntStorage[_key] = _value;
	}

	function setString(bytes32 _key, string calldata _value)
		external
		onlyCurrentOwner
	{
		stringStorage[_key] = _value;
	}

	function setAddress(bytes32 _key, address _value)
		external
		onlyCurrentOwner
	{
		addressStorage[_key] = _value;
	}

	function setBytes(bytes32 _key, bytes32 _value) external onlyCurrentOwner {
		bytesStorage[_key] = _value;
	}

	function setBool(bytes32 _key, bool _value) external onlyCurrentOwner {
		boolStorage[_key] = _value;
	}

	function setInt(bytes32 _key, int256 _value) external onlyCurrentOwner {
		intStorage[_key] = _value;
	}

	// *** Delete Methods ***
	function deleteUint(bytes32 _key) external onlyCurrentOwner {
		delete uIntStorage[_key];
	}

	function deleteString(bytes32 _key) external onlyCurrentOwner {
		delete stringStorage[_key];
	}

	function deleteAddress(bytes32 _key) external onlyCurrentOwner {
		delete addressStorage[_key];
	}

	function deleteBytes(bytes32 _key) external onlyCurrentOwner {
		delete bytesStorage[_key];
	}

	function deleteBool(bytes32 _key) external onlyCurrentOwner {
		delete boolStorage[_key];
	}

	function deleteInt(bytes32 _key) external onlyCurrentOwner {
		delete intStorage[_key];
	}
}


contract UsingStorage is Ownable {
	address private _storage;

	modifier hasStorage() {
		require(_storage != address(0), "storage is not setted");
		_;
	}

	function eternalStorage()
		internal
		view
		hasStorage
		returns (EternalStorage)
	{
		return EternalStorage(_storage);
	}

	function getStorageAddress() external view hasStorage returns (address) {
		return _storage;
	}

	function createStorage() external onlyOwner {
		require(_storage == address(0), "storage is setted");
		EternalStorage tmp = new EternalStorage();
		_storage = address(tmp);
	}

	function setStorage(address _storageAddress) external onlyOwner {
		_storage = _storageAddress;
	}

	function changeOwner(address newOwner) external onlyOwner {
		EternalStorage(_storage).changeOwner(newOwner);
	}
}




contract VoteTimesStorage is
	UsingStorage,
	UsingConfig,
	UsingValidator,
	Killable
{
	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	// Vote Times
	function getVoteTimes() external view returns (uint256) {
		return eternalStorage().getUint(getVoteTimesKey());
	}

	function setVoteTimes(uint256 times) external {
		addressValidator().validateAddress(msg.sender, config().voteTimes());

		return eternalStorage().setUint(getVoteTimesKey(), times);
	}

	function getVoteTimesKey() private pure returns (bytes32) {
		return keccak256(abi.encodePacked("_voteTimes"));
	}

	//Vote Times By Property
	function getVoteTimesByProperty(address _property)
		external
		view
		returns (uint256)
	{
		return eternalStorage().getUint(getVoteTimesByPropertyKey(_property));
	}

	function setVoteTimesByProperty(address _property, uint256 times) external {
		addressValidator().validateAddress(msg.sender, config().voteTimes());

		return
			eternalStorage().setUint(
				getVoteTimesByPropertyKey(_property),
				times
			);
	}

	function getVoteTimesByPropertyKey(address _property)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_voteTimesByProperty", _property));
	}
}


contract VoteTimes is UsingConfig, UsingValidator, Killable {
	using SafeMath for uint256;

	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function addVoteTime() external {
		addressValidator().validateAddresses(
			msg.sender,
			config().marketFactory(),
			config().policyFactory()
		);

		uint256 voteTimes = getStorage().getVoteTimes();
		voteTimes = voteTimes.add(1);
		getStorage().setVoteTimes(voteTimes);
	}

	function addVoteTimesByProperty(address _property) external {
		addressValidator().validateAddress(msg.sender, config().voteCounter());

		uint256 voteTimesByProperty = getStorage().getVoteTimesByProperty(
			_property
		);
		voteTimesByProperty = voteTimesByProperty.add(1);
		getStorage().setVoteTimesByProperty(_property, voteTimesByProperty);
	}

	function resetVoteTimesByProperty(address _property) external {
		addressValidator().validateAddresses(
			msg.sender,
			config().allocator(),
			config().propertyFactory()
		);

		uint256 voteTimes = getStorage().getVoteTimes();
		getStorage().setVoteTimesByProperty(_property, voteTimes);
	}

	function getAbstentionTimes(address _property)
		external
		view
		returns (uint256)
	{
		uint256 voteTimes = getStorage().getVoteTimes();
		uint256 voteTimesByProperty = getStorage().getVoteTimesByProperty(
			_property
		);
		return voteTimes.sub(voteTimesByProperty);
	}

	function getStorage() private view returns (VoteTimesStorage) {
		return VoteTimesStorage(config().voteTimesStorage());
	}
}
// prettier-ignore



contract VoteCounterStorage is
	UsingStorage,
	UsingConfig,
	UsingValidator,
	Killable
{
	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	// Already Vote Flg
	function setAlreadyVoteFlg(
		address _user,
		address _sender,
		address _property
	) external {
		addressValidator().validateAddress(msg.sender, config().voteCounter());

		bytes32 alreadyVoteKey = getAlreadyVoteKey(_user, _sender, _property);
		return eternalStorage().setBool(alreadyVoteKey, true);
	}

	function getAlreadyVoteFlg(
		address _user,
		address _sender,
		address _property
	) external view returns (bool) {
		bytes32 alreadyVoteKey = getAlreadyVoteKey(_user, _sender, _property);
		return eternalStorage().getBool(alreadyVoteKey);
	}

	function getAlreadyVoteKey(
		address _sender,
		address _target,
		address _property
	) private pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked("_alreadyVote", _sender, _target, _property)
			);
	}

	// Agree Count
	function getAgreeCount(address _sender) external view returns (uint256) {
		return eternalStorage().getUint(getAgreeVoteCountKey(_sender));
	}

	function setAgreeCount(address _sender, uint256 count)
		external
		returns (uint256)
	{
		addressValidator().validateAddress(msg.sender, config().voteCounter());

		eternalStorage().setUint(getAgreeVoteCountKey(_sender), count);
	}

	function getAgreeVoteCountKey(address _sender)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked(_sender, "_agreeVoteCount"));
	}

	// Opposite Count
	function getOppositeCount(address _sender) external view returns (uint256) {
		return eternalStorage().getUint(getOppositeVoteCountKey(_sender));
	}

	function setOppositeCount(address _sender, uint256 count)
		external
		returns (uint256)
	{
		addressValidator().validateAddress(msg.sender, config().voteCounter());

		eternalStorage().setUint(getOppositeVoteCountKey(_sender), count);
	}

	function getOppositeVoteCountKey(address _sender)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked(_sender, "_oppositeVoteCount"));
	}
}


contract VoteCounter is UsingConfig, UsingValidator, Killable {
	using SafeMath for uint256;

	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function addVoteCount(address _user, address _property, bool _agree)
		external
	{
		addressValidator().validateGroups(
			msg.sender,
			config().marketGroup(),
			config().policyGroup()
		);

		bool alreadyVote = getStorage().getAlreadyVoteFlg(
			_user,
			msg.sender,
			_property
		);
		require(alreadyVote == false, "already vote");
		uint256 voteCount = getVoteCount(_user, _property);
		require(voteCount != 0, "vote count is 0");
		getStorage().setAlreadyVoteFlg(_user, msg.sender, _property);
		if (_agree) {
			addAgreeCount(msg.sender, voteCount);
		} else {
			addOppositeCount(msg.sender, voteCount);
		}
	}

	function getAgreeCount(address _sender) external view returns (uint256) {
		return getStorage().getAgreeCount(_sender);
	}

	function getOppositeCount(address _sender) external view returns (uint256) {
		return getStorage().getOppositeCount(_sender);
	}

	function getVoteCount(address _sender, address _property)
		private
		returns (uint256)
	{
		uint256 voteCount;
		if (Property(_property).author() == _sender) {
			// solium-disable-next-line operator-whitespace
			voteCount = Lockup(config().lockup())
				.getPropertyValue(_property)
				.add(
				Allocator(config().allocator()).getRewardsAmount(_property)
			);
			VoteTimes(config().voteTimes()).addVoteTimesByProperty(_property);
		} else {
			voteCount = Lockup(config().lockup()).getValue(_property, _sender);
		}
		return voteCount;
	}

	function addAgreeCount(address _target, uint256 _voteCount) private {
		uint256 agreeCount = getStorage().getAgreeCount(_target);
		agreeCount = agreeCount.add(_voteCount);
		getStorage().setAgreeCount(_target, agreeCount);
	}

	function addOppositeCount(address _target, uint256 _voteCount) private {
		uint256 oppositeCount = getStorage().getOppositeCount(_target);
		oppositeCount = oppositeCount.add(_voteCount);
		getStorage().setOppositeCount(_target, oppositeCount);
	}

	function getStorage() private view returns (VoteCounterStorage) {
		return VoteCounterStorage(config().voteCounterStorage());
	}
}


contract IMarket {
	function calculate(address _metrics, uint256 _start, uint256 _end)
		external
		returns (bool);

	function authenticate(
		address _prop,
		string memory _args1,
		string memory _args2,
		string memory _args3,
		string memory _args4,
		string memory _args5
	)
		public
		returns (
			// solium-disable-next-line indentation
			address
		);

	function getAuthenticationFee(address _property)
		private
		view
		returns (uint256);

	function authenticatedCallback(address _property, bytes32 _idHash)
		external
		returns (address);

	function vote(address _property, bool _agree) external;

	function schema() external view returns (string memory);
}


contract IMarketBehavior {
	string public schema;

	function authenticate(
		address _prop,
		string calldata _args1,
		string calldata _args2,
		string calldata _args3,
		string calldata _args4,
		string calldata _args5,
		address market
	)
		external
		returns (
			// solium-disable-next-line indentation
			address
		);

	function calculate(address _metrics, uint256 _start, uint256 _end)
		external
		returns (bool);
}




contract PropertyGroup is
	UsingConfig,
	UsingStorage,
	UsingValidator,
	IGroup,
	Killable
{
	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function addGroup(address _addr) external {
		addressValidator().validateAddress(
			msg.sender,
			config().propertyFactory()
		);

		require(isGroup(_addr) == false, "already enabled");
		eternalStorage().setBool(getGroupKey(_addr), true);
	}

	function isGroup(address _addr) public view returns (bool) {
		return eternalStorage().getBool(getGroupKey(_addr));
	}
}


contract IPolicy {
	function rewards(uint256 _lockups, uint256 _assets)
		external
		view
		returns (uint256);

	function holdersShare(uint256 _amount, uint256 _lockups)
		external
		view
		returns (uint256);

	function assetValue(uint256 _value, uint256 _lockups)
		external
		view
		returns (uint256);

	function authenticationFee(uint256 _assets, uint256 _propertyAssets)
		external
		view
		returns (uint256);

	function marketApproval(uint256 _agree, uint256 _opposite)
		external
		view
		returns (bool);

	function policyApproval(uint256 _agree, uint256 _opposite)
		external
		view
		returns (bool);

	function marketVotingBlocks() external view returns (uint256);

	function policyVotingBlocks() external view returns (uint256);

	function abstentionPenalty(uint256 _count) external view returns (uint256);

	function lockUpBlocks() external view returns (uint256);
}





contract MarketGroup is
	UsingConfig,
	UsingStorage,
	IGroup,
	UsingValidator,
	Killable
{
	using SafeMath for uint256;

	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) UsingStorage() {}

	function addGroup(address _addr) external {
		addressValidator().validateAddress(
			msg.sender,
			config().marketFactory()
		);

		require(isGroup(_addr) == false, "already enabled");
		eternalStorage().setBool(getGroupKey(_addr), true);
		addCount();
	}

	function isGroup(address _addr) public view returns (bool) {
		return eternalStorage().getBool(getGroupKey(_addr));
	}

	function addCount() private {
		bytes32 key = getCountKey();
		uint256 number = eternalStorage().getUint(key);
		number = number.add(1);
		eternalStorage().setUint(key, number);
	}

	function getCount() external view returns (uint256) {
		bytes32 key = getCountKey();
		return eternalStorage().getUint(key);
	}

	function getCountKey() private pure returns (bytes32) {
		return keccak256(abi.encodePacked("_count"));
	}
}


contract PolicySet is UsingConfig, UsingStorage, UsingValidator, Killable {
	using SafeMath for uint256;

	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function addSet(address _addr) external {
		addressValidator().validateAddress(
			msg.sender,
			config().policyFactory()
		);

		uint256 index = eternalStorage().getUint(getPlicySetIndexKey());
		bytes32 key = getIndexKey(index);
		eternalStorage().setAddress(key, _addr);
		index = index.add(1);
		eternalStorage().setUint(getPlicySetIndexKey(), index);
	}

	function deleteAll() external {
		addressValidator().validateAddress(
			msg.sender,
			config().policyFactory()
		);

		uint256 index = eternalStorage().getUint(getPlicySetIndexKey());
		for (uint256 i = 0; i < index; i++) {
			bytes32 key = getIndexKey(i);
			eternalStorage().setAddress(key, address(0));
		}
		eternalStorage().setUint(getPlicySetIndexKey(), 0);
	}

	function count() external view returns (uint256) {
		return eternalStorage().getUint(getPlicySetIndexKey());
	}

	function get(uint256 _index) external view returns (address) {
		bytes32 key = getIndexKey(_index);
		return eternalStorage().getAddress(key);
	}

	function getIndexKey(uint256 _index) private pure returns (bytes32) {
		return keccak256(abi.encodePacked("_index", _index));
	}

	function getPlicySetIndexKey() private pure returns (bytes32) {
		return keccak256(abi.encodePacked("_policySetIndex"));
	}
}



contract PolicyGroup is
	UsingConfig,
	UsingStorage,
	UsingValidator,
	IGroup,
	Killable
{
	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function addGroup(address _addr) external {
		addressValidator().validateAddress(
			msg.sender,
			config().policyFactory()
		);

		require(isGroup(_addr) == false, "already enabled");
		eternalStorage().setBool(getGroupKey(_addr), true);
	}

	function deleteGroup(address _addr) external {
		addressValidator().validateAddress(
			msg.sender,
			config().policyFactory()
		);

		require(isGroup(_addr), "not enabled");
		return eternalStorage().setBool(getGroupKey(_addr), false);
	}

	function isGroup(address _addr) public view returns (bool) {
		return eternalStorage().getBool(getGroupKey(_addr));
	}
}


contract PolicyFactory is Pausable, UsingConfig, UsingValidator, Killable {
	event Create(address indexed _from, address _policy, address _innerPolicy);

	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function create(address _newPolicyAddress) external returns (address) {
		require(paused() == false, "You cannot use that");
		addressValidator().validateIllegalAddress(_newPolicyAddress);

		Policy policy = new Policy(address(config()), _newPolicyAddress);
		address policyAddress = address(policy);
		emit Create(msg.sender, policyAddress, _newPolicyAddress);
		if (config().policy() == address(0)) {
			config().setPolicy(policyAddress);
		} else {
			VoteTimes(config().voteTimes()).addVoteTime();
		}
		PolicyGroup policyGroup = PolicyGroup(config().policyGroup());
		policyGroup.addGroup(policyAddress);
		PolicySet policySet = PolicySet(config().policySet());
		policySet.addSet(policyAddress);
		return policyAddress;
	}

	function convergePolicy(address _currentPolicyAddress) external {
		addressValidator().validateGroup(msg.sender, config().policyGroup());

		config().setPolicy(_currentPolicyAddress);
		PolicySet policySet = PolicySet(config().policySet());
		PolicyGroup policyGroup = PolicyGroup(config().policyGroup());
		for (uint256 i = 0; i < policySet.count(); i++) {
			address policyAddress = policySet.get(i);
			if (policyAddress == _currentPolicyAddress) {
				continue;
			}
			Policy(policyAddress).kill();
			policyGroup.deleteGroup(policyAddress);
		}
		policySet.deleteAll();
		policySet.addSet(_currentPolicyAddress);
	}
}


contract Policy is Killable, UsingConfig, UsingValidator {
	using SafeMath for uint256;
	IPolicy private _policy;
	uint256 private _votingEndBlockNumber;

	constructor(address _config, address _innerPolicyAddress)
		public
		UsingConfig(_config)
	{
		addressValidator().validateAddress(
			msg.sender,
			config().policyFactory()
		);

		_policy = IPolicy(_innerPolicyAddress);
		setVotingEndBlockNumber();
	}

	function voting() public view returns (bool) {
		return block.number <= _votingEndBlockNumber;
	}

	function rewards(uint256 _lockups, uint256 _assets)
		external
		view
		returns (uint256)
	{
		return _policy.rewards(_lockups, _assets);
	}

	function holdersShare(uint256 _amount, uint256 _lockups)
		external
		view
		returns (uint256)
	{
		return _policy.holdersShare(_amount, _lockups);
	}

	function assetValue(uint256 _value, uint256 _lockups)
		external
		view
		returns (uint256)
	{
		return _policy.assetValue(_value, _lockups);
	}

	function authenticationFee(uint256 _assets, uint256 _propertyAssets)
		external
		view
		returns (uint256)
	{
		return _policy.authenticationFee(_assets, _propertyAssets);
	}

	function marketApproval(uint256 _agree, uint256 _opposite)
		external
		view
		returns (bool)
	{
		return _policy.marketApproval(_agree, _opposite);
	}

	function policyApproval(uint256 _agree, uint256 _opposite)
		external
		view
		returns (bool)
	{
		return _policy.policyApproval(_agree, _opposite);
	}

	function marketVotingBlocks() external view returns (uint256) {
		return _policy.marketVotingBlocks();
	}

	function policyVotingBlocks() external view returns (uint256) {
		return _policy.policyVotingBlocks();
	}

	function abstentionPenalty(uint256 _count) external view returns (uint256) {
		return _policy.abstentionPenalty(_count);
	}

	function lockUpBlocks() external view returns (uint256) {
		return _policy.lockUpBlocks();
	}

	function vote(address _property, bool _agree) external {
		addressValidator().validateGroup(_property, config().propertyGroup());

		require(config().policy() != address(this), "this policy is current");
		require(voting(), "voting deadline is over");
		VoteCounter voteCounter = VoteCounter(config().voteCounter());
		voteCounter.addVoteCount(msg.sender, _property, _agree);
		bool result = Policy(config().policy()).policyApproval(
			voteCounter.getAgreeCount(address(this)),
			voteCounter.getOppositeCount(address(this))
		);
		if (result == false) {
			return;
		}
		PolicyFactory(config().policyFactory()).convergePolicy(address(this));
		_votingEndBlockNumber = 0;
	}

	function setVotingEndBlockNumber() private {
		if (config().policy() == address(0)) {
			return;
		}
		uint256 tmp = Policy(config().policy()).policyVotingBlocks();
		_votingEndBlockNumber = block.number.add(tmp);
	}
}



contract Metrics {
	address public market;
	address public property;

	constructor(address _market, address _property) public {
		//Do not validate because there is no AddressConfig
		market = _market;
		property = _property;
	}
}



contract MetricsGroup is
	UsingConfig,
	UsingStorage,
	UsingValidator,
	IGroup,
	Killable
{
	using SafeMath for uint256;

	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function addGroup(address _addr) external {
		addressValidator().validateAddress(
			msg.sender,
			config().metricsFactory()
		);

		require(isGroup(_addr) == false, "already enabled");
		eternalStorage().setBool(getGroupKey(_addr), true);
		uint256 totalCount = eternalStorage().getUint(getTotalCountKey());
		totalCount = totalCount.add(1);
		eternalStorage().setUint(getTotalCountKey(), totalCount);
	}

	function isGroup(address _addr) public view returns (bool) {
		return eternalStorage().getBool(getGroupKey(_addr));
	}

	function totalIssuedMetrics() external view returns (uint256) {
		return eternalStorage().getUint(getTotalCountKey());
	}

	function getTotalCountKey() private pure returns (bytes32) {
		return keccak256(abi.encodePacked("_totalCount"));
	}
}


contract MetricsFactory is Pausable, UsingConfig, UsingValidator, Killable {
	event Create(address indexed _from, address _metrics);

	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function create(address _property) external returns (address) {
		require(paused() == false, "You cannot use that");
		addressValidator().validateGroup(msg.sender, config().marketGroup());

		Metrics metrics = new Metrics(msg.sender, _property);
		MetricsGroup metricsGroup = MetricsGroup(config().metricsGroup());
		address metricsAddress = address(metrics);
		metricsGroup.addGroup(metricsAddress);
		emit Create(msg.sender, metricsAddress);
		return metricsAddress;
	}
}


contract Market is UsingConfig, IMarket, UsingValidator {
	using SafeMath for uint256;
	bool public enabled;
	address public behavior;
	uint256 private _votingEndBlockNumber;
	uint256 public issuedMetrics;
	mapping(bytes32 => bool) private idMap;

	constructor(address _config, address _behavior)
		public
		UsingConfig(_config)
	{
		addressValidator().validateAddress(
			msg.sender,
			config().marketFactory()
		);

		behavior = _behavior;
		enabled = false;
		uint256 marketVotingBlocks = Policy(config().policy())
			.marketVotingBlocks();
		_votingEndBlockNumber = block.number.add(marketVotingBlocks);
	}

	function toEnable() external {
		addressValidator().validateAddress(
			msg.sender,
			config().marketFactory()
		);
		enabled = true;
	}

	function calculate(address _metrics, uint256 _start, uint256 _end)
		external
		returns (bool)
	{
		addressValidator().validateAddress(msg.sender, config().allocator());

		return IMarketBehavior(behavior).calculate(_metrics, _start, _end);
	}

	function authenticate(
		address _prop,
		string memory _args1,
		string memory _args2,
		string memory _args3,
		string memory _args4,
		string memory _args5
	) public returns (address) {
		addressValidator().validateAddress(
			msg.sender,
			Property(_prop).author()
		);
		require(enabled, "market is not enabled");

		uint256 len = bytes(_args1).length;
		require(len > 0, "id is required");

		return
			IMarketBehavior(behavior).authenticate(
				_prop,
				_args1,
				_args2,
				_args3,
				_args4,
				_args5,
				address(this)
			);
	}

	function getAuthenticationFee(address _property)
		private
		view
		returns (uint256)
	{
		uint256 tokenValue = Lockup(config().lockup()).getPropertyValue(
			_property
		);
		Policy policy = Policy(config().policy());
		MetricsGroup metricsGroup = MetricsGroup(config().metricsGroup());
		return
			policy.authenticationFee(
				metricsGroup.totalIssuedMetrics(),
				tokenValue
			);
	}

	function authenticatedCallback(address _property, bytes32 _idHash)
		external
		returns (address)
	{
		addressValidator().validateAddress(msg.sender, behavior);
		require(enabled, "market is not enabled");

		require(idMap[_idHash] == false, "id is duplicated");
		idMap[_idHash] = true;
		address sender = Property(_property).author();
		MetricsFactory metricsFactory = MetricsFactory(
			config().metricsFactory()
		);
		address metrics = metricsFactory.create(_property);
		uint256 authenticationFee = getAuthenticationFee(_property);
		require(
			Dev(config().token()).fee(sender, authenticationFee),
			"dev fee failed"
		);
		issuedMetrics = issuedMetrics.add(1);
		return metrics;
	}

	function vote(address _property, bool _agree) external {
		addressValidator().validateGroup(_property, config().propertyGroup());
		require(enabled == false, "market is already enabled");
		require(
			block.number <= _votingEndBlockNumber,
			"voting deadline is over"
		);

		VoteCounter voteCounter = VoteCounter(config().voteCounter());
		voteCounter.addVoteCount(msg.sender, _property, _agree);
		enabled = Policy(config().policy()).marketApproval(
			voteCounter.getAgreeCount(address(this)),
			voteCounter.getOppositeCount(address(this))
		);
	}

	function schema() external view returns (string memory) {
		return IMarketBehavior(behavior).schema();
	}
}

// prettier-ignore



contract WithdrawStorage is
	UsingStorage,
	UsingConfig,
	UsingValidator,
	Killable
{
	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	// RewardsAmount
	function setRewardsAmount(address _property, uint256 _value) external {
		addressValidator().validateAddress(msg.sender, config().withdraw());

		eternalStorage().setUint(getRewardsAmountKey(_property), _value);
	}

	function getRewardsAmount(address _property)
		external
		view
		returns (uint256)
	{
		return eternalStorage().getUint(getRewardsAmountKey(_property));
	}

	function getRewardsAmountKey(address _property)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_rewardsAmount", _property));
	}

	// CumulativePrice
	function setCumulativePrice(address _property, uint256 _value)
		external
		returns (uint256)
	{
		addressValidator().validateAddress(msg.sender, config().withdraw());

		eternalStorage().setUint(getCumulativePriceKey(_property), _value);
	}

	function getCumulativePrice(address _property)
		external
		view
		returns (uint256)
	{
		return eternalStorage().getUint(getCumulativePriceKey(_property));
	}

	function getCumulativePriceKey(address _property)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_cumulativePrice", _property));
	}

	// WithdrawalLimitTotal
	function setWithdrawalLimitTotal(
		address _property,
		address _user,
		uint256 _value
	) external {
		addressValidator().validateAddress(msg.sender, config().withdraw());

		eternalStorage().setUint(
			getWithdrawalLimitTotalKey(_property, _user),
			_value
		);
	}

	function getWithdrawalLimitTotal(address _property, address _user)
		external
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(
				getWithdrawalLimitTotalKey(_property, _user)
			);
	}

	function getWithdrawalLimitTotalKey(address _property, address _user)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_withdrawalLimitTotal", _property, _user)
			);
	}

	// WithdrawalLimitBalance
	function setWithdrawalLimitBalance(
		address _property,
		address _user,
		uint256 _value
	) external {
		addressValidator().validateAddress(msg.sender, config().withdraw());

		eternalStorage().setUint(
			getWithdrawalLimitBalanceKey(_property, _user),
			_value
		);
	}

	function getWithdrawalLimitBalance(address _property, address _user)
		external
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(
				getWithdrawalLimitBalanceKey(_property, _user)
			);
	}

	function getWithdrawalLimitBalanceKey(address _property, address _user)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_withdrawalLimitBalance", _property, _user)
			);
	}

	//LastWithdrawalPrice
	function setLastWithdrawalPrice(
		address _property,
		address _user,
		uint256 _value
	) external {
		addressValidator().validateAddress(msg.sender, config().withdraw());

		eternalStorage().setUint(
			getLastWithdrawalPriceKey(_property, _user),
			_value
		);
	}

	function getLastWithdrawalPrice(address _property, address _user)
		external
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(
				getLastWithdrawalPriceKey(_property, _user)
			);
	}

	function getLastWithdrawalPriceKey(address _property, address _user)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_lastWithdrawalPrice", _property, _user)
			);
	}

	//PendingWithdrawal
	function setPendingWithdrawal(
		address _property,
		address _user,
		uint256 _value
	) external {
		addressValidator().validateAddress(msg.sender, config().withdraw());

		eternalStorage().setUint(
			getPendingWithdrawalKey(_property, _user),
			_value
		);
	}

	function getPendingWithdrawal(address _property, address _user)
		external
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(getPendingWithdrawalKey(_property, _user));
	}

	function getPendingWithdrawalKey(address _property, address _user)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(abi.encodePacked("_pendingWithdrawal", _property, _user));
	}
}


contract Withdraw is Pausable, UsingConfig, UsingValidator, Killable {
	using SafeMath for uint256;
	using Decimals for uint256;

	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function withdraw(address _property) external {
		require(paused() == false, "You cannot use that");
		addressValidator().validateGroup(_property, config().propertyGroup());

		uint256 value = _calculateWithdrawableAmount(_property, msg.sender);
		require(value != 0, "withdraw value is 0");
		uint256 price = getStorage().getCumulativePrice(_property);
		getStorage().setLastWithdrawalPrice(_property, msg.sender, price);
		getStorage().setPendingWithdrawal(_property, msg.sender, 0);
		ERC20Mintable erc20 = ERC20Mintable(config().token());
		require(erc20.mint(msg.sender, value), "dev mint failed");
	}

	function beforeBalanceChange(address _property, address _from, address _to)
		external
	{
		addressValidator().validateAddress(msg.sender, config().allocator());

		uint256 price = getStorage().getCumulativePrice(_property);
		uint256 amountFrom = _calculateAmount(_property, _from);
		uint256 amountTo = _calculateAmount(_property, _to);
		getStorage().setLastWithdrawalPrice(_property, _from, price);
		getStorage().setLastWithdrawalPrice(_property, _to, price);
		uint256 pendFrom = getStorage().getPendingWithdrawal(_property, _from);
		uint256 pendTo = getStorage().getPendingWithdrawal(_property, _to);
		getStorage().setPendingWithdrawal(
			_property,
			_from,
			pendFrom.add(amountFrom)
		);
		getStorage().setPendingWithdrawal(_property, _to, pendTo.add(amountTo));
		uint256 totalLimit = getStorage().getWithdrawalLimitTotal(
			_property,
			_to
		);
		uint256 total = getStorage().getRewardsAmount(_property);
		if (totalLimit != total) {
			getStorage().setWithdrawalLimitTotal(_property, _to, total);
			getStorage().setWithdrawalLimitBalance(
				_property,
				_to,
				ERC20(_property).balanceOf(_to)
			);
		}
	}

	function increment(address _property, uint256 _allocationResult) external {
		addressValidator().validateAddress(msg.sender, config().allocator());
		uint256 priceValue = _allocationResult.outOf(
			ERC20(_property).totalSupply()
		);
		uint256 total = getStorage().getRewardsAmount(_property);
		getStorage().setRewardsAmount(_property, total.add(_allocationResult));
		uint256 price = getStorage().getCumulativePrice(_property);
		getStorage().setCumulativePrice(_property, price.add(priceValue));
	}

	function getRewardsAmount(address _property)
		external
		view
		returns (uint256)
	{
		return getStorage().getRewardsAmount(_property);
	}

	function _calculateAmount(address _property, address _user)
		private
		view
		returns (uint256)
	{
		uint256 _last = getStorage().getLastWithdrawalPrice(_property, _user);
		uint256 totalLimit = getStorage().getWithdrawalLimitTotal(
			_property,
			_user
		);
		uint256 balanceLimit = getStorage().getWithdrawalLimitBalance(
			_property,
			_user
		);
		uint256 price = getStorage().getCumulativePrice(_property);
		uint256 priceGap = price.sub(_last);
		uint256 balance = ERC20(_property).balanceOf(_user);
		uint256 total = getStorage().getRewardsAmount(_property);
		if (totalLimit == total) {
			balance = balanceLimit;
		}
		uint256 value = priceGap.mul(balance);
		return value.div(Decimals.basis());
	}

	function calculateAmount(address _property, address _user)
		external
		view
		returns (uint256)
	{
		return _calculateAmount(_property, _user);
	}

	function _calculateWithdrawableAmount(address _property, address _user)
		private
		view
		returns (uint256)
	{
		uint256 _value = _calculateAmount(_property, _user);
		uint256 value = _value.add(
			getStorage().getPendingWithdrawal(_property, _user)
		);
		return value;
	}

	function calculateWithdrawableAmount(address _property, address _user)
		external
		view
		returns (uint256)
	{
		return _calculateWithdrawableAmount(_property, _user);
	}

	function getStorage() private view returns (WithdrawStorage) {
		return WithdrawStorage(config().withdrawStorage());
	}
}



contract AllocatorStorage is
	UsingStorage,
	UsingConfig,
	UsingValidator,
	Killable
{
	constructor(address _config) public UsingConfig(_config) UsingStorage() {}

	// Last Block Number
	function setLastBlockNumber(address _metrics, uint256 _blocks) external {
		addressValidator().validateAddress(msg.sender, config().allocator());

		eternalStorage().setUint(getLastBlockNumberKey(_metrics), _blocks);
	}

	function getLastBlockNumber(address _metrics)
		external
		view
		returns (uint256)
	{
		return eternalStorage().getUint(getLastBlockNumberKey(_metrics));
	}

	function getLastBlockNumberKey(address _metrics)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_lastBlockNumber", _metrics));
	}

	// Base Block Number
	function setBaseBlockNumber(uint256 _blockNumber) external {
		addressValidator().validateAddress(msg.sender, config().allocator());

		eternalStorage().setUint(getBaseBlockNumberKey(), _blockNumber);
	}

	function getBaseBlockNumber() external view returns (uint256) {
		return eternalStorage().getUint(getBaseBlockNumberKey());
	}

	function getBaseBlockNumberKey() private pure returns (bytes32) {
		return keccak256(abi.encodePacked("_baseBlockNumber"));
	}

	// PendingIncrement
	function setPendingIncrement(address _metrics, bool value) external {
		addressValidator().validateAddress(msg.sender, config().allocator());

		eternalStorage().setBool(getPendingIncrementKey(_metrics), value);
	}

	function getPendingIncrement(address _metrics)
		external
		view
		returns (bool)
	{
		return eternalStorage().getBool(getPendingIncrementKey(_metrics));
	}

	function getPendingIncrementKey(address _metrics)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_pendingIncrement", _metrics));
	}

	// LastAllocationBlockEachMetrics
	function setLastAllocationBlockEachMetrics(
		address _metrics,
		uint256 blockNumber
	) external {
		addressValidator().validateAddress(msg.sender, config().allocator());

		eternalStorage().setUint(
			getLastAllocationBlockEachMetricsKey(_metrics),
			blockNumber
		);
	}

	function getLastAllocationBlockEachMetrics(address _metrics)
		external
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(
				getLastAllocationBlockEachMetricsKey(_metrics)
			);
	}

	function getLastAllocationBlockEachMetricsKey(address _addr)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_lastAllocationBlockEachMetrics", _addr)
			);
	}

	// LastAssetValueEachMetrics
	function setLastAssetValueEachMetrics(address _metrics, uint256 value)
		external
	{
		addressValidator().validateAddress(msg.sender, config().allocator());

		eternalStorage().setUint(
			getLastAssetValueEachMetricsKey(_metrics),
			value
		);
	}

	function getLastAssetValueEachMetrics(address _metrics)
		external
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(getLastAssetValueEachMetricsKey(_metrics));
	}

	function getLastAssetValueEachMetricsKey(address _addr)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_lastAssetValueEachMetrics", _addr));
	}

	// lastAssetValueEachMarketPerBlock
	function setLastAssetValueEachMarketPerBlock(address _market, uint256 value)
		external
	{
		addressValidator().validateAddress(msg.sender, config().allocator());

		eternalStorage().setUint(
			getLastAssetValueEachMarketPerBlockKey(_market),
			value
		);
	}

	function getLastAssetValueEachMarketPerBlock(address _market)
		external
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(
				getLastAssetValueEachMarketPerBlockKey(_market)
			);
	}

	function getLastAssetValueEachMarketPerBlockKey(address _addr)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_lastAssetValueEachMarketPerBlock", _addr)
			);
	}
}


contract Allocator is
	Killable,
	Ownable,
	UsingConfig,
	IAllocator,
	UsingValidator
{
	using SafeMath for uint256;
	using Decimals for uint256;
	event BeforeAllocation(
		uint256 _blocks,
		uint256 _mint,
		uint256 _value,
		uint256 _marketValue,
		uint256 _assets,
		uint256 _totalAssets
	);

	uint64 public constant basis = 1000000000000000000;

	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function allocate(address _metrics) external {
		addressValidator().validateGroup(_metrics, config().metricsGroup());

		validateTargetPeriod(_metrics);
		address market = Metrics(_metrics).market();
		getStorage().setPendingIncrement(_metrics, true);
		Market(market).calculate(
			_metrics,
			getLastAllocationBlockNumber(_metrics),
			block.number
		);
		getStorage().setLastBlockNumber(_metrics, block.number);
	}

	function calculatedCallback(address _metrics, uint256 _value) external {
		addressValidator().validateGroup(_metrics, config().metricsGroup());

		Metrics metrics = Metrics(_metrics);
		Market market = Market(metrics.market());
		require(
			msg.sender == market.behavior(),
			"don't call from other than market behavior"
		);
		require(
			getStorage().getPendingIncrement(_metrics),
			"not asking for an indicator"
		);
		Policy policy = Policy(config().policy());
		uint256 totalAssets = MetricsGroup(config().metricsGroup())
			.totalIssuedMetrics();
		uint256 lockupValue = Lockup(config().lockup()).getPropertyValue(
			metrics.property()
		);
		uint256 blocks = block.number.sub(
			getStorage().getLastAllocationBlockEachMetrics(_metrics)
		);
		uint256 mint = policy.rewards(lockupValue, totalAssets);
		uint256 value = (policy.assetValue(_value, lockupValue).mul(basis)).div(
			blocks
		);
		uint256 marketValue = getStorage()
			.getLastAssetValueEachMarketPerBlock(metrics.market())
			.sub(getStorage().getLastAssetValueEachMetrics(_metrics))
			.add(value);
		uint256 assets = market.issuedMetrics();
		getStorage().setLastAllocationBlockEachMetrics(_metrics, block.number);
		getStorage().setLastAssetValueEachMetrics(_metrics, value);
		getStorage().setLastAssetValueEachMarketPerBlock(
			metrics.market(),
			marketValue
		);
		emit BeforeAllocation(
			blocks,
			mint,
			value,
			marketValue,
			assets,
			totalAssets
		);
		uint256 result = allocation(
			blocks,
			mint,
			value,
			marketValue,
			assets,
			totalAssets
		);
		increment(metrics.property(), result, lockupValue);
		getStorage().setPendingIncrement(_metrics, false);
	}

	function increment(address _property, uint256 _reward, uint256 _lockup)
		private
	{
		uint256 holders = Policy(config().policy()).holdersShare(
			_reward,
			_lockup
		);
		uint256 interest = _reward.sub(holders);
		Withdraw(config().withdraw()).increment(_property, holders);
		Lockup(config().lockup()).increment(_property, interest);
	}

	function beforeBalanceChange(address _property, address _from, address _to)
		external
	{
		addressValidator().validateGroup(msg.sender, config().propertyGroup());

		Withdraw(config().withdraw()).beforeBalanceChange(
			_property,
			_from,
			_to
		);
	}

	function getRewardsAmount(address _property)
		external
		view
		returns (uint256)
	{
		return Withdraw(config().withdraw()).getRewardsAmount(_property);
	}

	function allocation(
		uint256 _blocks,
		uint256 _mint,
		uint256 _value,
		uint256 _marketValue,
		uint256 _assets,
		uint256 _totalAssets
	) public pure returns (uint256) {
		uint256 aShare = _totalAssets > 0
			? _assets.outOf(_totalAssets)
			: Decimals.basis();
		uint256 vShare = _marketValue > 0
			? _value.outOf(_marketValue)
			: Decimals.basis();
		uint256 mint = _mint.mul(_blocks);
		return
			mint.mul(aShare).mul(vShare).div(Decimals.basis()).div(
				Decimals.basis()
			);
	}

	function validateTargetPeriod(address _metrics) private {
		address property = Metrics(_metrics).property();
		VoteTimes voteTimes = VoteTimes(config().voteTimes());
		uint256 abstentionCount = voteTimes.getAbstentionTimes(property);
		uint256 notTargetPeriod = Policy(config().policy()).abstentionPenalty(
			abstentionCount
		);
		if (notTargetPeriod == 0) {
			return;
		}
		uint256 blockNumber = getLastAllocationBlockNumber(_metrics);
		uint256 notTargetBlockNumber = blockNumber.add(notTargetPeriod);
		require(
			notTargetBlockNumber < block.number,
			"outside the target period"
		);
		getStorage().setLastBlockNumber(_metrics, notTargetBlockNumber);
		voteTimes.resetVoteTimesByProperty(property);
	}

	function getLastAllocationBlockNumber(address _metrics)
		private
		returns (uint256)
	{
		uint256 blockNumber = getStorage().getLastBlockNumber(_metrics);
		uint256 baseBlockNumber = getStorage().getBaseBlockNumber();
		if (baseBlockNumber == 0) {
			getStorage().setBaseBlockNumber(block.number);
		}
		uint256 lastAllocationBlockNumber = blockNumber > 0
			? blockNumber
			: getStorage().getBaseBlockNumber();
		return lastAllocationBlockNumber;
	}

	function getStorage() private view returns (AllocatorStorage) {
		return AllocatorStorage(config().allocatorStorage());
	}
}


contract Property is ERC20, ERC20Detailed, UsingConfig, UsingValidator {
	uint8 private constant _decimals = 18;
	uint256 private constant _supply = 10000000;
	address public author;

	constructor(
		address _config,
		address _own,
		string memory _name,
		string memory _symbol
	) public UsingConfig(_config) ERC20Detailed(_name, _symbol, _decimals) {
		addressValidator().validateAddress(
			msg.sender,
			config().propertyFactory()
		);

		author = _own;
		_mint(author, _supply);
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		addressValidator().validateIllegalAddress(_to);
		require(_value != 0, "illegal transfer value");

		Allocator(config().allocator()).beforeBalanceChange(
			address(this),
			msg.sender,
			_to
		);
		_transfer(msg.sender, _to, _value);
	}

	function withdraw(address _sender, uint256 _value) external {
		addressValidator().validateAddress(msg.sender, config().lockup());

		ERC20 devToken = ERC20(config().token());
		devToken.transfer(_sender, _value);
	}
}



contract LockupStorage is UsingConfig, UsingStorage, UsingValidator, Killable {
	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	//Value
	function setValue(address _property, address _sender, uint256 _value)
		external
		returns (uint256)
	{
		addressValidator().validateAddress(msg.sender, config().lockup());

		bytes32 key = getValueKey(_property, _sender);
		eternalStorage().setUint(key, _value);
	}

	function getValue(address _property, address _sender)
		external
		view
		returns (uint256)
	{
		bytes32 key = getValueKey(_property, _sender);
		return eternalStorage().getUint(key);
	}

	function getValueKey(address _property, address _sender)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_value", _property, _sender));
	}

	//PropertyValue
	function setPropertyValue(address _property, uint256 _value)
		external
		returns (uint256)
	{
		addressValidator().validateAddress(msg.sender, config().lockup());

		bytes32 key = getPropertyValueKey(_property);
		eternalStorage().setUint(key, _value);
	}

	function getPropertyValue(address _property)
		external
		view
		returns (uint256)
	{
		bytes32 key = getPropertyValueKey(_property);
		return eternalStorage().getUint(key);
	}

	function getPropertyValueKey(address _property)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_propertyValue", _property));
	}

	//WithdrawalStatus
	function setWithdrawalStatus(
		address _property,
		address _from,
		uint256 _value
	) external {
		addressValidator().validateAddress(msg.sender, config().lockup());

		bytes32 key = getWithdrawalStatusKey(_property, _from);
		eternalStorage().setUint(key, _value);
	}

	function getWithdrawalStatus(address _property, address _from)
		external
		view
		returns (uint256)
	{
		bytes32 key = getWithdrawalStatusKey(_property, _from);
		return eternalStorage().getUint(key);
	}

	function getWithdrawalStatusKey(address _property, address _sender)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_withdrawalStatus", _property, _sender)
			);
	}

	//InterestPrice
	function setInterestPrice(address _property, uint256 _value)
		external
		returns (uint256)
	{
		addressValidator().validateAddress(msg.sender, config().lockup());

		eternalStorage().setUint(getInterestPriceKey(_property), _value);
	}

	function getInterestPrice(address _property)
		external
		view
		returns (uint256)
	{
		return eternalStorage().getUint(getInterestPriceKey(_property));
	}

	function getInterestPriceKey(address _property)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_interestTotals", _property));
	}

	//LastInterestPrice
	function setLastInterestPrice(
		address _property,
		address _user,
		uint256 _value
	) external {
		addressValidator().validateAddress(msg.sender, config().lockup());

		eternalStorage().setUint(
			getLastInterestPriceKey(_property, _user),
			_value
		);
	}

	function getLastInterestPrice(address _property, address _user)
		external
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(getLastInterestPriceKey(_property, _user));
	}

	function getLastInterestPriceKey(address _property, address _user)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_lastLastInterestPrice", _property, _user)
			);
	}

	//PendingWithdrawal
	function setPendingInterestWithdrawal(
		address _property,
		address _user,
		uint256 _value
	) external {
		addressValidator().validateAddress(msg.sender, config().lockup());

		eternalStorage().setUint(
			getPendingInterestWithdrawalKey(_property, _user),
			_value
		);
	}

	function getPendingInterestWithdrawal(address _property, address _user)
		external
		view
		returns (uint256)
	{
		return
			eternalStorage().getUint(
				getPendingInterestWithdrawalKey(_property, _user)
			);
	}

	function getPendingInterestWithdrawalKey(address _property, address _user)
		private
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("_pendingInterestWithdrawal", _property, _user)
			);
	}
}


contract Lockup is Pausable, UsingConfig, UsingValidator, Killable {
	using SafeMath for uint256;
	using Decimals for uint256;
	event Lockedup(address _from, address _property, uint256 _value);

	// solium-disable-next-line no-empty-blocks
	constructor(address _config) public UsingConfig(_config) {}

	function lockup(address _from, address _property, uint256 _value) external {
		require(paused() == false, "You cannot use that");
		addressValidator().validateAddress(msg.sender, config().token());
		addressValidator().validateGroup(_property, config().propertyGroup());
		require(_value != 0, "illegal lockup value");

		bool isWaiting = getStorage().getWithdrawalStatus(_property, _from) !=
			0;
		require(isWaiting == false, "lockup is already canceled");
		updatePendingInterestWithdrawal(_property, _from);
		addValue(_property, _from, _value);
		addPropertyValue(_property, _value);
		getStorage().setLastInterestPrice(
			_property,
			_from,
			getStorage().getInterestPrice(_property)
		);
		emit Lockedup(_from, _property, _value);
	}

	function cancel(address _property) external {
		addressValidator().validateGroup(_property, config().propertyGroup());

		require(hasValue(_property, msg.sender), "dev token is not locked");
		bool isWaiting = getStorage().getWithdrawalStatus(
			_property,
			msg.sender
		) !=
			0;
		require(isWaiting == false, "lockup is already canceled");
		uint256 blockNumber = Policy(config().policy()).lockUpBlocks();
		blockNumber = blockNumber.add(block.number);
		getStorage().setWithdrawalStatus(_property, msg.sender, blockNumber);
	}

	function withdraw(address _property) external {
		addressValidator().validateGroup(_property, config().propertyGroup());

		require(possible(_property, msg.sender), "waiting for release");
		uint256 lockupedValue = getStorage().getValue(_property, msg.sender);
		require(lockupedValue != 0, "dev token is not locked");
		updatePendingInterestWithdrawal(_property, msg.sender);
		Property(_property).withdraw(msg.sender, lockupedValue);
		getStorage().setValue(_property, msg.sender, 0);
		subPropertyValue(_property, lockupedValue);
		getStorage().setWithdrawalStatus(_property, msg.sender, 0);
	}

	function increment(address _property, uint256 _interestResult) external {
		addressValidator().validateAddress(msg.sender, config().allocator());
		uint256 priceValue = _interestResult.outOf(
			getStorage().getPropertyValue(_property)
		);
		incrementInterest(_property, priceValue);
	}

	function _calculateInterestAmount(address _property, address _user)
		private
		view
		returns (uint256)
	{
		uint256 _last = getStorage().getLastInterestPrice(_property, _user);
		uint256 price = getStorage().getInterestPrice(_property);
		uint256 priceGap = price.sub(_last);
		uint256 lockupedValue = getStorage().getValue(_property, _user);
		uint256 value = priceGap.mul(lockupedValue);
		return value.div(Decimals.basis());
	}

	function calculateInterestAmount(address _property, address _user)
		external
		view
		returns (uint256)
	{
		return _calculateInterestAmount(_property, _user);
	}

	function _calculateWithdrawableInterestAmount(
		address _property,
		address _user
	) private view returns (uint256) {
		uint256 pending = getStorage().getPendingInterestWithdrawal(
			_property,
			_user
		);
		return _calculateInterestAmount(_property, _user).add(pending);
	}

	function calculateWithdrawableInterestAmount(
		address _property,
		address _user
	) external view returns (uint256) {
		return _calculateWithdrawableInterestAmount(_property, _user);
	}

	function withdrawInterest(address _property) external {
		addressValidator().validateGroup(_property, config().propertyGroup());

		uint256 value = _calculateWithdrawableInterestAmount(
			_property,
			msg.sender
		);
		require(value > 0, "your interest amount is 0");
		getStorage().setLastInterestPrice(
			_property,
			msg.sender,
			getStorage().getInterestPrice(_property)
		);
		getStorage().setPendingInterestWithdrawal(_property, msg.sender, 0);
		ERC20Mintable erc20 = ERC20Mintable(config().token());
		require(erc20.mint(msg.sender, value), "dev mint failed");
	}

	function getPropertyValue(address _property)
		external
		view
		returns (uint256)
	{
		return getStorage().getPropertyValue(_property);
	}

	function getValue(address _property, address _sender)
		external
		view
		returns (uint256)
	{
		return getStorage().getValue(_property, _sender);
	}

	function addValue(address _property, address _sender, uint256 _value)
		private
	{
		uint256 value = getStorage().getValue(_property, _sender);
		value = value.add(_value);
		getStorage().setValue(_property, _sender, value);
	}

	function hasValue(address _property, address _sender)
		private
		view
		returns (bool)
	{
		uint256 value = getStorage().getValue(_property, _sender);
		return value != 0;
	}

	function addPropertyValue(address _property, uint256 _value) private {
		uint256 value = getStorage().getPropertyValue(_property);
		value = value.add(_value);
		getStorage().setPropertyValue(_property, value);
	}

	function subPropertyValue(address _property, uint256 _value) private {
		uint256 value = getStorage().getPropertyValue(_property);
		value = value.sub(_value);
		getStorage().setPropertyValue(_property, value);
	}

	function incrementInterest(address _property, uint256 _priceValue) private {
		uint256 price = getStorage().getInterestPrice(_property);
		getStorage().setInterestPrice(_property, price.add(_priceValue));
	}

	function updatePendingInterestWithdrawal(address _property, address _user)
		private
	{
		uint256 pending = getStorage().getPendingInterestWithdrawal(
			_property,
			_user
		);
		getStorage().setPendingInterestWithdrawal(
			_property,
			_user,
			_calculateInterestAmount(_property, _user).add(pending)
		);
	}

	function possible(address _property, address _from)
		private
		view
		returns (bool)
	{
		uint256 blockNumber = getStorage().getWithdrawalStatus(
			_property,
			_from
		);
		if (blockNumber == 0) {
			return false;
		}
		return blockNumber <= block.number;
	}

	function getStorage() private view returns (LockupStorage) {
		return LockupStorage(config().lockupStorage());
	}
}


contract Dev is
	ERC20Detailed,
	ERC20Mintable,
	ERC20Burnable,
	UsingConfig,
	UsingValidator
{
	constructor(address _config)
		public
		ERC20Detailed("Dev", "DEV", 18)
		UsingConfig(_config)
	{}

	function deposit(address _to, uint256 _amount) external returns (bool) {
		require(transfer(_to, _amount), "dev transfer failed");
		lock(msg.sender, _to, _amount);
		return true;
	}

	function depositFrom(address _from, address _to, uint256 _amount)
		external
		returns (bool)
	{
		require(transferFrom(_from, _to, _amount), "dev transferFrom failed");
		lock(_from, _to, _amount);
		return true;
	}

	function fee(address _from, uint256 _amount) external returns (bool) {
		addressValidator().validateGroup(msg.sender, config().marketGroup());
		_burn(_from, _amount);
		return true;
	}

	function lock(address _from, address _to, uint256 _amount) private {
		Lockup(config().lockup()).lockup(_from, _to, _amount);
	}
}