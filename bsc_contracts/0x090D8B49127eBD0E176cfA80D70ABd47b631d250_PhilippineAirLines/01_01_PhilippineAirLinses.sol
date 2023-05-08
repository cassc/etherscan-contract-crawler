// SPDX-License-Identifier: MIT
pragma solidity  0.8.18;

 /**

    * WelCome to PhilippineAirLines Token   
    * Dev Shakil Hossain    .
    
    
* PAL symbol
* Name PhilippineAirLines (PAL)
* Supply 180,000,000
* Max Buy Limit (0.1% Total Supply)
* Max Sell Limit (0.05% Total Supply)
* Anti-Whale Function (1% Total supply)
* Anti-Dump time limit 30 mins
* 6% Buy Fee Redistribution:
* 4% BUSD to holders.
* 1% Liquidity Pool.
* 1% towards Buy-Back & Burn.
* 8% Sell Fee Redistribution:
* 4% BUSD to holders.
* 1% Liquidity Pool.
* 2% towards Buy-Back & Burn.
* 1% Marketing and development
 * */


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



interface IPancakeRouter01 {
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
interface IPancakeRouter02 is IPancakeRouter01 {
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

interface IPancakeFactory {
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
interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract PhilippineAirLines is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string private constant _NAME = "PhilippineAirLines";
    string private constant _SYMBOL = "PAL";
    function decimals() public pure  override returns (uint8) {
    return 18;
}
function totalSupply() external view override returns (uint256) {
  return _TOTAL_SUPPLY;
}
  uint256  public _TOTAL_SUPPLY = 180000000 * 10**18;
    uint256 private _maxTxAmount = _TOTAL_SUPPLY.div(100); // 1% of total supply
      uint256 public maxBuyLimit = _TOTAL_SUPPLY / 1000; // 0.1% of total supply
    uint256 public maxSellLimit = _TOTAL_SUPPLY / 2000; // 0.05% of total supply
    uint256 public antiWhaleLimit = _TOTAL_SUPPLY / 100; // 1% of total supply
    uint256 public antiDumpTimeLimit = 1800; // 30 minutes in seconds
    mapping(address => uint256) private _lastTransactionTime;
     address private _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    // address public immutable wbnb;
    mapping(address => bool) private _isExcludedFromFee;
    bool private _feesEnabled = false;
    uint256 private _buyFee = 6;
    uint256 private _sellFee = 8;
    uint256 private _liquidityFee = 1;
    uint256 private _buyBackFee = 1;
    uint256 private _marketingFee = 1;
    uint256 private _totalFee = _buyFee.add(_sellFee);
    bool private _inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 private _maxTxPercent = 1;
    uint256 private _numTokensSellToAddToLiquidity = _maxTxAmount.mul(10).div(100); // 10% of maxTxAmount

    uint256 private _buyBackBalance;
    address private _buyBackAddress = 0x3C671913640Def4aa8DE9ADB4e6cf8907A2497C4;
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event BuyBack(uint256 amount);

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
event LiquidityAdded(uint256 tokenAmount, uint256 ethAmount, uint256 liquidity);

mapping(address => bool) private _isExcluded;
mapping(address => uint256) private _rOwned;
 mapping (address => uint256) private _tOwned;
uint256 private _rTotal;
uint256 private _tFeeTotal;
address[] private _excluded;
 uint256 private _previousBuyFee ;
uint256 private _previousSellFee;
uint256 private _previousLiquidityFee;
uint256 private _previousBuyBackFee;
uint256 private _previousMarketingFee;
uint256 constant MAX_FEE = 100;
uint256 private _maxWalletSize = 1000000 * 10**18;




IPancakeRouter02 public  pancakeRouter;

uint256 public  wbnb;
address public pancakePair;

function addressToUint256(address addr) internal pure returns (uint256) {
    return uint256(uint160(addr));
}


function tokenAddressToNumber(address tokenAddress) private pure returns (uint256) {
    return uint256(addressToUint256(tokenAddress));
}
 IPancakeFactory public pancakeFactory;
// PancakeSwap Factory contract address for Binance Smart Chain

address  private pancakeFactoryAddress =  0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    constructor(IPancakeRouter02  _pancakeRouter22) {
        _balances[_msgSender()] = _TOTAL_SUPPLY;
   // Set up PancakeSwap Router and Factory
  pancakeRouter = IPancakeRouter02(_pancakeRouter22);
  pancakeFactory = IPancakeFactory(pancakeFactoryAddress);


    wbnb = tokenAddressToNumber(pancakeRouter.WETH());

        // Create the pair for OU-WBNB
        pancakePair = IPancakeFactory(pancakeFactory).createPair(address(this), pancakeRouter.WETH());

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
         _owner = msg.sender;
    emit Transfer(address(0), _msgSender(), _TOTAL_SUPPLY);
}




function addressToNumber(address addr) internal pure returns (uint256) {
    return uint256(uint160(addr));
}

function name() public view virtual override returns (string memory) {
    return _NAME;
}

function symbol() public view virtual override returns (string memory) {
    return _SYMBOL;
}

function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
}

function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
}

function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
}

