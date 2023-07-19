/**
 *Submitted for verification at Etherscan.io on 2023-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
* @dev Wrappers over Solidity's arithmetic operations.
*
* NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
* now has built in overflow checking.
*/
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
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
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
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
     * Counterpart to Solidity's `-` operator.
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
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
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
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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

// Interface of reward token Merces
interface Merces {
    // Function that transact amount Merces to receiver address from Merces contract address.
    // It is called only when prediction is made
    function getRewardFromSponsio(address reciever) external returns (bool);
    // Function that burn amount Merces from burner address. Needed to create new Events
    function burnFromSponsio(address burner, uint256 amount) external returns (bool);
    // Total Supply of Merces token. Needed for calculation of event price and reward amount 
    function totalSupply() external view returns (uint256);
    // Owner of Merces contract. Needed to pay for the Event creation
    function getOwner() external view returns (address);
}
// Structures that is used in Sponsio contract
contract Structures {
    // Structure to keep track of when each address made a prediction.
    struct Prediction{
        // Adress that made a prediction
        address predictionAddress;
        // Prediction Timestamp
        uint32 timestamp;
    }
    // The type of currency that the event creator will pay to create it
    enum createEventCurrency {
        Sponsio,
        Merces
    }
    // The type of prediction expected in the event prediction.
    // It is needed only in order to immediately clarify what is expected in the prediction when creating an event.
    // In fact, all predictions must be in Bytes32 format converted from a string.
    enum PredictionType {
        // Expected Integer as an answer e.g.
        // If correct answer for Event is 1 then prediction should be 
        // 0x3100000000000000000000000000000000000000000000000000000000000000
        // note that the prediction 
        // 0x1000000000000000000000000000000000000000000000000000000000000000
        // will be INCORRECT !!!
        IntegerExactMatch,
        // Expected any string that can be converted it Bytes32 format. 
        // Unless otherwise stated in the text of the event, the response must always be in LOWERCASE !!!
        // E.g. if correct answer for Event is 'correct answer' then prediction should be 
        // 0x636f727265637420616e73776572000000000000000000000000000000000000
        StringExactMatch,
        // Expected string that represents a date in the format yyyy.mm.dd. e.g.
        // If correct answer for Event is '2000.01.20' then prediction should be 
        // 0x323030302e30312e323000000000000000000000000000000000000000000000
        DateExactMatch,
        // Expected Unix Timestamp, an integer number representing the time as the number of seconds since January 1st, 1970 at 00:00:00 UTC.
        // If correct answer for Event is '948316800' (that is Wednesday, 19 January 2000 21:20:00) then prediction should be 
        // 0x3934383331363830300000000000000000000000000000000000000000000000
        DateTimeExactMatch
    }
    enum EventStatus {
        // No such event
        NotExists,
        // The Event is active and anyone can make predictions on it.
        // Status form Active can be changed only to Freezed and Finished
        Active,
        // The Event is freezed and nobody can make predictions on it
        // It can become Active again, Finished or Reverted
        Freezed,
        // Event is over but not finished yet. It means than noone can make predictions on it,
        // But results are still unknown. It can become only Finished or Reverted.
        OutOfTime,
        // The Event is finished and nobody can make predictions on it
        // Event prize is distributed and this status can never be changed
        Finished,
        // The Event is reverted and everyone who made a prediction on it can withdraw their prediction price on their wallet
        // Event prize will never be distributed and this status can never be changed
        Reverted
    }

    struct TimeSettings {
        // Timestamp when all predictions are done and Event is ended and become OutOfTime status.
        // If 0 the Event is timeless
        uint32 endTime;
        // Indicates whether Event can be restarted from OutOfTime status or not. 
        // If yes you can restart an event with another endTime value.
        uint8 canBeRestarted;
        // Time when the Event was last active. From this time depending on eventTimeToVotingClosing it is considered
        // Whether the prediction counts when determining the winners or not. 
        uint32 lastActiveTime;
    }
    struct RoyaltySetting {
        // Royalty for creator of the Event. Max is 15%, Min is 5%. 
        // Set by creator once when the event is created, cannot be changed
        uint8 royaltyForCreator;
        // Royalty for creator of the contract. Max is 5%, Min is 0%. 
        // Set by contract once when the event is created, cannot be changed
        uint8 royaltyForContract;
        // A flag that determines whether royalties will be charged from all participants in the event
        // Or only from those who make an incorrect prediction. 
        // In other words - whether to collect royalties from the winners of the event
        // If the flag is true, then royalties will be collected only after the end of the event !!!
        // If false, then immediately when the prediction is made
        uint8 royaltyOnlyLosers;
    }
    struct Event {
        // Event id - always unique
        uint32 eventId;
        // Event Text 
        bytes eventText;
        // Event Status
        EventStatus eventStatus;
        // It is a time interval before the voting closes, during which new predictions are not taken into account.
        // For example, if this interval is 24 hours and you want all predictions to be accepted no later than 6 hours before the real-world event occurs
        // You should freeze it after the real-world event occurs
        // wait until the current time minus 24 hours equals 6 hours before the event
        // and only then close the voting in the contract.
        uint32 eventTimeToVotingClosing;
        // Prediction Type
        PredictionType predictionType;
        // Price in Sponsio tokens for making prediction on this Event
        // cannot be changed
        uint256 predictionPrice;
        // Total prize pool to be shared after the Event ends
        // Updates every time someone makes a prediction
        uint256 prize;
        // Event creator address
        address creator;
        // Correct Answer. It is needed only for History. 
        // Before Event finished it is always 0x0000000000000000000000000000000000000000000000000000000000000000
        // Once the Event Finished, the value is set to the correct response and can never be changed again.
        bytes32 correctAnswer;
        // Event text language, needed to separate events of different language groups
        // Used only like filtering tag
        uint8 language;
        // royaltyForCreator, royaltyForContract and royaltyOnlyLosers Settings
        RoyaltySetting royaltySetting;
        // endTime and canBeRestarted Settings
        TimeSettings timeSettings; 
    }
}
abstract contract Depositable is ERC20, Ownable {
    function deposit() external payable {
        require(msg.value > 0, "Amount invalid");
        _mint(msg.sender, msg.value);
    }
    function withdraw() external {
        uint256 balanceSIO = balanceOf(msg.sender);
        require(balanceSIO > 0, "Zero balance");
        require(address(this).balance >= balanceSIO, "Insufficient contract balance");
        _burn(msg.sender, balanceSIO);
        (bool success,) = msg.sender.call{value: balanceSIO}("");
        require(success, "Failed");
    }
    // If somehow we got ETH with 0 supply of SIO we can withdraw this leftovers
    function withdrawLeftovers() external onlyOwner {
        require(totalSupply() == 0);
        uint256 leftOverEthBalance = address(this).balance;
        require(leftOverEthBalance > 0);
        (bool success,) = owner().call{value: leftOverEthBalance}("");
        require(success, "Failed");
    }
}
contract Sponsio is Depositable, Structures  {
    using SafeMath for uint256;
    using SafeMath for uint32;
    // Address of reward token contract Merces
    address public MercesAddress;
    // Instanse of reward token contract Merces
    Merces contractMercesInstance;

    // Merces address can be set only once
    function setMercesAddress(address _newMercesAddress) external onlyOwner {
        require(MercesAddress == address(0));
        MercesAddress = _newMercesAddress;
        contractMercesInstance = Merces(MercesAddress);
    }
    // Id of last event (or just total amount of Events)
    // Starts from 1
    uint32 public lastEventId;
    modifier EventExists(uint256 eventId) {
        require(eventId > 0 && eventId <= lastEventId, "Event invalid");
        _;
    }
    // All Events mapping EventId -> Event
    mapping(uint32 => Event) public allEvents;
    // Count of predictions for each event for each address
    // mapping EventId -> (mapping address -> prediction count)
    mapping(uint32 => mapping(address => uint16)) predictionsByAddressCounts;
    
    // All predictions for each event for each address
    // mapping EventId -> (mapping prediction in format Bytes32 -> [Address, Timestamp])
    mapping(uint32 => mapping(bytes32 => Prediction[])) public predictions;

    // Initial price of Event Creation in Sponsio tokens
    uint256 public eventPriceInSio = 1*10**decimals();
    // Initial price of Event Creation in Merces tokens
    uint256 public eventPriceInMerces = (1*10**6)*10**decimals();
    // Initial royalty for Contract creator
    uint8 private royaltyForContract = 5;
    // Total possible win all time
    // Increasing when prediction is made
    // Decreasing when Event is Reverted
    uint256 totalWinAllTime;
    // The maximum length of the event text, can be changed by the contract owner
    uint16 private maximumEventTextLength = 1000;

    /* 
        60*60*24*3
        The time interval before the Events ware last active in which all predictions are invalidated. 
        Cannot exceed maxVotingCloseTime interval and the minVotingCloseTime
        (except for time-limited events. In them, this interval is 0 by default)
    */
    uint32 private timeToVotingClosing = 259200;
    /*
        maxVotingCloseTime is needed so that it is not possible to cancel all event predictions
        60*60*24*20
    */
    uint32 private maxVotingCloseTime = 1728000;
    /*
        minVotingCloseTime is needed to take the time to close the event
        (except for time-limited events. In them, this interval is 0 by default)
        60*60
    */
    uint32 private minVotingCloseTime = 3600;

    constructor() ERC20("Sponsio", "SIO") {}

    receive() external payable {
        _mint(msg.sender, msg.value);
    }

    function createEvent(
        createEventCurrency _createEventCurrency,
        PredictionType _predictionType,
        uint8 _royaltyForCreator,
        uint256 _predictionPrice,
        string memory _eventText,
        uint8 _language,
        uint8 _royaltyOnlyLosers,
        uint32 _endTime,
        uint8 _canBeRestarted
    ) public {
        uint256 eventTextLength = bytes(_eventText).length;
        // Event text cannot be empty
        require(eventTextLength != 0, "Text invalid");
        // Event text cannot be too long
        require(eventTextLength <= maximumEventTextLength, "Text ivalid");
        // Event Prediction Type must be valid Prediction Type
        require(
            _predictionType == PredictionType.IntegerExactMatch || 
            _predictionType == PredictionType.StringExactMatch ||
            _predictionType == PredictionType.DateExactMatch ||
            _predictionType == PredictionType.DateTimeExactMatch,
            "Invalid Type"
        );
        // Event Prediction Price should be greateer then zero
        require(_predictionPrice > 0, "Price invalid");
        // If want to pay in Merces
        if (_createEventCurrency == createEventCurrency.Merces) {
            // If it is contract owner, then burn from Merces owner wallet
            if (msg.sender == owner()){
                require(
                    contractMercesInstance.burnFromSponsio(contractMercesInstance.getOwner(), eventPriceInMerces),
                    "Merces Pay Failed"
                );
            }
            else {
                require(
                    contractMercesInstance.burnFromSponsio(msg.sender, eventPriceInMerces),
                    "Merces Pay Failed"
                );
            }
            updateCostInMerces();
        }
        else {
            // For owner event creation in Sponsio tokens is free
            if (msg.sender != owner()){
                uint256 balance = balanceOf(msg.sender);
                require(balance >= eventPriceInSio, "Insufficient payment amount");
                require(transfer(owner(), eventPriceInSio), "Event creation failed");
            }
            updateeventPriceInSio();
        }
        Event memory eventum;
        // If eventId is overload then just start from 1
        // 65535 is a lot of events, so if 65535 Event will be created the 1 one will be already finished
        // And no need to store it
        lastEventId = lastEventId >= 4294967295 ? 1 : uint32(lastEventId+1);
        eventum.eventId = lastEventId;
        eventum.eventText = bytes(_eventText);
        eventum.predictionType = _predictionType;
        eventum.predictionPrice = _predictionPrice;
        eventum.creator = payable(msg.sender);

        RoyaltySetting memory _royaltySetting;
        // royaltyForCreator can`t be more then 15% !
        _royaltySetting.royaltyForCreator = _royaltyForCreator <= 15 ? _royaltyForCreator : 15;
        _royaltySetting.royaltyForContract = royaltyForContract;
        _royaltySetting.royaltyOnlyLosers = _royaltyOnlyLosers;
        eventum.royaltySetting = _royaltySetting;

        eventum.eventStatus = EventStatus.Active;
        // if _endTime == 0 so Event is endless
        eventum.eventTimeToVotingClosing = _endTime == 0 ? timeToVotingClosing : 0;
        eventum.language = _language;

        TimeSettings memory _timeSettings;
        _timeSettings.endTime = _endTime;
        _timeSettings.canBeRestarted = _canBeRestarted;
        eventum.timeSettings = _timeSettings;
        allEvents[lastEventId] = eventum;
    }
    // change language if it is accidently set wrong
    function changeEventLanguage(uint8 _language, uint32 eventId) external onlyOwner EventExists(eventId) {
        Event storage eventum = allEvents[eventId];
        eventum.language = _language;
    }
    // We can change eventTimeToVotingClosing of any Event to prevent predictions from people who knew the outcome in advance
    function changeEventTimeToVotingClosing(uint32 eventId, uint32 newTimeToVotingClosing) external onlyOwner EventExists(eventId) {
        require(newTimeToVotingClosing>=minVotingCloseTime || newTimeToVotingClosing<=maxVotingCloseTime);
        Event storage eventum = allEvents[eventId];
        require(eventum.eventStatus != EventStatus.NotExists);
        eventum.eventTimeToVotingClosing = newTimeToVotingClosing;
    }
    /*
        We can finish Event by providing the correct answer
        It can be done only once. We can Finish only Active, Freezed and OutOfTime Events.
        Once Event is Finished all rewards are distributed and Event is no more available to be changed
    */
    function finishEventSuccess(uint32 eventId, bytes32 eventResult) external onlyOwner EventExists(eventId) {
        Event storage eventum = allEvents[eventId];
        require(
            eventum.eventStatus == EventStatus.Active ||
            eventum.eventStatus == EventStatus.Freezed ||
            eventum.eventStatus == EventStatus.OutOfTime
        );
        if (eventum.eventStatus == EventStatus.Active){
            eventum.timeSettings.lastActiveTime = uint32(block.timestamp);
        }
        // Distribute rewards here
        require(sponsioPoenalis(eventum, eventResult));
        eventum.eventStatus = EventStatus.Finished;
    }
    // Restart Event that is out of time and can be restarted
    function restartEndedEvent(uint32 _endTime, uint32 eventId) external onlyOwner EventExists(eventId) {
        Event storage eventum = allEvents[eventId];
        require(eventum.eventStatus == EventStatus.OutOfTime && eventum.timeSettings.canBeRestarted > 0);
        eventum.timeSettings.endTime = _endTime;
    }
    // Freeze, Unfreeze or Revert event
    function changeEventStatus(EventStatus newStatus, uint32 eventId) external onlyOwner EventExists(eventId) returns (bool){
        require(
            newStatus == EventStatus.Active ||
            newStatus == EventStatus.Freezed ||
            newStatus == EventStatus.Reverted
        );
        Event storage eventum = allEvents[eventId];
        require(
            (
                eventum.eventStatus == EventStatus.Active &&
                newStatus != EventStatus.Reverted
            ) ||
            eventum.eventStatus == EventStatus.Freezed ||
            (
                eventum.eventStatus == EventStatus.OutOfTime &&
                newStatus == EventStatus.Reverted
            )
        );
        if (newStatus == EventStatus.Reverted) {
            totalWinAllTime = totalWinAllTime.sub(eventum.prize);
        }
        else {
            if (eventum.timeSettings.endTime > 0 && uint32(block.timestamp) > eventum.timeSettings.endTime){
                eventum.timeSettings.lastActiveTime = eventum.timeSettings.endTime;
                eventum.eventStatus = EventStatus.OutOfTime;
                return false;
            }
        }
        
        eventum.timeSettings.lastActiveTime = uint32(block.timestamp);
        eventum.eventStatus = EventStatus(newStatus);
        return true;
    }
    // Withdraw all money from reverted event
    function withdrawFromReverted(uint32 eventId) external EventExists(eventId) {
        Event storage eventum = allEvents[eventId];
        require(eventum.eventStatus == EventStatus.Reverted, "Event invalid");
        uint256 votesCount = predictionsByAddressCounts[eventId][msg.sender];
        require(votesCount > 0, "Nothing to withdraw");
        uint256 predictionPriceDiv100 = eventum.predictionPrice.div(100);
        uint256 amountToWithdraw = votesCount * (
            eventum.royaltySetting.royaltyOnlyLosers > 0 ? eventum.predictionPrice : (
                eventum.predictionPrice.sub(
                    predictionPriceDiv100.mul(
                        eventum.royaltySetting.royaltyForContract+eventum.royaltySetting.royaltyForCreator
                    )
                )
            )
            
        );
        predictionsByAddressCounts[eventId][msg.sender] = 0;
        _burn(address(this), amountToWithdraw);
        (bool success,) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Transfer failed");
    }
    // Deposit and make a prediction at the same time
    function depositAndMakePrediction(uint32 eventId, bytes32 predictionString) external payable {
        require(msg.value > 0, "Amount invalid");
        _mint(msg.sender, msg.value);
        require(makePrediction(eventId, predictionString));
    }
    // Make prediction for Event. Pay in SIO, rewards in MRCS
    function makePrediction(uint32 eventId, bytes32 predictionString) public EventExists(eventId) returns (bool) {
        Event storage eventum = allEvents[eventId];
        require(eventum.eventStatus == EventStatus.Active, "Event invalid");
        // Check if we need to End event because time ended
        if (eventum.timeSettings.endTime > 0 && uint32(block.timestamp) > eventum.timeSettings.endTime){
            eventum.timeSettings.lastActiveTime = eventum.timeSettings.endTime;
            eventum.eventStatus = EventStatus.OutOfTime;
            return false;
        }
        require(balanceOf(msg.sender) >= eventum.predictionPrice, "Insufficient payment amount");
        uint256 finalPredictCost;
        // Trying to pay royalties
        if (eventum.royaltySetting.royaltyOnlyLosers == 0){
            uint256 predictionPriceDiv100 = eventum.predictionPrice.div(100);
            require(transfer(eventum.creator, predictionPriceDiv100.mul(eventum.royaltySetting.royaltyForCreator)), "Failed to pay");
            require(transfer(owner(), predictionPriceDiv100.mul(eventum.royaltySetting.royaltyForContract)), "Failed to pay");
            finalPredictCost = predictionPriceDiv100.mul(100 - eventum.royaltySetting.royaltyForContract - eventum.royaltySetting.royaltyForCreator);
        }
        else{
            finalPredictCost = eventum.predictionPrice;
        }
        // Pay for prediction first
        require(transfer(address(this), finalPredictCost), "Failed to pay");
        Prediction memory prediction;
        prediction.predictionAddress = msg.sender;
        prediction.timestamp = uint32(block.timestamp);
        predictions[eventId][predictionString].push(prediction);
        predictionsByAddressCounts[eventId][msg.sender] += 1;
        eventum.prize = eventum.prize.add(finalPredictCost);
        totalWinAllTime = totalWinAllTime.add(finalPredictCost);
        contractMercesInstance.getRewardFromSponsio(msg.sender);
        return true;
    }
    // Distribute rewards from prize pool
    function sponsioPoenalis(Event storage currentEvent, bytes32 eventResult) private onlyOwner returns (bool)
    {
        Prediction[] memory preWinners = predictions[currentEvent.eventId][eventResult];
        address[] memory winners = new address[](preWinners.length);
        uint64 j = 0;
        for (uint64 i=0; i<preWinners.length; i++)
        {
            if (currentEvent.timeSettings.lastActiveTime.sub(preWinners[i].timestamp) > currentEvent.eventTimeToVotingClosing){
                winners[j] = preWinners[i].predictionAddress;
                j++;
            }
        }
        if (j > 0) {
            uint256 dividedPrize;
            // If only losers need to pay roalties then we need to pay royalties first
            if (currentEvent.royaltySetting.royaltyOnlyLosers > 0) {
                uint256 losersPrizePart = (currentEvent.prize-j*currentEvent.predictionPrice).div(100);
                uint256 royaltyLosersContract = losersPrizePart.mul(currentEvent.royaltySetting.royaltyForContract);
                uint256 royaltyLosersCreator = losersPrizePart.mul(currentEvent.royaltySetting.royaltyForCreator);
                dividedPrize = (currentEvent.prize-royaltyLosersCreator-royaltyLosersContract).div(j);
                _transfer(address(this), owner(), royaltyLosersContract);
                _transfer(address(this), currentEvent.creator, royaltyLosersCreator);
                totalWinAllTime = totalWinAllTime-royaltyLosersContract-royaltyLosersCreator;
            }
            else {
                dividedPrize = currentEvent.prize.div(j);
            }
            for (uint64 i=0; i<j; i++){
                _transfer(address(this), winners[i], dividedPrize);
            }
        }
        else {
            _transfer(address(this), owner(), currentEvent.prize);
        }
        currentEvent.eventStatus = EventStatus.Finished;
        currentEvent.correctAnswer = eventResult;
        return true;
    }
    /*
        Assuming that creator gets always 15% of royalty we aim to 50% of profit for creator
        Royalty Percent = 15 / 100
        (Total Win) / (Events Count) * (Royalty Percent) = Average Earn for Creator
        Now we devide Average Earn for Creator on 1.5 for make a 50% profit for creator. 
        Because of Royalty Percent it is equal as just devide by 10.
        To stabilize grow or fall of creation price we relay on previous price to make an average price.
    */
    function updateeventPriceInSio() private {
        eventPriceInSio = totalWinAllTime.div(lastEventId>0?lastEventId:1).div(10).add(eventPriceInSio).div(2);
    }
    /*
        Price in Merces is always 1% of Total Supply.
    */
    function updateCostInMerces() private {
        eventPriceInMerces = contractMercesInstance.totalSupply().div(100);
    }
    function updateMaximumEventTextLength(uint16 newMaximumEventTextLength) external onlyOwner{
        require(newMaximumEventTextLength>0);
        maximumEventTextLength = newMaximumEventTextLength;
    }
    function updateRoyaltyForContract(uint8 newRoyaltyForContract) external onlyOwner{
        // newRoyaltyForContract can`t be more then 5%
        require(newRoyaltyForContract==0 || newRoyaltyForContract<=5);
        royaltyForContract = newRoyaltyForContract;
    }
    // Update timeToVotingClosing it will influence only for future Events
    function updateTimeToVotingClosing(uint32 newTimeToVotingClosing) external onlyOwner {
        require(
            newTimeToVotingClosing>=minVotingCloseTime || newTimeToVotingClosing<=maxVotingCloseTime
        );
        timeToVotingClosing = newTimeToVotingClosing;
    }
}