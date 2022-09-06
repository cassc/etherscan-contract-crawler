/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// solhint-disable-next-line compiler-version

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

/*
    ===== Badger Base Strategy =====
    Common base class for all Sett strategies

    Changelog
    V1.1
    - Verify amount unrolled from strategy positions on withdraw() is within a threshold relative to the requested amount as a sanity check
    - Add version number which is displayed with baseStrategyVersion(). If a strategy does not implement this function, it can be assumed to be 1.0

    V1.2
    - Remove idle want handling from base withdraw() function. This should be handled as the strategy sees fit in _withdrawSome()

    V1.5
    - No controller as middleman. The Strategy directly interacts with the vault
    - withdrawToVault would withdraw all the funds from the strategy and move it into vault
    - strategy would take the actors from the vault it is connected to
        - SettAccessControl removed
    - fees calculation for autocompounding rewards moved to vault
    - autoCompoundRatio param added to keep a track in which ratio harvested rewards are being autocompounded
*/

abstract contract BaseStrategy is PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    uint256 public constant MAX_BPS = 10_000; // MAX_BPS in terms of BPS = 100%

    address public want; // Token used for deposits
    address public vault; // address of the vault the strategy is connected to
    uint256 public withdrawalMaxDeviationThreshold; // max allowed slippage when withdrawing

    /// @notice percentage of rewards converted to want
    /// @dev converting of rewards to want during harvest should take place in this ratio
    /// @dev change this ratio if rewards are converted in a different percentage
    /// value ranges from 0 to 10_000
    /// 0: keeping 100% harvest in reward tokens
    /// 10_000: converting all rewards tokens to want token
    uint256 public autoCompoundRatio; // NOTE: I believe this is unused

    // NOTE: You have to set autoCompoundRatio in the initializer of your strategy

    event SetWithdrawalMaxDeviationThreshold(uint256 newMaxDeviationThreshold);

    // Return value for harvest, tend and balanceOfRewards
    struct TokenAmount {
        address token;
        uint256 amount;
    }

    /// @notice Initializes BaseStrategy. Can only be called once. 
    ///         Make sure to call it from the initializer of the derived strategy.
    /// @param _vault Address of the vault that the strategy reports to.
    function __BaseStrategy_init(address _vault) public initializer whenNotPaused {
        require(_vault != address(0), "Address 0");
        __Pausable_init();

        vault = _vault;

        withdrawalMaxDeviationThreshold = 50; // BPS
        // NOTE: See above
        autoCompoundRatio = 10_000;
    }

    // ===== Modifiers =====

    /// @notice Checks whether a call is from governance. 
    /// @dev For functions that only the governance should be able to call 
    ///      Most of the time setting setters, or to rescue/sweep funds
    function _onlyGovernance() internal view {
        require(msg.sender == governance(), "onlyGovernance");
    }

    /// @notice Checks whether a call is from strategist or governance. 
    /// @dev For functions that only known benign entities should call
    function _onlyGovernanceOrStrategist() internal view {
        require(msg.sender == strategist() || msg.sender == governance(), "onlyGovernanceOrStrategist");
    }

    /// @notice Checks whether a call is from keeper or governance. 
    /// @dev For functions that only known benign entities should call
    function _onlyAuthorizedActors() internal view {
        require(msg.sender == keeper() || msg.sender == governance(), "onlyAuthorizedActors");
    }

    /// @notice Checks whether a call is from the vault. 
    /// @dev For functions that only the vault should use
    function _onlyVault() internal view {
        require(msg.sender == vault, "onlyVault");
    }

    /// @notice Checks whether a call is from keeper, governance or the vault. 
    /// @dev Modifier used to check if the function is being called by a benign entity
    function _onlyAuthorizedActorsOrVault() internal view {
        require(msg.sender == keeper() || msg.sender == governance() || msg.sender == vault, "onlyAuthorizedActorsOrVault");
    }

    /// @notice Checks whether a call is from guardian or governance.
    /// @dev Modifier used exclusively for pausing
    function _onlyAuthorizedPausers() internal view {
        require(msg.sender == guardian() || msg.sender == governance(), "onlyPausers");
    }

    /// ===== View Functions =====
    /// @notice Used to track the deployed version of BaseStrategy.
    /// @return Current version of the contract.
    function baseStrategyVersion() external pure returns (string memory) {
        return "1.5";
    }

    /// @notice Gives the balance of want held idle in the Strategy.
    /// @dev Public because used internally for accounting
    /// @return Balance of want held idle in the strategy.
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    /// @notice Gives the total balance of want managed by the strategy.
    ///         This includes all want deposited to active strategy positions as well as any idle want in the strategy.
    /// @return Total balance of want managed by the strategy.
    function balanceOf() external view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    /// @notice Tells whether the strategy is supposed to be tended.
    /// @dev This is usually a constant. The harvest keeper would only call `tend` if this is true.
    /// @return Boolean indicating whether strategy is supposed to be tended or not.
    function isTendable() external pure returns (bool) {
        return _isTendable();
    }

    function _isTendable() internal virtual pure returns (bool);

    /// @notice Checks whether a token is a protected token.
    ///         Protected tokens are managed by the strategy and can't be transferred/sweeped.
    /// @return Boolean indicating whether the token is a protected token.
    function isProtectedToken(address token) public view returns (bool) {
        require(token != address(0), "Address 0");

        address[] memory protectedTokens = getProtectedTokens();
        for (uint256 i = 0; i < protectedTokens.length; i++) {
            if (token == protectedTokens[i]) {
                return true;
            }
        }
        return false;
    }

    /// @notice Fetches the governance address from the vault.
    /// @return The governance address.
    function governance() public view returns (address) {
        return IVault(vault).governance();
    }

    /// @notice Fetches the strategist address from the vault.
    /// @return The strategist address.
    function strategist() public view returns (address) {
        return IVault(vault).strategist();
    }

    /// @notice Fetches the keeper address from the vault.
    /// @return The keeper address.
    function keeper() public view returns (address) {
        return IVault(vault).keeper();
    }

    /// @notice Fetches the guardian address from the vault.
    /// @return The guardian address.
    function guardian() public view returns (address) {
        return IVault(vault).guardian();
    }

    /// ===== Permissioned Actions: Governance =====
    
    /// @notice Sets the max withdrawal deviation (percentage loss) that is acceptable to the strategy.
    ///         This can only be called by governance.
    /// @dev This is used as a slippage check against the actual funds withdrawn from strategy positions.
    ///      See `withdraw`.
    function setWithdrawalMaxDeviationThreshold(uint256 _threshold) external {
        _onlyGovernance();
        require(_threshold <= MAX_BPS, "_threshold should be <= MAX_BPS");
        withdrawalMaxDeviationThreshold = _threshold;
        emit SetWithdrawalMaxDeviationThreshold(_threshold);
    }

    /// @notice Deposits any idle want in the strategy into positions.
    ///         This can be called by either the vault, keeper or governance.
    ///         Note that deposits don't work when the strategy is paused. 
    /// @dev See `deposit`.
    function earn() external whenNotPaused {
        deposit();
    }

    /// @notice Deposits any idle want in the strategy into positions.
    ///         This can be called by either the vault, keeper or governance.
    ///         Note that deposits don't work when the strategy is paused. 
    /// @dev Is basically the same as tend, except without custom code for it 
    function deposit() public whenNotPaused {
        _onlyAuthorizedActorsOrVault();
        uint256 _amount = IERC20Upgradeable(want).balanceOf(address(this));
        if (_amount > 0) {
            _deposit(_amount);
        }
    }

    // ===== Permissioned Actions: Vault =====

    /// @notice Withdraw all funds from the strategy to the vault, unrolling all positions.
    ///         This can only be called by the vault.
    /// @dev This can be called even when paused, and strategist can trigger this via the vault.
    ///      The idea is that this can allow recovery of funds back to the strategy faster.
    ///      The risk is that if _withdrawAll causes a loss, this can be triggered.
    ///      However the loss could only be triggered once (just like if governance called)
    ///      as pausing the strats would prevent earning again.
    function withdrawToVault() external {
        _onlyVault();

        _withdrawAll();

        uint256 balance = IERC20Upgradeable(want).balanceOf(address(this));
        _transferToVault(balance);
    }

    /// @notice Withdraw partial funds from the strategy to the vault, unrolling from strategy positions as necessary.
    ///         This can only be called by the vault.
    ///         Note that withdraws don't work when the strategy is paused. 
    /// @dev If the strategy fails to recover sufficient funds (defined by `withdrawalMaxDeviationThreshold`), 
    ///      the withdrawal would fail so that this unexpected behavior can be investigated.
    /// @param _amount Amount of funds required to be withdrawn.
    function withdraw(uint256 _amount) external whenNotPaused {
        _onlyVault();
        require(_amount != 0, "Amount 0");

        // Withdraw from strategy positions, typically taking from any idle want first.
        _withdrawSome(_amount);
        uint256 _postWithdraw = IERC20Upgradeable(want).balanceOf(address(this));

        // Sanity check: Ensure we were able to retrieve sufficient want from strategy positions
        // If we end up with less than the amount requested, make sure it does not deviate beyond a maximum threshold
        if (_postWithdraw < _amount) {
            uint256 diff = _diff(_amount, _postWithdraw);

            // Require that difference between expected and actual values is less than the deviation threshold percentage
            require(diff <= _amount.mul(withdrawalMaxDeviationThreshold).div(MAX_BPS), "withdraw-exceed-max-deviation-threshold");
        }

        // Return the amount actually withdrawn if less than amount requested
        uint256 _toWithdraw = MathUpgradeable.min(_postWithdraw, _amount);

        // Transfer remaining to Vault to handle withdrawal
        _transferToVault(_toWithdraw);
    }

    // Discussion: https://discord.com/channels/785315893960900629/837083557557305375
    /// @notice Sends balance of any extra token earned by the strategy (from airdrops, donations etc.) to the vault.
    ///         The `_token` should be different from any tokens managed by the strategy.
    ///         This can only be called by the vault.
    /// @dev This is a counterpart to `_processExtraToken`.
    ///      This is for tokens that the strategy didn't expect to receive. Instead of sweeping, we can directly
    ///      emit them via the badgerTree. This saves time while offering security guarantees.
    ///      No address(0) check because _onlyNotProtectedTokens does it.
    ///      This is not a rug vector as it can't use protected tokens.
    /// @param _token Address of the token to be emitted.
    function emitNonProtectedToken(address _token) external {
        _onlyVault();
        _onlyNotProtectedTokens(_token);
        IERC20Upgradeable(_token).safeTransfer(vault, IERC20Upgradeable(_token).balanceOf(address(this)));
        IVault(vault).reportAdditionalToken(_token);
    }

    /// @notice Withdraw the balance of a non-protected token to the vault.
    ///         This can only be called by the vault.
    /// @dev Should only be used in an emergency to sweep any asset.
    ///      This is the version that sends the assets to governance.
    ///      No address(0) check because _onlyNotProtectedTokens does it.
    /// @param _asset Address of the token to be withdrawn.
    function withdrawOther(address _asset) external {
        _onlyVault();
        _onlyNotProtectedTokens(_asset);
        IERC20Upgradeable(_asset).safeTransfer(vault, IERC20Upgradeable(_asset).balanceOf(address(this)));
    }

    /// ===== Permissioned Actions: Authorized Contract Pausers =====

    /// @notice Pauses the strategy.
    ///         This can be called by either guardian or governance.
    /// @dev Check the `onlyWhenPaused` modifier for functionality that is blocked when pausing
    function pause() external {
        _onlyAuthorizedPausers();
        _pause();
    }

    /// @notice Unpauses the strategy.
    ///         This can only be called by governance (usually a multisig behind a timelock).
    function unpause() external {
        _onlyGovernance();
        _unpause();
    }

    /// ===== Internal Helper Functions =====

    /// @notice Transfers `_amount` of want to the vault.
    /// @dev Strategy should have idle funds >= `_amount`.
    /// @param _amount Amount of want to be transferred to the vault.
    function _transferToVault(uint256 _amount) internal {
        if (_amount > 0) {
            IERC20Upgradeable(want).safeTransfer(vault, _amount);
        }
    }

    /// @notice Report an harvest to the vault.
    /// @param _harvestedAmount Amount of want token autocompounded during harvest.
    function _reportToVault(
        uint256 _harvestedAmount
    ) internal {
        IVault(vault).reportHarvest(_harvestedAmount);
    }

    /// @notice Sends balance of an additional token (eg. reward token) earned by the strategy to the vault.
    ///         This should usually be called exclusively on protectedTokens.
    ///         Calls `Vault.reportAdditionalToken` to process fees and forward amount to badgerTree to be emitted.
    /// @dev This is how you emit tokens in V1.5
    ///      After calling this function, the tokens are gone, sent to fee receivers and badgerTree
    ///      This is a rug vector as it allows to move funds to the tree
    ///      For this reason, it is recommended to verify the tree is the badgerTree from the registry
    ///      and also check for this to be used exclusively on harvest, exclusively on protectedTokens.
    /// @param _token Address of the token to be emitted.
    /// @param _amount Amount of token to transfer to vault.
    function _processExtraToken(address _token, uint256 _amount) internal {
        require(_token != want, "Not want, use _reportToVault");
        require(_token != address(0), "Address 0");
        require(_amount != 0, "Amount 0");

        IERC20Upgradeable(_token).safeTransfer(vault, _amount);
        IVault(vault).reportAdditionalToken(_token);
    }

    /// @notice Utility function to diff two numbers, expects higher value in first position
    function _diff(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "a should be >= b");
        return a.sub(b);
    }

    // ===== Abstract Functions: To be implemented by specific Strategies =====

    /// @dev Internal deposit logic to be implemented by a derived strategy.
    /// @param _want Amount of want token to be deposited into the strategy.
    function _deposit(uint256 _want) internal virtual;

    /// @notice Checks if a token is not used in yield process.
    /// @param _asset Address of token.
    function _onlyNotProtectedTokens(address _asset) internal view {
        require(!isProtectedToken(_asset), "_onlyNotProtectedTokens");
    }

    /// @notice Gives the list of protected tokens.
    /// @return Array of protected tokens.
    function getProtectedTokens() public view virtual returns (address[] memory);

    /// @dev Internal logic for strategy migration. Should exit positions as efficiently as possible.
    function _withdrawAll() internal virtual;

    /// @dev Internal logic for partial withdrawals. Should exit positions as efficiently as possible.
    ///      Should ideally use idle want in the strategy before attempting to exit strategy positions.
    /// @param _amount Amount of want token to be withdrawn from the strategy.
    /// @return Withdrawn amount from the strategy.
    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    /// @notice Realize returns from strategy positions.
    ///         This can only be called by keeper or governance.
    ///         Note that harvests don't work when the strategy is paused. 
    /// @dev Returns can be reinvested into positions, or distributed in another fashion.
    /// @return harvested An array of `TokenAmount` containing the address and amount harvested for each token.
    function harvest() external whenNotPaused returns (TokenAmount[] memory harvested) {
        _onlyAuthorizedActors();
        return _harvest();
    }

    /// @dev Virtual function that should be overridden with the logic for harvest. 
    ///      Should report any want or non-want gains to the vault.
    ///      Also see `harvest`.
    function _harvest() internal virtual returns (TokenAmount[] memory harvested);

    /// @notice Tend strategy positions as needed to maximize returns.
    ///         This can only be called by keeper or governance.
    ///         Note that tend doesn't work when the strategy is paused. 
    /// @dev Is only called by the keeper when `isTendable` is true.
    /// @return tended An array of `TokenAmount` containing the address and amount tended for each token.
    function tend() external whenNotPaused returns (TokenAmount[] memory tended) {
        _onlyAuthorizedActors();

        return _tend();
    }

    /// @dev Virtual function that should be overridden with the logic for tending. 
    ///      Also see `tend`.
    function _tend() internal virtual returns (TokenAmount[] memory tended);

    /// @notice Fetches the name of the strategy.
    /// @dev Should be user-friendly and easy to read.
    /// @return Name of the strategy.
    function getName() external pure virtual returns (string memory);

    /// @notice Gives the balance of want held in strategy positions.
    /// @return Balance of want held in strategy positions.
    function balanceOfPool() public view virtual returns (uint256);

    /// @notice Gives the total amount of pending rewards accrued for each token.
    /// @dev Should take into account all reward tokens.
    /// @return rewards An array of `TokenAmount` containing the address and amount of each reward token.
    function balanceOfRewards() external view virtual returns (TokenAmount[] memory rewards);

    uint256[49] private __gap;
}