function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
}

function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
}

function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
}

function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFromFee[account];
}

function enableFees() public onlyOwner {
    _feesEnabled = true;
}

function disableFees() public onlyOwner {
    _feesEnabled = false;
}

function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner {
    _maxTxPercent = maxTxPercent;
    _maxTxAmount = _TOTAL_SUPPLY.mul(_maxTxPercent).div(10**2);
}

function setNumTokensSellToAddToLiquidity(uint256 numTokensSellToAddToLiquidity) public onlyOwner {
    _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
}

function setBuyFee(uint256 buyFee) public onlyOwner {
    _buyFee = buyFee;
    _totalFee = _buyFee.add(_sellFee);
}

function setSellFee(uint256 sellFee) public onlyOwner {
    _sellFee = sellFee;
    _totalFee = _buyFee.add(_sellFee);
}

function setLiquidityFee(uint256 liquidityFee) public onlyOwner {
    _liquidityFee = liquidityFee;
}

function setBuyBackFee(uint256 buyBackFee) public onlyOwner {

    _buyBackFee = buyBackFee;
}

function setMarketingFee(uint256 marketingFee) public onlyOwner {
    _marketingFee = marketingFee;
}


function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
}

function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
}

address private _marketingAddress = 0x3C671913640Def4aa8DE9ADB4e6cf8907A2497C4;
function setMarketingAddress(address marketingAddress) public onlyOwner {
    _marketingAddress = marketingAddress;
}

function setBuyBackAddress(address buyBackAddress) public onlyOwner {
    _buyBackAddress = buyBackAddress;
}

function deliver(uint256 tAmount) public {
    address sender = _msgSender();
    require(!_isExcluded[sender], "Excluded addresses cannot call this function");
    (uint256 rAmount,,,,,) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
}

function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
    require(tAmount <= _TOTAL_SUPPLY, "Amount must be less than supply");
    if (!deductTransferFee) {
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        return rAmount;
    } else {
        (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
        return rTransferAmount;
    }
}

function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");
    uint256 currentRate = _getRate();
    return rAmount.div(currentRate);
}

function excludeFromReward(address account) public onlyOwner() {
    require(!_isExcluded[account], "Account is already excluded");
    if (_rOwned[account] > 0) {
        _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
}

function includeInReward(address account) external onlyOwner() {
    require(_isExcluded[account], "Account is already included");
    for (uint256 i = 0; i < _excluded.length; i++) {
        if (_excluded[i] == account) {
            _excluded[i] = _excluded[_excluded.length - 1];
            _tOwned[account] = 0;
            _isExcluded[account] = false;
            _excluded.pop();
            break;
        }
    }
}

function restoreAllFee() private {
    _buyFee = _previousBuyFee;
    _sellFee = _previousSellFee;
    _liquidityFee = _previousLiquidityFee;
    _buyBackFee = _previousBuyBackFee;
    _marketingFee = _previousMarketingFee;

    _totalFee = _buyFee.add(_sellFee).add(_liquidityFee).add(_buyBackFee).add(_marketingFee);
}


function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tBuyBack, uint256 tMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    uint256 rBuyBack = tBuyBack.mul(currentRate);
    uint256 rMarketing = tMarketing.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rBuyBack).sub(rMarketing);
    return (rAmount, rTransferAmount, rFee);
}

