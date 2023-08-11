/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Interface an aggregator needs to adhere.
interface IAggregatorV3Interface {
    /// @notice decimals used by the aggregator
    function decimals() external view returns (uint8);

    /// @notice aggregator's description
    function description() external view returns (string memory);

    /// @notice aggregator's version
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    /// @notice get's round data for requested id
    function getRoundData(
        uint80 id
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    /// @notice get's latest round data
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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
     * ////IMPORTANT: The same issues {IERC20-approve} has related to transaction
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

library OracleMath {
    
    function process(
        address oracle,
        uint256 twapTimeInterval,
        uint8 tokenDecimals,
        uint256 tokenAmount
    ) internal view returns (uint256 usdValue) {
        IAggregatorV3Interface chainlink = IAggregatorV3Interface(oracle);
        (uint80 roundId, int256 price,,,) = chainlink.latestRoundData();
        uint256 oracleDecimals = chainlink.decimals();

        int256 finalPriceInt = twapTimeInterval == 0
            ? price
            : getTwapPrice(chainlink, roundId, price, twapTimeInterval);

        uint256 finalPrice;

        if (oracleDecimals > tokenDecimals) {
            finalPrice = uint256(finalPriceInt) / 10**(oracleDecimals - tokenDecimals);
        } else if (oracleDecimals < tokenDecimals) {
            finalPrice = uint256(finalPriceInt) * 10**(tokenDecimals - oracleDecimals);
        } else {
            finalPrice = uint256(finalPriceInt);
        }

        // Adjust usdValue to have 18 decimal places
        usdValue = (tokenAmount * finalPrice * 10**(18 - tokenDecimals)) / (10**tokenDecimals);

        return usdValue;
    }

    function getPrice(
        address oracle,
        uint8 tokenDecimals
    ) internal view returns (uint256 finalPrice) {
        IAggregatorV3Interface chainlink = IAggregatorV3Interface(oracle);
        (, int256 price,,,) = chainlink.latestRoundData();
        uint256 oracleDecimals = chainlink.decimals();

        if (oracleDecimals > tokenDecimals) {
            finalPrice = uint256(price) / 10**(oracleDecimals - tokenDecimals);
        } else if (oracleDecimals < tokenDecimals) {
            finalPrice = uint256(price) * 10**(tokenDecimals - oracleDecimals);
        } else {
            finalPrice = uint256(price);
        }
    }

    function getTwapPrice(
        IAggregatorV3Interface chainlink,
        uint80 latestRoundId,
        int256 latestPrice,
        uint256 twapTimeInterval
    ) internal view returns (int256 price) {
        int256 priceSum = latestPrice;
        uint256 priceCount = 1;

        uint256 startTime = block.timestamp - twapTimeInterval;

        while (latestRoundId > 0) {
            try chainlink.getRoundData(--latestRoundId) returns (
                uint80,
                int256 answer,
                uint256,
                uint256 updatedAt,
                uint80
            ) {
                if (updatedAt < startTime) {
                    break;
                }
                priceSum += answer;
                priceCount++;
            } catch {
                break;
            }
        }

        return priceSum / int256(priceCount);
    }
}

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

interface IParaSwapAugustus {
  function getTokenTransferProxy() external view returns (address);
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

interface IOracleRegistry{
    function getSupportedOracle(address) external view returns (address);
}

interface ITokenRegistry {
    function getSupportedToken(address) external view returns (bool);
}

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), '0 address');
        emit OwnershipTransferred(owner, newOwner);    
        owner = newOwner;
    }
}

/**
 * @notice FractBaseStrategy should be inherited by new strategies.
 */