interface IVault {
    function token() external view returns (address);

    function reportHarvest(uint256 _harvestedAmount) external;

    function reportAdditionalToken(address _token) external;

    // Fees
    function performanceFeeGovernance() external view returns (uint256);

    function performanceFeeStrategist() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    // Actors
    function governance() external view returns (address);

    function keeper() external view returns (address);

    function guardian() external view returns (address);

    function strategist() external view returns (address);

    function treasury() external view returns (address);

    // External
    function deposit(uint256 _amount) external;

    function balanceOf(address) external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);
}

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

enum ExitKind {
    EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
    EXACT_BPT_IN_FOR_TOKENS_OUT,
    BPT_IN_FOR_EXACT_TOKENS_OUT
}

enum JoinKind {
    INIT,
    EXACT_TOKENS_IN_FOR_BPT_OUT,
    TOKEN_IN_FOR_EXACT_BPT_OUT,
    ALL_TOKENS_IN_FOR_EXACT_BPT_OUT,
    ADD_TOKEN // for Managed Pool
}

interface IBalancerVault {
    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}

interface IAuraToken {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Initialised();
    event OperatorChanged(
        address indexed previousOperator,
        address indexed newOperator
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function EMISSIONS_MAX_SUPPLY() external view returns (uint256);

    function INIT_MINT_AMOUNT() external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function init(address _to, address _minter) external;

    function mint(address _to, uint256 _amount) external;

    function minter() external view returns (address);

    function minterMint(address _to, uint256 _amount) external;

    function name() external view returns (string memory);

    function operator() external view returns (address);

    function reductionPerCliff() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalCliffs() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function updateOperator() external;

    function vecrvProxy() external view returns (address);
}

interface IBaseRewardPool {
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function addExtraReward(address _reward) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function clearExtraRewards() external;