function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
}

function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _TOTAL_SUPPLY;

    for (uint256 i = 0; i < _excluded.length; i++) {
        if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _TOTAL_SUPPLY);
        rSupply = rSupply.sub(_rOwned[_excluded[i]]);
        tSupply = tSupply.sub(_tOwned[_excluded[i]]);

}

if (rSupply < _rTotal.div(_TOTAL_SUPPLY)) return (_rTotal, _TOTAL_SUPPLY);

return (rSupply, tSupply);
}

function _takeFee(uint256 amount, uint8 feeType) private {
uint256 currentRate = _getRate();
uint256 rAmount = amount.mul(currentRate);
uint256 rFee = rAmount.mul(feeType).div(MAX_FEE);
uint256 tFee = amount.mul(feeType).div(MAX_FEE);
_rTotal = _rTotal.sub(rFee);
if (feeType == _buyFee) {
_rOwned[address(this)] = _rOwned[address(this)].add(rFee);
emit Transfer(msg.sender, address(this), tFee);
} else {
_rOwned[address(0)] = _rOwned[address(0)].add(rFee.div(2));
_rOwned[address(this)] = _rOwned[address(this)].add(rFee.div(2));
emit Transfer(msg.sender, address(this), tFee.div(2));
}
}
struct Fees {
    uint256 tFeeBuy;
    uint256 tFeeSell;
    // add more fee variables here
}



function _getValues(uint256 tAmount) private view returns (
  uint256 rAmount,
  uint256 rTransferAmount,
  uint256 rFeeBuy,
  uint256 rFeeSell,
  uint256 tTransferAmount,
  uint256 tFeeTotal
) {
 
  uint256 currentRate = _getRate();
  rAmount = tAmount.mul(currentRate);
  rFeeBuy = rAmount.mul(_buyFee).div(MAX_FEE);
  rFeeSell = rAmount.mul(_sellFee).div(MAX_FEE);
  tFeeTotal = tAmount.mul(_buyFee.add(_sellFee)).div(MAX_FEE);
  tTransferAmount = tAmount.sub(tFeeTotal);
  rTransferAmount = rAmount.sub(rFeeBuy).sub(rFeeSell);
}




  function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Anti-Whale Function
        if (recipient != _owner && amount > antiWhaleLimit) {
            require(amount <= antiWhaleLimit, "Transfer amount exceeds anti-whale limit");
        }

        // Anti-Dump Function
        uint256 timeSinceLastTransaction = block.timestamp - _lastTransactionTime[sender];
        if (timeSinceLastTransaction < antiDumpTimeLimit) {
            require(amount <= maxBuyLimit, "Transfer amount exceeds max buy limit during anti-dump time limit");
        } else {
            require(amount <= maxSellLimit, "Transfer amount exceeds max sell limit");
        }
        _lastTransactionTime[sender] = block.timestamp;

        // Transfer tokens
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Insufficient balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }




function _takeFee(uint256 rAmount, uint256 fee) private {
    uint256 tAmount = rAmount.mul(fee).div(10**2);
    _rOwned[address(this)] = _rOwned[address(this)].add(tAmount);
    if (_isExcluded[address(this)])
        _tOwned[address(this)] = _tOwned[address(this)].add(tAmount);
}



function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
if (!takeFee) {
removeAllFee();
}
// calculate transfer values and fees
(uint256 rAmount, uint256 rTransferAmount, uint256 rFeeBuy, uint256 rFeeSell, uint256 tTransferAmount, uint256 tFee) =
    _getValues(amount);

// update balances
_rOwned[sender] = _rOwned[sender].sub(rAmount);
_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

// take fees
if (takeFee) {
    if (recipient == pancakePair) {
        _takeFee(rAmount, _sellFee);
    } else {
        _takeFee(rAmount, _buyFee);
    }
}

// transfer event
emit Transfer(sender, recipient, tTransferAmount);

