/**
 *Submitted for verification at Etherscan.io on 2023-07-09
*/

// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/libraries/TransferHelper.sol


pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]


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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/PaymentGateway.sol


pragma solidity ^0.8.6;




contract PaymentGateway is OwnableUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;

    event TokenDeposited(
        string merchantCode,
        string orderId,
        address account,
        string currency,
        uint256 amount
    );
    event TokenWithdrawn(
        string merchantCode,
        string orderId,
        address account,
        string currency,
        uint256 amount
    );
    event TokenAdded(string symbol, address tokenAddress, uint8 tokenType);
    event TokenRemoved(string symbol);
    event Received(address Sender, uint Value);
    event WithdrawCallerChanged(
        string merchantCode,
        address oldWithdrawCaller,
        address withdrawCaller
    );
    event DepositCollectorChanged(
        string merchantCode,
        address oldDepositCollector,
        address newDepositCollector
    );
    event WithdrawWalletChanged(
        string merchantCode,
        address oldWithdrawWallet,
        address newWithdrawWallet
    );
    event FeeCollectorChanged(
        string merchantCode,
        address oldFeeCollector,
        address newFeeCollector
    );
    event FeeRatioChanged(
        string merchantCode,
        uint256 oldFeeRatio,
        uint256 newFeeRatio
    );
    event MerchantSetted(
        string merchantCode,
        uint256 feeRatio,
        address withdrawCaller,
        address depositCollector,
        address feeCollector,
        address withdrawWallet
    );

    struct TokenInfo {
        string symbol;
        address tokenAddress;
        uint8 tokenType;
    }

    struct OrderInfo {
        string merchantCode;
        string orderId;
        address account;
        string currency;
        uint256 amount;
        uint256 blockNumber;
        uint256 timestamp;
    }

    struct OrderIndex {
        string merchantCode;
        string orderId;
    }
    struct MerchantInfo {
        string merchantCode;
        uint256 feeRatio; // 100% is 10000
        address withdrawCaller;
        address payable depositCollector;
        address payable feeCollector;
        address payable withdrawWallet;
    }
    uint256 public depositCount;
    uint256 public withdrawCount;

    mapping(string => TokenInfo) public tokenInfos;
    string[] public supportedTokens;

    mapping(string => MerchantInfo) public merchantInfos;
    mapping(string => mapping(string => OrderInfo)) public depositInfos; // merchant code and Order id to order info
    mapping(string => mapping(string => OrderInfo)) public withdrawInfos; // merchant code and Order id  to order info
    OrderIndex[] public depositIndexs;
    OrderIndex[] public withdrawIndexs;

    uint8 public constant ERC20 = 1;
    uint8 public constant BASE_TOKEN = 2;

    function getTokenAddress(
        string calldata symbol
    ) public view returns (address) {
        return tokenInfos[symbol].tokenAddress;
    }

    function getTokenType(string calldata symbol) public view returns (uint8) {
        return tokenInfos[symbol].tokenType;
    }

    function isTokenSupported(
        string calldata symbol
    ) public view returns (bool) {
        if (
            tokenInfos[symbol].tokenType == ERC20 ||
            tokenInfos[symbol].tokenType == BASE_TOKEN
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isMerchantSupported(
        string memory merchantCode
    ) public view returns (bool) {
        if (merchantInfos[merchantCode].depositCollector != address(0)) {
            return true;
        } else {
            return false;
        }
    }

    function supportedTokenList() public view returns (string[] memory) {
        return supportedTokens;
    }

    function __PaymentGateway_init() public initializer {
        __Ownable_init();
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function addMerchantInfo(
        string memory _merchantCode,
        uint256 _feeRatio,
        address _withdrawCaller,
        address payable _depositCollector,
        address payable _feeCollector,
        address payable _withdrawWallet
    ) external onlyOwner {
        require(
            !isMerchantSupported(_merchantCode),
            "PaymentGateway: merchant already exists"
        );
        merchantInfos[_merchantCode] = MerchantInfo({
            merchantCode: _merchantCode,
            feeRatio: _feeRatio,
            withdrawCaller: _withdrawCaller,
            depositCollector: _depositCollector,
            feeCollector: _feeCollector,
            withdrawWallet: _withdrawWallet
        });

        emit MerchantSetted(
            _merchantCode,
            _feeRatio,
            _withdrawCaller,
            _depositCollector,
            _feeCollector,
            _withdrawWallet
        );
    }

    function setWithdrawCaller(
        string memory _merchantCode,
        address _withdrawCaller
    ) external onlyOwner {
        require(_withdrawCaller != address(0), "PaymentGateway: zero address");
        require(
            isMerchantSupported(_merchantCode),
            "PaymentGateway: merchant not supported"
        );
        require(
            merchantInfos[_merchantCode].withdrawCaller != _withdrawCaller,
            "PaymentGateway: withdraw caller not changed"
        );

        address oldWithdrawCaller = merchantInfos[_merchantCode].withdrawCaller;
        merchantInfos[_merchantCode].withdrawCaller = _withdrawCaller;

        emit WithdrawCallerChanged(
            _merchantCode,
            oldWithdrawCaller,
            merchantInfos[_merchantCode].withdrawCaller
        );
    }

    function setFeeCollector(
        string memory _merchantCode,
        address payable _feeCollector
    ) external onlyOwner {
        require(_feeCollector != address(0), "PaymentGateway: zero address");
        require(
            isMerchantSupported(_merchantCode),
            "PaymentGateway: merchant not supported"
        );
        address oldFeeCollector;
        merchantInfos[_merchantCode].feeCollector = _feeCollector;
        emit FeeCollectorChanged(
            _merchantCode,
            oldFeeCollector,
            merchantInfos[_merchantCode].feeCollector
        );
    }

    function setDepositCollector(
        string memory _merchantCode,
        address payable _depositCollector
    ) external onlyOwner {
        require(
            _depositCollector != address(0),
            "PaymentGateway: zero address"
        );
        require(
            isMerchantSupported(_merchantCode),
            "PaymentGateway: merchant not supported"
        );

        address oldDepositCollector;
        merchantInfos[_merchantCode].depositCollector = _depositCollector;
        emit DepositCollectorChanged(
            _merchantCode,
            oldDepositCollector,
            merchantInfos[_merchantCode].depositCollector
        );
    }

    function setWithdrawWallet(
        string memory _merchantCode,
        address payable _withdrawWallet
    ) external onlyOwner {
        require(_withdrawWallet != address(0), "PaymentGateway: zero address");
        require(
            isMerchantSupported(_merchantCode),
            "PaymentGateway: merchant not supported"
        );

        address oldWithdrawWallet;
        merchantInfos[_merchantCode].withdrawWallet = _withdrawWallet;
        emit WithdrawWalletChanged(
            _merchantCode,
            oldWithdrawWallet,
            merchantInfos[_merchantCode].withdrawWallet
        );
    }

    function setFeeRatio(
        string memory _merchantCode,
        uint256 _feeRatio
    ) external onlyOwner {
        require(
            0 <= _feeRatio && _feeRatio <= 10000,
            "PaymentGateway: Illegal value range"
        );
        require(
            isMerchantSupported(_merchantCode),
            "PaymentGateway: merchant not supported"
        );

        uint256 oldFeeRatio = merchantInfos[_merchantCode].feeRatio;
        merchantInfos[_merchantCode].feeRatio = _feeRatio;
        emit FeeRatioChanged(
            _merchantCode,
            oldFeeRatio,
            merchantInfos[_merchantCode].feeRatio
        );
    }

    function addToken(
        string calldata _symbol,
        address _tokenAddress,
        uint8 _tokenType
    ) external onlyOwner {
        require(
            tokenInfos[_symbol].tokenAddress == address(0),
            "PaymentGateway: token already exists"
        );
        require(
            _tokenType == ERC20 || _tokenType == BASE_TOKEN,
            "PaymentGateway: unknown token  type"
        );
        if (_tokenType != BASE_TOKEN) {
            require(
                _tokenAddress != address(0),
                "PaymentGateway: zero address"
            );
        }
        tokenInfos[_symbol] = TokenInfo({
            symbol: _symbol,
            tokenAddress: _tokenAddress,
            tokenType: _tokenType
        });
        supportedTokens.push(_symbol);
        emit TokenAdded(_symbol, _tokenAddress, _tokenType);
    }

    function removeToken(string calldata _symbol) external onlyOwner {
        require(
            tokenInfos[_symbol].tokenType != ERC20 ||
                tokenInfos[_symbol].tokenType != BASE_TOKEN,
            "PaymentGateway: token does not exists"
        );
        delete tokenInfos[_symbol];
        emit TokenRemoved(_symbol);
    }

    function deposit(
        string memory _merchantCode,
        string memory _orderId,
        string calldata _currency,
        uint256 _amount
    ) external payable {
        require(_amount > 0, "PaymentGateway: amount must be positive");
        require(
            isTokenSupported(_currency),
            "PaymentGateway: token not supported"
        );
        require(
            isMerchantSupported(_merchantCode),
            "PaymentGateway: merchant not supported"
        );
        require(
            depositInfos[_merchantCode][_orderId].amount == 0,
            "PaymentGateway: the order in this merchan already exists"
        );

        TokenInfo memory tokenInfo = tokenInfos[_currency];
        OrderIndex memory orderIndex = OrderIndex({
            merchantCode: _merchantCode,
            orderId: _orderId
        });
        depositIndexs.push(orderIndex);
        depositCount = depositCount + 1;

        uint256 feeAmount = _amount.div(10000).mul(
            merchantInfos[_merchantCode].feeRatio
        );

        if (tokenInfo.tokenType == ERC20) {
            depositInfos[_merchantCode][_orderId] = OrderInfo({
                merchantCode: _merchantCode,
                orderId: _orderId,
                account: msg.sender,
                currency: _currency,
                amount: _amount,
                blockNumber: block.number,
                timestamp: block.timestamp
            });
            if (feeAmount > 0) {
                TransferHelper.safeTransferFrom(
                    tokenInfo.tokenAddress,
                    msg.sender,
                    merchantInfos[_merchantCode].feeCollector,
                    feeAmount
                );
            }
            TransferHelper.safeTransferFrom(
                tokenInfo.tokenAddress,
                msg.sender,
                merchantInfos[_merchantCode].depositCollector,
                _amount.sub(feeAmount)
            );
        } else if (tokenInfo.tokenType == BASE_TOKEN) {
            require(_amount == msg.value, "PaymentGateway: deposit amount ");
            depositInfos[_merchantCode][_orderId] = OrderInfo({
                merchantCode: _merchantCode,
                orderId: _orderId,
                account: msg.sender,
                currency: _currency,
                amount: msg.value,
                blockNumber: block.number,
                timestamp: block.timestamp
            });
            if (feeAmount > 0) {
                TransferHelper.safeTransferETH(
                    merchantInfos[_merchantCode].feeCollector,
                    feeAmount
                );
            }
            TransferHelper.safeTransferETH(
                merchantInfos[_merchantCode].depositCollector,
                _amount.sub(feeAmount)
            );
        } else {
            require(false, "PaymentGateway: unknown token type");
        }

        emit TokenDeposited(
            _merchantCode,
            _orderId,
            msg.sender,
            _currency,
            _amount
        );
    }

    function withdraw(
        string memory _merchantCode,
        string memory _orderId,
        string calldata _currency,
        uint256 _amount,
        address payable _recipient
    ) external {
        require(
            isMerchantSupported(_merchantCode),
            "PaymentGateway: merchant not supported"
        );
        require(
            msg.sender == merchantInfos[_merchantCode].withdrawCaller,
            "PaymentGateway: caller is not the withdraw caller"
        );
        require(_amount > 0, "PaymentGateway: amount must be positive");
        require(
            isTokenSupported(_currency),
            "PaymentGateway: token not supported"
        );
        require(_recipient != address(0), "PaymentGateway: zero address");
        require(
            withdrawInfos[_merchantCode][_orderId].amount == 0,
            "PaymentGateway: the order in this merchan already exists"
        );
        TokenInfo memory tokenInfo = tokenInfos[_currency];

        OrderIndex memory orderIndex = OrderIndex({
            merchantCode: _merchantCode,
            orderId: _orderId
        });
        withdrawIndexs.push(orderIndex);
        withdrawCount = withdrawCount + 1;

        withdrawInfos[_merchantCode][_orderId] = OrderInfo({
            merchantCode: _merchantCode,
            orderId: _orderId,
            account: msg.sender,
            currency: _currency,
            amount: _amount,
            blockNumber: block.number,
            timestamp: block.timestamp
        });
        if (tokenInfo.tokenType == ERC20) {
            TransferHelper.safeTransferFrom(
                tokenInfo.tokenAddress,
                merchantInfos[_merchantCode].withdrawWallet,
                _recipient,
                _amount
            );
        } else if (tokenInfo.tokenType == BASE_TOKEN) {
            TransferHelper.safeTransferETH(_recipient, _amount);
        } else {
            require(false, "PaymentGateway: unknown token lock type");
        }

        emit TokenWithdrawn(
            _merchantCode,
            _orderId,
            msg.sender,
            _currency,
            _amount
        );
    }

    function getDepositByIndex(
        uint256 _index
    )
        external
        view
        returns (
            string memory merchantCode,
            string memory orderId,
            address account,
            string memory currency,
            uint256 amount,
            uint256 blockNumber,
            uint256 timestamp
        )
    {
        OrderIndex memory index = depositIndexs[_index];
        return (
            depositInfos[index.merchantCode][index.orderId].merchantCode,
            depositInfos[index.merchantCode][index.orderId].orderId,
            depositInfos[index.merchantCode][index.orderId].account,
            depositInfos[index.merchantCode][index.orderId].currency,
            depositInfos[index.merchantCode][index.orderId].amount,
            depositInfos[index.merchantCode][index.orderId].blockNumber,
            depositInfos[index.merchantCode][index.orderId].timestamp
        );
    }

    function getWithdrawByIndex(
        uint256 _index
    )
        external
        view
        returns (
            string memory merchantCode,
            string memory orderId,
            address account,
            string memory currency,
            uint256 amount,
            uint256 blockNumber,
            uint256 timestamp
        )
    {
        OrderIndex memory index = withdrawIndexs[_index];
        return (
            withdrawInfos[index.merchantCode][index.orderId].merchantCode,
            withdrawInfos[index.merchantCode][index.orderId].orderId,
            withdrawInfos[index.merchantCode][index.orderId].account,
            withdrawInfos[index.merchantCode][index.orderId].currency,
            withdrawInfos[index.merchantCode][index.orderId].amount,
            withdrawInfos[index.merchantCode][index.orderId].blockNumber,
            withdrawInfos[index.merchantCode][index.orderId].timestamp
        );
    }
}