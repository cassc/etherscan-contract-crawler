/**
 *Submitted for verification at Etherscan.io on 2019-09-27
*/

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
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
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/property/Reclaimable.sol

/**
 * @title Reclaimable
 * @dev This contract gives owner right to recover any ERC20 tokens accidentally sent to 
 * the token contract. The recovered token will be sent to the owner of token. 
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
pragma solidity ^0.5.0;





contract Reclaimable is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @notice Let the owner to retrieve other tokens accidentally sent to this contract.
     * @dev This function is suitable when no token of any kind shall be stored under
     * the address of the inherited contract.
     * @param tokenToBeRecovered address of the token to be recovered.
     */
    function reclaimToken(IERC20 tokenToBeRecovered) external onlyOwner {
        uint256 balance = tokenToBeRecovered.balanceOf(address(this));
        tokenToBeRecovered.safeTransfer(owner(), balance);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

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
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
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

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
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
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

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

// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol

pragma solidity ^0.5.0;



/**
 * @dev Extension of `ERC20` that adds a set of accounts with the `MinterRole`,
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See `ERC20._mint`.
     *
     * Requirements:
     *
     * - the caller must have the `MinterRole`.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol

pragma solidity ^0.5.0;


/**
 * @dev Extension of `ERC20Mintable` that adds a cap to the supply of tokens.
 */
contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See `ERC20Mintable.mint`.
     *
     * Requirements:
     *
     * - `value` must not cause the total supply to go over the cap.
     */
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol

pragma solidity ^0.5.0;


/**
 * @dev Extension of `ERC20` that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is ERC20 {
    /**
     * @dev Destoys `amount` tokens from the caller.
     *
     * See `ERC20._burn`.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /**
     * @dev See `ERC20._burnFrom`.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

// File: openzeppelin-solidity/contracts/math/Math.sol

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/token/Snapshots.sol

/**
 * @title Snapshot
 * @dev Utility library of the Snapshot structure, including getting value.
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
pragma solidity ^0.5.0;




library Snapshots {
    using Math for uint256;
    using SafeMath for uint256;

    /**
     * @notice This structure stores the historical value associate at a particular blocknumber
     * @param fromBlock The blocknumber of the creation of the snapshot
     * @param value The value to be recorded
     */
    struct Snapshot {
        uint256 fromBlock;
        uint256 value;
    }

    struct SnapshotList {
        Snapshot[] history;
    }

    /**
     * @notice This function creates snapshots for certain value...
     * @dev To avoid having two Snapshots with the same block.number, we check if the last
     * existing one is the current block.number, we update the last Snapshot
     * @param item The SnapshotList to be operated
     * @param _value The value associated the the item that is going to have a snapshot
     */
    function createSnapshot(SnapshotList storage item, uint256 _value) internal {
        uint256 length = item.history.length;
        if (length == 0 || (item.history[length.sub(1)].fromBlock < block.number)) {
            item.history.push(Snapshot(block.number, _value));
        } else {
            // When the last existing snapshot is ready to be updated
            item.history[length.sub(1)].value = _value;
        }
    }

    /**
     * @notice Find the index of the item in the SnapshotList that contains information
     * corresponding to the blockNumber. (FindLowerBond of the array)
     * @dev The binary search logic is inspired by the Arrays.sol from Openzeppelin
     * @param item The list of Snapshots to be queried
     * @param blockNumber The block number of the queried moment
     * @return The index of the Snapshot array
     */
    function findBlockIndex(
        SnapshotList storage item, 
        uint256 blockNumber
    ) 
        internal
        view 
        returns (uint256)
    {
        // Find lower bound of the array
        uint256 length = item.history.length;

        // Return value for extreme cases: If no snapshot exists and/or the last snapshot
        if (item.history[length.sub(1)].fromBlock <= blockNumber) {
            return length.sub(1);
        } else {
            // Need binary search for the value
            uint256 low = 0;
            uint256 high = length.sub(1);

            while (low < high.sub(1)) {
                uint256 mid = Math.average(low, high);
                // mid will always be strictly less than high and it rounds down
                if (item.history[mid].fromBlock <= blockNumber) {
                    low = mid;
                } else {
                    high = mid;
                }
            }
            return low;
        }   
    }

    /**
     * @notice This function returns the value of the corresponding Snapshot
     * @param item The list of Snapshots to be queried
     * @param blockNumber The block number of the queried moment
     * @return The value of the queried moment
     */
    function getValueAt(
        SnapshotList storage item, 
        uint256 blockNumber
    )
        internal
        view
        returns (uint256)
    {
        if (item.history.length == 0 || blockNumber < item.history[0].fromBlock) {
            return 0;
        } else {
            uint256 index = findBlockIndex(item, blockNumber);
            return item.history[index].value;
        }
    }
}