// handle fees
_handleFees(rFeeBuy, rFeeSell, tFee);
}



function setMaxBuyLimit(uint256 newLimit) public onlyOwner {
        maxBuyLimit = newLimit;
    }

 function setMaxSellLimit(uint256 newLimit) public onlyOwner {
        maxSellLimit = newLimit;
    }

 
address private _busdHolderAddress = 0x3C671913640Def4aa8DE9ADB4e6cf8907A2497C4;
function setBUSDAddr(address _busdaddr) public onlyOwner{
    _busdHolderAddress = _busdaddr;
}
uint256 private constant BUSD_DIVISOR = 10**18; // Initialize to the appropriate value


function _handleFees(uint256 rFeeBuy, uint256 rFeeSell, uint256 tFee) private {
// transfer buy fees to BUSD holder and liquidity pool
if (rFeeBuy > 0) {
uint256 tFeeBuy = tFee.div(2);
_rOwned[address(this)] = _rOwned[address(this)].add(rFeeBuy);
_transferStandard(address(this), _busdHolderAddress, tFeeBuy.mul(BUSD_DIVISOR).div(_TOTAL_SUPPLY));
_addLiquidity(rFeeBuy.div(2));
}

// transfer sell fees to BUSD holder, marketing & development, and liquidity pool
if (rFeeSell > 0) {
    uint256 tFeeSell = tFee.div(2);
    uint256 tMarketing = tFeeSell.div(2);
    _rOwned[address(0)] = _rOwned[address(0)].add(rFeeSell.div(2));
    _rOwned[address(this)] = _rOwned[address(this)].add(rFeeSell.div(2));
    _transferStandard(address(this), _busdHolderAddress, tFeeSell.sub(tMarketing).mul(BUSD_DIVISOR).div(_TOTAL_SUPPLY));
    _transferStandard(address(this), _marketingAddress, tMarketing.mul(BUSD_DIVISOR).div(_TOTAL_SUPPLY));
    _addLiquidity(rFeeSell.div(2));
}

}

function _transferStandard(address sender, address recipient, uint256 tAmount) private {
uint256 currentRate = _getRate();
uint256 rAmount = tAmount.mul(currentRate);
_rOwned[sender] = _rOwned[sender].sub(rAmount);
_rOwned[recipient] = _rOwned[recipient].add(rAmount);
emit Transfer(sender, recipient, tAmount);
}

function swapTokensForBnb(uint256 tokenAmount) private {
    
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pancakeRouter.WETH();

    // approve the PancakeSwap router to spend the tokenAmount
    _approve(address(this), address(pancakeRouter), tokenAmount);

    
    pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        0, // accept any amount of BNB
        path,
        address(this),
        block.timestamp
    );
}

function _addLiquidity(uint256 tokenAmount) private {
    uint256 halfTokenAmount = tokenAmount.div(2);
    uint256 otherHalfTokenAmount = tokenAmount.sub(halfTokenAmount);

    // remember the initial balance of the contract
    uint256 initialBalance = address(this).balance;

    // swap half of the tokens for BNB
    swapTokensForBnb(halfTokenAmount);

    // calculate the new BNB balance of the contract
    uint256 newBalance = address(this).balance.sub(initialBalance);

    // approve token transfer to PancakeSwap router
    _approve(address(this), address(pancakeRouter), otherHalfTokenAmount);

    // add liquidity to PancakeSwap pool
    pancakeRouter.addLiquidityETH{value: newBalance}(
        address(this),
        otherHalfTokenAmount,
        0, // slippage is unavoidable
        0, // slippage is unavoidable
        owner(), // send liquidity tokens to the contract owner
        block.timestamp + 3600
    );

    // emit liquidity added event
    emit LiquidityAdded(tokenAmount, newBalance, otherHalfTokenAmount);
}



function calculateTaxFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_totalFee).div(10**2).mul(_sellFee).div(_totalFee);
}

function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_totalFee).div(10**2).mul(_liquidityFee).div(_totalFee);
}

function calculateBuyBackFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_totalFee).div(10**2).mul(_buyBackFee).div(_totalFee);
}

