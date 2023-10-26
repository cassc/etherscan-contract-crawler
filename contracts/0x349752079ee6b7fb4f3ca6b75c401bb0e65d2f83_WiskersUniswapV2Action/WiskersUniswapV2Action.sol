/**
 *Submitted for verification at Etherscan.io on 2023-10-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}






// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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



address constant GELATO_RELAY = 0xaBcC9b596420A9E9172FD5938620E265a0f9Df92;
address constant GELATO_RELAY_ERC2771 = 0xb539068872230f20456CF38EC52EF2f91AF4AE49;

address constant GELATO_RELAY_ZKSYNC = 0xB16a1DbE755f992636705fDbb3A8678a657EB3ea;
address constant GELATO_RELAY_ERC2771_ZKSYNC = 0x22DCC39b2AC376862183dd35A1664798dafC7Da6;

abstract contract GelatoRelayBase {
    modifier onlyGelatoRelay() {
        require(_isGelatoRelay(msg.sender), "onlyGelatoRelay");
        _;
    }

    function _isGelatoRelay(address _forwarder) internal view returns (bool) {
        return
            block.chainid == 324 || block.chainid == 280
                ? _forwarder == GELATO_RELAY_ZKSYNC
                : _forwarder == GELATO_RELAY;
    }
}

address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

library TokenUtils {
    using SafeERC20 for IERC20;

    modifier onlyERC20(address _token) {
        require(_token != NATIVE_TOKEN, "TokenUtils.onlyERC20");
        _;
    }

    function transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        _token == NATIVE_TOKEN
            ? Address.sendValue(payable(_to), _amount)
            : IERC20(_token).safeTransfer(_to, _amount);
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal onlyERC20(_token) {
        if (_amount == 0) return;
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }

    function getBalance(address token, address user)
        internal
        view
        returns (uint256)
    {
        return
            token == NATIVE_TOKEN
                ? user.balance
                : IERC20(token).balanceOf(user);
    }
}

uint256 constant _FEE_COLLECTOR_START = 72; // offset: address + address + uint256
uint256 constant _FEE_TOKEN_START = 52; // offset: address + uint256
uint256 constant _FEE_START = 32; // offset: uint256

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContext
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeCollectorRelayContext() pure returns (address feeCollector) {
    assembly {
        feeCollector := shr(
            96,
            calldataload(sub(calldatasize(), _FEE_COLLECTOR_START))
        )
    }
}

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContext
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeTokenRelayContext() pure returns (address feeToken) {
    assembly {
        feeToken := shr(96, calldataload(sub(calldatasize(), _FEE_TOKEN_START)))
    }
}

// WARNING: Do not use this free fn by itself, always inherit GelatoRelayContext
// solhint-disable-next-line func-visibility, private-vars-leading-underscore
function _getFeeRelayContext() pure returns (uint256 fee) {
    assembly {
        fee := calldataload(sub(calldatasize(), _FEE_START))
    }
}

/**
 * @dev Context variant with feeCollector, feeToken and fee appended to msg.data
 * Expects calldata encoding:
 * abi.encodePacked( _data,
 *                   _feeCollector,
 *                   _feeToken,
 *                   _fee);
 * Therefore, we're expecting 20 + 20 + 32 = 72 bytes to be appended to normal msgData
 * 32bytes start offsets from calldatasize:
 *     feeCollector: - 72 bytes
 *     feeToken: - 52 bytes
 *     fee: - 32 bytes
 */
/// @dev Do not use with GelatoRelayFeeCollector - pick only one
abstract contract GelatoRelayContext is GelatoRelayBase {
    using TokenUtils for address;

    // DANGER! Only use with onlyGelatoRelay `_isGelatoRelay` before transferring
    function _transferRelayFee() internal {
        _getFeeToken().transfer(_getFeeCollector(), _getFee());
    }

    // DANGER! Only use with onlyGelatoRelay `_isGelatoRelay` before transferring
    function _transferRelayFeeCapped(uint256 _maxFee) internal {
        uint256 fee = _getFee();
        require(
            fee <= _maxFee,
            "GelatoRelayContext._transferRelayFeeCapped: maxFee"
        );
        _getFeeToken().transfer(_getFeeCollector(), fee);
    }

    function _getMsgData() internal view returns (bytes calldata) {
        return
            _isGelatoRelay(msg.sender)
                ? msg.data[:msg.data.length - _FEE_COLLECTOR_START]
                : msg.data;
    }

    // Only use with GelatoRelayBase onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFeeCollector() internal pure returns (address) {
        return _getFeeCollectorRelayContext();
    }

    // Only use with previous onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFeeToken() internal pure returns (address) {
        return _getFeeTokenRelayContext();
    }

    // Only use with previous onlyGelatoRelay or `_isGelatoRelay` checks
    function _getFee() internal pure returns (uint256) {
        return _getFeeRelayContext();
    }
}


