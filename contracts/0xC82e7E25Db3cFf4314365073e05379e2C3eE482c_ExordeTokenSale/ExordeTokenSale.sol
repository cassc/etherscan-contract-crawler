/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/token-distribution/ExordeTokenSale.sol


pragma solidity 0.8.8;







    /* 
    * ________________ Token Sale Setup __________________
        The EXD Token Sale is a 3-Tiered Dollar-based Token Sale
    *      Tier 1 = $0.33/EXD for the first 0.5 million (500 000) EXD tokens sold, then
    *      Tier 2 = $0.34/EXD for next 1.5 million (1 500 000) EXD tokens sold, then
    *      Tier 3 = $0.35/EXD for the last 10 million (10 000 000) EXD tokens sold.
    *   Total EXD sold (to be deposited in contract initially) = 12 000 000 EXD tokens. Twelve millions.
    * ________________ Requirements of the sale: __________________
    *      A. All buyers must be whitelisted by Exorde Labs, according to their KYC verification done on exorde.network
    *      B. All buyers are limited to $50k ($50 000), 
    *          fifty thousand dollars of purchase, overall (they can buy multiple times).
    *      C. A tier ends when all tokens have been sold. 
    *      D. If tokens remain unsold after the sale, 
    *          the owner of the contract can withdraw the remaining tokens.
    *      E. Buyers get the EXD token instantly when buying.
    * ________________ Contract Administration __________________
    *      A. When paused/ended, the owner can withdraw any ERC20 tokens from the contract
    *      B. The owner can pause the contract in case of emergency
    *      C. The end time can be extended at will by the owner
    */