    function currentRewards() external view returns (uint256);

    function donate(uint256 _amount) external returns (bool);

    function duration() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function getReward() external returns (bool);

    function getReward(address _account, bool _claimExtras)
        external
        returns (bool);

    function historicalRewards() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function newRewardRatio() external view returns (uint256);

    function operator() external view returns (address);

    function periodFinish() external view returns (uint256);

    function pid() external view returns (uint256);

    function processIdleRewards() external;

    function queueNewRewards(uint256 _rewards) external returns (bool);

    function queuedRewards() external view returns (uint256);

    function rewardManager() external view returns (address);

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function rewards(address) external view returns (uint256);

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external;

    function withdrawAllAndUnwrap(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);
}

interface IVirtualBalanceRewardPool {
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function balanceOf(address account) external view returns (uint256);

    function currentRewards() external view returns (uint256);

    function deposits() external view returns (address);

    function donate(uint256 _amount) external returns (bool);

    function duration() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getReward() external;

    function getReward(address _account) external;

    function historicalRewards() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function newRewardRatio() external view returns (uint256);

    function operator() external view returns (address);

    function periodFinish() external view returns (uint256);

    function queueNewRewards(uint256 _rewards) external;

    function queuedRewards() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function rewards(address) external view returns (uint256);

    function stake(address _account, uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function withdraw(address _account, uint256 amount) external;
}

contract AuraBalStakerStrategy is BaseStrategy {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bool public claimRewardsOnWithdrawAll;
    uint256 public balEthBptToAuraBalMinOutBps;
    uint256 public minBbaUsdHarvest;

    IBaseRewardPool public constant AURABAL_REWARDS =
        IBaseRewardPool(0x5e5ea2048475854a5702F5B8468A51Ba1296EFcC);

    IVault public constant GRAVIAURA =
        IVault(0xBA485b556399123261a5F9c95d413B4f93107407);

    IBalancerVault public constant BALANCER_VAULT =
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    IAuraToken public constant AURA =
        IAuraToken(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);

    IERC20Upgradeable public constant AURABAL =
        IERC20Upgradeable(0x616e8BfA43F920657B3497DBf40D6b1A02D4608d);
    IERC20Upgradeable public constant WETH =
        IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable public constant BAL =
        IERC20Upgradeable(0xba100000625a3754423978a60c9317c58a424e3D);
    IERC20Upgradeable public constant BALETH_BPT =
        IERC20Upgradeable(0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56);
    IERC20Upgradeable public constant BB_A_USD =
        IERC20Upgradeable(0x7B50775383d3D6f0215A8F290f2C9e2eEBBEceb2);
    IERC20Upgradeable public constant BB_A_USDC =
        IERC20Upgradeable(0x9210F1204b5a24742Eba12f710636D76240dF3d0);
    IERC20Upgradeable public constant USDC =
        IERC20Upgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    bytes32 public constant BAL_ETH_POOL_ID =
        0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;
    bytes32 public constant AURABAL_BALETH_BPT_POOL_ID =
        0x3dd0843a028c86e0b760b1a76929d1c5ef93a2dd000200000000000000000249;
    bytes32 public constant BB_A_USD_POOL_ID =
        0x7b50775383d3d6f0215a8f290f2c9e2eebbeceb20000000000000000000000fe;
    bytes32 public constant BB_A_USDC_POOL_ID =
        0x9210f1204b5a24742eba12f710636d76240df3d00000000000000000000000fc;
    bytes32 public constant USDC_WETH_POOL_ID =
        0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019;

    /// @dev Initialize the Strategy with security settings as well as tokens
    /// @notice Proxies will set any non constant variable you declare as default value
    /// @dev add any extra changeable variable at end of initializer as shown
    function initialize(address _vault) public initializer {
        require(IVault(_vault).token() == address(AURABAL));

        __BaseStrategy_init(_vault);

        want = address(AURABAL);

        claimRewardsOnWithdrawAll = true;
        balEthBptToAuraBalMinOutBps = 9500; // max 5% slippage
        minBbaUsdHarvest = 1000e18; // ~$1000

        AURABAL.safeApprove(address(AURABAL_REWARDS), type(uint256).max);

        BAL.safeApprove(address(BALANCER_VAULT), type(uint256).max);
        WETH.safeApprove(address(BALANCER_VAULT), type(uint256).max);
        BALETH_BPT.safeApprove(address(BALANCER_VAULT), type(uint256).max);
        BB_A_USD.approve(address(BALANCER_VAULT), type(uint256).max);

        AURA.approve(address(GRAVIAURA), type(uint256).max);
    }

    function setClaimRewardsOnWithdrawAll(bool _claimRewardsOnWithdrawAll)
        external
    {
        _onlyGovernanceOrStrategist();
        claimRewardsOnWithdrawAll = _claimRewardsOnWithdrawAll;
    }

    function setBalEthBptToAuraBalMinOutBps(uint256 _minOutBps) external {
        _onlyGovernanceOrStrategist();
        require(_minOutBps <= MAX_BPS, "Invalid minOutBps");

        balEthBptToAuraBalMinOutBps = _minOutBps;
    }

    function setMinBbaUsdHarvest(uint256 _minBbaUsd) external {
        _onlyGovernanceOrStrategist();

        minBbaUsdHarvest = _minBbaUsd;
    }

    /// @dev Return the name of the strategy
    function getName() external pure override returns (string memory) {
        return "AuraBalStakerStrategy";
    }

    /// @dev Return a list of protected tokens
    /// @notice It's very important all tokens that are meant to be in the strategy to be marked as protected
    /// @notice this provides security guarantees to the depositors they can't be sweeped away
    function getProtectedTokens()
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        address[] memory protectedTokens = new address[](4);
        protectedTokens[0] = want; // AURABAL
        protectedTokens[1] = address(AURA);
        protectedTokens[2] = address(BAL);
        protectedTokens[3] = address(BB_A_USD);
        return protectedTokens;
    }