// File: contracts/token/IERC20Snapshot.sol

/**
 * @title Snapshot Token Interface
 * @dev This is the interface of the ERC20Snapshot
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
pragma solidity ^0.5.0;


contract IERC20Snapshot {
    /**
     * @notice Return the historical supply of the token at a certain time
     * @param blockNumber The block number of the moment when token supply is queried
     * @return The total supply at "blockNumber"
     */
    function totalSupplyAt(uint256 blockNumber) public view returns (uint256);

    /**
     * @notice Return the historical balance of an account at a certain time
     * @param owner The address of the token holder
     * @param blockNumber The block number of the moment when token supply is queried
     * @return The balance of the queried token holder at "blockNumber"
     */
    function balanceOfAt(address owner, uint256 blockNumber) public view returns (uint256);
}

// File: contracts/token/ERC20Snapshot.sol

/**
 * @title Snapshot Token
 * @dev This is an ERC20 compatible token that takes snapshots of account balances.
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
pragma solidity ^0.5.0;





contract ERC20Snapshot is ERC20, IERC20Snapshot {
    using Snapshots for Snapshots.SnapshotList;

    mapping(address => Snapshots.SnapshotList) private _snapshotBalances; 
    Snapshots.SnapshotList private _snapshotTotalSupply;   

    event AccountSnapshotCreated(address indexed account, uint256 indexed blockNumber, uint256 value);
    event TotalSupplySnapshotCreated(uint256 indexed blockNumber, uint256 value);

    /**
     * @notice Return the historical supply of the token at a certain time
     * @param blockNumber The block number of the moment when token supply is queried
     * @return The total supply at "blockNumber"
     */
    function totalSupplyAt(uint256 blockNumber) public view returns (uint256) {
        return _snapshotTotalSupply.getValueAt(blockNumber);
    }

    /**
     * @notice Return the historical balance of an account at a certain time
     * @param owner The address of the token holder
     * @param blockNumber The block number of the moment when token supply is queried
     * @return The balance of the queried token holder at "blockNumber"
     */
    function balanceOfAt(address owner, uint256 blockNumber) 
        public 
        view 
        returns (uint256) 
    {
        return _snapshotBalances[owner].getValueAt(blockNumber);
    }

    /** OVERRIDE
     * @notice Transfer tokens between two accounts while enforcing the update of Snapshots
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param value The amount to be transferred
     */
    function _transfer(address from, address to, uint256 value) internal {
        super._transfer(from, to, value);
        _snapshotBalances[from].createSnapshot(balanceOf(from));
        _snapshotBalances[to].createSnapshot(balanceOf(to));
        emit AccountSnapshotCreated(from, block.number, balanceOf(from));
        emit AccountSnapshotCreated(to, block.number, balanceOf(to));
    }

    /** OVERRIDE
     * @notice Mint tokens to one account while enforcing the update of Snapshots
     * @param account The address that receives tokens
     * @param value The amount of tokens to be created
     */
    function _mint(address account, uint256 value) internal {
        super._mint(account, value);
        _snapshotBalances[account].createSnapshot(balanceOf(account));
        _snapshotTotalSupply.createSnapshot(totalSupply());
        emit AccountSnapshotCreated(account, block.number, balanceOf(account));
        emit TotalSupplySnapshotCreated(block.number, totalSupply());
    }

    /** OVERRIDE
     * @notice Burn tokens of one account
     * @param account The address whose tokens will be burnt
     * @param value The amount of tokens to be burnt
     */
    function _burn(address account, uint256 value) internal {
        super._burn(account, value);
        _snapshotBalances[account].createSnapshot(balanceOf(account));
        _snapshotTotalSupply.createSnapshot(totalSupply());
        emit AccountSnapshotCreated(account, block.number, balanceOf(account));
        emit TotalSupplySnapshotCreated(block.number, totalSupply());
    }
}

// File: contracts/membership/ManagerRole.sol

