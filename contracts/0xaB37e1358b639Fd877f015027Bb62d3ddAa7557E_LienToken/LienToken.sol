/**
 *Submitted for verification at Etherscan.io on 2020-08-11
*/

// File: @openzeppelin/contracts/math/Math.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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

            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.transferFrom.selector,
                from,
                to,
                value
            )
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(
            address(token).isContract(),
            "SafeERC20: call to non-contract"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    constructor() internal {}

    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
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
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        override
        view
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(
            recipient != address(0),
            "ERC20: transfer to the zero address"
        );

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/ERC20Vestable.sol

pragma solidity 0.6.5;

/**
 * @notice Vestable ERC20 Token.
 * One beneficiary can have multiple grants.
 * Grants for one beneficiary are identified by unique ids from 1.
 * When some tokens are deposited to a grant, the tokens are transferred from the depositor to the beneficiary.
 * Tokens deposited to a grant become gradually spendable along with the elapsed time.
 * One grant has its unique start time and end time.
 * The vesting of the grant is directly proportionally to the elapsed time since the start time.
 * At the end time, all the tokens of the grant is finally vested.
 * When the beneficiary claims the vested tokens, the tokens become spendable.
 * You can additionally deposit tokens to the already started grants to increase the amount vested.
 * In such a case, some part of the tokens immediately become vested proportionally to the elapsed time since the start time.
 */
abstract contract ERC20Vestable is ERC20 {
    using SafeMath for uint256;

    struct Grant {
        uint256 amount; // total of deposited tokens to the grant
        uint256 claimed; // total of claimed vesting of the grant
        uint128 startTime; // the time when the grant starts
        uint128 endTime; // the time when the grant ends
    }

    // account => Grant[]
    mapping(address => Grant[]) private grants;

    // account => amount
    mapping(address => uint256) private remainingGrants;

    /**
     * @notice Sum of not yet claimed grants.
     * It includes already vested but not claimed grants.
     */
    uint256 public totalRemainingGrants;

    event CreateGrant(
        address indexed beneficiary,
        uint256 indexed id,
        address indexed creator,
        uint256 endTime
    );
    event DepositToGrant(
        address indexed beneficiary,
        uint256 indexed id,
        address indexed depositor,
        uint256 amount
    );
    event ClaimVestedTokens(address beneficiary, uint256 id, uint256 amount);

    modifier spendable(address account, uint256 amount) {
        require(
            balanceOf(account).sub(remainingGrants[account]) >= amount,
            "transfer amount exceeds spendable balance"
        );
        _;
    }

    /**
     * @notice Creates new grant and starts it.
     * @param beneficiary recipient of vested tokens of the grant.
     * @param endTime Time at which all the tokens of the grant will be vested.
     * @return id of the grant.
     */
    function createGrant(address beneficiary, uint256 endTime)
        public
        returns (uint256)
    {
        require(endTime > now, "endTime is before now");
        Grant memory g = Grant(0, 0, uint128(now), uint128(endTime));
        address creator = msg.sender;
        grants[beneficiary].push(g);
        uint256 id = grants[beneficiary].length;
        emit CreateGrant(beneficiary, id, creator, endTime);
        return id;
    }

    /**
     * @notice Deposits tokens to grant.
     * @param beneficiary recipient of vested tokens of the grant.
     * @param id id of the grant.
     * @param amount amount of tokens.
     */
    function depositToGrant(
        address beneficiary,
        uint256 id,
        uint256 amount
    ) public {
        Grant storage g = _getGrant(beneficiary, id);
        address depositor = msg.sender;
        _transfer(depositor, beneficiary, amount);
        g.amount = g.amount.add(amount);
        remainingGrants[beneficiary] = remainingGrants[beneficiary].add(
            amount
        );
        totalRemainingGrants = totalRemainingGrants.add(amount);
        emit DepositToGrant(beneficiary, id, depositor, amount);
    }

    /**
     * @notice Claims spendable vested tokens of the grant which are vested after the last claiming.
     * @param beneficiary recipient of vested tokens of the grant.
     * @param id id of the grant.
     */
    function claimVestedTokens(address beneficiary, uint256 id) public {
        Grant storage g = _getGrant(beneficiary, id);
        uint256 amount = _vestedAmount(g);
        require(amount != 0, "vested amount is zero");
        uint256 newClaimed = g.claimed.add(amount);
        g.claimed = newClaimed;
        remainingGrants[beneficiary] = remainingGrants[beneficiary].sub(
            amount
        );
        totalRemainingGrants = totalRemainingGrants.sub(amount);
        if (newClaimed == g.amount) {
            _deleteGrant(beneficiary, id);
        }
        emit ClaimVestedTokens(beneficiary, id, amount);
    }

    /**
     * @notice Returns the last id of grant of `beneficiary`.
     * If `beneficiary` does not have any grant, returns `0`.
     */
    function getLastGrantID(address beneficiary)
        public
        view
        returns (uint256)
    {
        return grants[beneficiary].length;
    }

    /**
     * @notice Returns information of grant
     * @param beneficiary recipient of vested tokens of the grant.
     * @param id id of the grant.
     * @return amount is the total of deposited tokens
     * @return claimed is the total of already claimed spendable tokens.
     * @return  vested is the amount of vested and not claimed tokens.
     * @return startTime is the start time of grant.
     * @return  endTime is the end time time of grant.
     */
    function getGrant(address beneficiary, uint256 id)
        public
        view
        returns (
            uint256 amount,
            uint256 claimed,
            uint256 vested,
            uint256 startTime,
            uint256 endTime
        )
    {
        Grant memory g = _getGrant(beneficiary, id);
        amount = g.amount;
        claimed = g.claimed;
        vested = _vestedAmount(g);
        startTime = g.startTime;
        endTime = g.endTime;
    }

    /**
     * @notice Returns sum of not yet claimed tokens of `account`
     * It includes already vested but not claimed grants.
     */
    function remainingGrantOf(address account) public view returns (uint256) {
        return remainingGrants[account];
    }

    /**
     * @dev When `amount` exceeds spendable balance, it reverts.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override spendable(from, amount) {
        super._transfer(from, to, amount);
    }

    function _deleteGrant(address beneficiary, uint256 id) private {
        delete grants[beneficiary][id - 1];
    }

    function _getGrant(address beneficiary, uint256 id)
        private
        view
        returns (Grant storage)
    {
        require(id != 0, "0 is invalid as id");
        id = id - 1;
        require(id < grants[beneficiary].length, "grant does not exist");
        Grant storage g = grants[beneficiary][id];
        // check if the grant is deleted
        require(
            g.endTime != 0,
            "cannot get grant which is already claimed entirely"
        );
        return g;
    }

    /**
     * @dev Returns tokens that were vested after the last claiming.
     */
    function _vestedAmount(Grant memory g) private view returns (uint256) {
        uint256 n = now;
        if (g.endTime > n) {
            uint256 elapsed = n - g.startTime;
            uint256 duration = g.endTime - g.startTime;
            return g.amount.mul(elapsed).div(duration).sub(g.claimed);
        }
        return g.amount.sub(g.claimed);
    }
}

// File: @openzeppelin/contracts/utils/Arrays.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element)
        internal
        view
        returns (uint256)
    {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId)
        public
        view
        returns (uint256)
    {
        (bool snapshotted, uint256 value) = _valueAt(
            snapshotId,
            _accountBalanceSnapshots[account]
        );

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(
            snapshotId,
            _totalSupplySnapshots
        );

        return snapshotted ? value : totalSupply();
    }

    // _transfer, _mint and _burn are the only functions where the balances are modified, so it is there that the
    // snapshots are updated. Note that the update happens _before_ the balance change, with the pre-modified value.
    // The same is true for the total supply and _mint and _burn.
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);

        super._transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal virtual override {
        _updateAccountSnapshot(account);
        _updateTotalSupplySnapshot();

        super._mint(account, value);
    }

    function _burn(address account, uint256 value) internal virtual override {
        _updateAccountSnapshot(account);
        _updateTotalSupplySnapshot();

        super._burn(account, value);
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private
        view
        returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(
            snapshotId <= _currentSnapshotId.current(),
            "ERC20Snapshot: nonexistent id"
        );

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue)
        private
    {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids)
        private
        view
        returns (uint256)
    {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// File: contracts/ERC20RegularlyRecord.sol

pragma solidity 0.6.5;

/**
 * @dev This contract extends an ERC20Snapshot token, which extends ERC20 and has a snapshot mechanism.
 * When a snapshot is created, the balances and the total supply (state) at the time are recorded for later accesses.
 *
 * This contract records states at regular intervals.
 * When the first transferring, minting, or burning on the term occurring, snapshot is taken to record the state at the end of the previous term.
 * If no action occurs on the next term of one term, state at the end of the term is not snapshotted, but the state is same as the one at the end of next term of it.
 * So, in that case, accessing to the state at the end of the term is internally solved by referencing to the snapshot taken after it has ended.
 * If no action occurs after one term, state at the end of the term is same as the current state and Accessing to the state is solved by referencing the current state.
 */
abstract contract ERC20RegularlyRecord is ERC20Snapshot {
    using SafeMath for uint256;

    /**
     * @dev Interval of records in seconds.
     */
    uint256 public immutable interval;

    /**
     * @dev Starting Time of the first term.
     */
    uint256 public immutable initialTime;

    // term => snapshotId
    mapping(uint256 => uint256) private snapshotsOfTermEnd;

    modifier termValidation(uint256 _term) {
        require(_term != 0, "0 is invalid value as term");
        _;
    }

    /**
     * @param _interval Interval of records in seconds.
     * The first term starts when this contract is constructed.
     */
    constructor(uint256 _interval) public {
        interval = _interval;
        initialTime = now;
    }

    /**
     * @notice Returns term of `time`.
     * The first term is 1, After one interval, the term becomes 2.
     * Term of time T is calculated by the following formula
     * (T - initialTime)/interval + 1
     */
    function termOfTime(uint256 time) public view returns (uint256) {
        return time.sub(initialTime, "time is invalid").div(interval).add(1);
    }

    /**
     * @notice Returns the current term.
     */
    function currentTerm() public view returns (uint256) {
        return termOfTime(now);
    }

    /**
     * @notice Returns when `term` starts.
     * @param term > 0
     */
    function startOfTerm(uint256 term)
        public
        view
        termValidation(term)
        returns (uint256)
    {
        return initialTime.add(term.sub(1).mul(interval));
    }

    /**
     * @notice Returns when `term` ends.
     * @param term > 0
     */
    function endOfTerm(uint256 term)
        public
        view
        termValidation(term)
        returns (uint256)
    {
        return initialTime.add(term.mul(interval)).sub(1);
    }

    /**
     * @notice Retrieves the balance of `account` at the end of the `term`
     */
    function balanceOfAtTermEnd(address account, uint256 term)
        public
        view
        termValidation(term)
        returns (uint256)
    {
        uint256 _currentTerm = currentTerm();
        for (uint256 i = term; i < _currentTerm; i++) {
            if (_isSnapshottedOnTermEnd(i)) {
                return balanceOfAt(account, snapshotsOfTermEnd[i]);
            }
        }
        return balanceOf(account);
    }

    /**
     * @notice Retrieves the total supply at the end of the `term`
     */
    function totalSupplyAtTermEnd(uint256 term)
        public
        view
        termValidation(term)
        returns (uint256)
    {
        uint256 _currentTerm = currentTerm();
        for (uint256 i = term; i < _currentTerm; i++) {
            if (_isSnapshottedOnTermEnd(i)) {
                return totalSupplyAt(snapshotsOfTermEnd[i]);
            }
        }
        return totalSupply();
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        _snapshotOnTermEnd();
        super._transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal virtual override {
        _snapshotOnTermEnd();
        super._mint(account, value);
    }

    function _burn(address account, uint256 value) internal virtual override {
        _snapshotOnTermEnd();
        super._burn(account, value);
    }

    /**
     * @dev Takes a snapshot before the first transferring, minting or burning on the term.
     * If snapshot is not taken after the last term ended, take a snapshot to record states at the end of the last term.
     */
    function _snapshotOnTermEnd() private {
        uint256 _currentTerm = currentTerm();
        if (_currentTerm > 1 && !_isSnapshottedOnTermEnd(_currentTerm - 1)) {
            snapshotsOfTermEnd[_currentTerm - 1] = _snapshot();
        }
    }

    /**
     * @dev Returns `true` if snapshot was already taken to record states at the end of the `term`.
     * If it's not, snapshotOfTermEnd[`term`] is 0 as the default value.
     */
    function _isSnapshottedOnTermEnd(uint256 term)
        private
        view
        returns (bool)
    {
        return snapshotsOfTermEnd[term] != 0;
    }
}

// File: contracts/LienToken.sol

pragma solidity 0.6.5;

/**
 * @notice ERC20 Token with dividend mechanism.
 * It accepts ether and ERC20 tokens as assets for profit, and distributes them to the token holders pro rata to their shares.
 * Total profit and dividends of each holders are settled regularly at the pre specified interval.
 * Even after moving tokens, the holders keep the right to receive already settled dividends because this contract records states(the balances of accounts and the total supply of token) at the moment of settlement.
 * There is a pre specified length of period for right to receive dividends.
 * When the period expires, unreceived dividends are carried over to a new term and distributed to the holders on the new term.
 * It also have token vesting mechanism.
 * The beneficiary of the grant cannot transfer the granted token before vested, but can earn dividends for the granted tokens.
 */
contract LienToken is ERC20RegularlyRecord, ERC20Vestable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public constant ETH_ADDRESS = address(0);

    // Profit and paid balances of a certain asset.
    struct Balances {
        uint256 profit;
        uint256 paid;
    }

    // Expiration term number for the right to receive dividends.
    uint256 public immutable expiration;

    // account address => token => term
    mapping(address => mapping(address => uint256)) public lastTokenReceived;

    // term => token => balances
    mapping(uint256 => mapping(address => Balances)) private balancesMap;

    event SettleProfit(
        address indexed token,
        uint256 indexed term,
        uint256 amount
    );
    event ReceiveDividend(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @param _interval Length of a term in second
     * @param _expiration Number of term for expiration
     * @param totalSupply Total supply of this token
     **/
    constructor(
        uint256 _interval,
        uint256 _expiration,
        uint256 totalSupply
    ) public ERC20RegularlyRecord(_interval) ERC20("lien", "LIEN") {
        _setupDecimals(8);
        ERC20._mint(msg.sender, totalSupply);
        expiration = _expiration;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @notice Recognizes the unsettled profit in the form of token occurred in the current term.
     * Carried over dividends are also counted.
     */
    function settleProfit(address token) external {
        uint256 amount = unsettledProfit(token);
        uint256 currentTerm = currentTerm();
        Balances storage b = balancesMap[currentTerm][token];
        uint256 newProfit = b.profit.add(amount);
        b.profit = newProfit;
        emit SettleProfit(token, currentTerm, newProfit);
    }

    /**
     * @notice Receives all the valid dividends in the form of token.
     * @param recipient recipient of dividends.
     */
    function receiveDividend(address token, address recipient) external {
        uint256 i;
        uint256 total;
        uint256 divAt;
        uint256 currentTerm = currentTerm();
        for (
            i = Math.max(
                _oldestValidTerm(),
                lastTokenReceived[recipient][token]
            );
            i < currentTerm;
            i++
        ) {
            divAt = dividendAt(token, recipient, i);
            balancesMap[i][token].paid = balancesMap[i][token].paid.add(divAt);
            total = total.add(divAt);
        }
        lastTokenReceived[recipient][token] = i;
        emit ReceiveDividend(token, recipient, total);
        if (token == ETH_ADDRESS) {
            (bool success, ) = recipient.call{value: total}("");
            require(success, "transfer failed");
        } else {
            IERC20(token).safeTransfer(recipient, total);
        }
    }

    /**
     * @notice Returns settled profit in the form of `token` on `term`.
     */
    function profitAt(address token, uint256 term)
        public
        view
        returns (uint256)
    {
        return balancesMap[term][token].profit;
    }

    /**
     * @notice Returns the balance of already-paid dividends in `token` on `term`.
     */
    function paidAt(address token, uint256 term)
        public
        view
        returns (uint256)
    {
        return balancesMap[term][token].paid;
    }

    /**
     * @notice Returns the balance of dividends in `token` on `term` to `account`.
     */
    function dividendAt(
        address token,
        address account,
        uint256 term
    ) public view returns (uint256) {
        return
            _dividend(
                profitAt(token, term),
                balanceOfAtTermEnd(account, term),
                totalSupply()
            );
    }

    /**
     * @notice Returns the balance of unrecognized profit in `token`.
     * It includes carried over dividends.
     */
    function unsettledProfit(address token) public view returns (uint256) {
        uint256 remain;
        uint256 tokenBalance;
        uint256 currentTerm = currentTerm();
        for (uint256 i = _oldestValidTerm(); i <= currentTerm; i++) {
            Balances memory b = balancesMap[i][token];
            uint256 remainAt = b.profit.sub(b.paid);
            remain = remain.add(remainAt);
        }
        if (token == ETH_ADDRESS) {
            tokenBalance = address(this).balance;
        } else {
            tokenBalance = IERC20(token).balanceOf(address(this));
        }
        return tokenBalance.sub(remain);
    }

    /**
     * @notice Returns the balance of valid dividends in `token`.
     * @param recipient recipient of dividend.
     */
    function unreceivedDividend(address token, address recipient)
        external
        view
        returns (uint256)
    {
        uint256 i;
        uint256 total;
        uint256 divAt;
        uint256 currentTerm = currentTerm();
        for (
            i = Math.max(
                _oldestValidTerm(),
                lastTokenReceived[recipient][token]
            );
            i < currentTerm;
            i++
        ) {
            divAt = dividendAt(token, recipient, i);
            total = total.add(divAt);
        }
        return total;
    }

    /**
     * @dev It Overrides ERCVestable and ERC20RegularlyRecord.
     * To record states regularly, it calls `transfer` of ERC20RegularlyRecord.
     * To restrict value to be less than max spendable balance, it uses `spendable` modifier of ERC20Vestable.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    )
        internal
        virtual
        override(ERC20Vestable, ERC20RegularlyRecord)
        spendable(from, value)
    {
        ERC20RegularlyRecord._transfer(from, to, value);
    }

    /**
     * @dev It overrides ERC20Vestable and ERC20RegularlyRecord.
     * Both of these base class define `_burn`, so this contract must override `_burn` expressly.
     */
    function _burn(address account, uint256 value)
        internal
        virtual
        override(ERC20, ERC20RegularlyRecord)
    {
        ERC20RegularlyRecord._burn(account, value);
    }

    /**
     * @dev It overrides ERC20Vestable and ERC20RegularlyRecord.
     * Both of these base class define `_mint`, so this contract must override `_mint` expressly.
     */
    function _mint(address account, uint256 value)
        internal
        virtual
        override(ERC20, ERC20RegularlyRecord)
    {
        ERC20RegularlyRecord._mint(account, value);
    }

    function _oldestValidTerm() private view returns (uint256) {
        uint256 currentTerm = currentTerm();
        if (currentTerm <= expiration) {
            return 1;
        }
        return currentTerm.sub(expiration);
    }

    /**
     * @dev Returns the value of dividend pro rata share of token.
     * dividend = profit * balance / totalSupply
     */
    function _dividend(
        uint256 profit,
        uint256 balance,
        uint256 totalSupply
    ) private pure returns (uint256) {
        return profit.mul(balance).div(totalSupply);
    }
}