abstract contract FractBaseStrategy is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    address constant PARASWAP = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    address constant NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 constant BIPS_DIVISOR = uint256(10000);
    uint256 constant ONE_ETHER = uint256(10 ** 18);

    /*///////////////////////////////////////////////////////////////
                        Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes the contract setting the deployer as the operator.
     */
    constructor() {
        _operator = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                        Receive
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                        State Variables
    //////////////////////////////////////////////////////////////*/

    //slot1
    address internal _operator;
    //slot2
    address internal _oracleRegistry;
    //slot3
    address internal _tokenRegistry;

    /*///////////////////////////////////////////////////////////////
                        Mappings
    //////////////////////////////////////////////////////////////*/

    //Map of token and its deployed amounts
    mapping(address => PositionParams[]) internal tokenDeployedAmounts;
    //Map of token and its withdrawn amounts
    mapping(address => PositionParams[]) internal tokenWithdrawalAmounts;

    /*///////////////////////////////////////////////////////////////
                        Structs
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Position Params.
     * @param amount The amount of token deployed into a position.
     * @param price The price of the token at time of deployment into a position.
     * @param time The time of deployment into the position.
     */
    struct PositionParams {
        uint256 amount;
        uint256 price;
        uint256 time;
    }

    /*///////////////////////////////////////////////////////////////
                        Events
    //////////////////////////////////////////////////////////////*/


    event DepositETH(address account, uint256 amount);
    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event WithdrawETH(address account, uint256 amount);
    event WithdrawToOwner(IERC20 token, uint256 amount);
    event SetOracleRegistry(address oracleRegistry);
    event SetTokenRegistry(address tokenRegistry);

    /*///////////////////////////////////////////////////////////////
                        Modifiers
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Only called by operator
     */
    modifier onlyOperator() {
        require(msg.sender == _operator, "Only Operator");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner || msg.sender == _operator, "not owner or operator");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        Setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the operator address
     * @param operatorAddr Specifies the address of the poolContract.
     */
    function setOperator(address operatorAddr) external nonReentrant onlyOwner {
        _operator = operatorAddr;
    }

    /**
     * @notice Sets the oracle registry address
     * @param oracleRegistryAddr Specifies the address of the oracle registry.
     */
    function setOracleRegistry(address oracleRegistryAddr) external nonReentrant onlyOwner {
        _oracleRegistry = oracleRegistryAddr;

        emit SetOracleRegistry(_oracleRegistry);
    }

    /**
     * @notice Sets the oracle registry address
     * @param tokenRegistryAddr Specifies the address of the oracle registry.
     */
    function setTokenRegistry(address tokenRegistryAddr) external nonReentrant onlyOwner {
        _tokenRegistry = tokenRegistryAddr;

        emit SetTokenRegistry(_tokenRegistry);
    }

    /*///////////////////////////////////////////////////////////////
                            Base Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Log a deposit or withdrawal into the strategy contract.
     * @param token token to deposit or withdrawal.
     * @param amount amount of tokens to deposit or withdraw.
     */
    function _logPosition(address token, uint256 amount) internal view returns (PositionParams memory positionParams) {
        uint8 decimals = (token == NATIVE_ASSET) ? 18 : IERC20Metadata(token).decimals();
        uint256 price =
            OracleMath.getPrice(IOracleRegistry(_oracleRegistry).getSupportedOracle(address(token)), decimals);
        positionParams.amount = amount;
        positionParams.time = block.timestamp;
        positionParams.price = price;

        return positionParams;
    }

    /**
     * @notice Deposit into the strategy
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     */
    function _deposit(IERC20 token, uint256 amount) internal {
        token.safeTransferFrom(msg.sender, address(this), amount);

        PositionParams memory deployedAmount = _logPosition(address(token), amount);

        tokenDeployedAmounts[address(token)].push(deployedAmount); // Store the deposit information

        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Withdraw from the strategy
     * @param token token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function _withdraw(IERC20 token, uint256 amount) internal {
        token.safeTransfer(msg.sender, amount);

        PositionParams memory withdrawnAmount = _logPosition(address(token), amount);

        tokenWithdrawalAmounts[address(token)].push(withdrawnAmount); // Store the withdrawal information

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @notice Withdraw from the strategy to the owner.
     * @param token token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function _withdrawToOwner(IERC20 token, uint256 amount) internal {
        token.safeTransfer(owner, amount);

        PositionParams memory withdrawnAmount = _logPosition(address(token), amount);

        tokenWithdrawalAmounts[address(token)].push(withdrawnAmount); // Store the withdrawal information

        emit WithdrawToOwner(token, amount);
    }

    /**
     * @notice Swap rewards via the paraswap router.
     * @param srcToken The token to swap.
     * @param destToken The token to receive.
     * @param srcAmount The amount of tokens to swap.
     * @param minDestAmountOut The minimum amount of tokens out we expect to receive.
     * @param callData The callData to pass to the paraswap router. Generated offchain.
     */
    function _swap(
        IERC20 srcToken,
        IERC20 destToken,
        uint256 srcAmount,
        uint256 minDestAmountOut,
        bytes memory callData
    ) internal {
        require(ITokenRegistry(_tokenRegistry).getSupportedToken(address(srcToken)), "invalid token");
        require(ITokenRegistry(_tokenRegistry).getSupportedToken(address(destToken)), "invalid token");

        address tokenTransferProxy = IParaSwapAugustus(PARASWAP).getTokenTransferProxy();

        uint256 destTokenBalanceBefore = destToken.balanceOf(address(this));

        srcToken.safeApprove(tokenTransferProxy, srcAmount);

        (bool success,) = PARASWAP.call(callData);

        require(success, "swap failed");

        uint256 destTokenBalanceAfter = destToken.balanceOf(address(this));

        require(destTokenBalanceAfter - destTokenBalanceBefore >= minDestAmountOut, "slippage check");

        srcToken.safeApprove(tokenTransferProxy, 0);
    }

    /*///////////////////////////////////////////////////////////////
                            ETH Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Depost ETH into the contract
     */
    function depositETH() external payable nonReentrant onlyOwnerOrOperator {
        PositionParams memory deployedAmount = _logPosition(NATIVE_ASSET, msg.value);

        tokenDeployedAmounts[NATIVE_ASSET].push(deployedAmount); // Store the deposit information

        emit DepositETH(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw eth locked in contract back to owner
     * @param amount amount of eth to send.
     */
    function withdrawETH(uint256 amount) external nonReentrant onlyOwnerOrOperator {

        PositionParams memory withdrawnAmount = _logPosition(NATIVE_ASSET, amount);

        tokenWithdrawalAmounts[NATIVE_ASSET].push(withdrawnAmount); // Store the withdrawal information

        payable(msg.sender).transfer(amount);

        emit WithdrawETH(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Getters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get array of token deployments.
     * @param token token address.
     * @dev pass NATIVE_ASSET to return ETH deployments.
     */
    function getTokenDeployedAmounts(address token) external view returns (PositionParams[] memory) 
    {
        return tokenDeployedAmounts[token];
    }

    /**
     * @notice Get array of token withdrawals.
     * @param token token address.
     * @dev pass NATIVE_ASSET to return ETH withdrawals.
     */
    function getTokenWithdrawalAmounts(address token) external view returns (PositionParams[] memory) 
    {
        return tokenWithdrawalAmounts[token];
    }
}

interface IOriginRewardsSource {
    /// @notice Collect rewards.
    ///
    /// Can only be called by the contract that will receive the rewards.
    ///
    /// @return rewards OGV collected
    function collectRewards() external returns (uint256);

    /// @notice Preview the amount of rewards that would be returned if rewards
    /// were collected now.
    ///
    /// @return rewards OGV that would be collected
    function previewRewards() external view returns (uint256);
}

interface IOriginRewardsHarvester {
    /**
     * @dev Collect reward tokens for a specific strategy and swap for supported
     *      stablecoin via Uniswap. Can be called by anyone. Rewards incentivizing
     *      the caller are sent to the caller of this function.
     * @param _strategyAddr Address of the strategy to collect rewards from
     */    
    function harvestAndSwap(address _strategyAddr) external;
}

interface IOrigin {
    function rebaseOptIn() external;
    function rebaseOptOut() external;
    function rebaseState(address addr) external view returns (uint8);
}

contract OriginStrategy is FractBaseStrategy {
    address public constant OUSD_ADDRESS = address(0x2A8e1E676Ec238d8A992307B495b45B3fEAa5e86);
    address public constant OETH_ADDRESS = address(0x856c4Efb76C1D1AE02e20CEB03A2A6a08b0b8dC3);
    address public constant OUSD_HARVESTER = address(0x21Fb5812D70B3396880D30e90D9e5C1202266c89);
    address public constant OETH_HARVESTER = address(0x0D017aFA83EAce9F10A8EC5B6E13941664A6785C);
    address public constant OGV_REWARDS_SOURCE = address(0x7d82E86CF1496f9485a8ea04012afeb3C7489397);

    using SafeERC20 for IERC20;

    function deposit(IERC20 token, uint256 amount) external nonReentrant onlyOwner {
        _deposit(token, amount);
    }

    function withdraw(IERC20 token, uint256 amount) external nonReentrant onlyOwnerOrOperator {
        _withdraw(token, amount);
    }

    function withdrawToOwner(IERC20 token, uint256 amount) external nonReentrant onlyOwner {
        _withdrawToOwner(token, amount);
    }

    function rebaseOptInUsd() external nonReentrant onlyOwnerOrOperator {
        IOrigin(OUSD_ADDRESS).rebaseOptIn();
    }

    function rebaseOptInEth() external nonReentrant onlyOwnerOrOperator {
        IOrigin(OETH_ADDRESS).rebaseOptIn();
    }

    function rebaseOptOutUsd() external nonReentrant onlyOwnerOrOperator {
        IOrigin(OUSD_ADDRESS).rebaseOptOut();
    }

    function rebaseOptOutEth() external nonReentrant onlyOwnerOrOperator {
        IOrigin(OETH_ADDRESS).rebaseOptOut();
    }

    function swap(IERC20 srcToken, IERC20 destToken, uint256 srcAmount, uint256 minDestAmountOut, bytes memory callData) external payable nonReentrant onlyOperator {
        _swap(srcToken, destToken, srcAmount, minDestAmountOut, callData);
    }

    function computeRewardsUsdForEveryone(address strategyAddr) external nonReentrant onlyOwnerOrOperator {
        IOriginRewardsHarvester(OUSD_HARVESTER).harvestAndSwap(strategyAddr);
    }

    function computeRewardsEthForEveryone(address strategyAddr) external nonReentrant onlyOwnerOrOperator {
        IOriginRewardsHarvester(OETH_HARVESTER).harvestAndSwap(strategyAddr);
    }

    function collectRewards() external nonReentrant onlyOwnerOrOperator returns (uint256) {
        return IOriginRewardsSource(OGV_REWARDS_SOURCE).collectRewards();
    }

    function previewRewards() external view returns (uint256) {
        return IOriginRewardsSource(OGV_REWARDS_SOURCE).previewRewards();
    }

    function getCurrentRebaseStateUsd() external view returns (uint8) {
        return IOrigin(OUSD_ADDRESS).rebaseState(address(this));
    }

    function getCurrentRebaseStateEth() external view returns (uint8) {
        return IOrigin(OETH_ADDRESS).rebaseState(address(this));
    }
}