/**
 * @title Manager Role
 * @dev This contract is developed based on the Manager contract of OpenZeppelin.
 * The key difference is the management of the manager roles is restricted to one owner
 * account. At least one manager should exist in any situation.
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
pragma solidity ^0.5.0;





contract ManagerRole is Ownable {
    using Roles for Roles.Role;
    using SafeMath for uint256;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    Roles.Role private managers;
    uint256 private _numManager;

    constructor() internal {
        _addManager(msg.sender);
        _numManager = 1;
    }

    /**
     * @notice Only manager can take action
     */
    modifier onlyManager() {
        require(isManager(msg.sender), "The account is not a manager");
        _;
    }

    /**
     * @notice This function allows to add managers in batch with control of the number of 
     * interations
     * @param accounts The accounts to be added in batch
     */
    // solhint-disable-next-line
    function addManagers(address[] calldata accounts) external onlyOwner {
        uint256 length = accounts.length;
        require(length <= 256, "too many accounts");
        for (uint256 i = 0; i < length; i++) {
            _addManager(accounts[i]);
        }
    }
    
    /**
     * @notice Add an account to the list of managers,
     * @param account The account address whose manager role needs to be removed.
     */
    function removeManager(address account) external onlyOwner {
        _removeManager(account);
    }

    /**
     * @notice Check if an account is a manager
     * @param account The account to be checked if it has a manager role
     * @return true if the account is a manager. Otherwise, false
     */
    function isManager(address account) public view returns (bool) {
        return managers.has(account);
    }

    /**
     *@notice Get the number of the current managers
     */
    function numManager() public view returns (uint256) {
        return _numManager;
    }

    /**
     * @notice Add an account to the list of managers,
     * @param account The account that needs to tbe added as a manager
     */
    function addManager(address account) public onlyOwner {
        require(account != address(0), "account is zero");
        _addManager(account);
    }

    /**
     * @notice Renounce the manager role
     * @dev This function was not explicitly required in the specs. There should be at
     * least one manager at any time. Therefore, at least two when one manage renounces
     * themselves.
     */
    function renounceManager() public {
        require(_numManager >= 2, "Managers are fewer than 2");
        _removeManager(msg.sender);
    }

    /** OVERRIDE 
    * @notice Allows the current owner to relinquish control of the contract.
    * @dev Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        revert("Cannot renounce ownership");
    }

    /**
     * @notice Internal function to be called when adding a manager
     * @param account The address of the manager-to-be
     */
    function _addManager(address account) internal {
        _numManager = _numManager.add(1);
        managers.add(account);
        emit ManagerAdded(account);
    }

    /**
     * @notice Internal function to remove one account from the manager list
     * @param account The address of the to-be-removed manager
     */
    function _removeManager(address account) internal {
        _numManager = _numManager.sub(1);
        managers.remove(account);
        emit ManagerRemoved(account);
    }
}

// File: contracts/membership/PausableManager.sol

/**
 * @title Pausable Manager Role
 * @dev This manager can also pause a contract. This contract is developed based on the 
 * Pause contract of OpenZeppelin.
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
pragma solidity ^0.5.0;



contract PausableManager is ManagerRole {

    event BePaused(address manager);
    event BeUnpaused(address manager);

    bool private _paused;   // If the crowdsale contract is paused, controled by the manager...

    constructor() internal {
        _paused = false;
    }

   /**
    * @notice Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!_paused, "not paused");
        _;
    }

    /**
    * @notice Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(_paused, "paused");
        _;
    }

    /**
    * @return true if the contract is paused, false otherwise.
    */
    function paused() public view returns(bool) {
        return _paused;
    }

    /**
    * @notice called by the owner to pause, triggers stopped state
    */
    function pause() public onlyManager whenNotPaused {
        _paused = true;
        emit BePaused(msg.sender);
    }

    /**
    * @notice called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyManager whenPaused {
        _paused = false;
        emit BeUnpaused(msg.sender);
    }
}

// File: contracts/vault/IVault.sol

/*
 * @title Interface for basic vaults
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
pragma solidity ^0.5.0;


contract IVault {
    /**
     * @notice Adding beneficiary to the vault
     * @param beneficiary The account that receives token
     * @param value The amount of token allocated
     */
    function receiveFor(address beneficiary, uint256 value) public;

    /**
     * @notice Update the releaseTime for vaults
     * @param roundEndTime The new releaseTime
     */
    function updateReleaseTime(uint256 roundEndTime) public;
}

// File: contracts/property/CounterGuard.sol

/**
 * @title modifier contract that guards certain properties only triggered once
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
pragma solidity ^0.5.0;


contract CounterGuard {
    /**
     * @notice Controle if a boolean attribute (false by default) was updated to true.
     * @dev This attribute is designed specifically for recording an action.
     * @param criterion The boolean attribute that records if an action has taken place
     */
    modifier onlyOnce(bool criterion) {
        require(criterion == false, "Already been set");
        _;
    }
}

// File: contracts/token/IvoToken.sol

/**
 * @title IVO token
 * @author Validity Labs AG <[email protected]>
 */
// solhint-disable-next-line compiler-fixed, compiler-gt-0_5
pragma solidity ^0.5.0;