    /// @dev Deposit `_amount` of want, investing it to earn yield
    function _deposit(uint256 _amount) internal override {
        // Add code here to invest `_amount` of want to earn yield
        AURABAL_REWARDS.stake(_amount);
    }

    /// @dev Withdraw all funds, this is used for migrations, most of the time for emergency reasons
    function _withdrawAll() internal override {
        uint256 poolBalance = balanceOfPool();
        if (poolBalance > 0) {
            AURABAL_REWARDS.withdrawAll(claimRewardsOnWithdrawAll);
        }
    }

    /// @dev Withdraw `_amount` of want, so that it can be sent to the vault / depositor
    /// @notice just unlock the funds and return the amount you could unlock
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 wantBalance = balanceOfWant();
        if (wantBalance < _amount) {
            uint256 toWithdraw = _amount.sub(wantBalance);
            AURABAL_REWARDS.withdraw(toWithdraw, false);
        }
        return MathUpgradeable.min(_amount, balanceOfWant());
    }

    /// @dev Does this function require `tend` to be called?
    function _isTendable() internal pure override returns (bool) {
        return false; // Change to true if the strategy should be tended
    }

    function _harvest()
        internal
        override
        returns (TokenAmount[] memory harvested)
    {
        AURABAL_REWARDS.getReward();

        // Rewards are handled like this:
        // BB_A_USD  --> AURABAL (autocompounded)
        // BAL       --> BAL/ETH BPT --> AURABAL (autocompounded)
        // AURA      --> GRAVIAURA (emitted)
        harvested = new TokenAmount[](2);
        harvested[0].token = address(AURABAL);
        harvested[1].token = address(GRAVIAURA);

        // BB_A_USD --> WETH
        uint256 bbaUsdBalance = BB_A_USD.balanceOf(address(this));
        uint256 wethEarned;
        if (bbaUsdBalance > minBbaUsdHarvest) {
            IAsset[] memory assets = new IAsset[](4);
            assets[0] = IAsset(address(BB_A_USD));
            assets[1] = IAsset(address(BB_A_USDC));
            assets[2] = IAsset(address(USDC));
            assets[3] = IAsset(address(WETH));

            int256[] memory limits = new int256[](4);
            limits[0] = int256(bbaUsdBalance);

            IBalancerVault.BatchSwapStep[]
                memory swaps = new IBalancerVault.BatchSwapStep[](3);

            // BB_A_USD --> BB_A_USDC
            swaps[0] = IBalancerVault.BatchSwapStep({
                poolId: BB_A_USD_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: bbaUsdBalance,
                userData: new bytes(0)
            });
            // BB_A_USDC --> USDC
            swaps[1] = IBalancerVault.BatchSwapStep({
                poolId: BB_A_USDC_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0, // 0 means all from last step
                userData: new bytes(0)
            });
            // USDC --> WETH
            swaps[2] = IBalancerVault.BatchSwapStep({
                poolId: USDC_WETH_POOL_ID,
                assetInIndex: 2,
                assetOutIndex: 3,
                amount: 0, // 0 means all from last step
                userData: new bytes(0)
            });

            IBalancerVault.FundManagement memory fundManagement = IBalancerVault
                .FundManagement({
                    sender: address(this),
                    fromInternalBalance: false,
                    recipient: payable(address(this)),
                    toInternalBalance: false
                });

            int256[] memory assetBalances = BALANCER_VAULT.batchSwap(
                IBalancerVault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                fundManagement,
                limits,
                type(uint256).max
            );
            wethEarned = uint256(-assetBalances[assetBalances.length - 1]);
        }

        // BAL --> BAL/ETH BPT --> AURABAL
        uint256 balBalance = BAL.balanceOf(address(this));
        uint256 auraBalEarned;
        if (balBalance > 0) {
            // Deposit BAL --> BAL/ETH BPT
            IAsset[] memory assets = new IAsset[](2);
            assets[0] = IAsset(address(BAL));
            assets[1] = IAsset(address(WETH));
            uint256[] memory maxAmountsIn = new uint256[](2);
            maxAmountsIn[0] = balBalance;
            maxAmountsIn[1] = wethEarned;

            BALANCER_VAULT.joinPool(
                BAL_ETH_POOL_ID,
                address(this),
                address(this),
                IBalancerVault.JoinPoolRequest({
                    assets: assets,
                    maxAmountsIn: maxAmountsIn,
                    userData: abi.encode(
                        JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                        maxAmountsIn,
                        0 // minOut
                    ),
                    fromInternalBalance: false
                })
            );

            // Swap BAL/ETH BPT --> AURABAL
            uint256 balEthBptBalance = IERC20Upgradeable(BALETH_BPT).balanceOf(
                address(this)
            );

            // Swap BAL/ETH BPT --> auraBal
            IBalancerVault.FundManagement memory fundManagement = IBalancerVault
                .FundManagement({
                    sender: address(this),
                    fromInternalBalance: false,
                    recipient: payable(address(this)),
                    toInternalBalance: false
                });
            IBalancerVault.SingleSwap memory singleSwap = IBalancerVault
                .SingleSwap({
                    poolId: AURABAL_BALETH_BPT_POOL_ID,
                    kind: IBalancerVault.SwapKind.GIVEN_IN,
                    assetIn: IAsset(address(BALETH_BPT)),
                    assetOut: IAsset(address(AURABAL)),
                    amount: balEthBptBalance,
                    userData: new bytes(0)
                });
            uint256 minOut = (balEthBptBalance * balEthBptToAuraBalMinOutBps) /
                MAX_BPS;
            auraBalEarned = BALANCER_VAULT.swap(
                singleSwap,
                fundManagement,
                minOut,
                type(uint256).max
            );

            harvested[0].amount = auraBalEarned;
        }

        // AURA --> graviAURA
        uint256 auraBalance = AURA.balanceOf(address(this));
        if (auraBalance > 0) {
            GRAVIAURA.deposit(auraBalance);
            uint256 graviAuraBalance = GRAVIAURA.balanceOf(address(this));

            harvested[1].amount = graviAuraBalance;
            _processExtraToken(address(GRAVIAURA), graviAuraBalance);
        }

        // Report harvest
        _reportToVault(auraBalEarned);

        // Stake whatever is earned
        if (auraBalEarned > 0) {
            _deposit(auraBalEarned);
        }
    }

