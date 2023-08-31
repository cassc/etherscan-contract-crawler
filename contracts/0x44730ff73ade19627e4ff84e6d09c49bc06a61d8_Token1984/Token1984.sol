/**
 *Submitted for verification at Etherscan.io on 2023-08-17
*/

///////************************Important Links of the Platform****************////////

//Twitter: @1984token

//Telegram: https://t.me/official_1984_token

//Web site created using create-react-app

//https://1984token.com/

//************************Important Links of the Platform****************////////


// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

// CAUTION
// This version of SafeMath should only be used with  0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over 's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with  0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to 's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to 's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to 's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to 's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to 's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while  uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to 's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to 's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to 's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while  uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of  v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum//issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/sun.sol

//Official Links:
//Twitter: @1984token
//Website: 1984token.com

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Token1984 is ERC20, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _skipCount; //total skip count
    Counters.Counter private _walletCount; //total count for wallets

    /**
     * @dev Emitted when a wallet address is blacklisted.
     * @param wallet The blacklisted wallet address.
     */
    event WalletBlacklisted(address indexed wallet);
    /**
     * @dev Emitted when an exchange wallet address is blacklisted.
     * @param wallet The blacklisted exchange wallet address.
     */
    event ExchangeWalletBlacklisted(address indexed wallet);
    /**
     * @dev Emitted when a wallet address is removed from the blacklist.
     * @param wallet The wallet address that was removed from the blacklist.
     */
    event RemovedWalletBlacklisted(address indexed wallet);
    /**
     * @dev Emitted when an exchange wallet address is removed from the blacklist.
     * @param wallet The exchange wallet address that was removed from the blacklist.
     */
    event RemovedExchangeWalletBlacklisted(address indexed wallet);
    /**
     * @dev Emitted when a winner is determined.
     * @param winner The address of the winner.
     */
    event Winner(address indexed winner);
    /**
     * @dev Emitted when the marketing address is updated.
     * @param marketingAddress The updated marketing address.
     */
    event MarketingAddress(address indexed marketingAddress);

    mapping(address => bool) public existingWallet;
    mapping(address => bool) private airdropBlacklistedWallets;
    mapping(address => bool) private blacklistedExchangeWallets;
    mapping(address => bool) public isDexAddress;
    mapping(address => bool) public isStopSell;

    address public socialRewardBeneficiary;
    uint256 public chosenTimestamp;

    uint256 private LotteryPool;
    uint256 private liquidityPool;
    uint256 private minimumBalance;
    uint256 private startTime;
    uint256 private endTime;
    uint256 private lockedTokens;
    address private marketingAddress;

    address[] private walletAddresses;
    address[] private allLotteryBlacklistedWallets;
    address[] private allBlacklistedExchangeWallets;
    address[] private recentWinners;
    address[] private lpPairs;

    // The list of DEX addresses
    // address[] public dexAddresses;

    // The status of selling on DEX
    mapping(address => bool) public isSellingDeactivatedOnDex;

    // The timestamp when the selling was deactivated on DEX
    mapping(address => uint256) public sellingDeactivatedTimestamp;

    // The duration of selling deactivation on DEX (in seconds)
    uint256 public sellingDeactivationDuration;

    // The interval between automatic selling deactivations (in seconds)
    // uint256 public sellingDeactivationInterval = 7 days;

    // The minimum duration of selling deactivation (in seconds)
    uint256 public minSellingDeactivationDuration = 2 days;

    // The maximum duration of selling deactivation (in seconds)
    uint256 public maxSellingDeactivationDuration = 12 days;

    // The timestamp of the last automatic selling deactivation
    uint256 public lastSellingDeactivationTimestamp;

    /**
     * @dev Modifier to check if the specified wallet address is not blacklisted for exchange.
     * @param wallet The address to be checked.
     *
     * Requirements:
     * - The wallet address must not be blacklisted for exchange operations.
     */
    modifier notBlacklistedExchange(address wallet) {
        _notBlackListedExchange(wallet);
        _;
    }

    uint256 public launchTime;
    uint256 public recentWinnersCount = 10;
    uint256 public transferTax = 25;
    uint256 public requiredTxns = 150;
    uint256 public noSellLimt = 1 * 10**decimals();

    /**
 * @notice 
 Contract 
 uint256 public launchTime;
address public lpPair;
uint256 public transferTax = 25;
constructor.
 * @dev Constructor function for the KLVR token contract.
 * It also sets the minimum balance, start time, end time, and locks a portion of the total supply.

 */

    constructor(address _marketingAddress) ERC20("1984", "1984") {
        launchTime = block.timestamp;
        uint256 totalSupply = 10_000_000_000 * 10**18;
        _mint(msg.sender, totalSupply);
        minimumBalance = 5_000_000 * 10**decimals();
        startTime = block.timestamp;
        endTime = startTime.add(30 days);
        marketingAddress = _marketingAddress;
        lockedTokens = (totalSupply).mul(50).div(100);
        super._transfer(owner(), address(this), lockedTokens);
    }

    /**
     * @notice Allows the owner of the contract to withdraw locked tokens and distribute them among specified wallets.
     * @param wallets An array of wallet addresses to receive the locked tokens.
     * @dev Requires the contract to have locked tokens, at least one wallet address, and the current time to be after the end time.
     * @dev Emits a `Transfer` event for each successful token transfer.
     * @dev Sets the `lockedTokens` variable to 0 after successful distribution.
     * @dev Throws an error if any wallet address is invalid.
     */
    function withdrawLockedTokens(address[] memory wallets) external onlyOwner {
        require(lockedTokens > 0, "No Locked Tokens");
        require(wallets.length > 0, "No wallets provided");
        require(
            block.timestamp >= endTime,
            "There is still time left to withdraw tokens, Please Wait."
        );
        uint256 totalAmountShare = lockedTokens.div(wallets.length);
        for (uint256 i = 0; i < wallets.length; i++) {
            require(
                wallets[i] != address(0),
                "Withdraw: Invalid wallet address"
            );
            _transfer(address(this), wallets[i], totalAmountShare);
            emit Transfer(address(this), wallets[i], totalAmountShare);
        }
        lockedTokens = 0;
    }

    /**
     * @dev Blacklists multiple wallets to prevent them from participating in the airdrop.
     * @param wallets An array of addresses to be blacklisted.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     * - At least one wallet address must be provided.
     * - Each wallet address must be valid and not already blacklisted.
     *
     * Effects:
     * - Adds each wallet address to the airdrop blacklist.
     * - Appends each wallet address to the array of all blacklisted wallets.
     * - Emits a `WalletBlacklisted` event for each blacklisted wallet address.
     */
    function blacklistWallets(address[] memory wallets) external onlyOwner {
        require(wallets.length > 0, "No wallets provided");

        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            require(wallet != address(0), "Invalid wallet address");
            require(
                !airdropBlacklistedWallets[wallet],
                "Wallet is already blacklisted"
            );

            airdropBlacklistedWallets[wallet] = true;
            allLotteryBlacklistedWallets.push(wallet);
            emit WalletBlacklisted(wallet);
        }
    }

    /**
     * @notice Blacklists multiple exchange wallets to restrict their access and participation.
     * @param wallets An array of exchange wallet addresses to be blacklisted.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     * - At least one wallet address must be provided.
     * - Each wallet address must be valid and not already blacklisted.
     *
     * Effects:
     * - Adds each exchange wallet address to the blacklist.
     * - Appends each wallet address to the array of all blacklisted exchange wallets.
     * - Emits an `ExchangeWalletBlacklisted` event for each blacklisted exchange wallet address.
     */
    function blacklistExchangeWallets(address[] memory wallets)
        external
        onlyOwner
    {
        require(wallets.length > 0, "No wallets provided");

        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            require(wallet != address(0), "Invalid wallet address");
            require(
                !blacklistedExchangeWallets[wallet],
                "Wallet is already blacklisted"
            );

            blacklistedExchangeWallets[wallet] = true;
            allBlacklistedExchangeWallets.push(wallet);
            emit ExchangeWalletBlacklisted(wallet);
        }
    }

    /**
     * @notice Removes a wallet from the blacklist.
     * @param wallet The address of the wallet to be removed from the blacklist.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     * - The array of blacklisted wallets must not be empty.
     *
     * Effects:
     * - Finds the provided wallet address in the array of all blacklisted wallets.
     * - Replaces the found wallet address with the last address in the array.
     * - Removes the last element from the array of all blacklisted wallets.
     * - Sets the `airdropBlacklistedWallets` mapping value for the removed wallet address to `false`.
     */
    function removeBlacklistWallet(address wallet) external onlyOwner {
        require(
            allLotteryBlacklistedWallets.length > 0,
            "No blacklisted wallet to remove"
        );

        for (uint256 i = 0; i < allLotteryBlacklistedWallets.length; i++) {
            if (allLotteryBlacklistedWallets[i] == wallet) {
                allLotteryBlacklistedWallets[i] = allLotteryBlacklistedWallets[
                    allLotteryBlacklistedWallets.length - 1
                ];
                allLotteryBlacklistedWallets.pop();
                airdropBlacklistedWallets[wallet] = false;
                emit RemovedWalletBlacklisted(wallet);
            }
        }
    }

    /**
     * @notice Removes a wallet from the blacklist for exchange wallets.
     * @param wallet The address of the wallet to be removed from the blacklist.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     * - The array of blacklisted exchange wallets must not be empty.
     *
     * Effects:
     * - Finds the provided wallet address in the array of all blacklisted exchange wallets.
     * - Replaces the found wallet address with the last address in the array.
     * - Removes the last element from the array of all blacklisted exchange wallets.
     * - Sets the `blacklistedExchangeWallets` mapping value for the removed wallet address to `false`.
     */
    function removeBlacklistExchangeWallet(address wallet) external onlyOwner {
        require(
            allBlacklistedExchangeWallets.length > 0,
            "No blacklisted exchange wallet to remove"
        );

        for (uint256 i = 0; i < allBlacklistedExchangeWallets.length; i++) {
            if (allBlacklistedExchangeWallets[i] == wallet) {
                allBlacklistedExchangeWallets[
                    i
                ] = allBlacklistedExchangeWallets[
                    allBlacklistedExchangeWallets.length - 1
                ];
                allBlacklistedExchangeWallets.pop();
                blacklistedExchangeWallets[wallet] = false;
                emit RemovedExchangeWalletBlacklisted(wallet);
            }
        }
    }

    /**
     * @dev Sets the marketing address.
     * @param _marketingAddress The address to set as the marketing address.
     *
     * Requirements:
     * - Only the contract owner is allowed to call this function.
     */
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(_marketingAddress != address(0), "Set: Invalid wallet address");

        marketingAddress = _marketingAddress;
        emit MarketingAddress(marketingAddress);
    }

    /**
     * @dev Retrieves the addresses stored in allLotteryBlacklistedWallets.
     * @return An array containing all the addresses stored in allLotteryBlacklistedWallets.
     */
    function getAirdropBlacklistedWallets()
        external
        view
        returns (address[] memory)
    {
        return allLotteryBlacklistedWallets;
    }

    /**
     * @dev Retrieves the addresses stored in allBlacklistedExchangeWallets.
     * @return An array containing all the addresses stored in allBlacklistedExchangeWallets.
     */
    function getBlacklistedExchangeWallets()
        external
        view
        returns (address[] memory)
    {
        return allBlacklistedExchangeWallets;
    }

    /**
     * @dev Retrieves the addresses stored in walletAddresses.
     * @return An array containing all the addresses stored in walletAddresses.
     */
    function getAddedWallets() external view returns (address[] memory) {
        return walletAddresses;
    }

    /**
     * @dev Returns the marketing address.
     * @return The current marketing address.
     */
    function getMarketingAddress() external view returns (address) {
        return marketingAddress;
    }

    /**
     * @dev Retrieves the value of LotteryPool.
     * @return The current value of LotteryPool.
     */
    function getLotteryPool() external view returns (uint256) {
        return LotteryPool;
    }

    /**
     * @dev Retrieves the value of liquidityPool.
     * @return The current value of liquidityPool.
     */
    function getLiquidityPool() external view returns (uint256) {
        return liquidityPool;
    }

    /**
     * @dev Retrieves the total count of wallets or addresses registered in the system.
     * @return The total count of wallets or addresses.
     */
    function getWalletCount() external view returns (uint256) {
        return _walletCount.current();
    }

    /**
     * @dev Retrieves the value of minimumBalance.
     * @return The current value of minimumBalance.
     */
    function getMinimumBalanceAirdrop() external view returns (uint256) {
        return minimumBalance;
    }

    /**
     * @dev Retrieves the value of lockedTokens.
     * @return The current value of lockedTokens.
     */
    function getLockedTokens() external view returns (uint256) {
        return lockedTokens;
    }

    /**
     * @dev Retrieves the start time of the event or period.
     * @return The start time represented as a Unix timestamp.
     */
    function getStartTime() external view returns (uint256) {
        return startTime;
    }

    /**
     * @dev Retrieves the end time of the event or period.
     * @return The end time represented as a Unix timestamp.
     */
    function getEndTime() external view returns (uint256) {
        return endTime;
    }

    /**
     * @notice Transfers a specified amount of tokens from the sender's account to the recipient's account.
     * @dev This function implements the ERC20 `transfer` function and includes additional functionality.
     * The transferred amount is subject to a 2.5% tax, which is divided equally between the airdrop pool and the liquidity pool.
     * Additionally, if the recipient address is not blacklisted for exchanges, the transfer is allowed.
     * @param recipient The address of the recipient account.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean value indicating the success of the transfer.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        notBlacklistedExchange(recipient)
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        bool isLpPair;
        for (uint256 i = 0; i < lpPairs.length; i++) {
            if (to == lpPairs[i]) {
                isLpPair = true;
                break;
            }
        }

        if (isLpPair && isSellingDeactivatedOnDex[to]) {
            reactivateSellingOnDex();
        }
        uint256 taxAmount = amount.mul(transferTax).div(1000);
        uint256 marketingAmount = amount.mul(10).div(1000);

        //0.5 percent for lotteryPool and 1 % for liqudityPool
        liquidityPool = liquidityPool.add(amount.mul(10).div(1000));

        // Allocate 0.5% to lottery pool
        LotteryPool = LotteryPool.add(amount.mul(5).div(1000));

        if (!existingWallet[to] && !isLpPair) {
            walletAddresses.push(to);
            _walletCount.increment();
            existingWallet[to] = true;
        }
        if (_walletCount.current() % requiredTxns == 0) {
            triggerLotteryAirdrop();
        }

        // Check if the caller is a recent winner
        bool isRecentWinner = false;
        for (uint256 i = 0; i < recentWinners.length; i++) {
            if (recentWinners[i] == from) {
                isRecentWinner = true;
                break;
            }
        }

        // Check if a recent winner is selling more than 1 token
        if (isRecentWinner && amount > noSellLimt) {
            if (!isStopSell[from] && isLpPair) {
                deactivateSellingOnDex();
            }
        }

        super._transfer(from, address(this), taxAmount);
        super._transfer(address(this), marketingAddress, marketingAmount);
        super._transfer(from, to, amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    /**
     * @dev Burns a specific amount of tokens from the caller's address.
     * @param amount The amount of tokens to burn.
     *
     * Requirements:
     * - The caller must have a sufficient balance of tokens to burn.
     *
     * Emits a {Transfer} event indicating the burning of tokens.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /**
     * @notice Returns a randomly selected eligible address from the list of wallet addresses.
     * @dev The eligibility criteria include having a balance greater than or equal to the minimumBalance multiplied by 10
     * and not being blacklisted for airdrop.
     * @return The randomly selected eligible address.
     */
    function getRandomEligibleAddress() internal returns (address) {
        uint256 eligibleCount = 0;
        address[] memory eligibleAddresses = new address[](
            _walletCount.current()
        );
        for (uint256 i = 0; i < _walletCount.current(); i++) {
            address account = walletAddresses[i];
            if (
                balanceOf(account) >= minimumBalance &&
                !airdropBlacklistedWallets[account]
            ) {
                eligibleAddresses[eligibleCount] = account;
                eligibleCount++;
            }
        }
        if (_skipCount.current() % 10 == 0) {
            minimumBalance = 5_000_000 * 10**decimals();
        }
        if (eligibleCount == 0) {
            _skipCount.increment();
            for (uint256 i = 0; i < walletAddresses.length; i++) {
                existingWallet[walletAddresses[i]] = false;
            }
            delete walletAddresses;
            _walletCount.reset();
            minimumBalance = 5_000_000 * 10**decimals();
            return address(0);
        }
        address[] memory validAddresses = new address[](eligibleCount);
        for (uint256 i = 0; i < _walletCount.current(); i++) {
            if (eligibleAddresses[i] != address(0)) {
                validAddresses[i] = eligibleAddresses[i];
            }
        }
        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        ) % eligibleCount;
        for (uint256 i = 0; i < walletAddresses.length; i++) {
            existingWallet[walletAddresses[i]] = false;
        }
        delete walletAddresses;
        _walletCount.reset();
        return validAddresses[randomIndex];
    }

    /**
     * @dev Verifies that the provided wallet address is not blacklisted as an exchange wallet.
     * @param wallet The wallet address to be checked.
     * @dev Reverts with "Exchange Wallet is blacklisted" if the wallet address is blacklisted.
     */
    function _notBlackListedExchange(address wallet) internal view {
        require(
            !blacklistedExchangeWallets[wallet],
            "Exchange Wallet is blacklisted"
        );
    }

    // The function to add a DEX address
    // function addDexAddress(address dexAddress) external onlyOwner {
    //     dexAddresses.push(dexAddress);
    // }

    // The function to deactivate selling on DEX

    function deactivateSellingOnDex() internal {
        // Deactivate selling on all DEX
        require(
            block.timestamp >=
                lastSellingDeactivationTimestamp + sellingDeactivationDuration,
            "Selling is already off"
        );
        for (uint256 i = 0; i < lpPairs.length; i++) {
            isSellingDeactivatedOnDex[lpPairs[i]] = true;
            sellingDeactivatedTimestamp[lpPairs[i]] = block.timestamp;
        }

        // Set the duration of selling deactivation
        // This is just a placeholder for a secure random number generation
        sellingDeactivationDuration =
            minSellingDeactivationDuration +
            (block.timestamp %
                (maxSellingDeactivationDuration -
                    minSellingDeactivationDuration));

        // Update the timestamp of the last automatic selling deactivation
        isStopSell[msg.sender] = true;
        lastSellingDeactivationTimestamp = block.timestamp;
    }

    // The function to reactivate selling on DEX
    function reactivateSellingOnDex() private {
        require(
            block.timestamp >=
                lastSellingDeactivationTimestamp + sellingDeactivationDuration,
            "Selling Duration not over yet"
        );
        // Reactivate selling on all DEX where the deactivation duration has passed
        for (uint256 i = 0; i < lpPairs.length; i++) {
            if (
                isSellingDeactivatedOnDex[lpPairs[i]] &&
                block.timestamp >
                sellingDeactivatedTimestamp[lpPairs[i]] +
                    sellingDeactivationDuration
            ) {
                isSellingDeactivatedOnDex[lpPairs[i]] = false;
            }
        }
    }

    function setDexAddress(address dexAddress, bool status) external onlyOwner {
        isDexAddress[dexAddress] = status;
    }

    /**
     * @notice Triggers an airdrop by transferring tokens from the contract's balance to a randomly selected eligible address.
     *
     * Effects:
     * - Requires the LotteryPool balance to be greater than or equal to the minimumBalance multiplied by 10.
     * - Generates a random eligible address from the eligible addresses list.
     * - Transfers the entire LotteryPool balance to the randomly selected eligible address.
     * - Sets the LotteryPool balance to zero.
     */

    function triggerLotteryAirdrop() internal {
        address winner = getRandomEligibleAddress();
        if (winner != address(0)) {
            // Add the new winner to the list of recent winners
            recentWinners.push(winner);

            // If there are more than 10 recent winners, remove the oldest one
            if (recentWinners.length > recentWinnersCount) {
                for (uint256 i = 0; i < recentWinners.length - 1; i++) {
                    recentWinners[i] = recentWinners[i + 1];
                }
                recentWinners.pop();
            }
            super._transfer(address(this), winner, LotteryPool);
            LotteryPool = 0;
            minimumBalance = 5_000_000 * 10**decimals();
            _skipCount.reset();
            emit Winner(winner);
        }
    }

    function setRecentWinnersCount(uint256 _newWinnersCount)
        external
        onlyOwner
    {
        recentWinnersCount = _newWinnersCount;
    }

    function setMinSellingDeactivationDuration(
        uint256 _newMinSellingDeactivationDuration
    ) external onlyOwner {
        minSellingDeactivationDuration = _newMinSellingDeactivationDuration;
    }

    function setMaxSellingDeactivationDuration(
        uint256 _newMaxSellingDeactivationDuration
    ) external onlyOwner {
        maxSellingDeactivationDuration = _newMaxSellingDeactivationDuration;
    }

    function setTransferTax(uint256 _newTransferTax) external onlyOwner {
        transferTax = _newTransferTax;
    }

    function setRequiredTxns(uint256 _newTxns) external onlyOwner {
        requiredTxns = _newTxns;
    }

    function setNoSellLimt(uint256 _noSellLimit) external onlyOwner {
        noSellLimt = _noSellLimit;
    }

    function setLpPair(address _lpPair) external onlyOwner {
        lpPairs.push(_lpPair);
    }

    function getLpPairs() external view returns (address[] memory) {
        return lpPairs;
    }

    function getRecentWinners() external view returns (address[] memory) {
        return recentWinners;
    }

    function setSocialRewardBeneficiary(address _socialRewardBeneficiary)
        external
        onlyOwner
    {
        socialRewardBeneficiary = _socialRewardBeneficiary;
    }

    function setMinimumBalance(uint256 _newMinBalance) external onlyOwner {
        minimumBalance = _newMinBalance * 10**decimals();
    }

    function setChosenTimestamp(uint256 _chosenTimestamp) external onlyOwner {
        chosenTimestamp = _chosenTimestamp;
    }
}