contract IvoToken is CounterGuard, Reclaimable, ERC20Detailed,
    ERC20Snapshot, ERC20Capped, ERC20Burnable, PausableManager {
    // /* solhint-disable */
    uint256 private constant SAFT_ALLOCATION = 22500000 ether;
    uint256 private constant RESERVE_ALLOCATION = 10000000 ether;
    uint256 private constant ADVISOR_ALLOCATION = 1500000 ether;
    uint256 private constant TEAM_ALLOCATION = 13500000 ether;

    address private _saftVaultAddress;
    address private _reserveVaultAddress;
    address private _advisorVestingAddress;
    address private _teamVestingAddress;
    mapping(address=>bool) private _listOfVaults;
    bool private _setRole;

    /**
     * @notice Constructor of the token contract
     * @param name The complete name of the token: "INVAO token"
     * @param symbol The abbreviation of the token, to be searched for on exchange: "IVO"
     * @param decimals The decimals of the token: 18
     * @param cap The max cap of the token supply: 100000000000000000000000000
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap
    )
        public
        ERC20Detailed(name, symbol, decimals)
        ERC20Capped(cap) {
            pause();
        }

    /**
     * @notice Pausable transfer function, with exception of letting vaults/vesting
     * contracts transfer tokens to beneficiaries, when beneficiaries claim their token
     * from vaults or vesting contracts.
     * @param to The recipient address
     * @param value The amount of token to be transferred
     */
    function transfer(address to, uint256 value)
        public
        returns (bool)
    {
        require(!this.paused() || _listOfVaults[msg.sender], "The token is paused and you are not a valid vault/vesting contract");
        return super.transfer(to, value);
    }

    /**
     * @notice Pausable transferFrom function
     * @param from The address from which tokens are sent
     * @param to The recipient address
     * @param value The amount of token to be transferred.
     * @return If the transaction was successful in bool.
     */
    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @notice Pausable approve function
     * @param spender The authorized account to spend a certain amount of token on behalf of the holder
     * @param value The amount of token that is allowed to spent
     * @return If the transaction was successful in bool.
     */
    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    /**
     * @notice Pausable increaseAllowance function
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     * @return If the action was successful in bool.
     */
    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
     * @notice Pausable decreaseAllowance function
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     * @return If the action was successful in bool.
     */
    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
    * @notice setup roles and contract addresses for the new token
    * @param newOwner Address of the owner who is also a manager
    * @param crowdsaleContractAddress crowdsal address: can mint and pause token
    * @param saftVaultAddress Address of the SAFT vault contract.
    * @param privateVaultAddress Address of the private sale vault contract
    * @param presaleVaultAddress Address of the presale vault contract
    * @param advisorVestingAddress Address of the advisor vesting contract.
    * @param teamVestingAddress Address of the team vesting contract.
    * @param reserveVaultAddress Address of the reserve vault contract.
    */
    function roleSetup(
        address newOwner,
        address crowdsaleContractAddress,
        IVault saftVaultAddress,
        IVault privateVaultAddress,
        IVault presaleVaultAddress,
        IVault advisorVestingAddress,
        IVault teamVestingAddress,
        IVault reserveVaultAddress
    )
        public
        onlyOwner
        onlyOnce(_setRole)
    {
        _setRole = true;

        // set vault and vesting contract addresses
        _saftVaultAddress = address(saftVaultAddress);
        _reserveVaultAddress = address(reserveVaultAddress);
        _advisorVestingAddress = address(advisorVestingAddress);
        _teamVestingAddress = address(teamVestingAddress);
        _listOfVaults[_saftVaultAddress] = true;
        _listOfVaults[address(privateVaultAddress)] = true;
        _listOfVaults[address(presaleVaultAddress)] = true;
        _listOfVaults[_advisorVestingAddress] = true;
        _listOfVaults[_teamVestingAddress] = true;

        //After setting adresses of vaults, manager can trigger the allocation of tokens
        // to vaults. No need to mint to the private vault nor the presale vault  because
        // it's been minted dynamicly.
        mint(_saftVaultAddress, SAFT_ALLOCATION);
        mint(_reserveVaultAddress, RESERVE_ALLOCATION);
        mint(_advisorVestingAddress, ADVISOR_ALLOCATION);
        mint(_teamVestingAddress, TEAM_ALLOCATION);

        addManager(newOwner);
        addManager(crowdsaleContractAddress);
        addMinter(crowdsaleContractAddress);
        _removeManager(msg.sender);
        _removeMinter(msg.sender);
        transferOwnership(newOwner);
    }
}