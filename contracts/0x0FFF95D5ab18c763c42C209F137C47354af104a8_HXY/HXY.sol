/**
 *Submitted for verification at Etherscan.io on 2020-06-17
*/

pragma solidity ^0.6.2;


// SPDX-License-Identifier: MIT
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

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
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
}

// SPDX-License-Identifier: MIT
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
    using Address for address;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _cap;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
        require(recipient != address(this), "ERC20: Cannot transfer to self");
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * e.g. implement automatic token fees, slashing mechanisms, etc.S
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

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
     * Requirements
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

// SPDX-License-Identifier: MIT
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

library WhitelistLib {
    struct AllowedAddress {
        bool tradeable;
        uint256 lockPeriod;
        uint256 dailyLimit;
        uint256 dailyLimitToday;
        uint256 addedAt;
        uint256 recordTime;
    }
}

contract HexWhitelist is AccessControl, ReentrancyGuard {
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    uint256 public constant SECONDS_IN_DAY = 86400;

    using WhitelistLib for WhitelistLib.AllowedAddress;

    mapping(address => WhitelistLib.AllowedAddress) internal exchanges;
    mapping(address => WhitelistLib.AllowedAddress) internal dapps;
    mapping(address => WhitelistLib.AllowedAddress) internal referrals;

    uint256 internal whitelistRecordTime;

    modifier onlyAdminOrDeployerRole() {
        bool hasAdminRole = hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
        bool hasDeployerRole = hasRole(DEPLOYER_ROLE, _msgSender());
        require(hasAdminRole || hasDeployerRole, "Must have admin or deployer role");
        _;
    }

    constructor (address _adminAddress) public {
        _setupRole(DEPLOYER_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _adminAddress);

        whitelistRecordTime = SafeMath.add(block.timestamp, SafeMath.mul(1, SECONDS_IN_DAY));
    }
    function registerExchangeTradeable(address _address, uint256 dailyLimit) public onlyAdminOrDeployerRole {
        _registerExchange(_address, true, 0, dailyLimit);
    }

    function registerDappTradeable(address _address, uint256 dailyLimit) public onlyAdminOrDeployerRole {
        _registerDapp(_address, true, 0, dailyLimit);
    }

    function registerReferralTradeable(address _address, uint256 dailyLimit) public onlyAdminOrDeployerRole {
        _registerReferral(_address, true, 0, dailyLimit);
    }

    function registerExchangeNonTradeable(address _address, uint256 dailyLimit, uint256 lockPeriod) public onlyAdminOrDeployerRole {
        _registerExchange(_address, false, lockPeriod, dailyLimit);
    }

    function registerDappNonTradeable(address _address, uint256 dailyLimit, uint256 lockPeriod) public onlyAdminOrDeployerRole {
        _registerDapp(_address, false, lockPeriod, dailyLimit);
    }

    function registerReferralNonTradeable(address _address, uint256 dailyLimit, uint256 lockPeriod) public onlyAdminOrDeployerRole {
        _registerReferral(_address, false, lockPeriod, dailyLimit);
    }


    function unregisterExchange(address _address) public onlyAdminOrDeployerRole {
        delete exchanges[_address];
    }

    function unregisterDapp(address _address) public onlyAdminOrDeployerRole {
        delete dapps[_address];
    }

    function unregisterReferral(address _address) public onlyAdminOrDeployerRole {
        delete referrals[_address];
    }

    function setExchangepDailyLimit(address _address, uint256 _dailyLimit) public onlyAdminOrDeployerRole {
        exchanges[_address].dailyLimit = _dailyLimit;
    }

    function setDappDailyLimit(address _address, uint256 _dailyLimit) public onlyAdminOrDeployerRole {
        dapps[_address].dailyLimit = _dailyLimit;
    }

    function setReferralDailyLimit(address _address, uint256 _dailyLimit) public onlyAdminOrDeployerRole {
        referrals[_address].dailyLimit = _dailyLimit;
    }

    function setExchangeLockPeriod(address _address, uint256 _lockPeriod) public onlyAdminOrDeployerRole {
        require(!getExchangeTradeable(_address), "cannot set lock period to tradeable address");
        exchanges[_address].lockPeriod = _lockPeriod;
    }

    function setDappLockPeriod(address _address, uint256 _lockPeriod) public onlyAdminOrDeployerRole {
        require(!getExchangeTradeable(_address), "cannot set lock period to tradeable address");
        dapps[_address].lockPeriod = _lockPeriod;
    }

    function setReferralLockPeriod(address _address, uint256 _lockPeriod) public onlyAdminOrDeployerRole {
        require(!getExchangeTradeable(_address), "cannot set lock period to tradeable address");
        dapps[_address].lockPeriod = _lockPeriod;
    }

    function addToExchangeDailyLimit(address _address, uint256 amount) public {
        if (exchanges[_address].dailyLimit > 0) {
            if (isNewDayStarted(exchanges[_address].recordTime)) {
                exchanges[_address].dailyLimitToday = 0;
                exchanges[_address].recordTime = getNewRecordTime();
            }

            uint256 limitToday = dapps[_address].dailyLimitToday;
            require(SafeMath.add(limitToday, amount) < exchanges[_address].dailyLimit, "daily limit exceeded");

            exchanges[_address].dailyLimitToday = SafeMath.add(limitToday, amount);
        }
    }

    function addToDappDailyLimit(address _address, uint256 amount) public {
        if (dapps[_address].dailyLimit > 0) {
            if (isNewDayStarted(dapps[_address].recordTime)) {
                dapps[_address].dailyLimitToday = 0;
                dapps[_address].recordTime = getNewRecordTime();
            }

            uint256 limitToday = dapps[_address].dailyLimitToday;
            require(SafeMath.add(limitToday, amount) < dapps[_address].dailyLimit, "daily limit exceeded");

            dapps[_address].dailyLimitToday = SafeMath.add(limitToday, amount);
        }
    }

    function addToReferralDailyLimit(address _address, uint256 amount) public {
        if (referrals[_address].dailyLimit > 0) {
            if (isNewDayStarted(referrals[_address].recordTime)) {
                referrals[_address].dailyLimitToday = 0;
                referrals[_address].recordTime = getNewRecordTime();
            }

            uint256 limitToday = referrals[_address].dailyLimitToday;
            require(SafeMath.add(limitToday, amount) < referrals[_address].dailyLimit, "daily limit exceeded");

            referrals[_address].dailyLimitToday = SafeMath.add(limitToday, amount);
        }
    }


    function isRegisteredDapp(address _address) public view returns (bool) {
        return (dapps[_address].addedAt != 0) ? true : false;
    }

    function isRegisteredReferral(address _address) public view returns (bool) {
        if (dapps[_address].addedAt != 0) {
            return true;
        } else {
            return false;
        }
    }

    function isRegisteredDappOrReferral(address executionAddress) public view returns (bool) {
        if (isRegisteredDapp(executionAddress) || isRegisteredReferral(executionAddress)) {
            return true;
        } else {
            return false;
        }
    }

    function isRegisteredExchange(address _address) public view returns (bool) {
        if (exchanges[_address].addedAt != 0) {
            return true;
        } else {
            return false;
        }
    }

    function getExchangeTradeable(address _address) public view returns (bool) {
        return exchanges[_address].tradeable;
    }

    function getDappTradeable(address _address) public view returns (bool) {
        return dapps[_address].tradeable;
    }

    function getReferralTradeable(address _address) public view returns (bool) {
        return referrals[_address].tradeable;
    }

    function getDappOrReferralTradeable(address _address) public view returns (bool) {
        if (isRegisteredDapp(_address)) {
            return dapps[_address].tradeable;
        } else {
            return referrals[_address].tradeable;
        }
    }

    function getExchangeLockPeriod(address _address) public view returns (uint256) {
        return exchanges[_address].lockPeriod;
    }

    function getDappLockPeriod(address _address) public view returns (uint256) {
        return dapps[_address].lockPeriod;
    }

    function getReferralLockPeriod(address _address) public view returns (uint256) {
        return referrals[_address].lockPeriod;
    }

    function getDappOrReferralLockPeriod(address _address) public view returns (uint256) {
        if (isRegisteredDapp(_address)) {
            return dapps[_address].lockPeriod;
        } else {
            return referrals[_address].lockPeriod;
        }
    }

    function getDappDailyLimit(address _address) public view returns (uint256) {
        return dapps[_address].dailyLimit;
    }

    function getReferralDailyLimit(address _address) public view returns (uint256) {
        return referrals[_address].dailyLimit;
    }

    function getDappOrReferralDailyLimit(address _address) public view returns (uint256) {
        if (isRegisteredDapp(_address)) {
            return dapps[_address].dailyLimit;
        } else {
            return referrals[_address].dailyLimit;
        }
    }
    function getExchangeTodayMinted(address _address) public view returns (uint256) {
        return exchanges[_address].dailyLimitToday;
    }

    function getDappTodayMinted(address _address) public view returns (uint256) {
        return dapps[_address].dailyLimitToday;
    }

    function getReferralTodayMinted(address _address) public view returns (uint256) {
        return referrals[_address].dailyLimitToday;
    }

    function getExchangeRecordTimed(address _address) public view returns (uint256) {
        return exchanges[_address].recordTime;
    }

    function getDappRecordTimed(address _address) public view returns (uint256) {
        return dapps[_address].recordTime;
    }

    function getReferralRecordTimed(address _address) public view returns (uint256) {
        return referrals[_address].recordTime;
    }

    function getNewRecordTime() internal view returns (uint256) {
        return SafeMath.add(block.timestamp, SafeMath.mul(1, SECONDS_IN_DAY));
    }

    function isNewDayStarted(uint256 oldRecordTime) internal view returns (bool) {
        return block.timestamp > oldRecordTime ? true : false;
    }

    function _registerExchange(address _address, bool tradeable, uint256 lockPeriod, uint256 dailyLimit) internal
    {
        require(!isRegisteredDappOrReferral(_address), "address already registered as dapp or referral");
        require(!isRegisteredExchange(_address), "exchange already registered");
        exchanges[_address] = WhitelistLib.AllowedAddress({
            tradeable: tradeable,
            lockPeriod: lockPeriod,
            dailyLimit: dailyLimit,
            dailyLimitToday: 0,
            addedAt: block.timestamp,
            recordTime: getNewRecordTime()
            });
    }

    function _registerDapp(address _address, bool tradeable, uint256 lockPeriod, uint256 dailyLimit) internal
    {
        require(!isRegisteredExchange(_address) && !isRegisteredReferral(_address), "address already registered as exchange or referral");
        require(!isRegisteredDapp(_address), "address already registered");
        dapps[_address] = WhitelistLib.AllowedAddress({
            tradeable: tradeable,
            lockPeriod: lockPeriod,
            dailyLimit: dailyLimit,
            dailyLimitToday: 0,
            addedAt: block.timestamp,
            recordTime: getNewRecordTime()
            });
    }

    function _registerReferral(address _address, bool tradeable, uint256 lockPeriod, uint256 dailyLimit) internal
    {
        require(!isRegisteredExchange(_address) && !isRegisteredDapp(_address), "address already registered as exchange or referral");
        require(!isRegisteredReferral(_address), "address already registered");
        referrals[_address] = WhitelistLib.AllowedAddress({
            tradeable: tradeable,
            lockPeriod: lockPeriod,
            dailyLimit: dailyLimit,
            dailyLimitToday: 0,
            addedAt: block.timestamp,
            recordTime: getNewRecordTime()
            });
    }
}

