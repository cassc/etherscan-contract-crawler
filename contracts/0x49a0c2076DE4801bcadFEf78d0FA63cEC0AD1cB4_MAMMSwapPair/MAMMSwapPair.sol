/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


// 
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

// 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// 
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)
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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// 
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// 
// Forked from https://github.com/compound-finance/open-oracle/blob/master/contracts/Uniswap/UniswapLib.sol
// Based on code from https://github.com/Uniswap/uniswap-v2-periphery
// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // returns a uq112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << 112) / denominator);
    }

    // decode a uq112x112 into a uint with 18 decimals of precision
    function decode112with18(uq112x112 memory self) internal pure returns (uint) {
        // we only have 256 - 224 = 32 bits to spare, so scaling up by ~60 bits is dangerous
        // instead, get close to:
        //  (x * 1e18) >> 112
        // without risk of overflowing, e.g.:
        //  (x) / 2 ** (112 - lg(1e18))
        return uint(self._x) / 5192296858534827;
    }
}

// 
interface IMAMMSwapPair {
    function pause() external;
    function unpause() external;
    function setNewReordersController(address _reordersController) external;
    function addLiquidity() external;
    function removeLiquidity(uint amount0, uint amount1) external;
    function sync() external;
    function mintFee() external;
    function pavAllocation(
        uint newMMFRewards0, 
        uint newMMFRewards1, 
        uint newRainyDayFunds, 
        uint newProtocolFees
    ) external;
    function migrate(address to) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function getTiUSDPrice() external view returns (uint256, bool);
    function getMMFFunds() external view returns (uint _mmfFund0, uint _mmfFund1, uint32 _blockTimestampLast);
    function getDepth() external view returns (uint112 _fund0, uint112 _fund1, uint32 _blockTimestampLast);
}

// 
/**
 * @dev Fixed window oracle that recomputes the average price for the entire period once every period.
 * Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period.
 */
contract TiTiOracles {
    using FixedPoint for *;

    /// @notice The TWAP's calculation period.
    uint public period = 1 hours;

    /// @notice Sum of cumulative prices denominated in USDC.
    uint public price0CumulativeLast;

    /// @notice Sum of cumulative prices denominated in TiUSD.
    uint public price1CumulativeLast;

    /// @notice Last recorded cumulative prices denominated in USDC.
    uint public priorCumulative;

    /// @notice TiUSD's average price denominated in USDC.
    FixedPoint.uq112x112 public priceAverage;

    /// @notice Last update timestamp.
    uint32 public lastOracleUpdateTime;

    /// @notice Precision conversion to normalize USDC and TiUSD units.
    uint256 private constant BASE_TOKEN_DECIMALS_MULTIPLIER = 1e12;

    function _updatePrice(uint32 blockTimestamp) internal {
        if (lastOracleUpdateTime == 0) {
            lastOracleUpdateTime = blockTimestamp;
        } else {
            uint32 timeElapsed;
            
            unchecked {
                timeElapsed = blockTimestamp - lastOracleUpdateTime; // overflow is desired
            }

            // ensure that at least one full period has passed since the last update
            if (timeElapsed >= period) {
                uint256 currentCumulative = price0CumulativeLast;
            
                unchecked {
                    // overflow is desired, casting never truncates
                    // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
                    priceAverage = FixedPoint.uq112x112(uint224((currentCumulative - priorCumulative) / timeElapsed));
                }

                priorCumulative = currentCumulative;
                lastOracleUpdateTime = blockTimestamp;
            }            
        }
    }

    function _resetPrice() internal {
        // reset twap to $1
        priceAverage = FixedPoint.uq112x112(uint224(2**112) / uint224(1e12));
    }

    /// @notice Get TiUSD's average price denominated in USDC.
    /// @return tiusdPriceMantissa TiUSD price with 18-bit precision.
    /// @return isValid Whether the return TiUSD price is valid.
    function _getTiUSDPrice() internal view returns (uint256 tiusdPriceMantissa, bool isValid) {
        tiusdPriceMantissa = priceAverage.decode112with18() * BASE_TOKEN_DECIMALS_MULTIPLIER;
        isValid = tiusdPriceMantissa > 0;
    }
}