abstract contract WiskersBase is Ownable, GelatoRelayContext {
    using SafeERC20 for IERC20;
    struct signature_t {
        uint8 _v;
        bytes32 _r;
        bytes32 _s;
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _recoverSignatureSigner(
        bytes32 payloadHash,
        signature_t memory signature
    ) public pure returns (address) {
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash)
        );
        return ecrecover(messageHash, signature._v, signature._r, signature._s);
    }

    function recover() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "!recover");
    }

    function withdraw(IERC20 token, uint256 amount) external onlyOwner {
        uint256 bal = token.balanceOf(address(this));
        token.safeTransferFrom(
            address(this),
            msg.sender,
            amount > bal ? bal : amount
        );
    }

    /* Wrapper around gelato functions */
    function __getFee() internal view virtual returns (uint256) {
        return _getFee();
    }

    function __getFeeToken() internal view virtual returns (address) {
        return _getFeeToken();
    }

    function __transferRelayFee() internal virtual {
        return _transferRelayFee();
    }

    receive() external payable {}

    fallback() external payable {}
}






interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;
}


contract WiskersUniswapV2Action is WiskersBase {
    using SafeERC20 for IERC20;

    event NewOperator(address op);
    event TakeFee(address token, uint256 feeAmount);
    event RunAction(bytes32 actionHash);

    address public operator;

    struct _actionStorage {
        address creator;
        address assetIn;
        uint256 amountIn;
        bytes payload;
        bytes result;
    }
    mapping(bytes32 => _actionStorage) public actionStorage;

    struct actionStruct_t {
        uint256 nonce;
        address targetContract;
        address creator;
        address assetIn;
        uint256 amountIn;
        bytes payload;
    }

    /* user storage */
    mapping(address => uint) public actionIds;
    mapping(address => mapping(uint256 => bytes32)) public actionHashes;

    address constant public ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address immutable public weth;

    IUniswapV2Router02 public immutable swapRouter;

    address immutable public feeAddress;
    uint256 constant public protocolFee = 33;

    constructor(
        address _weth,
        address _swapRouter,
        address _feeAddress,
        address _op
    ) {
        weth = _weth;
        swapRouter = IUniswapV2Router02(_swapRouter);
        feeAddress = _feeAddress;
        operator = _op;
        emit NewOperator(_op);
    }

    modifier onlyOperator() {
        if (msg.sender != operator) revert("Not Operator");
        _;
    }

    function setOperator(address _op) public onlyOwner {
        operator = _op;
        emit NewOperator(_op);
    }

    function hasPair(
        address token0,
        address token1
    ) internal view returns (bool) {
        return
            IUniswapV2Factory(swapRouter.factory()).getPair(token0, token1) !=
            address(0);
    }

    /// @notice take protocol fee
    /// @dev takes protocol cut of assetIn
    /// @param assetIn asset being traded-in
    /// @return amount taken in fee
    function _takeFee(IERC20 assetIn) internal returns (uint256) {
        uint256 amountIn = assetIn.balanceOf(address(this));
        uint256 fee = (amountIn * protocolFee) / 10000;

        if (address(assetIn) == weth) {
            assetIn.safeTransfer(feeAddress, fee);
        } else {
            address[] memory swapPath = new address[](2);
            swapPath[0] = address(assetIn);
            swapPath[1] = address(weth);
            swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                fee,
                0,
                swapPath,
                feeAddress,
                block.timestamp
            );
        }

        emit TakeFee(address(assetIn), fee);
        return fee;
    }

    /// @notice pay execution fee
    /// @dev pay executor fee to gelato
    /// @param assetIn asset being traded-in
    /// @return amountFee taken in fee
    function _payExecutionFee(
        IERC20 assetIn,
        uint16 slippage
    ) internal returns (uint256 amountFee) {
        uint256 amountIn = assetIn.balanceOf(address(this));
        uint256 _fee = __getFee();
        if (address(assetIn) == weth) {
            amountFee = _fee;
            IWETH9(weth).withdraw(amountFee);
        } else {
            address[] memory swapPath = new address[](2);
            swapPath[0] = address(assetIn);
            swapPath[1] = address(weth);

            uint[] memory feeAmounts = swapRouter.getAmountsIn(_fee, swapPath);

            // we dont know the tax of the token, so we assume user will set slippage to ok value
            swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                (feeAmounts[0] * (uint256(slippage) + 10000)) / 10000,
                _fee,
                swapPath,
                address(this),
                block.timestamp
            );
            IWETH9(weth).withdraw(_fee);
            amountFee = amountIn - assetIn.balanceOf(address(this));
        }
        if (_fee > address(this).balance) {
            revert("ExecFeeNotPayable");
        }
        if (__getFeeToken() != ETH) {
            revert("ExecFeeTokenNotETH");
        }
        __transferRelayFee();
    }

    function makeActionHash(
        actionStruct_t memory action
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    action.nonce,
                    action.targetContract,
                    action.creator,
                    action.assetIn,
                    action.amountIn,
                    action.payload,
                    getChainID()
                )
            );
    }

    modifier validateSignature(
        bytes32 payload,
        signature_t memory signature,
        address assumedSigner
    ) {
        {
            address signer = _recoverSignatureSigner(payload, signature);
            if (signer == address(0) || signer != assumedSigner) {
                revert("InvalidOperatorSignature");
            }
        }
        _;
    }

    function swapAssets(
        actionStruct_t memory action,
        bytes memory guardrails
    ) internal returns (bytes memory result) {
        IERC20 assetIn = IERC20(action.assetIn);
        address creator = action.creator;
        (address assetOut, uint16 slippage, bool amountInPercent) = abi.decode(
            action.payload,
            (address, uint16, bool)
        );
        // Get amountIn if its % or keep old amountIn
        uint256 amountIn = amountInPercent
            ? (IERC20(action.assetIn).balanceOf(action.creator) *
                action.amountIn) / 10000
            : action.amountIn;

        if (assetIn.allowance(creator, address(this)) < amountIn) {
            revert("NotEnoughAllowance");
        }
        // Transfer assetIn from creator
        {
            assetIn.safeTransferFrom(creator, address(this), amountIn);
            uint256 balanceAfterTransfer = assetIn.balanceOf(address(this));
            if (balanceAfterTransfer == 0) {
                revert("AmountNull");
            }
            if (address(assetIn) != address(weth)) {
                assetIn.approve(address(swapRouter), balanceAfterTransfer);
            }
        }
        // Take fee and pay gelato
        uint256 _protocolFee = _takeFee(assetIn);
        uint256 _executionFee = _payExecutionFee(assetIn, slippage);

        if (address(assetIn) == address(weth)) {
            assetIn.approve(address(swapRouter), assetIn.balanceOf(address(this)));
        }

        // update amountIn to account for tax tokens
        amountIn = assetIn.balanceOf(address(this));
        // Decode guardrails, minAmountOut in this case
        uint256 minAmountOut = abi.decode(guardrails, (uint256));

        // make path
        address[] memory path = new address[](2);
        path[0] = address(assetIn);
        path[1] = address(assetOut);

        // get amountOut and apply slippage
        uint256 estimatedAmountOutWithSlippage = (swapRouter.getAmountsOut(
            amountIn,
            path
        )[1] * (10000 - slippage)) / 10000;

        // do swap
        swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            minAmountOut,
            path,
            address(this),
            block.timestamp
        );

        // check if amountOut is less than amount with slippage
        uint256 outAmount = IERC20(assetOut).balanceOf(address(this));
        if (estimatedAmountOutWithSlippage > outAmount) {
            revert("InsufficientAmountOutWithSlippage");
        }

        IERC20(assetOut).safeTransfer(creator, outAmount);
        //refund remaining gas
        if (assetOut != weth && IERC20(weth).balanceOf(address(this)) > 0) {
            IERC20(weth).safeTransfer(
                creator,
                IERC20(weth).balanceOf(address(this))
            );
        }

        result = abi.encode(
            uint256(amountIn),
            uint256(outAmount),
            uint256(_protocolFee),
            uint256(_executionFee)
        );
    }

    struct wrappedAction {
        bytes32 actionHash;
        actionStruct_t action;
        signature_t creatorSignature;
        signature_t signature;
        bytes guardrails;
    }

    function _runAction(
        wrappedAction memory wa
    )
        internal
        validateSignature(wa.actionHash, wa.creatorSignature, wa.action.creator)
        validateSignature(
            keccak256(abi.encode(wa.actionHash, keccak256(wa.guardrails))),
            wa.signature,
            operator
        )
    {
        if (!verifyAction(wa.action)) {
            revert("ActionVerificationFailed");
        }
        if (actionStorage[wa.actionHash].creator != address(0)) {
            revert("ActionAlreadyExecuted");
        }
        {
            /* Action Start End */

            bytes memory _result = swapAssets(wa.action, wa.guardrails);

            /* Action Specific End */

            actionStorage[wa.actionHash] = _actionStorage(
                wa.action.creator,
                address(wa.action.assetIn),
                wa.action.amountIn,
                wa.action.payload,
                _result
            );
        }
        emit RunAction(wa.actionHash);
    }

    function gelatoRunAction(
        actionStruct_t calldata action,
        signature_t calldata creatorSignature,
        bytes calldata guardrails,
        signature_t calldata signature
    ) public onlyGelatoRelay {
        _runAction(
            wrappedAction(
                makeActionHash(action),
                action,
                creatorSignature,
                signature,
                guardrails
            )
        );
    }

    // Checking/Validating Actions

    function verifyAction(
        actionStruct_t memory action
    ) public view returns (bool) {
        (address assetOut, uint16 maxSlippage, ) = abi.decode(
            action.payload,
            (address, uint16, bool)
        );
        if (maxSlippage > 10000) {
            revert("InvalidSlippage");
        }
        if (action.assetIn != weth) {
            if (!hasPair(address(action.assetIn), address(weth))) {
                revert("NoPairForAssetInAndGas");
            }
        }
        if (!hasPair(address(action.assetIn), address(assetOut))) {
            revert("NoPairForAssetInAndAssetOut");
        }

        return true;
    }

    function verifyActionAndSignature(
        actionStruct_t memory action,
        signature_t memory creatorSignature
    ) public view returns (bool) {
        bytes32 actionHash = makeActionHash(action);
        address signer = _recoverSignatureSigner(actionHash, creatorSignature);
        if (signer == address(0) || signer != action.creator) {
            revert("InvalidCreatorSignature");
        }
        return verifyAction(action);
    }

    function verifyActionOperatorSignature(
        actionStruct_t calldata action,
        bytes memory guardrails,
        signature_t calldata creatorSignature,
        signature_t calldata signature
    ) public view returns (bool) {
        bytes32 actionHash = makeActionHash(action);
        {
            if (verifyActionAndSignature(action, creatorSignature) == false) {
                return false;
            }
        }
        {
            address signer = _recoverSignatureSigner(
                keccak256(abi.encode(actionHash, keccak256(guardrails))),
                signature
            );
            if (signer == address(0) || operator != signer) {
                return false;
            }
        }
        return true;
    }

    function prepareActionCall(
        actionStruct_t calldata action,
        uint256 execFee
    ) public view returns (uint256 quoteMinAmountOut) {
        (address assetOut, uint16 maxSlippage, bool amountInPercent) = abi
            .decode(action.payload, (address, uint16, bool));
        IERC20 assetIn = IERC20(action.assetIn);
        uint256 amountIn = amountInPercent
            ? (assetIn.balanceOf(action.creator) * action.amountIn) / 10000
            : action.amountIn;

        uint256 _fee = (amountIn * protocolFee) / 10000;
        uint256 feeAmountsExec = execFee;

        if (action.assetIn != weth) {
            if (!hasPair(address(action.assetIn), address(weth))) {
                revert("NoPairForAssetInAndGas");
            }
            address[] memory feePath = new address[](2);
            feePath[0] = address(assetIn);
            feePath[1] = address(weth);
            uint[] memory feeAmounts = swapRouter.getAmountsIn(
                execFee,
                feePath
            );
            feeAmountsExec =
                (feeAmounts[0] * (uint256(maxSlippage) + 10000)) /
                10000;
        }
        //check if there is a pool for assetIn and assetOut
        if (!hasPair(address(action.assetIn), address(assetOut))) {
            revert("NoPairForAssetInAndAssetOut");
        }

        if ((feeAmountsExec + _fee) > amountIn) {
            revert("FeeGreaterThanAmountIn");
        }

        address[] memory swapPath = new address[](2);
        swapPath[0] = address(action.assetIn);
        swapPath[1] = address(assetOut);
        uint[] memory swapAmountsOut = swapRouter.getAmountsOut(
            amountIn - (feeAmountsExec + _fee),
            swapPath
        );
        quoteMinAmountOut =
            (swapAmountsOut[1] * (10000 - maxSlippage)) /
            10000;
    }
}