contract HexMoneyInternal is AccessControl, ReentrancyGuard {
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    // production
    uint256 public constant SECONDS_IN_DAY = 86400;

    HexWhitelist internal whitelist;

    modifier onlyAdminOrDeployerRole() {
        bool hasAdminRole = hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
        bool hasDeployerRole = hasRole(DEPLOYER_ROLE, _msgSender());
        require(hasAdminRole || hasDeployerRole, "Must have admin or deployer role");
        _;
    }

    function getWhitelistAddress() public view returns (address) {
        return address(whitelist);
    }

}

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20FreezableCapped is ERC20, HexMoneyInternal {
    uint256 public constant MINIMAL_FREEZE_PERIOD = 7;    // 7 days

    // freezing chains
    mapping (bytes32 => uint256) internal chains;
    // freezing amounts for each chain
    //mapping (bytes32 => uint) internal freezings;
    mapping(bytes32 => Freezing) internal freezings;
    // total freezing balance per address
    mapping (address => uint) internal freezingBalance;

    mapping(address => bytes32[]) internal freezingsByUser;

    mapping (address => uint256) internal latestFreezingTime;

    struct Freezing {
        address user;
        uint256 startDate;
        uint256 freezeDays;
        uint256 freezeAmount;
        bool capitalized;
    }



    event Freezed(address indexed to, uint256 release, uint amount);
    event Released(address indexed owner, uint amount);

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
     * @dev Gets the balance of the specified address include freezing tokens.
     * @param account The address to query the the balance of.
     * @return balance An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return super.balanceOf(account) + freezingBalance[account];
    }

    /**
     * @dev Gets the balance of the specified address without freezing tokens.
     * @param account The address to query the the balance of.
     * @return balance An uint256 representing the amount owned by the passed address.
     */
    function actualBalanceOf(address account) public view returns (uint256 balance) {
        return super.balanceOf(account);
    }

    function freezingBalanceOf(address account) public view returns (uint256 balance) {
        return freezingBalance[account];
    }

    function latestFreezeTimeOf(address account) public view returns (uint256) {
        return latestFreezingTime[account];
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }
    
    function getUserFreezings(address _user) public view returns (bytes32[] memory userFreezings) {
        return freezingsByUser[_user];
    }

    function getFreezingById(bytes32 freezingId)
        public
        view
        returns (address user, uint256 startDate, uint256 freezeDays, uint256 freezeAmount, bool capitalized)
    {
        Freezing memory userFreeze = freezings[freezingId];
        user = userFreeze.user;
        startDate = userFreeze.startDate;
        freezeDays = userFreeze.freezeDays;
        freezeAmount = userFreeze.freezeAmount;
        capitalized = userFreeze.capitalized;
    }


    function freeze(address _to, uint256 _start, uint256 _freezeDays, uint256 _amount) internal {
        require(_to != address(0x0), "FreezeContract: address cannot be zero");
        require(_start >= block.timestamp, "FreezeContract: start date cannot be in past");
        require(_freezeDays >= 0, "FreezeContract: amount of freeze days cannot be zero");
        require(_amount <= _balances[_msgSender()], "FreezeContract: freeze amount exceeds unfrozen balance");

        Freezing memory userFreeze = Freezing({
            user: _to,
            startDate: _start,
            freezeDays: _freezeDays,
            freezeAmount: _amount,
            capitalized: false
        });

        bytes32 freezeId = _toFreezeKey(_to, _start);

        _balances[_msgSender()] = _balances[_msgSender()].sub(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);

        freezings[freezeId] = userFreeze;
        freezingsByUser[_to].push(freezeId);
        latestFreezingTime[_to] = _start;

        emit Transfer(_msgSender(), _to, _amount);
        emit Freezed(_to, _start, _amount);
    }

    function mintAndFreeze(address _to, uint256 _start, uint256 _freezeDays, uint256 _amount) internal {
        require(_to != address(0x0), "FreezeContract: address cannot be zero");
        require(_start >= block.timestamp, "FreezeContract: start date cannot be in past");
        require(_freezeDays >= 0, "FreezeContract: amount of freeze days cannot be zero");

        Freezing memory userFreeze = Freezing({
            user: _to,
            startDate: _start,
            freezeDays: _freezeDays,
            freezeAmount: _amount,
            capitalized: false
        });

        bytes32 freezeId = _toFreezeKey(_to, _start);

        freezingBalance[_to] = freezingBalance[_to].add(_amount);

        freezings[freezeId] = userFreeze;
        freezingsByUser[_to].push(freezeId);
        latestFreezingTime[_to] = _start;

        _totalSupply = _totalSupply.add(_amount);

        emit Transfer(_msgSender(), _to, _amount);
        emit Freezed(_to, _start, _amount);
    }

    function _toFreezeKey(address _user, uint256 _startDate) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _startDate));
    }

    function release(uint256 _startTime) internal {
        bytes32 freezeId = _toFreezeKey(_msgSender(), _startTime);
        Freezing memory userFreeze = freezings[freezeId];

        uint256 lockUntil = _daysToTimestampFrom(userFreeze.startDate, userFreeze.freezeDays);
        require(block.timestamp >= lockUntil, "cannot release before lock");

        uint256 amount = userFreeze.freezeAmount;

        _balances[_msgSender()] = _balances[_msgSender()].add(amount);
        freezingBalance[_msgSender()] = freezingBalance[_msgSender()].sub(amount);

        _deleteFreezing(freezeId, freezingsByUser[_msgSender()]);

        emit Released(_msgSender(), amount);
    }

    function refreeze(uint256 _startTime, uint256 addAmount) internal {
        bytes32 freezeId = _toFreezeKey(_msgSender(), _startTime);
        Freezing storage userFreeze = freezings[freezeId];

        uint256 lockUntil;
        if (!userFreeze.capitalized) {
            lockUntil = _daysToTimestampFrom(userFreeze.startDate, userFreeze.freezeDays);
        } else {
            lockUntil = _daysToTimestampFrom(userFreeze.startDate, 1);
        }

        require(block.timestamp >= lockUntil, "cannot refreeze before lock");

        bytes32 newFreezeId = _toFreezeKey(userFreeze.user, block.timestamp);
        uint256 oldFreezeAmount = userFreeze.freezeAmount;
        uint256 newFreezeAmount = SafeMath.add(userFreeze.freezeAmount, addAmount);

        Freezing memory newFreeze = Freezing({
            user: userFreeze.user,
            startDate: block.timestamp,
            freezeDays: userFreeze.freezeDays,
            freezeAmount: newFreezeAmount,
            capitalized: true
        });

        freezingBalance[_msgSender()] = freezingBalance[_msgSender()].add(addAmount);

        freezings[newFreezeId] = newFreeze;
        freezingsByUser[userFreeze.user].push(newFreezeId);
        latestFreezingTime[userFreeze.user] = block.timestamp;

        _deleteFreezing(freezeId, freezingsByUser[_msgSender()]);
        delete freezings[freezeId];

        emit Released(_msgSender(), oldFreezeAmount);
        emit Transfer(_msgSender(), _msgSender(), addAmount);
        emit Freezed(_msgSender(), block.timestamp, newFreezeAmount);
    }

    function _deleteFreezing(bytes32 freezingId, bytes32[] storage userFreezings) internal {
        uint256 freezingIndex;
        bool freezingFound;
        for (uint256 i; i < userFreezings.length; i++) {
            if (userFreezings[i] == freezingId) {
                freezingIndex = i;
                freezingFound = true;
            }
        }

        if (freezingFound) {
            userFreezings[freezingIndex] = userFreezings[userFreezings.length - 1];
            delete userFreezings[userFreezings.length - 1];
            userFreezings.pop();
        }
    }

    function _daysToTimestampFrom(uint256 from, uint256 lockDays) internal pure returns(uint256) {
        return SafeMath.add(from, SafeMath.mul(lockDays, SECONDS_IN_DAY));
    }

    function _daysToTimestamp(uint256 lockDays) internal view returns(uint256) {
        return _daysToTimestampFrom(block.timestamp, lockDays);
    }

    function _getBaseLockDays() internal view returns (uint256) {
        return _daysToTimestamp(MINIMAL_FREEZE_PERIOD);
    }

    function _getBaseLockDaysFrom(uint256 from) internal pure returns (uint256) {
        return _daysToTimestampFrom(from, MINIMAL_FREEZE_PERIOD);
    }


    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        }
    }
}

