/**
 *Submitted for verification at Etherscan.io on 2023-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/**
 *
 * Each instance of a Crowdfinancing Contract represents a single campaign with a goal
 * of raising funds for a specific purpose. The contract is deployed by the creator through
 * the CrowdFinancingV1Factory contract. The creator specifies the recipient address, the
 * token to use for payments, the minimum and maximum funding goals, the minimum and maximum
 * contribution amounts, and the start and end times.
 *
 * The campaign is deemed successful if the minimum funding goal is met by the end time, or the
 * maximum funding goal is met before the end time.
 *
 * If the campaign is successful funds can be transferred to the recipient address. If the
 * campaign is not successful the funds can be withdrawn by the contributors.
 *
 * @title Crowd Financing with Optional Yield
 * @author Fabric Inc.
 *
 */
contract CrowdFinancingV1 is Initializable, ReentrancyGuardUpgradeable, IERC20 {
    /// @dev Guard to gate ERC20 specific functions
    modifier erc20Only() {
        require(_erc20, "erc20 only fn called");
        _;
    }

    /// @dev Guard to gate ETH specific functions
    modifier ethOnly() {
        require(!_erc20, "ETH only fn called");
        _;
    }

    /// @dev Guard to ensure yields are allowed
    modifier yieldGuard(uint256 amount) {
        require(_state == State.FUNDED, "Cannot accept payment");
        require(amount > 0, "Amount is 0");
        _;
    }

    /// @dev Guard to ensure contributions are allowed
    modifier contributionGuard(uint256 amount) {
        require(isContributionAllowed(), "Contributions are not allowed");
        uint256 total = _contributions[msg.sender] + amount;
        require(total >= _minContribution, "Contribution amount is too low");
        require(total <= _maxContribution, "Contribution amount is too high");
        require(_contributionTotal + amount <= _goalMax, "Contribution amount exceeds max goal");
        _;
    }

    /// @dev If transfer doesn't occur within the TRANSFER_WINDOW, the campaign can be unlocked
    /// and put into a failed state for withdraws. This is to prevent a campaign from being
    /// locked forever if the recipient addresses are compromised.
    uint256 private constant TRANSFER_WINDOW = 90 days;

    /// @dev Max campaign duration: 90 Days
    uint256 private constant MAX_DURATION_SECONDS = 90 days;

    /// @dev Min campaign duration: 30 minutes
    uint256 private constant MIN_DURATION_SECONDS = 30 minutes;

    /// @dev Allow a campaign to be deployed where the start time is up to one minute in the past
    uint256 private constant PAST_START_TOLERANCE_SECONDS = 60;

    /// @dev Maximum fee basis points (12.5%)
    uint16 private constant MAX_FEE_BIPS = 1250;

    /// @dev Maximum basis points
    uint16 private constant MAX_BIPS = 10_000;

    /// @dev Emitted when an account contributes funds to the contract
    event Contribution(address indexed account, uint256 numTokens);

    /// @dev Emitted when an account withdraws their initial contribution or yield balance
    event Withdraw(address indexed account, uint256 numTokens);

    /// @dev Emitted when the funds are transferred to the recipient and when
    /// fees are transferred to the fee collector, if specified
    event TransferContributions(address indexed account, uint256 numTokens);

    /// @dev Emitted when the campaign is marked as failed
    event Fail();

    /// @dev Emitted when yieldEth or yieldERC20 are called
    event Payout(address indexed account, uint256 numTokens);

    /// @dev A state enum to track the current state of the campaign
    enum State {
        FUNDING,
        FAILED,
        FUNDED
    }

    /// @dev The current state of the contract
    State private _state;

    /// @dev The address of the recipient in the event of a successful campaign
    address private _recipientAddress;

    /// @dev The token used for funding (optional)
    IERC20 private _token;

    /// @dev The minimum funding goal to meet for a successful campaign
    uint256 private _goalMin;

    /// @dev The maximum funding goal. If this goal is met, funds can be transferred early
    uint256 private _goalMax;

    /// @dev The minimum tokens an account can contribute
    uint256 private _minContribution;

    /// @dev The maximum tokens an account can contribute
    uint256 private _maxContribution;

    /// @dev The start timestamp for the campaign
    uint256 private _startTimestamp;

    /// @dev The end timestamp for the campaign
    uint256 private _endTimestamp;

    /// @dev The total amount contributed by all accounts
    uint256 private _contributionTotal;

    /// @dev The total amount withdrawn by all accounts
    uint256 private _withdrawTotal;

    /// @dev The mapping from account to balance (contributions or transfers)
    mapping(address => uint256) private _contributions;

    /// @dev The mapping from account to withdraws
    mapping(address => uint256) private _withdraws;

    /// @dev ERC20 allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    // Fee related items

    /// @dev The optional address of the fee recipient
    address private _feeRecipient;

    /// @dev The transfer fee in basis points, sent to the fee recipient upon transfer
    uint16 private _feeTransferBips;

    /// @dev The yield fee in basis points, used to dilute the cap table upon transfer
    uint16 private _feeYieldBips;

    /// @dev Track the number of tokens sent via yield calls
    uint256 private _yieldTotal;

    /// @dev Flag indicating the contract works with ERC20 tokens rather than ETH
    bool private _erc20;

    /// @dev This contract is intended for use with proxies, so we prevent direct
    ///      initialization. This contract will fail to function properly without a proxy
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize acts as the constructor, as this contract is intended to work with proxy contracts.
     *
     * @param recipient the address of the recipient, where funds are transferred when conditions are met
     * @param minGoal the minimum funding goal for the financing round
     * @param maxGoal the maximum funding goal for the financing round
     * @param minContribution the minimum initial contribution an account can make
     * @param maxContribution the maximum contribution an account can make
     * @param startTimestamp the UNIX time in seconds denoting when contributions can start
     * @param endTimestamp the UNIX time in seconds denoting when contributions are no longer allowed
     * @param erc20TokenAddr the address of the ERC20 token used for funding, or the 0 address for native token (ETH)
     * @param feeRecipientAddr the address of the fee recipient, or the 0 address if no fees are collected
     * @param feeTransferBips the transfer fee in basis points, collected during the transfer call
     * @param feeYieldBips the yield fee in basis points. Dilutes the cap table for the fee recipient.
     */
    function initialize(
        address recipient,
        uint256 minGoal,
        uint256 maxGoal,
        uint256 minContribution,
        uint256 maxContribution,
        uint256 startTimestamp,
        uint256 endTimestamp,
        address erc20TokenAddr,
        address feeRecipientAddr,
        uint16 feeTransferBips,
        uint16 feeYieldBips
    ) external initializer {
        require(recipient != address(0), "Invalid recipient address");
        require(startTimestamp + PAST_START_TOLERANCE_SECONDS >= block.timestamp, "Invalid start time");
        require(startTimestamp + MIN_DURATION_SECONDS <= endTimestamp, "Invalid time range");
        require(
            endTimestamp > block.timestamp && (endTimestamp - startTimestamp) < MAX_DURATION_SECONDS, "Invalid end time"
        );
        require(minGoal > 0, "Min goal must be > 0");
        require(minGoal <= maxGoal, "Min goal must be <= Max goal");
        require(minContribution > 0, "Min contribution must be > 0");
        require(minContribution <= maxContribution, "Min contribution must be <= Max contribution");
        require(
            minContribution < (maxGoal - minGoal) || minContribution == 1,
            "Min contribution must be < (maxGoal - minGoal) or 1"
        );
        require(feeTransferBips <= MAX_FEE_BIPS, "Transfer fee too high");
        require(feeYieldBips <= MAX_FEE_BIPS, "Yield fee too high");

        if (feeRecipientAddr != address(0)) {
            require(feeTransferBips > 0 || feeYieldBips > 0, "Fees required when fee recipient is present");
        } else {
            require(feeTransferBips == 0 && feeYieldBips == 0, "Fees must be 0 when there is no fee recipient");
        }

        _recipientAddress = recipient;
        _goalMin = minGoal;
        _goalMax = maxGoal;
        _minContribution = minContribution;
        _maxContribution = maxContribution;
        _startTimestamp = startTimestamp;
        _endTimestamp = endTimestamp;
        _token = IERC20(erc20TokenAddr);
        _erc20 = erc20TokenAddr != address(0);

        _feeRecipient = feeRecipientAddr;
        _feeTransferBips = feeTransferBips;
        _feeYieldBips = feeYieldBips;

        _contributionTotal = 0;
        _withdrawTotal = 0;
        _state = State.FUNDING;

        __ReentrancyGuard_init();
    }

    ///////////////////////////////////////////
    // Contributions
    ///////////////////////////////////////////

    /**
     * @notice Contribute ERC20 tokens into the contract
     *
     *         #### Events
     *         - Emits a {Contribution} event
     *         - Emits a {Transfer} event (ERC20)
     *
     *         #### Requirements
     *         - `amount` must be within range of min and max contribution for account
     *         - `amount` must not cause max goal to be exceeded
     *         - `amount` must be approved for transfer by the caller
     *         - contributions must be allowed
     *         - the contract must be configured to work with ERC20 tokens
     *
     * @param amount the amount of ERC20 tokens to contribute
     *
     */
    function contributeERC20(uint256 amount) external erc20Only nonReentrant {
        _addContribution(msg.sender, _transferSafe(msg.sender, amount));
    }

    /**
     * @notice Contribute ETH into the contract
     *
     *         #### Events
     *         - Emits a {Contribution} event
     *         - Emits a {Transfer} event (ERC20)
     *
     *         #### Requirements
     *         - `msg.value` must be within range of min and max contribution for account
     *         - `msg.value` must not cause max goal to be exceeded
     *         - contributions must be allowed
     *         - the contract must be configured to work with ETH
     */
    function contributeEth() external payable ethOnly {
        _addContribution(msg.sender, msg.value);
    }

    /**
     * @dev Add a contribution to the account and update totals
     *
     * @param account the account to add the contribution to
     * @param amount the amount of the contribution
     */
    function _addContribution(address account, uint256 amount) private contributionGuard(amount) {
        _contributions[account] += amount;
        _contributionTotal += amount;
        emit Contribution(account, amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @return true if contributions are allowed
     */
    function isContributionAllowed() public view returns (bool) {
        return _state == State.FUNDING && !isGoalMaxMet() && isStarted() && !isEnded();
    }

    ///////////////////////////////////////////
    // Transfer
    ///////////////////////////////////////////

    /**
     * @return true if the goal was met and funds can be transferred
     */
    function isTransferAllowed() public view returns (bool) {
        return ((isEnded() && isGoalMinMet()) || isGoalMaxMet()) && _state == State.FUNDING;
    }

    /**
     * @notice Transfer funds to the recipient and change the state
     *
     *         #### Events
     *         Emits a {TransferContributions} event if the target was met and funds transferred
     */
    function transferBalanceToRecipient() external {
        require(isTransferAllowed(), "Transfer not allowed");

        _state = State.FUNDED;

        uint256 feeAmount = _calculateTransferFee();
        uint256 transferAmount = _contributionTotal - feeAmount;

        // This can mutate _contributionTotal, so that withdraws don't over withdraw
        _allocateYieldFee();

        // If any transfer fee is present, pay that out to the fee recipient
        if (feeAmount > 0) {
            emit TransferContributions(_feeRecipient, feeAmount);
            if (_erc20) {
                SafeERC20.safeTransfer(_token, _feeRecipient, feeAmount);
            } else {
                (bool sent,) = payable(_feeRecipient).call{value: feeAmount}("");
                require(sent, "Failed to transfer Ether");
            }
        }

        emit TransferContributions(_recipientAddress, transferAmount);
        if (_erc20) {
            SafeERC20.safeTransfer(_token, _recipientAddress, transferAmount);
        } else {
            (bool sent,) = payable(_recipientAddress).call{value: transferAmount}("");
            require(sent, "Failed to transfer Ether");
        }
    }

    /**
     * @dev Dilutes supply by allocating tokens to the fee collector, allowing for
     *      withdraws of yield
     */
    function _allocateYieldFee() private returns (uint256) {
        if (_feeYieldBips == 0) {
            return 0;
        }
        uint256 feeAllocation = ((_contributionTotal * _feeYieldBips) / (MAX_BIPS - _feeYieldBips));

        _contributions[_feeRecipient] += feeAllocation;
        _contributionTotal += feeAllocation;

        return feeAllocation;
    }

    /**
     * @dev Calculates a fee to transfer to the fee collector
     */
    function _calculateTransferFee() private view returns (uint256) {
        if (_feeTransferBips == 0) {
            return 0;
        }
        return (_contributionTotal * _feeTransferBips) / (MAX_BIPS);
    }

    /**
     * @return true if the minimum goal was met
     */
    function isGoalMinMet() public view returns (bool) {
        return _contributionTotal >= _goalMin;
    }

    /**
     * @return true if the maximum goal was met
     */
    function isGoalMaxMet() public view returns (bool) {
        return _contributionTotal >= _goalMax;
    }

    ///////////////////////////////////////////
    // Unlocking Funds After Failed Transfer
    ///////////////////////////////////////////

    /**
     * @notice In the event that a transfer fails due to recipient contract behavior, the campaign
     *         can be unlocked (marked as failed) to allow contributors to withdraw their funds. This can only
     *         occur if the state of the campaign is FUNDING and the transfer window
     *         has expired. Note: Recipient should invoke transferBalanceToRecipient immediately upon success
     *         to prevent this function from being callable. This is a safety mechanism to prevent
     *         permanent loss of funds.
     *
     *         #### Events
     *         - Emits {Fail} event
     */
    function unlockFailedFunds() external {
        require(isUnlockAllowed(), "Funds cannot be unlocked");
        _state = State.FAILED;
        emit Fail();
    }

    ///////////////////////////////////////////
    // Phase 3: Yield / Refunds / Withdraws
    ///////////////////////////////////////////

    /**
     * @notice Yield ERC20 tokens to all campaign token holders in proportion to their token balance
     *
     *         #### Requirements
     *         - `amount` must be greater than 0
     *         - `amount` must be approved for transfer for the contract
     *
     *         #### Events
     *         - Emits {Payout} event with amount = `amount`
     *
     * @param amount the amount of tokens to payout
     */
    function yieldERC20(uint256 amount) external erc20Only yieldGuard(amount) nonReentrant {
        _trackYield(msg.sender, _transferSafe(msg.sender, amount));
    }

    /**
     * @notice Yield ETH to all token holders in proportion to their balance
     *
     *         #### Requirements
     *         - `msg.value` must be greater than 0
     *
     *         #### Events
     *         - Emits {Payout} event with amount = `msg.value`
     */
    function yieldEth() external payable ethOnly yieldGuard(msg.value) nonReentrant {
        _trackYield(msg.sender, msg.value);
    }

    /**
     * @dev Emit a Payout event and increase yield total
     */
    function _trackYield(address from, uint256 amount) private {
        emit Payout(from, amount);
        _yieldTotal += amount;
    }

    /**
     * @return The total amount of tokens/wei paid back by the recipient
     */
    function yieldTotal() public view returns (uint256) {
        return _yieldTotal;
    }

    /**
     * @param account the address of a contributor or token holder
     *
     * @return The total tokens withdrawn for a given account
     */
    function withdrawsOf(address account) public view returns (uint256) {
        return _withdraws[account];
    }

    /**
     * @return true if the contract allows withdraws
     */
    function isWithdrawAllowed() public view returns (bool) {
        return state() == State.FUNDED || state() == State.FAILED || (isEnded() && !isGoalMinMet());
    }

    /**
     * @return The total amount of tokens paid back to a given contributor
     */
    function _payoutsMadeTo(address account) private view returns (uint256) {
        if (_contributionTotal == 0) {
            return 0;
        }
        return (_contributions[account] * yieldTotal()) / _contributionTotal;
    }

    /**
     * @param account the address of a token holder
     *
     * @return The withdrawable amount of tokens for a given account, attributable to yield
     */
    function yieldBalanceOf(address account) public view returns (uint256) {
        return _payoutsMadeTo(account) - withdrawsOf(account);
    }

    /**
     * @param account the address of a contributor
     *
     * @return The total amount of tokens earned by the given account through yield
     */
    function yieldTotalOf(address account) public view returns (uint256) {
        uint256 _payout = _payoutsMadeTo(account);
        if (_payout <= _contributions[account]) {
            return 0;
        }
        return _payout - _contributions[account];
    }

    /**
     * @notice Withdraw all available funds to the caller if withdraws are allowed and
     *         the caller has a contribution balance (campaign failed), or a yield balance (campaign succeeded)
     *
     *         #### Events
     *         - Emits a {Withdraw} event with amount = the amount withdrawn
     *         - Emits a {Transfer} event representing a token burn if the campaign failed
     */
    function withdraw() external {
        require(isWithdrawAllowed(), "Withdraw not allowed");

        // Set the state to failed
        if (_state == State.FUNDING) {
            _state = State.FAILED;
            emit Fail();
        }

        address account = msg.sender;
        if (_state == State.FUNDED) {
            _withdrawYieldBalance(account);
        } else {
            _withdrawContribution(account);
        }
    }

    /**
     * @dev Withdraw the initial contribution for the given account
     */
    function _withdrawContribution(address account) private {
        uint256 amount = _contributions[account];
        require(amount > 0, "No balance");
        _contributions[account] = 0;
        _contributionTotal -= amount;
        emit Withdraw(account, amount);
        emit Transfer(account, address(0), amount);

        if (_erc20) {
            SafeERC20.safeTransfer(_token, account, amount);
        } else {
            (bool sent,) = payable(account).call{value: amount}("");
            require(sent, "Failed to transfer Ether");
        }
    }

    /**
     * @dev Withdraw the available yield balance for the given account
     */
    function _withdrawYieldBalance(address account) private {
        uint256 amount = yieldBalanceOf(account);
        require(amount > 0, "No balance");
        _withdraws[account] += amount;
        _withdrawTotal += amount;
        emit Withdraw(account, amount);

        if (_erc20) {
            SafeERC20.safeTransfer(_token, account, amount);
        } else {
            (bool sent,) = payable(account).call{value: amount}("");
            require(sent, "Failed to transfer Ether");
        }
    }

    ///////////////////////////////////////////
    // Utility Functions
    ///////////////////////////////////////////

    /**
     * @dev Token transfer function which leverages allowance. Additionally, it accounts
     *      for tokens which take fees on transfer. Fetch the balance of this contract
     *      before and after transfer, to determine the real amount of tokens transferred.
     *
     * @notice this contract is not compatible with tokens that rebase
     *
     * @return The amount of tokens transferred after fees
     */
    function _transferSafe(address account, uint256 amount) private returns (uint256) {
        uint256 allowed = _token.allowance(msg.sender, address(this));
        require(amount <= allowed, "Amount exceeds token allowance");
        uint256 priorBalance = _token.balanceOf(address(this));
        SafeERC20.safeTransferFrom(_token, account, address(this), amount);
        uint256 postBalance = _token.balanceOf(address(this));
        return postBalance - priorBalance;
    }

    ///////////////////////////////////////////
    // IERC20 Implementation
    ///////////////////////////////////////////

    /**
     * @inheritdoc IERC20
     * @dev Contributions mint tokens and increase the total supply
     */
    function totalSupply() external view returns (uint256) {
        return _contributionTotal;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) external view returns (uint256) {
        return _contributions[account];
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * See ERC20._transfer
     * @dev The primary difference here is that we also need to adjust withdraws
     *      to prevent over-withdrawal of yield/contribution
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _contributions[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _contributions[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _contributions[to] += amount;
        }

        // Transfer partial withdraws to balance payouts
        if (_state == State.FUNDED) {
            uint256 fromWithdraws = _withdraws[from];
            uint256 withdrawAmount = (amount * fromWithdraws) / fromBalance;
            unchecked {
                _withdraws[from] = fromWithdraws - withdrawAmount;
                _withdraws[to] += withdrawAmount;
            }
        }

        emit Transfer(from, to, amount);
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// See ERC20._spendAllowance
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /// See ERC20._approve
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /// See ERC20.increaseAllowance
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /// See ERC20.decreaseAllowance
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    ///////////////////////////////////////////
    // Public/External Views
    ///////////////////////////////////////////

    /**
     * @dev The values can be 0, indicating the account is not allowed to contribute.
     *      This method is helpful for preflight checks to ensure the amount is within the range.
     *
     * @return min The minimum contribution for the account
     * @return max The maximum contribution for the account
     */
    function contributionRangeFor(address account) external view returns (uint256 min, uint256 max) {
        uint256 balance = _contributions[account];
        if (balance >= _maxContribution || isGoalMaxMet()) {
            return (0, 0);
        }
        int256 minContribution = int256(_minContribution) - int256(balance);
        if (minContribution <= 0) {
            minContribution = 1;
        }
        uint256 remainingGoal = _goalMax - _contributionTotal;
        // If the remaining goal is less than the minimum contribution, then the account cannot contribute
        // This can lead to a gap between the supply and max goal, but existing contributors can top it off if
        // they are anxious to transfer early
        if (remainingGoal < uint256(minContribution)) {
            return (0, 0);
        }

        return (uint256(minContribution), Math.min(_maxContribution - balance, remainingGoal));
    }

    /**
     * @return The current state of the campaign
     */
    function state() public view returns (State) {
        return _state;
    }

    /**
     * @return The minimum allowed contribution of ERC20 tokens or WEI
     */
    function minAllowedContribution() external view returns (uint256) {
        return _minContribution;
    }

    /**
     * @return The maximum allowed contribution of ERC20 tokens or WEI
     */
    function maxAllowedContribution() external view returns (uint256) {
        return _maxContribution;
    }

    /**
     * @return The unix timestamp in seconds when the time window for contribution starts
     */
    function startsAt() external view returns (uint256) {
        return _startTimestamp;
    }

    /**
     * @return true if the time window for contribution has started
     */
    function isStarted() public view returns (bool) {
        return block.timestamp >= _startTimestamp;
    }

    /**
     * @return The unix timestamp in seconds when the contribution window ends
     */
    function endsAt() external view returns (uint256) {
        return _endTimestamp;
    }

    /**
     * @return true if the time window for contribution has closed
     */
    function isEnded() public view returns (bool) {
        return block.timestamp >= _endTimestamp;
    }

    /**
     * @return The address of the recipient
     */
    function recipientAddress() external view returns (address) {
        return _recipientAddress;
    }

    /**
     * @return true if the contract is ETH denominated
     */
    function isEthDenominated() public view returns (bool) {
        return !_erc20;
    }

    /**
     * @return The address of the ERC20 Token, or 0x0 if ETH
     */
    function erc20Address() external view returns (address) {
        return address(_token);
    }

    /**
     * @return The minimum goal amount as ERC20 tokens or WEI
     */
    function goalMin() external view returns (uint256) {
        return _goalMin;
    }

    /**
     * @return The maximum goal amount as ERC20 tokens or WEI
     */
    function goalMax() external view returns (uint256) {
        return _goalMax;
    }

    /**
     * @return The transfer fee as basis points
     */
    function transferFeeBips() external view returns (uint16) {
        return _feeTransferBips;
    }

    /**
     * @return The yield fee as basis points
     */
    function yieldFeeBips() external view returns (uint16) {
        return _feeYieldBips;
    }

    /**
     * @return The address where the fees are transferred to, or 0x0 if no fees are collected
     */
    function feeRecipientAddress() external view returns (address) {
        return _feeRecipient;
    }

    /**
     * @return true if the funds are unlockable, which means the campaign succeeded, but transfer
     *              failed to occur within the transfer window
     */
    function isUnlockAllowed() public view returns (bool) {
        return _state == State.FUNDING && block.timestamp >= _endTimestamp + TRANSFER_WINDOW;
    }
}