function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(_totalFee).div(10**2).mul(_marketingFee).div(_totalFee);
}


function removeAllFee() private {
    if (_buyFee == 0 && _sellFee == 0 && _liquidityFee == 0 && _buyBackFee == 0 && _marketingFee == 0) return;

    _previousBuyFee = _buyFee;
    _previousSellFee = _sellFee;
    _previousLiquidityFee = _liquidityFee;
    _previousBuyBackFee = _buyBackFee;
    _previousMarketingFee = _marketingFee;

    _buyFee = 0;
    _sellFee = 0;
    _liquidityFee = 0;
    _buyBackFee = 0;
    _marketingFee = 0;
    _totalFee = 0;
}

function setFeeRates() private {
    if (_TOTAL_SUPPLY == _TOTAL_SUPPLY) {
        _liquidityFee = 1;
        _sellFee = 8;
        _buyBackFee = 6;
        _marketingFee = 1;
    } else {
        _sellFee = 8;
        _liquidityFee = 1;
        _buyBackFee = 6;
        _marketingFee = 1;
    }
}


function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(amount > 0, "Transfer amount must be greater than zero");
    if (_isExcludedFromFee[_msgSender()] || _isExcludedFromFee[recipient]) {
        removeAllFee();
    } else {
        require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        require(balanceOf(recipient) + amount <= _maxWalletSize, "Wallet balance exceeds the maxWalletSize");
        require(balanceOf(address(this)) >= amount.mul(_liquidityFee.add(_buyBackFee).add(_marketingFee)).div(_totalFee), "Insufficient liquidity or buyback or marketing tokens in the contract");
        setFeeRates();
    }
    
    _transfer(_msgSender(), recipient, amount);

    return true;
}

address private _marketingWalletAddress = 0x3C671913640Def4aa8DE9ADB4e6cf8907A2497C4;
function setMarketingWal( address _mkaddr) public onlyOwner{
    _marketingWalletAddress = _mkaddr;
}
event BuyBackAndMarketingFees(uint256 buyBackAmount, uint256 marketingAmount);
 event EBuyBackFee(uint256 amount, uint256 buyBackBalance);
function buyBackTokens(uint256 amount) private {
    if (amount > 0) {
        uint256 initialBalance = address(this).balance;
        buyBackTokens(amount);
        uint256 newBalance = address(this).balance;
        uint256 buyBackBalance = newBalance.sub(initialBalance);
        emit EBuyBackFee(amount, buyBackBalance);
    }
}

function _buyBackAndMarketingFee(uint256 tBuyBackMarketing) private {
    uint256 currentBalance = address(this).balance;
    if (currentBalance >= tBuyBackMarketing) {
        uint256 buyBackAmount = tBuyBackMarketing.mul(_buyBackFee).div(_buyBackFee.add(_marketingFee));
        uint256 marketingAmount = tBuyBackMarketing.sub(buyBackAmount);
        buyBackTokens(buyBackAmount);
        payable(_marketingWalletAddress).transfer(marketingAmount);
        emit BuyBackAndMarketingFees(buyBackAmount, marketingAmount);
    } else {
        emit BuyBackAndMarketingFees(0, 0);
    }
}

function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
}

function _takeLiquidity(uint256 tLiquidity) private {
    uint256 currentRate = _getRate();
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if (_isExcluded[address(this)]) {
        _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    emit Transfer(msg.sender, address(this), tLiquidity);
}

function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
    uint256 tFee = calculateTaxFee(tAmount);
    uint256 tLiquidity = calculateLiquidityFee(tAmount);
    uint256 tBuyBackMarketing = calculateBuyBackFee(tAmount).add(calculateMarketingFee(tAmount));
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tBuyBackMarketing);
    return (tTransferAmount, tFee, tLiquidity, tBuyBackMarketing);
}

function _approve(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
}

function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
    if (from == address(0)) { // mint
        _TOTAL_SUPPLY = _TOTAL_SUPPLY.add(amount);
    } else if (to == address(0)) { // burn
        _TOTAL_SUPPLY = _TOTAL_SUPPLY.sub(amount);
    }
}


}