abstract contract HexMoneyTeam is AccessControl {
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    address payable internal teamAddress;

    modifier onlyTeamRole() {
        require(hasRole(TEAM_ROLE, _msgSender()), "Must have admin role to setup");
        _;
    }

    function getTeamAddress() public view returns (address) {
        return teamAddress;
    }
}

contract HXY is ERC20FreezableCapped, HexMoneyTeam {
    using WhitelistLib for WhitelistLib.AllowedAddress;

    uint256 internal liquidSupply = 694866350105876;
    uint256 internal lockedSupply = SafeMath.mul(6, 10 ** 14);

    uint256 internal lockedSupplyFreezingStarted;

    address internal lockedSupplyAddress;
    address internal liquidSupplyAddress;

    struct LockedSupplyAddresses {
        address firstAddress;
        address secondAddress;
        address thirdAddress;
        address fourthAddress;
        address fifthAddress;
        address sixthAddress;
    }

    LockedSupplyAddresses internal lockedSupplyAddresses;
    bool internal lockedSupplyPreminted;

    // total amounts variables
    uint256 internal totalMinted;
    uint256 internal totalFrozen;
    uint256 internal totalCirculating;
    uint256 internal totalPayedInterest;

    // round logic structures
    uint256 internal hxyMintedMultiplier = 10 ** 6;
    uint256[] internal hxyRoundMintAmount = [3, 6, 9, 12, 15, 18, 21, 24, 27];
    uint256 internal baseHexToHxyRate = 10 ** 3;
    uint256[] internal hxyRoundBaseRate = [2, 3, 4, 5, 6, 7, 8, 9, 10];

    uint256 internal maxHxyRounds = 9;

    // initial round
    uint256 internal currentHxyRound;
    uint256 internal currentHxyRoundRate = SafeMath.mul(hxyRoundBaseRate[0], baseHexToHxyRate);



    //constructor(address payable _teamAddress,  address _liqSupAddress, address _lockSupAddress, address _migratedSupplyAddress)
    constructor(address _whitelistAddress,  address _liqSupAddress, uint256 _liqSupAmount)
    public
    ERC20FreezableCapped(SafeMath.mul(60,  10 ** 14))        // cap = 60,000,000
    ERC20("HEX Money", "HXY")
    {
        require(address(_whitelistAddress) != address(0x0), "whitelist address should not be empty");
        require(address(_liqSupAddress) != address(0x0), "liquid supply address should not be empty");
        _setupDecimals(8);

        _setupRole(DEPLOYER_ROLE, _msgSender());


        whitelist = HexWhitelist(_whitelistAddress);
        _premintLiquidSupply(_liqSupAddress, _liqSupAmount);
    }

    function getRemainingHxyInRound() public view returns (uint256) {
        return _getRemainingHxyInRound(currentHxyRound);
    }

    function getTotalHxyInRound() public view returns (uint256) {
        return _getTotalHxyInRound(currentHxyRound);
    }

    function getTotalHxyMinted() public view returns (uint256) {
        return totalMinted;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return totalCirculating;
    }

    function getCurrentHxyRound() public view returns (uint256) {
        return currentHxyRound;
    }

    function getCurrentHxyRate() public view returns (uint256) {
        return currentHxyRoundRate;
    }

    function getTotalFrozen() public view returns (uint256) {
        return totalFrozen;
    }

    function getTotalPayedInterest() public view returns (uint256) {
        return totalPayedInterest;
    }


    function getCurrentInterestAmount(address _addr, uint256 _freezeStartDate) public view returns (uint256) {
        bytes32 freezeId = _toFreezeKey(_addr, _freezeStartDate);
        Freezing memory userFreeze = freezings[freezeId];

        uint256 frozenTokens = userFreeze.freezeAmount;
        if (frozenTokens != 0) {
            uint256 startFreezeDate = userFreeze.startDate;
            uint256 interestDays = SafeMath.div(SafeMath.sub(block.timestamp, startFreezeDate), SECONDS_IN_DAY);
            return SafeMath.mul(SafeMath.div(frozenTokens, 1000), interestDays);
        } else {
            return 0;
        }
    }

    function mintFromExchange(address account, uint256 amount) public {
        address executionAddress = _msgSender();
        require(whitelist.isRegisteredExchange(executionAddress), "must be executed from whitelisted dapp");
        whitelist.addToExchangeDailyLimit(executionAddress, amount);

        if (whitelist.getExchangeTradeable(executionAddress)) {
            mint(account, amount);
        } else {
            uint256 lockPeriod = whitelist.getExchangeLockPeriod(executionAddress);
            mintAndFreezeTo(account, amount, lockPeriod);
        }
    }

    function mintFromDappOrReferral(address account, uint256 amount) public {
        address executionAddress = _msgSender();
        require(whitelist.isRegisteredDappOrReferral(executionAddress), "must be executed from whitelisted address");
        if (whitelist.isRegisteredDapp(executionAddress)) {
            whitelist.addToDappDailyLimit(executionAddress, amount);
        } else {
            whitelist.addToReferralDailyLimit(executionAddress, amount);
        }

        if (whitelist.getDappTradeable(executionAddress)) {
            _mintDirectly(account, amount);
        } else {
            uint256 lockPeriod = whitelist.getDappOrReferralLockPeriod(executionAddress);
            _mintAndFreezeDirectly(account, amount, lockPeriod);
        }
    }

    function freezeHxy(uint256 lockAmount) public {
        freeze(_msgSender(), block.timestamp, MINIMAL_FREEZE_PERIOD, lockAmount);
        totalFrozen = SafeMath.add(totalFrozen, lockAmount);
        totalCirculating = SafeMath.sub(totalCirculating, lockAmount);
    }

    function refreezeHxy(uint256 startDate) public {
        bytes32 freezeId = _toFreezeKey(_msgSender(), startDate);
        Freezing memory userFreezing = freezings[freezeId];

        uint256 frozenTokens = userFreezing.freezeAmount;
        uint256 interestDays = SafeMath.div(SafeMath.sub(block.timestamp, userFreezing.startDate), SECONDS_IN_DAY);
        uint256 interestAmount = SafeMath.mul(SafeMath.div(frozenTokens, 1000), interestDays);

        refreeze(startDate, interestAmount);
        totalFrozen = SafeMath.add(totalFrozen, interestAmount);
    }

    function releaseFrozen(uint256 _startDate) public {
        bytes32 freezeId = _toFreezeKey(_msgSender(), _startDate);
        Freezing memory userFreezing = freezings[freezeId];

        uint256 frozenTokens = userFreezing.freezeAmount;

        release(_startDate);

        if (!_isLockedAddress()) {
            uint256 interestDays = SafeMath.div(SafeMath.sub(block.timestamp, userFreezing.startDate), SECONDS_IN_DAY);
            uint256 interestAmount = SafeMath.mul(SafeMath.div(frozenTokens, 1000), interestDays);
            _mint(_msgSender(), interestAmount);

            totalFrozen = SafeMath.sub(totalFrozen, frozenTokens);
            totalCirculating = SafeMath.add(totalCirculating, frozenTokens);
            totalPayedInterest = SafeMath.add(totalPayedInterest, interestAmount);
        }
    }

    function mint(address _to, uint256 _amount) internal {
        _preprocessMint(_to, _amount);
    }

    function mintAndFreezeTo(address _to, uint _amount, uint256 _lockDays) internal {
        _preprocessMintWithFreeze(_to, _amount, _lockDays);
    }

    function _premintLiquidSupply(address _liqSupAddress, uint256 _liqSupAmount) internal {
        require(_liqSupAddress != address(0x0), "liquid supply address cannot be zero");
        require(_liqSupAmount != 0, "liquid supply amount cannot be zero");
        liquidSupplyAddress = _liqSupAddress;
        liquidSupply = _liqSupAmount;
        _mint(_liqSupAddress, _liqSupAmount);
    }

    function premintLocked(address[6] memory _lockSupAddresses,  uint256[10] memory _unlockDates) public {
        require(hasRole(DEPLOYER_ROLE, _msgSender()), "Must have deployer role");
        require(!lockedSupplyPreminted, "cannot premint locked twice");
        _premintLockedSupply(_lockSupAddresses, _unlockDates);
    }

    function _premintLockedSupply(address[6] memory _lockSupAddresses, uint256[10] memory _unlockDates) internal {

        lockedSupplyAddresses.firstAddress = _lockSupAddresses[0];
        lockedSupplyAddresses.secondAddress = _lockSupAddresses[1];
        lockedSupplyAddresses.thirdAddress = _lockSupAddresses[2];
        lockedSupplyAddresses.fourthAddress = _lockSupAddresses[3];
        lockedSupplyAddresses.fifthAddress = _lockSupAddresses[4];
        lockedSupplyAddresses.sixthAddress = _lockSupAddresses[4];

        for (uint256 i = 0; i < 10; i++) {
            uint256 startDate = SafeMath.add(block.timestamp, SafeMath.add(i, 5));

            uint256 endFreezeDate = _unlockDates[i];
            uint256 lockSeconds = SafeMath.sub(endFreezeDate, startDate);
            uint256 lockDays = SafeMath.div(lockSeconds, SECONDS_IN_DAY);


            uint256 firstSecondAmount = SafeMath.mul(180000, 10 ** uint256(decimals()));
            uint256 thirdAmount = SafeMath.mul(120000, 10 ** uint256(decimals()));
            uint256 fourthAmount = SafeMath.mul(90000, 10 ** uint256(decimals()));
            uint256 fifthSixthAmount = SafeMath.mul(15000, 10 ** uint256(decimals()));

            mintAndFreeze(lockedSupplyAddresses.firstAddress, startDate, lockDays, firstSecondAmount);
            mintAndFreeze(lockedSupplyAddresses.secondAddress, startDate, lockDays, firstSecondAmount);
            mintAndFreeze(lockedSupplyAddresses.thirdAddress, startDate, lockDays, thirdAmount);
            mintAndFreeze(lockedSupplyAddresses.fourthAddress, startDate, lockDays, fourthAmount);
            mintAndFreeze(lockedSupplyAddresses.fifthAddress, startDate, lockDays, fifthSixthAmount);
            mintAndFreeze(lockedSupplyAddresses.sixthAddress, startDate, lockDays, fifthSixthAmount);
        }

        lockedSupplyPreminted = true;
    }


    function _preprocessMint(address _account, uint256 _hexAmount) internal {
        uint256 currentRoundHxyAmount = SafeMath.div(_hexAmount, currentHxyRoundRate);
        if (currentRoundHxyAmount < getRemainingHxyInRound()) {
            uint256 hxyAmount = currentRoundHxyAmount;
            _mint(_account, hxyAmount);

            totalMinted = SafeMath.add(totalMinted, hxyAmount);
            totalCirculating = SafeMath.add(totalCirculating, hxyAmount);
        } else if (currentRoundHxyAmount == getRemainingHxyInRound()) {
            uint256 hxyAmount = currentRoundHxyAmount;
            _mint(_account, hxyAmount);

            _incrementHxyRateRound();

            totalMinted = SafeMath.add(totalMinted, hxyAmount);
            totalCirculating = SafeMath.add(totalCirculating, hxyAmount);
        } else {
            uint256 hxyAmount;
            uint256 hexPaymentAmount;
            while (hexPaymentAmount < _hexAmount) {
                uint256 hxyRoundTotal = SafeMath.mul(_toDecimals(hxyRoundMintAmount[currentHxyRound]), hxyMintedMultiplier);

                uint256 hxyInCurrentRoundMax = SafeMath.sub(hxyRoundTotal, totalMinted);
                uint256 hexInCurrentRoundMax = SafeMath.mul(hxyInCurrentRoundMax, currentHxyRoundRate);

                uint256 hexInCurrentRound;
                uint256 hxyInCurrentRound;
                if (SafeMath.sub(_hexAmount, hexPaymentAmount) < hexInCurrentRoundMax) {
                    hexInCurrentRound = SafeMath.sub(_hexAmount, hexPaymentAmount);
                    hxyInCurrentRound = SafeMath.div(hexInCurrentRound, currentHxyRoundRate);
                } else {
                    hexInCurrentRound = hexInCurrentRoundMax;
                    hxyInCurrentRound = hxyInCurrentRoundMax;

                    _incrementHxyRateRound();
                }

                hxyAmount = SafeMath.add(hxyAmount, hxyInCurrentRound);
                hexPaymentAmount = SafeMath.add(hexPaymentAmount, hexInCurrentRound);

                totalMinted = SafeMath.add(totalMinted, hxyInCurrentRound);
                totalCirculating = SafeMath.add(totalCirculating, hxyAmount);
            }
            _mint(_account, hxyAmount);
        }
    }

    function _preprocessMintWithFreeze(address _account, uint256 _hexAmount, uint256 _freezeDays) internal {
        uint256 currentRoundHxyAmount = SafeMath.div(_hexAmount, currentHxyRoundRate);
        if (currentRoundHxyAmount < getRemainingHxyInRound()) {
            uint256 hxyAmount = currentRoundHxyAmount;
            totalMinted = SafeMath.add(totalMinted, hxyAmount);
            mintAndFreeze(_account, block.timestamp, _freezeDays, hxyAmount);
        } else if (currentRoundHxyAmount == getRemainingHxyInRound()) {
            uint256 hxyAmount = currentRoundHxyAmount;
            mintAndFreeze(_account, block.timestamp, _freezeDays, hxyAmount);

            totalMinted = SafeMath.add(totalMinted, hxyAmount);

            _incrementHxyRateRound();
        } else {
            uint256 hxyAmount;
            uint256 hexPaymentAmount;
            while (hexPaymentAmount < _hexAmount) {
                uint256 hxyRoundTotal = SafeMath.mul(_toDecimals(hxyRoundMintAmount[currentHxyRound]), hxyMintedMultiplier);

                uint256 hxyInCurrentRoundMax = SafeMath.sub(hxyRoundTotal, totalMinted);
                uint256 hexInCurrentRoundMax = SafeMath.mul(hxyInCurrentRoundMax, currentHxyRoundRate);

                uint256 hexInCurrentRound;
                uint256 hxyInCurrentRound;
                if (SafeMath.sub(_hexAmount, hexPaymentAmount) < hexInCurrentRoundMax) {
                    hexInCurrentRound = SafeMath.sub(_hexAmount, hexPaymentAmount);
                    hxyInCurrentRound = SafeMath.div(hexInCurrentRound, currentHxyRoundRate);
                } else {
                    hexInCurrentRound = hexInCurrentRoundMax;
                    hxyInCurrentRound = hxyInCurrentRoundMax;

                    _incrementHxyRateRound();
                }

                hxyAmount = SafeMath.add(hxyAmount, hxyInCurrentRound);
                hexPaymentAmount = SafeMath.add(hexPaymentAmount, hexInCurrentRound);

                totalMinted = SafeMath.add(totalMinted, hxyInCurrentRound);
            }
            mintAndFreeze(_account, block.timestamp, _freezeDays, hxyAmount);
        }
    }

    function _mintDirectly(address _account, uint256 _hxyAmount) internal {
        _mint(_account, _hxyAmount);
    }

    function _mintAndFreezeDirectly(address _account, uint256 _hxyAmount, uint256 _freezeDays) internal {
        mintAndFreeze(_account, block.timestamp, _freezeDays, _hxyAmount);
    }

    function _isLockedAddress() internal view returns (bool) {
        if (_msgSender() == lockedSupplyAddresses.firstAddress) {
            return true;
        } else if (_msgSender() == lockedSupplyAddresses.secondAddress) {
            return true;
        } else if (_msgSender() == lockedSupplyAddresses.thirdAddress) {
            return true;
        } else if (_msgSender() == lockedSupplyAddresses.fourthAddress) {
            return true;
        } else if (_msgSender() == lockedSupplyAddresses.fifthAddress) {
            return true;
        } else if (_msgSender() == lockedSupplyAddresses.sixthAddress) {
            return true;
        } else {
            return false;
        }
    }

    function _getTotalHxyInRound(uint256 _round) public view returns (uint256) {
        return SafeMath.mul(_toDecimals(hxyRoundMintAmount[_round]),hxyMintedMultiplier);
    }

    function _getRemainingHxyInRound(uint256 _round) public view returns (uint256) {
        return SafeMath.sub(SafeMath.mul(_toDecimals(hxyRoundMintAmount[_round]), hxyMintedMultiplier), totalMinted);
    }

    function _incrementHxyRateRound() internal {
        currentHxyRound = SafeMath.add(currentHxyRound, 1);
        currentHxyRoundRate = SafeMath.mul(hxyRoundBaseRate[currentHxyRound], baseHexToHxyRate);
    }

    function _toDecimals(uint256 amount) internal view returns (uint256) {
        return SafeMath.mul(amount, 10 ** uint256(decimals()));
    }
}