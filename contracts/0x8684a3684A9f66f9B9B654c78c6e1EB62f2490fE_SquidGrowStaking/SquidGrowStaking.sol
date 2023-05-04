/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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

library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


contract SquidGrowStaking is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 pendingReward;     // pending reward
        uint256 nftStaked;      // number of NFT staked
        uint256 lastRewardBlock; // last block when reward was claimed.
    }

    // Info of each pool. This contract has several reward method. First method is one that has reward per block and Second method has fixed apr.
    struct PoolInfo {
        IERC20 stakedToken;           // Address of staked token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Squidgrows to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Squidgrows distribution occurs.
        uint256 accSquidgrowPerShare;   // Accumulated Squidgrows per share, times 1e13. See below.
        uint256 totalStaked;
    }

    struct StakedNft {
        address staker;
        uint256 tokenId;
        address collection;
    }

    // NFT Staker info
    struct NftStaker {
        // Amount of tokens staked by the staker
        uint256 amountStaked;

        // Staked token ids
        StakedNft[] stakedNfts;        
    }

    struct Checkpoint {
        uint256 blockNumber;                    // blocknumber for checkpoint
        uint256 accSquidgrowPerSquidgrow;
        bool isToggleCheckpoint;                // true -> nftBoostToggle checkpoint ; false -> nft whitelist checkpoint
        bool state;                             // true -> boost enabled / collection whitelisted  ; false -> boost disabled, collection unwhitelisted
        address collection;                     // address of collection whitelisted.
    }

    // The Squidgrow TOKEN!
    IERC20 public Squidgrow;
    address private feeAddress;
    uint256 public squidStakingPoolId = 0;

    // Squidgrow tokens created per block.
    uint256 public SquidgrowPerBlock;

    // Toggle reward harvesting without withdrawing all the staked tokens.
    bool public isHarvestingEnabled = true;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;


    // whitelist info for fee
    mapping(address => bool) public isWhiteListed;

    // blacklist info for reward
    mapping(address => bool) public isBlackListed;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // Max fee rate: 10%.
    uint16 public constant MAXIMUM_FEE_RATE = 1000;

    // whitlisted NFTs for staking
    mapping(address => bool) public isNftWhitelisted;

    address [] public whitelistedNFTs;

    Checkpoint [] public checkpoints;


    // owner of staked NFTs (collection => tokenId => owner)
    mapping(address => mapping (uint256 => address)) public vault;

    // info of staked NFT ( user => NftStaker)
    mapping(address  => NftStaker) public stakedNfts;

    // // count of nft staked (staker => collection => count)
    mapping(address => mapping(address => uint256)) public nftStaked;

    // On/Off Nft staking
    bool public nftBoostEnabled = true;

    // Boost reward % on staking NFTs
    uint256 public boostAPRPerNft = 200; // 20%
    // The block number when SQUID mining starts.
    uint256 immutable public startBlock;

    uint256 depositTax = 200;
    uint256 withdrawTax = 200;
    uint256 harvestTax = 600;

    event PoolAdded(uint256 indexed poolId, address indexed stakedToken, uint256 allocPoint, uint256 totalAllocPoint);
    event PoolUpdated(uint256 indexed poolId, uint256 allocPoint, uint256 totalAllocPoint);
    event WhitelistedNFT(address indexed nftCollection);
    event UnwhitelistedNFT(address indexed nftCollection);
    event Deposited(address indexed user, uint256 indexed poolId, uint256 amount);
    event Harvested(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed poolId, uint256 amount);
    event DepositedNFTs(address indexed user, address indexed nftCollection, uint256 amount);
    event WithdrawnNFTs(address indexed user, address indexed nftCollection, uint256 amount);
    event WithdrawnAllNFTs(address indexed user, uint256 amount);
    event EmergencyWithdrawn(address indexed user, uint256 indexed poolId);
    event UpdatedEmissionRate(uint256 oldEmissionRate, uint256 newEmissionRate);
    event Whitelisted(address indexed user);
    event Unwhitelisted(address indexed user);
    event Blacklisted(address indexed user);
    event Unblacklisted(address indexed user);
    event NftBoostingEnabled(uint256 accSquidgrowPerSquidgrow);
    event NftBoostingDisabled(uint256 accSquidgrowPerSquidgrow);
    event BoostAPRPerNftUpdated(uint256 oldBoostAPR, uint256 newBoostAPR);
    event StakingTaxUpdated(uint256 withdrawTax, uint256 depositTax, uint256 harvestTax);
    event FeeAddressUpdated(address oldFeeAddress, address newFeeAddress);
    event UnsupportedTokenRecovered(address indexed receiver, address indexed token, uint256 amount);
    event HarvestingEnabled();
    event HarvestingDisabled();
    event UpdatedSquidgrowAddress(address squidgrow);

    constructor(
        IERC20 _squidgrow,
        address _feeAddress,
        uint256 _squidPerBlock,
        uint256 _startBlock
    ) {
        require(address(_squidgrow) != address(0), "Can't be zero address");
        Squidgrow = _squidgrow;
        feeAddress = _feeAddress;
        SquidgrowPerBlock = _squidPerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            stakedToken: _squidgrow,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accSquidgrowPerShare: 0,
            totalStaked: 0

        }));

        totalAllocPoint = 1000;

        emit PoolAdded(0, address(_squidgrow), 1000, totalAllocPoint);
    }

    // Add a new token to the pool. Can only be called by the owner.
    // XXX DO NOT add the same token more than once. Rewards will be messed up if you do.
    function add(IERC20 _stakedToken, uint256 _allocPoint, bool _withUpdate) external onlyOwner {
        require(address(_stakedToken) != address(0), "Can't be zero address");
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 length = poolInfo.length;
        for (uint256 i = 0 ; i < length; i++) {
            require(poolInfo[i].stakedToken != _stakedToken, "Pool Already added");
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            stakedToken: _stakedToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accSquidgrowPerShare: 0,
            totalStaked: 0
        }));

        emit PoolAdded(poolInfo.length - 1, address(_stakedToken), _allocPoint, totalAllocPoint);
    }

    // Update the given pool's Squidgrow allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint - prevAllocPoint + _allocPoint;
        }

        emit PoolUpdated(_pid, _allocPoint, totalAllocPoint);
    }

    // Whitelist NFT colletion for staking (to boost SQUID pool reward)
    function whitelistNFT(address nftCollection) external onlyOwner {
        require(nftCollection != address(0), "Can't be zero address");
        require(!isNftWhitelisted[nftCollection], "Already whitlisted");
        isNftWhitelisted[nftCollection] = true;
        whitelistedNFTs.push(nftCollection);
        updatePool(squidStakingPoolId);
        Checkpoint memory newcheckpoint = Checkpoint (block.number, poolInfo[squidStakingPoolId].accSquidgrowPerShare, false, true, nftCollection);
        checkpoints.push(newcheckpoint);

        emit WhitelistedNFT(nftCollection);
    }

    function removeWhitelistNFT(address nftCollection) external onlyOwner {
        require(nftCollection != address(0), "Can't be zero address");
        require(isNftWhitelisted[nftCollection], "Already non - whitlisted");
        isNftWhitelisted[nftCollection] = false;
        uint256 length = whitelistedNFTs.length;
        for(uint256 i =0; i< length; i++) {
            if (whitelistedNFTs[i] == nftCollection) {
                whitelistedNFTs[i] = whitelistedNFTs[length - 1];
                break;
            }
        }
        whitelistedNFTs.pop();
        updatePool(squidStakingPoolId);
        Checkpoint memory newcheckpoint = Checkpoint (block.number, poolInfo[squidStakingPoolId].accSquidgrowPerShare, false, false, nftCollection);
        checkpoints.push(newcheckpoint);

        emit UnwhitelistedNFT(nftCollection);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to - _from;
    }

    // View function to see pending Squidgrows on frontend.
    function pendingSquidgrow(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];

        
        uint256 accSquidgrowPerShare = pool.accSquidgrowPerShare;
        if (block.number > pool.lastRewardBlock && pool.totalStaked != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 SquidgrowReward = (multiplier * SquidgrowPerBlock * pool.allocPoint) / totalAllocPoint;
            accSquidgrowPerShare = accSquidgrowPerShare.add(SquidgrowReward.mul(1e13).div(pool.totalStaked));
        }
        uint256 equivalentAmount = getBoostEquivalentAmount(_user, _pid);
        uint256 pending = 0;

        if ( checkpoints.length!= 0 && user.lastRewardBlock <= checkpoints[checkpoints.length - 1].blockNumber && _pid == 0 && stakedNfts[msg.sender].amountStaked != 0) {

            uint256 index = checkpoints.length ;
            pending = equivalentAmount.mul(accSquidgrowPerShare).div(1e13).sub(equivalentAmount.mul(checkpoints[index -1].accSquidgrowPerSquidgrow).div(1e13));
            uint256 nftCount = _getWhitelistedNft(_user);
            uint256 boostedAmount = getBoostedAmount(user.amount, nftCount);
            bool boostEnable = nftBoostEnabled;
            for (uint256 i = index; i >= 1 ; --i) {
                if(user.lastRewardBlock > checkpoints[i-1].blockNumber)
                    break;
                
                if(checkpoints[i-1].isToggleCheckpoint) {
                    boostEnable = !boostEnable;
                    if(boostEnable) {
                        pending += boostedAmount.mul(checkpoints[i-1].accSquidgrowPerSquidgrow).div(1e13).sub(i == 1 || user.lastRewardBlock > checkpoints[i-2].blockNumber ? user.rewardDebt: boostedAmount.mul(checkpoints[i - 2].accSquidgrowPerSquidgrow).div(1e13));
                    } else {
                        pending += user.amount.mul(checkpoints[i-1].accSquidgrowPerSquidgrow).div(1e13).sub( i == 1 || user.lastRewardBlock > checkpoints[i-2].blockNumber ?user.rewardDebt : user.amount.mul(checkpoints[i - 2].accSquidgrowPerSquidgrow).div(1e13));
                    }
                    
                }else {
                    uint256 amount = nftStaked[_user][checkpoints[i-1].collection];
                    if(amount != 0) {
                        nftCount = checkpoints[i-1].state ? nftCount - amount : nftCount + amount;
                        boostedAmount = getBoostedAmount(user.amount, nftCount);
                    }
                    if(boostEnable) {
                        pending += boostedAmount.mul(checkpoints[i-1].accSquidgrowPerSquidgrow).div(1e13).sub(i == 1 || user.lastRewardBlock > checkpoints[i-2].blockNumber ? user.rewardDebt: boostedAmount.mul(checkpoints[i - 2].accSquidgrowPerSquidgrow).div(1e13));
                    } else {
                        pending += user.amount.mul(checkpoints[i-1].accSquidgrowPerSquidgrow).div(1e13).sub( i == 1 || user.lastRewardBlock > checkpoints[i-2].blockNumber ?user.rewardDebt : user.amount.mul(checkpoints[i - 2].accSquidgrowPerSquidgrow).div(1e13));
                    }

                }
            }
        }else {
            pending = equivalentAmount.mul(accSquidgrowPerShare).div(1e13).sub(user.rewardDebt);
        }
        return pending + user.pendingReward;

    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.totalStaked == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 accSquidgrowPerShare = pool.accSquidgrowPerShare;
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 SquidgrowReward = multiplier.mul(SquidgrowPerBlock).mul(pool.allocPoint).div(totalAllocPoint);


        pool.accSquidgrowPerShare = accSquidgrowPerShare.add(SquidgrowReward.mul(1e13).div(pool.totalStaked));
        pool.lastRewardBlock = block.number;

    }

    // Deposit LP tokens to MasterChef for Squidgrow allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(!isBlackListed[msg.sender], "user is blacklisted");
        require(_amount > 0 , "zero amount");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 equivalentAmount = getBoostEquivalentAmount(msg.sender, _pid);
        uint256 pending = 0;

        if ( checkpoints.length!= 0 && user.lastRewardBlock <= checkpoints[checkpoints.length - 1].blockNumber && _pid == 0 && stakedNfts[msg.sender].amountStaked != 0) {
            pending = getPendingreward(pool, msg.sender, user);
        } else {
            pending = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13).sub(user.rewardDebt);
        }
        user.pendingReward += isHarvestingEnabled ? 0 : pending;

        if(pending > 0 && isHarvestingEnabled){
            if (!isWhiteListed[msg.sender]) {
                uint256 harvestFee = pending.mul(harvestTax).div(10000);
                pending = pending - harvestFee;
                if(harvestFee > 0)
                    safeSquidgrowTransfer(feeAddress, harvestFee);
            }

            safeSquidgrowTransfer(msg.sender, pending);
        }   

        uint256 depositFee = 0;

        if (!isWhiteListed[msg.sender]) {
            depositFee = _amount.mul(depositTax).div(10000);
            if (depositFee > 0)
                pool.stakedToken.safeTransferFrom(msg.sender, feeAddress, depositFee);
        }
                
        uint256 balancebefore = pool.stakedToken.balanceOf(address(this));

        pool.stakedToken.safeTransferFrom(msg.sender, address(this), _amount - depositFee );
        // staked Tokens, might have transfer tax.
        uint256 amountReceived = pool.stakedToken.balanceOf(address(this)).sub(balancebefore);
        user.amount = user.amount.add(amountReceived);
        pool.totalStaked = pool.totalStaked.add(amountReceived);
            
        
        equivalentAmount =  getBoostEquivalentAmount(msg.sender, _pid);
        user.rewardDebt = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13);
        user.lastRewardBlock = block.number;

        emit Deposited(msg.sender, _pid, amountReceived);
    }

    function getBoostEquivalentAmount(address _account, uint256 _pid) public view returns (uint256) {
        UserInfo memory user = userInfo[_pid][_account];
        uint256 equivalentAmount = user.amount;

        if (_pid == squidStakingPoolId && nftBoostEnabled) { // NFT boost only for Squid staking pool (pid = 0)
            uint256 nftCount = _getWhitelistedNft(_account);
            equivalentAmount = getBoostedAmount(user.amount, nftCount);
        }
        return equivalentAmount;
    }

    // Harvest Reward
    function harvest(uint256 _pid) public nonReentrant {
        require(isHarvestingEnabled, "reward harvesting is not enabled, need to withdraw token to harvest reward!");
        require(!isBlackListed[msg.sender], "user is blacklisted");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "harvest: not good");
        updatePool((_pid));
        
        uint256 equivalentAmount = getBoostEquivalentAmount(msg.sender, _pid);

        uint256 pending = 0;
        
        if ( checkpoints.length!= 0 && user.lastRewardBlock <= checkpoints[checkpoints.length - 1].blockNumber && _pid == 0 && stakedNfts[msg.sender].amountStaked != 0) {
            pending = getPendingreward(pool, msg.sender, user);
        } else {
            pending = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13).sub(user.rewardDebt);
        }

        pending += user.pendingReward;
        user.pendingReward = 0;
        if(pending > 0){
            if (!isWhiteListed[msg.sender]) {
                uint256 harvestFee = pending.mul(harvestTax).div(10000);
                pending = pending - harvestFee;
                if(harvestFee > 0)
                    safeSquidgrowTransfer(feeAddress, harvestFee);
            }
                
            safeSquidgrowTransfer(msg.sender, pending);
        }

        equivalentAmount = getBoostEquivalentAmount(msg.sender, _pid);
        user.rewardDebt = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13);
        user.lastRewardBlock = block.number;

        emit Harvested(msg.sender, _pid, pending);
    }

    function getPendingreward(PoolInfo memory pool, address account, UserInfo memory user) internal view returns(uint256){
        uint256 index = checkpoints.length ;
        uint256 equivalentAmount = getBoostEquivalentAmount( account, 0);
        uint256 pending = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13).sub(equivalentAmount.mul(checkpoints[index -1].accSquidgrowPerSquidgrow).div(1e13));
        uint256 nftCount = _getWhitelistedNft(account);
        uint256 boostedAmount = getBoostedAmount(user.amount, nftCount);
        bool boostEnable = nftBoostEnabled;
        for (uint256 i = index; i >= 1 ; --i) {
            if(user.lastRewardBlock > checkpoints[i-1].blockNumber)
                break;
            
            if(checkpoints[i-1].isToggleCheckpoint) {
                boostEnable = !boostEnable;
                if(boostEnable) {
                    pending += boostedAmount.mul(checkpoints[i-1].accSquidgrowPerSquidgrow).div(1e13).sub(i == 1 || user.lastRewardBlock > checkpoints[i-2].blockNumber ? user.rewardDebt: boostedAmount.mul(checkpoints[i - 2].accSquidgrowPerSquidgrow).div(1e13));
                } else {
                    pending += user.amount.mul(checkpoints[i-1].accSquidgrowPerSquidgrow).div(1e13).sub( i == 1 || user.lastRewardBlock > checkpoints[i-2].blockNumber ?user.rewardDebt : user.amount.mul(checkpoints[i - 2].accSquidgrowPerSquidgrow).div(1e13));
                }
                
                
            }else {
                uint256 amount = nftStaked[account][checkpoints[i-1].collection];
                if(amount != 0) {
                    nftCount = checkpoints[i-1].state ? nftCount - amount : nftCount + amount;
                    boostedAmount = getBoostedAmount(user.amount, nftCount);
                }
                if(boostEnable) {
                    pending += boostedAmount.mul(checkpoints[i-1].accSquidgrowPerSquidgrow).div(1e13).sub(i == 1 || user.lastRewardBlock > checkpoints[i-2].blockNumber ? user.rewardDebt: boostedAmount.mul(checkpoints[i - 2].accSquidgrowPerSquidgrow).div(1e13));
                } else {
                    pending += user.amount.mul(checkpoints[i-1].accSquidgrowPerSquidgrow).div(1e13).sub( i == 1 || user.lastRewardBlock > checkpoints[i-2].blockNumber ?user.rewardDebt : user.amount.mul(checkpoints[i - 2].accSquidgrowPerSquidgrow).div(1e13));
                }

            }


        }
        return pending;

    }

    function getBoostedAmount(uint256 amount, uint256 nftCount) public view returns (uint256) {
        // multiplying nftCount by 10^8 and dividing the result by sqrt(10^8) = 10^4 for precision
        return amount + (amount * Math.sqrt(nftCount * 100_000_000) * boostAPRPerNft) / (1000 * 10_000);
    }

    // Withdraw LP tokens from Staking.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
       
        uint256 equivalentAmount = getBoostEquivalentAmount(msg.sender, _pid);

        uint256 pending = 0;
        
        if ( checkpoints.length!= 0 && user.lastRewardBlock <= checkpoints[checkpoints.length - 1].blockNumber && _pid == squidStakingPoolId && stakedNfts[msg.sender].amountStaked != 0) {
            pending = getPendingreward(pool, msg.sender, user);
        } else {
            pending = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13).sub(user.rewardDebt);
        }      
        user.pendingReward += isHarvestingEnabled ? 0 : pending; 
        uint256 withdrawFee = 0;
        if(pending > 0 && isHarvestingEnabled){
            if (!isWhiteListed[msg.sender]) {
                uint256 harvestFee = pending.mul(harvestTax).div(10000);
                pending = pending - harvestFee;
                if(harvestFee > 0)
                    safeSquidgrowTransfer(feeAddress, harvestFee);
            }
            if(!isBlackListed[msg.sender]) {
                safeSquidgrowTransfer(msg.sender, pending);
            }
        }

        if (!isWhiteListed[msg.sender]) {
            withdrawFee = (_amount * withdrawTax) / 10000;
            if(withdrawFee > 0)
                pool.stakedToken.safeTransfer(feeAddress, withdrawFee);
        }


        pool.stakedToken.safeTransfer(msg.sender, _amount - withdrawFee);
        pool.totalStaked=pool.totalStaked.sub(_amount);
        user.amount = user.amount.sub(_amount);

        equivalentAmount = getBoostEquivalentAmount(msg.sender, _pid);

        user.rewardDebt = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13);
        user.lastRewardBlock = block.number;

        if(user.amount == 0) {
            pending  = user.pendingReward;
            if(pending> 0 && !isHarvestingEnabled) {
                if (!isWhiteListed[msg.sender]) {
                    uint256 harvestFee = pending.mul(harvestTax).div(10000);
                    pending = pending - harvestFee;
                    if(harvestFee > 0)
                        safeSquidgrowTransfer(feeAddress, harvestFee);
                }
                if(!isBlackListed[msg.sender]) {
                    safeSquidgrowTransfer(msg.sender, pending);
                }
            }

            if( _pid == squidStakingPoolId && stakedNfts[msg.sender].amountStaked != 0)  {
                _withdrawAllNft(msg.sender);
            }
        }
        

        emit Withdrawn(msg.sender, _pid, _amount);
    }

    // Deposit NFT token to Staking
    function depositNft(address _collection, uint256[] calldata _tokenIds) public nonReentrant {
        require(!isBlackListed[msg.sender], "user is blacklisted");
        require(nftBoostEnabled, "NFT staking is turned off.");
        require(isNftWhitelisted[_collection], "Collection not whitelisted");
        updatePool(squidStakingPoolId);

        PoolInfo storage pool = poolInfo[squidStakingPoolId]; // pool id = 0 --> Squid staking pool
        UserInfo storage user = userInfo[squidStakingPoolId][msg.sender];
        require(user.amount > 0, "You should stake squid to deposit NFT.");
        uint256 equivalentAmount = getBoostEquivalentAmount(msg.sender, squidStakingPoolId);

       uint256 pending = 0;
        
        if ( checkpoints.length!= 0 && user.lastRewardBlock <= checkpoints[checkpoints.length - 1].blockNumber && stakedNfts[msg.sender].amountStaked != 0) {
            pending = getPendingreward(pool, msg.sender, user);
        } else {
            pending = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13).sub(user.rewardDebt);
        }
        user.pendingReward += isHarvestingEnabled ? 0 : pending; 
        if(pending > 0 && isHarvestingEnabled){
            if (!isWhiteListed[msg.sender]) {
                uint256 harvestFee = pending.mul(harvestTax).div(10000);
                pending = pending - harvestFee;
                if(harvestFee > 0)
                    safeSquidgrowTransfer(feeAddress, harvestFee);
            }
            safeSquidgrowTransfer(msg.sender, pending);
        }

        uint256 stakeAmount = _tokenIds.length;
        for (uint256 i = 0; i < stakeAmount; i++) {
            require(IERC721(_collection).ownerOf(_tokenIds[i]) == msg.sender, "Sender not owner");
            IERC721(_collection).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            vault[_collection][_tokenIds[i]] = msg.sender;
    
            StakedNft memory stakedNft = StakedNft(msg.sender, _tokenIds[i], _collection);
            stakedNfts[msg.sender].stakedNfts.push(stakedNft);
        }
        stakedNfts[msg.sender].amountStaked += stakeAmount;
        nftStaked[msg.sender][_collection] += stakeAmount;

        equivalentAmount = getBoostEquivalentAmount(msg.sender, squidStakingPoolId);
        user.rewardDebt = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13);
        user.lastRewardBlock = block.number;

        emit DepositedNFTs(msg.sender, _collection, _tokenIds.length);
    }

    // Withdraw Nft Token from staking
    function withdrawNft(address _collection, uint256[] calldata _tokenIds) public nonReentrant {
        require(
            stakedNfts[msg.sender].amountStaked > 0,
            "You have no NFT staked"
        );
        updatePool(squidStakingPoolId);
        PoolInfo storage pool = poolInfo[squidStakingPoolId]; // pool id = 0 --> Squid staking pool
        UserInfo storage user = userInfo[squidStakingPoolId][msg.sender];
        uint256 equivalentAmount = getBoostEquivalentAmount(msg.sender, squidStakingPoolId);

        uint256 pending = 0;
        
        if ( checkpoints.length!= 0 && user.lastRewardBlock <= checkpoints[checkpoints.length - 1].blockNumber && stakedNfts[msg.sender].amountStaked != 0) {
            pending = getPendingreward(pool, msg.sender, user);
        } else {
            pending = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13).sub(user.rewardDebt);
        }
        user.pendingReward += isHarvestingEnabled ? 0 : pending; 

        if(pending > 0 && isHarvestingEnabled){
            if (!isWhiteListed[msg.sender]) {
                uint256 harvestFee = pending.mul(harvestTax).div(10000);
                pending = pending - harvestFee;
                if(harvestFee > 0)
                    safeSquidgrowTransfer(feeAddress, harvestFee);
            }

            if (!isBlackListed[msg.sender]) {
                safeSquidgrowTransfer(msg.sender, pending);
            }
        }
        uint256 unstakeAmount = _tokenIds.length;
        for (uint256 i = 0; i < unstakeAmount; i++) {
            require(vault[_collection][_tokenIds[i]] == msg.sender, "You don't own this token!");

            // Find the index of this token id in the stakedTokens array
            uint256 index = 0;
            for (uint256 j = 0; i < stakedNfts[msg.sender].stakedNfts.length; j++) {
                if (
                    stakedNfts[msg.sender].stakedNfts[j].collection == _collection
                    &&
                    stakedNfts[msg.sender].stakedNfts[j].tokenId == _tokenIds[i] 
                    && 
                    stakedNfts[msg.sender].stakedNfts[j].staker != address(0)
                ) {
                    index = j;
                    break;
                }
            }
            stakedNfts[msg.sender].stakedNfts[index].staker = address(0);

            vault[_collection][_tokenIds[i]] = address(0);
            IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
        }
        stakedNfts[msg.sender].amountStaked -= unstakeAmount;
        nftStaked[msg.sender][_collection] -= unstakeAmount;

        equivalentAmount = getBoostEquivalentAmount(msg.sender, squidStakingPoolId);
        user.rewardDebt = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13);
        user.lastRewardBlock = block.number;

        emit WithdrawnNFTs(msg.sender, _collection, _tokenIds.length);

    }

    function withdrawAllNft() external nonReentrant{
        require(
            stakedNfts[msg.sender].amountStaked > 0,
            "You have no NFT staked"
        );
        _withdrawAllNft(msg.sender);
    }

    function _withdrawAllNft(address account) internal {
        
        updatePool(squidStakingPoolId);
        
        PoolInfo storage pool = poolInfo[squidStakingPoolId]; // pool id = 0 --> Squid staking pool
        UserInfo storage user = userInfo[squidStakingPoolId][account];
        uint256 equivalentAmount = getBoostEquivalentAmount(account, squidStakingPoolId);

        uint256 pending = 0;
        
        if ( checkpoints.length!= 0 && user.lastRewardBlock <= checkpoints[checkpoints.length - 1].blockNumber && stakedNfts[msg.sender].amountStaked != 0) {
            pending = getPendingreward(pool, msg.sender, user);
        } else {
            pending = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13).sub(user.rewardDebt);
        }
        user.pendingReward += isHarvestingEnabled ? 0 : pending; 

        if(pending > 0 && isHarvestingEnabled){
            if (!isWhiteListed[account]) {
                uint256 harvestFee = pending.mul(harvestTax).div(10000);
                pending = pending - harvestFee;
                if(harvestFee > 0)
                    safeSquidgrowTransfer(feeAddress, harvestFee);
            }

            if (!isBlackListed[account]) {
                safeSquidgrowTransfer(account, pending);
            }
        }

        emit WithdrawnAllNFTs(account, stakedNfts[msg.sender].amountStaked);
        stakedNfts[account].amountStaked = 0;

        for (uint256 i = 0; i < stakedNfts[account].stakedNfts.length; i++) {
            if (stakedNfts[account].stakedNfts[i].staker != address(0)) {
                stakedNfts[account].stakedNfts[i].staker = address(0);
                
                vault[stakedNfts[account].stakedNfts[i].collection][stakedNfts[account].stakedNfts[i].tokenId] = address(0);
                nftStaked[account][stakedNfts[account].stakedNfts[i].collection] = 0;
                IERC721(stakedNfts[account].stakedNfts[i].collection).safeTransferFrom(address(this), account,stakedNfts[account].stakedNfts[i].tokenId);
            }
        }
            

        equivalentAmount = getBoostEquivalentAmount(account, squidStakingPoolId);
        user.rewardDebt = equivalentAmount.mul(pool.accSquidgrowPerShare).div(1e13);
        user.lastRewardBlock = block.number;

    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.totalStaked = pool.totalStaked.sub(amount);
        
        uint256 withdrawFee = 0;
        if (!isWhiteListed[msg.sender]) {
            withdrawFee = (amount * withdrawTax) / 10000;
            if(withdrawFee > 0)
                pool.stakedToken.safeTransfer(feeAddress, withdrawFee);
        }
        pool.stakedToken.safeTransfer(msg.sender, amount - withdrawFee);

        if(_pid == squidStakingPoolId && stakedNfts[msg.sender].amountStaked != 0) {
            _withdrawAllNft(msg.sender);
        }

       emit EmergencyWithdrawn(msg.sender, _pid);
    }

    // Safe Squidgrow transfer function, just in case if rounding error causes pool to not have enough FOXs.
    function safeSquidgrowTransfer(address _to, uint256 _amount) internal {
        uint256 SquidgrowBal = Squidgrow.balanceOf(address(this));
        PoolInfo storage pool = poolInfo[squidStakingPoolId];
        uint256 rewardBalance = SquidgrowBal - pool.totalStaked;
        bool transferSuccess = false;
        if (_amount > rewardBalance) {
            transferSuccess = Squidgrow.transfer(_to, rewardBalance);
        } else {
            transferSuccess = Squidgrow.transfer(_to, _amount);
        }
        require(transferSuccess, "safeSquidgrowTransfer: Transfer failed");
    }

    function updateSquidStakingPoolId(uint256 _newId) external onlyOwner {
        squidStakingPoolId = _newId;
    }

    function changeSquidgrowAddress(address _squidgrow, bool _withUpdate) external onlyOwner {
        require(_squidgrow != address(0), "Can't be zero address");
        Squidgrow = IERC20(_squidgrow);
        if (_withUpdate) {
            massUpdatePools();
        }
        emit UpdatedSquidgrowAddress(_squidgrow);
    }

    // Recover unsupported tokens that are sent accidently.
    function recoverUnsupportedToken(address _addr, uint256 _amount) external onlyOwner {
        require(_addr != address(0), "non-zero address");
        uint256 totalDeposit = 0;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (poolInfo[pid].stakedToken == IERC20(_addr)) {
                totalDeposit = poolInfo[pid].totalStaked;
                break;
            }
        }
        uint256 balance = IERC20(_addr).balanceOf(address(this));
        uint256 amt = balance.sub(totalDeposit);
        if (_amount > 0 && _amount <= amt) {
            IERC20(_addr).safeTransfer(msg.sender, _amount);
        }

        emit UnsupportedTokenRecovered(msg.sender, _addr, _amount);
    }

    // set fee address
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0),"non-zero");
        emit FeeAddressUpdated(feeAddress, _feeAddress);
        feeAddress = _feeAddress;
    }

    // update reward per block
    function updateEmissionRate(uint256 _SquidgrowPerBlock) external onlyOwner {
        massUpdatePools();
        emit UpdatedEmissionRate(SquidgrowPerBlock, _SquidgrowPerBlock);
        SquidgrowPerBlock = _SquidgrowPerBlock;
    }

    // add peoples to whitelist for deposit fee
    function whiteList(address[] memory _addresses) external onlyOwner {
        uint256 count = _addresses.length;
        for (uint256 i =0 ; i< count; i++) {
            isWhiteListed[_addresses[i]] = true;
            emit Whitelisted(_addresses[i]);
        }
    }

    // remove peoples from whitelist for deposit fee
    function removeWhiteList(address[] memory _addresses) external onlyOwner {
        uint256 count = _addresses.length;
        for (uint256 i =0 ; i< count; i++) {
            isWhiteListed[_addresses[i]] = false;
            emit Unwhitelisted(_addresses[i]);
        }
    }


    // add peoples to blacklist for reward
    function blackList(address[] memory _addresses) external onlyOwner {
        uint256 count = _addresses.length;
        for (uint256 i =0 ; i< count; i++) {
            isBlackListed[_addresses[i]] = true;
            emit Blacklisted(_addresses[i]);
        }
    }

    // remove peoples from blacklist
    function removeBlackList(address[] memory _addresses) external onlyOwner {
        uint256 count = _addresses.length;
        for (uint256 i =0 ; i< count; i++) {
            isBlackListed[_addresses[i]] = false;
            emit Unblacklisted(_addresses[i]);
        }
    }

    function enableRewardHarvesting() external onlyOwner {
        require(!isHarvestingEnabled, "already enabled");
        isHarvestingEnabled = true;
        emit HarvestingEnabled();
    }

    function disableRewardHarvesting() external onlyOwner {
        require(isHarvestingEnabled, "already disabled");
        isHarvestingEnabled = false;
        emit HarvestingDisabled();
    }

    // get pool length
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Turn on Nft staking
    function turnOnNftStaking() external onlyOwner {
        require(!nftBoostEnabled, "already enable");
        nftBoostEnabled = true;
        updatePool(squidStakingPoolId);
        Checkpoint memory newcheckpoint = Checkpoint (block.number, poolInfo[squidStakingPoolId].accSquidgrowPerShare, true, true, address(0));
        checkpoints.push(newcheckpoint);

        emit NftBoostingEnabled(poolInfo[squidStakingPoolId].accSquidgrowPerShare);
    }

    // Turn off Nft staking
    function turnOffNftStaking() external onlyOwner {
        require(nftBoostEnabled, "already disable");
        nftBoostEnabled = false;
        updatePool(squidStakingPoolId);
        Checkpoint memory newcheckpoint = Checkpoint (block.number, poolInfo[squidStakingPoolId].accSquidgrowPerShare, true, false, address(0));
        checkpoints.push(newcheckpoint);

        emit NftBoostingDisabled(poolInfo[squidStakingPoolId].accSquidgrowPerShare);
    }
    
    function updateBoostAPRPerNft(uint256 _newBoostAPRPerNft) external onlyOwner {
        require(_newBoostAPRPerNft > 0 , "should be greater than zero");

        emit BoostAPRPerNftUpdated(boostAPRPerNft, _newBoostAPRPerNft);

        boostAPRPerNft = _newBoostAPRPerNft;
    }
    
    function setStakingTax(uint256 _newWithdrawTax, uint256 _newDepositTax, uint256 _newHarvestTax) external onlyOwner {
        require(_newWithdrawTax +  _newDepositTax + _newHarvestTax <= MAXIMUM_FEE_RATE, "Tax mustn't be greater than 10%");
        withdrawTax = _newWithdrawTax;
        depositTax = _newDepositTax;
        harvestTax = _newHarvestTax;

        emit StakingTaxUpdated(_newWithdrawTax, _newDepositTax, _newHarvestTax);
    }

    function getStakedNfts(address _user) public view returns (uint256[] memory, address[] memory) {
        // Check if we know this user
        if (stakedNfts[_user].amountStaked > 0) {
            // Return all the tokens in the stakedToken Array for this user that are not -1
            uint256[] memory _stakedNfts = new uint256[](stakedNfts[_user].amountStaked);
            address[] memory _collection = new address[](stakedNfts[_user].amountStaked);
            uint256 _index = 0;

            for (uint256 j = 0; j < stakedNfts[_user].stakedNfts.length; j++) {
                if (stakedNfts[_user].stakedNfts[j].staker != (address(0))) {
                    _stakedNfts[_index] = stakedNfts[_user].stakedNfts[j].tokenId;
                    _collection[_index] = stakedNfts[_user].stakedNfts[j].collection;
                    _index++;
                }
            }

            return (_stakedNfts, _collection);
        }
        
        // Otherwise, return empty array
        else {
            return (new uint256[](0), new address[](0));
        }
    }

    function _getWhitelistedNft(address user) internal view returns(uint256) {
        uint256 count = whitelistedNFTs.length;
        uint256 nftCount = 0;
        for (uint256 i = 0 ; i< count ; i++) {
            nftCount += nftStaked[user][whitelistedNFTs[i]];
        }
        return nftCount;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
}