// 
// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// 
// Sourced from the Uniswap v2 code base
// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
// range: [0, 2**112 - 1]
// resolution: 1 / 2**112
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// 
interface IReOrdersController {
    function sync() external;
    function pause() external;
    function unpause() external;
    function setNewMAMM(address _mamm) external;
    function setNewMMF(address _mmf) external;
    function setNewPegPrice(uint256 _pegPrice) external;
    function setNewDuration(uint256 _duration) external;
    function setNewAllocation(
        uint256 _mmfRewardsAllocation, 
        uint256 _rainyDayFundAllocation, 
        uint256 _protocolFeeAllocation,
        address _rainyDayFundVault, 
        address _protocolFeeVault
    ) external;
    function setNewCoreController(address _coreController) external;
    function reorders() external;
    function rainyDayFundVault() external view returns (address);
    function protocolFeeVault() external view returns (address);
    function PEG_PRICE() external view returns (uint256 _pegPrice);
}

// 
/// @title The MAMM module of TiTi Protocol
/// @author TiTi Protocol
/// @notice The module implements the related functions of MAMM.
/// @dev Only the owner can call the params' update function, the owner will be transferred to Timelock in the future.
contract MAMMSwapPair is Ownable, Pausable, TiTiOracles, ReentrancyGuard {
    using UQ112x112 for uint224;
    using SafeERC20 for IERC20;

    /// @notice MAX_UINT112.
    uint112 private constant MAX_UINT112 = type(uint112).max;

    /// @notice MarketMakerFund contract address.
    address public immutable mmf;

    /// @notice ReOrdersController contract address.
    address public reordersController;

    /// @notice The address used to receive swap fees.
    address public feeTo;

    /// @notice Whether to charge swap fees.
    bool public feeOn;

    /// @notice TiUSD contract address.
    IERC20 public immutable token0;

    /// @notice USDC contract address.
    IERC20 public immutable token1;

    /// @notice TiUSD balance.
    uint112 private fund0;       

    /// @notice USDC balance.    
    uint112 private fund1;

    /// @notice Last update timestamp. 
    uint32  private blockTimestampLast;

    /// @notice Last MMF's TiUSD staked amount in MAMM.
    uint private mmfFund0;

    /// @notice Last MMF's USDC staked amount in MAMM.
    uint private mmfFund1;
    
    /// @notice fund0 * fund1, as of immediately after the most recent liquidity event.
    uint public kLast;

    /// @notice Whether to allow contracts to call the function.
    bool public isAllowedContractsCall;

    /// @notice Emitted when users add liquidity through MarketMakerFund.
    event AddLiquidity(uint amount0, uint amount1);

    /// @notice Emitted when users remove liquidity through MarketMakerFund.
    event RemoveLiquidity(uint amount0, uint amount1);

    /// @notice Emitted when users mint TiUSD.
    event Mint(address indexed sender, uint baseTokenAmount, uint tiusdAmount);

    /// @notice Emitted when users redeem USDC.
    event Redeem(address indexed sender, uint baseTokenAmount, uint tiusdAmount);

    /// @notice Emitted when the fund0 and fund1 are updated.
    event Sync(uint112 fund0, uint112 fund1);

    /// @notice Emitted when new reordersController is set.
    event NewReordersController(address oldAddr, address newAddr);

    /// @notice Emitted when new feeTo address is set.
    event NewFeeTo(address oldFeeTo, address newFeeTo);

    /// @notice Emitted when new twap period is set.
    event NewTWAPPeriod(uint256 period);

    /// @notice Emitted when the isAllowedContractsCall is updated.
    event IsAllowedContractsCall(bool isAllowed);

    /// @notice Emitted when PAV allocation is triggered.
    event PAVAllocation(
        uint mmfRewards,
        uint rainyDayFunds,
        uint protocolFees,
        uint blockTimestampLast
    );

    constructor(
        IERC20 _token0,
        IERC20 _token1,
        address _mmf
    ) {
        token0 = _token0;
        token1 = _token1;
        mmf = _mmf;
    }

    modifier onlyEOA() {
        if (!isAllowedContractsCall) {
            require(tx.origin == msg.sender, "MAMMSwapPair: Not EOA");
        }
        _;
    }

    modifier onlyReordersController() {
        require(msg.sender == reordersController, "MAMMSwapPair: Not ReordersController");
        _;
    }

    modifier onlyMMF() {
        require(msg.sender == mmf, "MAMMSwapPair: Not Matched MMF");
        _;
    }

    /// @notice Set a new address to receive swap fees.
    /// @param _feeTo New address to receive swap fees.
    function setFeeTo(address _feeTo) external onlyOwner {
        address oldFeeTo = feeTo;
        feeTo = _feeTo;
        feeOn = feeTo != address(0);
        emit NewFeeTo(oldFeeTo, _feeTo);
    }

    /// @notice Set a new period for the TWAP window.
    /// @param _period New period for the TWAP window.
    function setPeriod(uint256 _period) external onlyOwner {
        require(_period != 0, "MAMMSwapPair: Cannot be zero");
        period = _period;
        emit NewTWAPPeriod(_period);
    }

    /// @notice Set the isAllowedContractsCall.
    /// @param _isAllowed Is to allow contracts to call.
    function setIsAllowedContractsCall(bool _isAllowed) external onlyOwner {
        isAllowedContractsCall = _isAllowed;
        emit IsAllowedContractsCall(_isAllowed);
    }

    /// @notice Set a new ReOrdersController contract.
    /// @param _reordersController New ReOrdersController contract address.
    function setNewReordersController(address _reordersController) external onlyOwner {
        require(_reordersController != address(0), "MAMMSwapPair: Cannot be address(0)");
        address oldReorders = reordersController;
        reordersController = _reordersController;
        emit NewReordersController(oldReorders, _reordersController);
    }

    /// @notice Receive swap fees.
    /// @dev Only ReOrdersController can call this function
    /// Since ReOrders will change K, it is necessary to complete the collection of the previous round of swap fee
    /// before executing ReOrders each time.
    function mintFee() external nonReentrant onlyReordersController {
        uint _kLast = kLast; // gas savings
        uint112 _fund0 = fund0;
        uint112 _fund1 = fund1;
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Babylonian.sqrt(uint(_fund0) * uint(_fund1));
                uint rootKLast = Babylonian.sqrt(_kLast);
                // When the swap fee is turned on, all swap fees will be included in the protocol fee
                if (rootK > rootKLast) {
                    uint amount0 = uint(_fund0) * (rootK - rootKLast) / rootK;
                    uint amount1 = uint(_fund1) * (rootK - rootKLast) / rootK;
                    token0.safeTransfer(feeTo, amount0);
                    token1.safeTransfer(feeTo, amount1);
                    
                    uint balance0 = token0.balanceOf(address(this));
                    uint balance1 = token1.balanceOf(address(this));

                    _update(balance0, balance1, _fund0, _fund1);
                    kLast = uint(fund0) * fund1; // fund0 and fund1 are up-to-date
                    
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    /// @notice Users add liquidity through MarketMakerFund.
    /// @dev Only MMF can call this function.
    function addLiquidity() external nonReentrant onlyMMF {
        uint112 _fund0 = fund0;
        uint112 _fund1 = fund1;
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        uint amount0 = balance0 - _fund0;
        uint amount1 = balance1 - _fund1;

        mmfFund0 += amount0;
        mmfFund1 += amount1;

        _update(balance0, balance1, _fund0, _fund1);

        if (feeOn) 
            kLast = uint(fund0) * fund1;

        emit AddLiquidity(amount0, amount1);
    }

    /// @notice Users remove liquidity through MarketMakerFund.
    /// @dev Only MMF can call this function.
    function removeLiquidity(uint _amount0, uint _amount1) external nonReentrant onlyMMF {
        uint112 _fund0 = fund0;
        uint112 _fund1 = fund1;
        IERC20 _token0 = token0;
        IERC20 _token1 = token1;
        
        _token0.safeTransfer(mmf, _amount0);
        _token1.safeTransfer(mmf, _amount1);

        uint balance0 = _token0.balanceOf(address(this));
        uint balance1 = _token1.balanceOf(address(this));

        mmfFund0 = mmfFund0 - _amount0;
        mmfFund1 = mmfFund1 - _amount1;

        _update(balance0, balance1, _fund0, _fund1);

        if (feeOn) 
            kLast = uint(fund0) * fund1;
        
        emit RemoveLiquidity(_amount0, _amount1);
    }

    /// @notice Users mint TiUSD by USDC.
    /// @param _amount Amount of USDC spent by users.
    function mint(uint256 _amount) external onlyEOA nonReentrant whenNotPaused {
        (uint256 _fund0, uint256 _fund1,) = getDepth();
        uint256 tiusdOut = _getAmountOut(_amount, _fund1, _fund0);
        token1.safeTransferFrom(msg.sender, address(this), _amount);
        _swap(tiusdOut, 0, msg.sender);   
        emit Mint(msg.sender, _amount, tiusdOut);
    }

    /// @notice Users redeem USDC by TiUSD.
    /// @param _amount Amount of TiUSD spent by users.
    function redeem(uint256 _amount) external onlyEOA nonReentrant whenNotPaused {
        (uint256 _fund0, uint256 _fund1,) = getDepth();
        uint256 baseTokenOut = _getAmountOut(_amount, _fund0, _fund1);
        token0.safeTransferFrom(msg.sender, address(this), _amount);
        _swap(0, baseTokenOut, msg.sender);
        emit Redeem(msg.sender, baseTokenOut, _amount);
    }

    /// @notice Match the requirements of reorders and update the global parameters.
    function sync() external nonReentrant whenNotPaused onlyReordersController {
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)), fund0, fund1);
        if (feeOn) kLast = uint(fund0) * fund1;
        _resetPrice();
    }

    /// @notice Update global parameters based on the latest balance.
    function updateOraclePrice() external nonReentrant whenNotPaused {
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)), fund0, fund1);
    }

    /// @notice Allocate PAV funds, this function is called by OrdersController in _reorders(), and its purpose is as follows:
    /// 1. It is used to complete the profit sharing for MMF participants. Since the total amount of shares is recorded in MMF, 
    /// only mmfFund0 and mmfFund1 need to be updated to distribute profits to participants;
    /// 2. Used to transfer part of USDC to rainyDayFund
    /// 3. Used to transfer part of USDC to protocolFeeVault
    /// @param _newMMFRewards0 The amount of TiUSD that needs to be allocated to MMF in PAV.
    /// @param _newMMFRewards1 The amount of USDC that needs to be allocated to MMF in PAV.
    /// @param _newRainyDayFunds The amount of USDC that needs to be withdrawn for rainy day fund in PAV.
    /// @param _newProtocolFees The amount of USDC that needs to be withdrawn for protocol fee in PAV.
    function pavAllocation(   
        uint _newMMFRewards0, 
        uint _newMMFRewards1, 
        uint _newRainyDayFunds, 
        uint _newProtocolFees
    ) 
        external 
        nonReentrant 
        onlyReordersController 
        whenNotPaused 
    {
        IERC20 _token = token1;
        uint newMMFRewards = _newMMFRewards1;
        // Since MMF is recorded by share, we can update mmfFund directly to complete the profit sharing
        mmfFund0 = mmfFund0 + _newMMFRewards0;
        mmfFund1 = mmfFund1 + _newMMFRewards1;

        address _rainyDayFundVault = IReOrdersController(reordersController).rainyDayFundVault();
        address _protocolFeeVault = IReOrdersController(reordersController).protocolFeeVault();
        
        _token.safeTransfer(_rainyDayFundVault, _newRainyDayFunds);
        _token.safeTransfer(_protocolFeeVault, _newProtocolFees);
        
        emit PAVAllocation(newMMFRewards, _newRainyDayFunds, _newProtocolFees, block.timestamp);
    }

    /// @notice Pause the whole system.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the whole system.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get the lastest MMF's TiUSD and USDC staked amount in MAMM.
    function getMMFFunds() external view returns (uint, uint, uint32) {
        return (mmfFund0, mmfFund1, blockTimestampLast);
    }

    /// @notice Get TiUSD's average price denominated in USDC.
    /// @return tiusdPriceMantissa TiUSD price with 18-bit precision.
    /// @return isValid Whether the return TiUSD price is valid.
    function getTiUSDPrice() external view whenNotPaused returns (uint256 tiusdPriceMantissa, bool isValid) {
        (tiusdPriceMantissa, isValid) = _getTiUSDPrice();
    }

    /// @notice Get the lastest MAMM's TiUSD and USDC depth.
    function getDepth() public view returns (uint112, uint112, uint32) {
        return (fund0, fund1, blockTimestampLast);
    }

    /// @notice Perform swap operation
    /// @dev this low-level function should be called from a contract which performs important safety checks
    function _swap(uint _amount0Out, uint _amount1Out, address _to) internal {
        require(_amount0Out > 0 || _amount1Out > 0, 'MAMMSwapPair: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _fund0, uint112 _fund1,) = getDepth(); // gas savings

        // Redeem cannot lose MMF's Fund, because currently MMF's Fund is only used to increase depth
        bool isSufficient = _amount0Out <= _fund0 && _amount1Out <= uint(_fund1) - mmfFund1;

        require(isSufficient, 'MAMMSwapPair: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
            IERC20 _token0 = token0;
            IERC20 _token1 = token1;
            require(_to != address(_token0) && _to != address(_token1) && _to != address(this), 'MAMMSwapPair: INVALID_TO');

            if (_amount0Out > 0) _token0.safeTransfer(_to, _amount0Out);
            if (_amount1Out > 0) _token1.safeTransfer(_to, _amount1Out);

            balance0 = _token0.balanceOf(address(this));
            balance1 = _token1.balanceOf(address(this));
        }

        uint amount0In = balance0 > _fund0 - _amount0Out ? balance0 - (_fund0 - _amount0Out) : 0;
        uint amount1In = balance1 > _fund1 - _amount1Out ? balance1 - (_fund1 - _amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'MAMMSwapPair: INSUFFICIENT_INPUT_AMOUNT');
        
        { // scope for funds{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0 * 1000 - (amount0In * 3);
            uint balance1Adjusted = balance1 * 1000 - (amount1In * 3);
            require(balance0Adjusted * balance1Adjusted >= uint(_fund0) * uint(_fund1) * 1000**2, 'MAMMSwapPair: K');
        }

        _update(balance0, balance1, _fund0, _fund1);   
    }
    
    /// @notice According to k = x * y, calculate the amount of tokenOut obtained in the swap process.
    function _getAmountOut(
        uint _amountIn,
        uint _fundIn,
        uint _fundOut
    )
        internal
        pure
        returns (uint amountOut)
    {
       require(_amountIn > 0, 'MAMMSwapPair: INSUFFICIENT_INPUT_AMOUNT');
       require(_fundIn > 0 && _fundOut > 0, 'MAMMSwapPair: INSUFFICIENT_LIQUIDITY');
       uint amountInWithFee = _amountIn * 997;
       uint numerator = amountInWithFee * _fundOut;
       uint denominator = _fundIn * 1000 + amountInWithFee;
       amountOut = numerator / denominator;
    }

    function _update(uint _balance0, uint _balance1, uint112 _fund0, uint112 _fund1) private {
        require(_balance0 <= MAX_UINT112 && _balance1 <= MAX_UINT112, 'MAMMSwapPair: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);

        unchecked {
            uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

            if (timeElapsed > 0 && _fund0 != 0 && _fund1 != 0) {

                // * never overflows, and + overflow is desired
                price0CumulativeLast += uint(UQ112x112.encode(_fund1).uqdiv(_fund0)) * timeElapsed;
                price1CumulativeLast += uint(UQ112x112.encode(_fund0).uqdiv(_fund1)) * timeElapsed;
                
            }
        }
        // Update TiUSD's TWAP
        _updatePrice(blockTimestamp);

        fund0 = uint112(_balance0);
        fund1 = uint112(_balance1);
        blockTimestampLast = blockTimestamp;

        emit Sync(fund0, fund1);
    }
}