    // Example tend is a no-op which returns the values, could also just revert
    function _tend() internal override returns (TokenAmount[] memory tended) {
        revert("no op");
    }

    /// @dev Return the balance (in want) that the strategy has invested somewhere
    function balanceOfPool() public view override returns (uint256) {
        // Change this to return the amount of want invested in another protocol
        return AURABAL_REWARDS.balanceOf(address(this));
    }

    /// @dev Return the balance of rewards that the strategy has accrued
    /// @notice Used for offChain APY and Harvest Health monitoring
    function balanceOfRewards()
        external
        view
        override
        returns (TokenAmount[] memory rewards)
    {
        uint256 numExtraRewards = AURABAL_REWARDS.extraRewardsLength();
        rewards = new TokenAmount[](numExtraRewards + 2);

        uint256 balEarned = AURABAL_REWARDS.earned(address(this));

        rewards[0] = TokenAmount(address(BAL), balEarned);
        rewards[1] = TokenAmount(
            address(AURA),
            getMintableAuraRewards(balEarned)
        );

        for (uint256 i; i < numExtraRewards; ++i) {
            IVirtualBalanceRewardPool extraRewardPool = IVirtualBalanceRewardPool(
                    address(AURABAL_REWARDS.extraRewards(i))
                );
            rewards[i + 2] = TokenAmount(
                extraRewardPool.rewardToken(),
                extraRewardPool.earned(address(this))
            );
        }
    }

    /// @notice Returns the expected amount of AURA to be minted given an amount of BAL rewards
    /// @dev ref: https://etherscan.io/address/0xc0c293ce456ff0ed870add98a0828dd4d2903dbf#code#F1#L86
    function getMintableAuraRewards(uint256 _balAmount)
        public
        view
        returns (uint256 amount)
    {
        // NOTE: Only correct if AURA.minterMinted() == 0
        //       minterMinted is a private var in the contract, so we can't access it directly
        uint256 emissionsMinted = AURA.totalSupply() - AURA.INIT_MINT_AMOUNT();

        uint256 cliff = emissionsMinted.div(AURA.reductionPerCliff());
        uint256 totalCliffs = AURA.totalCliffs();

        if (cliff < totalCliffs) {
            uint256 reduction = totalCliffs.sub(cliff).mul(5).div(2).add(700);
            amount = _balAmount.mul(reduction).div(totalCliffs);

            uint256 amtTillMax = AURA.EMISSIONS_MAX_SUPPLY().sub(
                emissionsMinted
            );
            if (amount > amtTillMax) {
                amount = amtTillMax;
            }
        }
    }
}