contract ExordeTokenSale is Context, ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event AddressWhitelisted(address indexed user);
    event AddressDeWhitelisted(address indexed user);

    // The EXD ERC20 token being sold
    // Predeployed & deposited in this contract after deployment
    IERC20 private _token; 

    IERC20 public USDC;
    IERC20 public USDT;
    IERC20 public DAI;

    uint256 public constant USDC_decimal_count = 6;
    uint256 public constant USDT_decimal_count = 6;
    uint256 public constant DAI_decimal_count = 18;

    uint256 private constant THOUSAND = 10**3;
    uint256 private constant MILLION = 10**6;
    uint256 private constant EXD_DECIMAL_COUNT = 10**18;
    
    // price per tier, in dollar (divided by 1000)
    uint256 public _priceBase = 1000*(10**12);
    uint256 public _priceTier1 = 330; // $0.33
    uint256 public _priceTier2 = 340; // $0.34
    uint256 public _priceTier3 = 350; // $0.35

   // You can only buy up to 12M tokens
    uint256 public maxTokensRaised       =    12 * MILLION  * EXD_DECIMAL_COUNT;            // 12 millions EXD (12 000 000 EXD) maximum to sell

   // tiers supply threshold (cumulative): tier 2 threshold is tier 1 supply + tier 2 supply
    uint256 public _tier1SupplyThreshold =   500 * THOUSAND * EXD_DECIMAL_COUNT;            // first 500k EXD (500 000 EXD)
    uint256 public _tier2SupplyThreshold =     2 * MILLION  * EXD_DECIMAL_COUNT;            // then 1.5m EXD (1 500 000 EXD) + previous tokens
    uint256 public _tier3SupplyThreshold =    12 * MILLION  * EXD_DECIMAL_COUNT;            // last threshold is amount to the max Tokens Raised

   // An individual is capped to $50k
    uint256 public userMaxTotalPurchase = 50 * THOUSAND * (10**6); // 50000 dollars ($50k) in USDC 6 decimals base

    uint256 public startTime;
    uint256 public endTime;
    uint256 private immutable OneWeekDuration = 60*60*24*7; //in seconds, 1 week = 60*60*24*7 = 604800

    // Amount of dollar raised
    uint256 public _dollarRaised;
    
    // Users state
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public _usersTotalPurchase;

    // Amount of token sold
    uint256 public totalTokensRaised;

    // Address where funds are collected
    address payable private _wallet = payable(0xd2Ec33d098C207CeC8774db5D5373274Fd3e914f); //gnosis safe 
    // EXORDE LABS MILTISIG SAFE: https://app.safe.global/eth:0xd2Ec33d098C207CeC8774db5D5373274Fd3e914f/settings/setup

    // Address where funds are collected
    address public whitelister_wallet;

    /*
    * @dev Constructor setting up the sale
    * @param startTime_ (timestamp) date of start of the token sale
    * @param endTime_ (timestamp) date of end of the token sale (can be extended)
    */
    constructor (uint256 startTime_, uint256 endTime_, address initial_whitelister_wallet_,
    IERC20 token_, IERC20 USDC_, IERC20 USDT_, IERC20 DAI_) {
        require(address(token_) != address(0), "Crowdsale: token is the zero address");
        require(address(initial_whitelister_wallet_) != address(0), "initial_whitelister_wallet_: zero address not acceptable");
        require(startTime_ < endTime_ && endTime_ > block.timestamp, "start & end time are incorrect");
        startTime = startTime_;
        endTime = endTime_;

        USDC = IERC20(USDC_);
        USDT = IERC20(USDT_);
        DAI = IERC20(DAI_);

        _token = token_;
        whitelister_wallet = initial_whitelister_wallet_;
        transferOwnership(_wallet); // make the gnosis safe the owner of the contract
    }

    //  ----------- WHITELISTING - KYC/AML -----------

    /**
    * @dev Updates the whitelister_wallet, only address allowed to add/remove from whitelist
    * @param new_whitelister_wallet Address to become the new whitelister_wallet 
    */
    function adminUpdateWhitelisterAddress(address new_whitelister_wallet) public onlyOwner {
        require(new_whitelister_wallet != address(0), "new whitelister address must be non zero");
        whitelister_wallet = new_whitelister_wallet;
    }

    /**
    * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
    */
    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary],"user not whitelisted");
        _;
    }

    /**
    * @dev Adds single address to whitelist.
    * @param _beneficiary Address to be added to the whitelist
    */
    function addToWhitelist(address _beneficiary) external {
        require(msg.sender == whitelister_wallet, "sender is not allowed to modify whitelist");
        whitelist[_beneficiary] = true;
        emit AddressWhitelisted(_beneficiary);
    }

    /**
    * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
    * @param _beneficiaries Addresses to be added to the whitelist
    */
    function addManyToWhitelist(address[] memory _beneficiaries) external {
        require(msg.sender == whitelister_wallet, "sender is not allowed to modify whitelist");
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
            emit AddressWhitelisted(_beneficiaries[i]);
        }
    }

    /**
    * @dev Removes single address from whitelist.
    * @param _beneficiary Address to be removed to the whitelist
    */
    function removeFromWhitelist(address _beneficiary) external {
        require(msg.sender == whitelister_wallet, "sender is not allowed to modify whitelist");
        whitelist[_beneficiary] = false;
        emit AddressDeWhitelisted(_beneficiary);
    }

    //  ----------- ADMIN - END -----------

    /**
    * @notice Withdraw (admin/owner only) any unsold Exorde tokens or other ERC20 stuck on the contract
    */
    function adminWithdrawERC20(IERC20 token_, address beneficiary_, uint256 tokenAmount_) external
    onlyOwner
    isInactive
    MinimumTimeLock
    {
        token_.safeTransfer(beneficiary_, tokenAmount_);
    }
    
    /**
   * @notice Pause or unpause the contract
  */
    function toggleSystemPause() public onlyOwner {        
        if(paused()){
            _unpause();
        }else{
            _pause();
        }
    }

    //  ----------------------------------------------
    /**
    * @notice Allow to extend Sale end date
    * @param _endTime Endtime of Sale
    */
    function setEndDate(uint256 _endTime)
        external 
        onlyOwner 
        MinimumTimeLock
    {
        require(block.timestamp < _endTime, "new endTime must > now");
        endTime = _endTime;
    }

    /**
    * @dev Reverts if sale has not started or has ended
    */
    modifier isSaleOpen() {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "the sale is not open");
        _;
    }

    /**
    * @dev Reverts if 1 week has not passed since the start of the Public Sale
    */
    modifier MinimumTimeLock() {        
        require(block.timestamp > startTime + OneWeekDuration, "Owner must wait at least 1 week after Sale start to update");
        _;
    }
    /**
    * @dev Returns if the Token Sale is active (started & not ended)
    * @return the boolean indicating if the sale is active (true : active)
    */
    function isOpen() public view returns (bool){
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }
    
    /**
    * @dev Reverts if Sale is Inactive (paused or closed)
    */
    modifier isInactive() {
        require( !isOpen(), "the sale is active" );
        _;
    }
    
    /**
    * @dev fallback to reject non zero ETH transactions
    */
    receive () external payable {
        revert("ETH not authorized, please use buyTokens()");
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }


    /**
     * @return the amount of dollar raised.
     */
    function dollarRaised() public view returns (uint256) {
        return _dollarRaised;
    }

    /**
     * @dev Token Purchase Function, using USDC on Ethereum, with 6 decimals
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param purchaseAmount in dollar (usdc/usdt/dai)
     */
    function buyTokensUSDC(uint256 purchaseAmount) public 
    nonReentrant 
    whenNotPaused
    isSaleOpen
    isWhitelisted(_msgSender()) 
    {
        address beneficiary = _msgSender();
        USDC.safeTransferFrom(beneficiary, address(this), purchaseAmount);
        
        _preValidatePurchase(beneficiary, purchaseAmount);

        (uint256 tokens, uint256 dollarsToRefund) = _getTokenAmount(purchaseAmount);

        require( dollarsToRefund  <= purchaseAmount, "error: dollarsToRefund > purchaseAmount");
        uint256 effectivePurchaseAmount = purchaseAmount - dollarsToRefund;
        
        // update state
        _dollarRaised = _dollarRaised.add(effectivePurchaseAmount);

        _processPurchase(beneficiary, tokens);  
        emit TokensPurchased(beneficiary, beneficiary, effectivePurchaseAmount, tokens);

        _updatePurchasingState(beneficiary, effectivePurchaseAmount);

        _forwardFunds(USDC, effectivePurchaseAmount);
        _postValidatePurchase(USDC, beneficiary, dollarsToRefund);
    }


    /**
     * @dev Token Purchase Function, using USDT (Tether) on Ethereum, with 6 decimals
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param purchaseAmount in dollar (usdc/usdt/dai)
     */
    function buyTokensUSDT(uint256 purchaseAmount) public 
    nonReentrant 
    whenNotPaused
    isSaleOpen
    isWhitelisted( _msgSender()) 
    {
        address beneficiary = _msgSender();
        USDT.safeTransferFrom(beneficiary, address(this), purchaseAmount);
        
        _preValidatePurchase(beneficiary, purchaseAmount);

        (uint256 tokens, uint256 dollarsToRefund) = _getTokenAmount(purchaseAmount);
        require( dollarsToRefund  <= purchaseAmount, "error: dollarsToRefund > purchaseAmount");
        uint256 effectivePurchaseAmount = purchaseAmount - dollarsToRefund;
        
        // update state
        _dollarRaised = _dollarRaised.add(effectivePurchaseAmount);

        _processPurchase(beneficiary, tokens);  
        emit TokensPurchased(_msgSender(), beneficiary, effectivePurchaseAmount, tokens);

        _updatePurchasingState(beneficiary, effectivePurchaseAmount);

        _forwardFunds(USDT, effectivePurchaseAmount);
        _postValidatePurchase(USDT, beneficiary, dollarsToRefund);
    }


    /**
     * @dev Token Purchase Function, using DAI on Ethereum, with 18 decimals
     * The user who calls this needs to have previously approved (approve()) purchaseAmount_ on the DAI contract
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param purchaseAmount_ in dollar (usdc/usdt/dai)
     */
    function buyTokensDAI(uint256 purchaseAmount_) public 
    nonReentrant 
    whenNotPaused
    isSaleOpen
    isWhitelisted( _msgSender()) 
    {
        address beneficiary = _msgSender();
        DAI.safeTransferFrom(_msgSender(), address(this), purchaseAmount_);
        uint256 purchaseAmount = purchaseAmount_.div(10**12); //DAI has 12 more digits than USDC/UST
        
        _preValidatePurchase(beneficiary, purchaseAmount);

        (uint256 tokens, uint256 dollarsToRefund) = _getTokenAmount(purchaseAmount);
        require( dollarsToRefund  <= purchaseAmount, "error: dollarsToRefund > purchaseAmount");
        uint256 effectivePurchaseAmount = purchaseAmount - dollarsToRefund;
        
        // update state
        _dollarRaised = _dollarRaised.add(effectivePurchaseAmount);

        _processPurchase(beneficiary, tokens);  
        emit TokensPurchased(_msgSender(), beneficiary, effectivePurchaseAmount, tokens);

        _updatePurchasingState(beneficiary, effectivePurchaseAmount);

        _forwardFunds(DAI, effectivePurchaseAmount.mul(10**12));
        _postValidatePurchase(DAI, beneficiary, dollarsToRefund);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, dollarAmount);
     *     require(dollarRaised().add(dollarAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param dollarAmount Value in dollar involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 dollarAmount) internal view virtual {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(dollarAmount != 0, "Crowdsale: dollarAmount is 0");
        require(totalTokensRaised < maxTokensRaised, "Crowdsale is now sold out");
        // check if user total purchase is below the user cap.
        require( (_usersTotalPurchase[beneficiary]+dollarAmount) <= userMaxTotalPurchase, 
        "total user purchase is capped at $50k" );
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param toRefundAmount Value in dollar to be refunded
     */
    function _postValidatePurchase(IERC20 inputToken_, address beneficiary, uint256 toRefundAmount) internal {
        if( toRefundAmount > 0){
            _refundDollars(inputToken_, beneficiary, toRefundAmount);
        }
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal virtual {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal virtual {
        _deliverTokens(beneficiary, tokenAmount);
        totalTokensRaised += tokenAmount;
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param dollarAmount Value in dollar involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 dollarAmount) internal virtual {
        _usersTotalPurchase[beneficiary] += dollarAmount;
    }

    /**
     * @notice Returns the supply limit threshold of tierSelected_
     * @param tierSelected_ The tier (1, 2 or 3)
     * @return supplyLimit of the Tier, in EXD, with 18 decimals
     */
    function getSupplyLimitPerTier(uint256 tierSelected_) public view returns (uint256) {
        require(tierSelected_ >= 1 && tierSelected_ <= 3);
        uint256 _supplyLmit;
        if( tierSelected_ == 1 ){
            _supplyLmit = _tier1SupplyThreshold;
        }
        else if( tierSelected_ == 2 ){            
            _supplyLmit = _tier2SupplyThreshold;
        }
        else if( tierSelected_ == 3 ){            
            _supplyLmit = _tier3SupplyThreshold;
        }
        return _supplyLmit;
    }

    /**
     * @notice Returns the price of tierSelected_
     * @param tierSelected_ The tier (1, 2 or 3)
     * @return price price of the tier, in dollar (with 6 decimals for USDC & USDT)
     */
    function getPricePerTier(uint256 tierSelected_) public view returns (uint256) {
        require(tierSelected_ >= 1 && tierSelected_ <= 3);
        uint256 _price;
        if( tierSelected_ == 1 ){
            _price = _priceTier1;
        }
        else if( tierSelected_ == 2 ){            
            _price = _priceTier2;
        }
        else if( tierSelected_ == 3 ){            
            _price = _priceTier3;
        }
        return _price;
    }


    /**
     * @notice Return the current Tier (between 1, 2 or 3)
     * @return Tier current Tier
     */
    function getCurrentTier() public view returns (uint256) {
        uint256 _currentTier;
        // if tokenRaised is > threshold2, then we are in Tier 3
        if( totalTokensRaised > _tier2SupplyThreshold ){
            _currentTier = 3;
        // Else, if tokenRaised is > threshold1, then we are in Tier 2
        }else if( totalTokensRaised > _tier1SupplyThreshold ){
            _currentTier = 2;
        }
        // Else, we are by default in Tier 1
        else{
            _currentTier = 1;
        }

        return _currentTier;
    }


    /**
     * @notice Calculate the token amount per tier function of dollarPaid in input
     * @param dollarPaid_ The amount of dollar paid that will be used to buy tokens
     * @param tierSelected_ The tier that you'll use for thir purchase
     * @return calculatedTokens Returns how many tokens you've bought for that dollar paid
     */
   function calculateTokensTier(uint256 dollarPaid_, uint256 tierSelected_) public 
   view returns(uint256){
      require(tierSelected_ >= 1 && tierSelected_ <= 3);
      uint256 calculatedTokens;

      if(tierSelected_ == 1){
         calculatedTokens = dollarPaid_.div(_priceTier1).mul(_priceBase);
      }
      else if(tierSelected_ == 2){
         calculatedTokens = dollarPaid_.div(_priceTier2).mul(_priceBase);
      }
      else{
         calculatedTokens = dollarPaid_.div(_priceTier3).mul(_priceBase);
      }

     return calculatedTokens;
   }

    /**
     * @notice Remaining number of dollars (>= 0) left in the current Tier of the Sale
     */
   function remainingTierDollars() public 
   view returns(uint256){
        uint256 tierSelected = getCurrentTier();
        uint256 remainingTierTokens_ = getSupplyLimitPerTier(tierSelected) - totalTokensRaised;
        uint256 remainingTierDollarPurchase_ = remainingTierTokens_.mul(getPricePerTier(tierSelected)).div(_priceBase);
        return remainingTierDollarPurchase_;
   }

    /**
     * @notice Buys the tokens for the specified tier and for the next one
     * @param dollarPurchaseAmount The amount of dollar paid to buy the tokens
     * @return totalTokens The total amount of tokens bought combining the tier prices
     * @return surplusTokens A potentially non-zero surplus of dollars to refund
     */
   function _getTokenAmount(uint256 dollarPurchaseAmount) view public returns(uint256, uint256) {
        require(dollarPurchaseAmount > 0);
        uint256 allocatedTokens = 0;
        uint256 surplusDollarsForNextTier = 0;
        uint256 surplusDollarsToRefund = 0;

        uint256 _currentTier = getCurrentTier();
        uint256 _tokensNextTier = 0;

        uint256 remainingTierDollarPurchase = remainingTierDollars();
        // Check if there isn't enough dollars for the current Tier
        if ( dollarPurchaseAmount > remainingTierDollarPurchase ){
            surplusDollarsForNextTier = dollarPurchaseAmount - remainingTierDollarPurchase;
        }
        if( surplusDollarsForNextTier > 0 ){
            // If there's excessive dollar for the last tier
            if(_currentTier <= 2){ // if we are in Tier 1 or 2, then all dollars can be used
                _tokensNextTier = calculateTokensTier(surplusDollarsForNextTier, (_currentTier + 1) );
            }
            else{ // if we are in the last tier & have surplus, we have to refund this amount
                surplusDollarsToRefund = surplusDollarsForNextTier;
            }
            // total Allocated Tokens = tokens for this tier + token for next tier
            allocatedTokens = calculateTokensTier((dollarPurchaseAmount - surplusDollarsForNextTier), _currentTier) 
                              + _tokensNextTier; 
        }
        else{
            allocatedTokens = calculateTokensTier(dollarPurchaseAmount, _currentTier);
        }
        
        return (allocatedTokens, surplusDollarsToRefund);
   }

    /**
     * @dev Determines how funds are stored/forwarded on purchases.
     */
    function _forwardFunds(IERC20 inputToken_, uint256 amount_) internal virtual {
        inputToken_.safeTransfer( _wallet, amount_  );
    }

    /**
     * @dev Determines how funds are stored/forwarded on purchases.
     */
    function _refundDollars(IERC20 inputToken_, address beneficiary,  uint256 amount_) internal  {
        inputToken_.safeTransfer( beneficiary , amount_  );
    }
}