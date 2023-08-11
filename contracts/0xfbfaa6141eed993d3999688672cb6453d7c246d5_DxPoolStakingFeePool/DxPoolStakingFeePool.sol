/**
 *Submitted for verification at Etherscan.io on 2023-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
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


/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

interface IDxpoolStakingFeePool {
    event ValidatorEntered(bytes validatorPubkey, address depositorAddress, uint256 ts);
    event ValidatorLeft(bytes validatorPubkey, address depositorAddress, uint256 ts);
    event ValidatorRewardClaimed(address depositorAddress, address withdrawAddress, uint256 rewardAmount);
    event ValidatorTransferred(bytes indexed validatorPubkey, address indexed from, address indexed to, uint256 ts);
    event OperatorChanged(address newOperator);
    event CommissionFeeRateChanged(uint256 newFeeRate);
    event CommissionClaimed(address withdrawAddress, uint256 collectedAmount);

    // Only operation can do those operations

    /**
     * @notice Add a validator to the pool
     * @dev operatorOnly.
     */
    function enterPool(bytes calldata validatorPubKey, address depositorAddress) external;

    /**
     * @notice Remove a validator from the pool
     * @dev operatorOnly.
     */
    function leavePool(bytes calldata validatorPubKey) external;

    /**
     * @notice Add many validators to the pool
     * @dev operatorOnly.
     */
    function batchEnterPool(bytes calldata validatorPubKeys, address[] calldata depositorAddresses) external;

    /**
     * @notice Remove many validators from the pool
     * @dev operatorOnly.
     */
    function batchLeavePool(bytes calldata validatorPubKeys) external;


    // Only admin can do those operations

    /**
     * @notice Set the contract commission fee rate
     * @dev adminOnly.
     */
    function setStakeCommissionFeeRate(uint256 stakeCommissionFeeRate) external;

    /**
     * @notice Claim commission fees up to `amount`.
     * @dev adminOnly.
     */
    function claimStakeCommissionFee(address payable withdrawAddress, uint256 amount) external;

    /**
     * @notice Change the contract operator
     * @dev adminOnly.
     */
    function changeOperator(address newOperator) external;

    /**
     * @notice Disable withdrawal permission
     * @dev adminOnly.
     */
    function closePoolForWithdrawal() external;

    /**
     * @notice Enable withdrawal permission
     * @dev adminOnly.
     */
    function openPoolForWithdrawal() external;

    /**
     * @notice Transfer one or more validators to new fee pool owners.
     * @dev adminOnly.
     */
    function transferValidatorByAdmin(bytes calldata validatorPubKeys, address[] calldata toAddresses) external;

    /**
     * @notice Admin function to help users recover funds from a lost or stolen wallet
     * @dev adminOnly.
     */
    function emergencyWithdraw(address[] calldata depositor, address[] calldata withdrawAddress, uint256 amount) external;


    /**
     * @notice Admin function to transfer balance into a cold wallet for safe.
     * @dev adminOnly.
     */
    function saveToColdWallet(address wallet, uint256 amount) external;

    /**
     * @notice Admin function to transfer balance back from a cold wallet.
     * @dev adminOnly.
     */
    function loadFromColdWallet() external payable;

    // EveryOne can use those functions

    /**
     * @notice The amount of rewards a depositor can withdraw, and all rewards they have ever withdrawn
     */
    function getUserRewardInfo(address depositor) external view returns (uint256 totalRewards, uint256 unclaimedRewards, uint256 claimedRewards);

    /**
     * @notice Allow a depositor (`msg.sender`) to collect their tip rewards from the pool.
     * @dev Emits an {ValidatorRewardCollected} event.
     */
    function claimReward(address payable withdrawAddress, uint256 amount) external;

    /**
     * @notice The total count validators in the pool
     */
    function getTotalValidatorsCount() external view returns (uint256);

    /**
     * @notice A summary of the pool's current state
     */
    function getPoolInfo() external view returns (
        uint256 lastRewardBlock,
        uint256 accRewardPerValidator,
        uint256 totalValidatorsCount,
        uint256 totalClaimedStakeCommissionFee,
        uint256 totalPaidToUserRewards,
        uint256 totalTransferredToColdWallet,
        bool isPoolOpenForWithdrawal
    );

    /**
     * @notice A summary of the depositor's activity in the pool
     * @param user The depositor's address
     */
    function getUserInfo(address user) external view returns (
        uint256 validatorCount,
        uint256 totalReward,
        uint256 debit,
        uint256 claimedReward
    );

    /**
     * @notice A summary of pool stake commission fee 
     */
     function getStakeCommissionFeeInfo() external view returns (
         uint256 totalStakeCommissionFee, 
         uint256 unclaimedStakeCommissionFee,
         uint256 claimedStakeCommissionFee
     );

     function justifyValidatorInPool(bytes calldata validatorPubkey) external view returns (
        bool inPool,
        uint256 timestamp  
     );
}


// Storage Message
contract DxpoolStakingFeePoolStorage {
    // user struct
    struct UserInfo {
        uint128 validatorCount;
        uint128 totalReward;
        uint128 debit;
        uint128 claimedReward;
    }

    // admin, operator address
    address internal adminAddress;
    address internal operatorAddress;

    uint256 public totalClaimedStakeCommissionFee;
    uint256 public totalPaidToUserRewards;
    uint256 public totalTransferredToColdWallet;

    uint256 internal totalValidatorsCount;
    uint256 public   stakeCommissionFeeRate;

    bool public isOpenForWithdrawal;

    mapping(address => UserInfo) internal users;
    mapping(bytes => uint256) internal validatorOwnerAndJoinTime;

    uint256 internal accRewardPerValidator;
    uint256 internal accTotalStakeCommissionFee;

    uint256 internal lastRewardBlock;
    uint256 internal lastPeriodReward;
}


contract DxPoolStakingFeePool is
    IDxpoolStakingFeePool,
    DxpoolStakingFeePoolStorage,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuard
{
    using Address for address payable;

    // initialize 
    function initialize(address operatorAddress_, address adminAddress_) initializer external {
        require(operatorAddress_ != address(0));
        require(adminAddress_ != address(0));
        adminAddress = adminAddress_;
        operatorAddress = operatorAddress_;
        totalValidatorsCount = 0;
        stakeCommissionFeeRate = 2000;
        isOpenForWithdrawal = true;

        accRewardPerValidator = 0;
        accTotalStakeCommissionFee = 0;
        totalTransferredToColdWallet = 0;
        lastRewardBlock  = block.number;
        lastPeriodReward = getTotalRewards();
    }

    // Only admin can update contract
    function _authorizeUpgrade(address) internal override adminOnly {}

    // decode or encode validator information
    function decodeValidatorInfo(uint256 data) public pure returns (address, uint256) {
        address ownerAddress = address(uint160(data));
        uint256 joinPoolTimestamp = data >> 224;
        return (ownerAddress, joinPoolTimestamp);
    }

    function encodeValidatorInfo(address ownerAddress, uint256 joinPoolTimestamp) public pure returns (uint256) {
        return uint256(uint160(ownerAddress)) | (joinPoolTimestamp << 224);
    }

    // get total rewards since contract created
    function getTotalRewards() public view returns (uint256) {
        return address(this).balance
            + totalTransferredToColdWallet 
            + totalPaidToUserRewards
            + totalClaimedStakeCommissionFee;
    }

    // get accumulate rewards per validator 
    function getAccRewardPerValidator() public view returns (uint256) {
        return accRewardPerValidator / 1e6;
    }

    // get commission have earned
    function getAccStakeCommissionFee() public view returns (uint256) {
        uint256 currentPeriodReward = getTotalRewards();
        return (
            accTotalStakeCommissionFee
            + 1e6 * (currentPeriodReward - lastPeriodReward) * stakeCommissionFeeRate / 10000
        ) / 1e6;
    }

    // Compute a Reward by adding pending reward to user totalRewards
    function computeReward(address depositor) internal {
        uint256 userValidatorCount = users[depositor].validatorCount;
        if (userValidatorCount > 0) {
            uint256 pending = userValidatorCount * getAccRewardPerValidator() - users[depositor].debit;
            users[depositor].totalReward += uint128(pending);
        }
    }

    function updatePool() internal {
        if (block.number <= lastRewardBlock || totalValidatorsCount == 0) {
            return;
        }
        uint256 currentPeriodReward = getTotalRewards();
        accRewardPerValidator += 1e6 * (currentPeriodReward - lastPeriodReward) / totalValidatorsCount * (10000 - stakeCommissionFeeRate) / 10000;
        accTotalStakeCommissionFee += 1e6 * (currentPeriodReward - lastPeriodReward)  * stakeCommissionFeeRate / 10000;
        lastRewardBlock = block.number;
        lastPeriodReward = currentPeriodReward;
    }

    /**
     * Operator Functions
       Those methods Reference: https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/farms-pools/contracts/MasterChef.sol
    */
    function enterPool(bytes calldata validatorPubKey, address depositor) external nonReentrant operatorOnly {
        // One validator joined, the previous time period ends.
        updatePool();
        _enterPool(validatorPubKey, depositor);
        emit ValidatorEntered(validatorPubKey, depositor, block.timestamp);
    }

    function _enterPool(bytes calldata validatorPubKey,address depositor) internal {
        require(validatorOwnerAndJoinTime[validatorPubKey] == 0, "Validator already in pool");
        require(depositor != address(0), "depositorAddress not be empty");

        computeReward(depositor);

        users[depositor].validatorCount += 1;
        totalValidatorsCount += 1;
        validatorOwnerAndJoinTime[validatorPubKey] = encodeValidatorInfo(depositor, block.timestamp);
        users[depositor].debit = uint128(users[depositor].validatorCount * getAccRewardPerValidator());
    }

    function leavePool(
        bytes calldata validatorPubKey
    ) external nonReentrant operatorOnly {
        // One validator left, the previous time period ends.
        updatePool();
        address depositor = _leavePool(validatorPubKey);
        emit ValidatorLeft(validatorPubKey, depositor, block.timestamp);
    }

    function _leavePool(
        bytes calldata validatorPubKey
    ) internal returns (address depositorAddress) {
        (address depositor, ) = decodeValidatorInfo(validatorOwnerAndJoinTime[validatorPubKey]);
        require(depositor != address(0), "Validator not in pool");

        computeReward(depositor);

        totalValidatorsCount -= 1;
        users[depositor].validatorCount -= 1;
        delete validatorOwnerAndJoinTime[validatorPubKey];
        users[depositor].debit = uint128(users[depositor].validatorCount * getAccRewardPerValidator());

        return depositor;
    }

    function batchEnterPool(
        bytes calldata validatorPubkeyArray,
        address[] calldata depositorAddresses
    ) external nonReentrant operatorOnly {
        require(depositorAddresses.length == 1 || depositorAddresses.length * 48 == validatorPubkeyArray.length, "Invalid depositorAddresses length");

        updatePool();
        uint256 validatorCount = validatorPubkeyArray.length / 48;
        if (depositorAddresses.length == 1) {
            for(uint256 i = 0; i < validatorCount; i++) {
                _enterPool(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[0]);
                emit ValidatorEntered(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[0], block.timestamp);
            }
        } else {
            for(uint256 i = 0; i < validatorCount; i++) {
                _enterPool(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[i]);
                emit ValidatorEntered(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[i], block.timestamp);
            }
        }
    }

    function batchLeavePool(
        bytes calldata validatorPubkeyArray
    ) external nonReentrant operatorOnly {
        require(validatorPubkeyArray.length % 48 == 0, "pubKeyArray length not multiple of 48");

        updatePool();
        uint256 validatorCount = validatorPubkeyArray.length / 48;
        for(uint256 i = 0; i < validatorCount; i++) {
            address depositor = _leavePool(validatorPubkeyArray[i*48:(i+1)*48]);
            emit ValidatorLeft(validatorPubkeyArray[i*48:(i+1)*48], depositor, block.timestamp);
        }
    }

    // @returns totalRewards, unclaimedRewards, claimedRewards
    function computeRewards(address depositor) internal view returns (uint256, uint256, uint256) {
        uint256 accRewardPerValidatorWithCurPeriod = getAccRewardPerValidator();
        if (block.number > lastRewardBlock && totalValidatorsCount > 0) {
            uint256 currentPeriodReward = getTotalRewards();
            accRewardPerValidatorWithCurPeriod +=
               (1e6 * (currentPeriodReward - lastPeriodReward) / totalValidatorsCount * (10000 - stakeCommissionFeeRate) / 10000 ) / 1e6;
        }

        uint256 totalReward = users[depositor].totalReward + users[depositor].validatorCount * accRewardPerValidatorWithCurPeriod - users[depositor].debit;

        if (totalReward > users[depositor].claimedReward) {
            return (totalReward, totalReward - users[depositor].claimedReward, users[depositor].claimedReward);
        } else {
            return (users[depositor].claimedReward, 0, users[depositor].claimedReward);
        }
    }

    // This function estimates user totalRewards, unclaimedRewards, claimedRewards based on latest timestamp. 
    function getUserRewardInfo(address depositor) external view returns (uint256, uint256, uint256) {
        require(depositor != address(0), "depositorAddress not be empty");
        return computeRewards(depositor);
    }

    function _claimReward(
        address depositor,
        address payable withdrawAddress,
        uint256 amount
    ) internal {
        if (withdrawAddress == address(0)) {
            withdrawAddress = payable(depositor);
        }

        computeReward(depositor);
        users[depositor].debit = uint128(users[depositor].validatorCount * getAccRewardPerValidator());

        uint256 unClaimedReward = users[depositor].totalReward - users[depositor].claimedReward;
        if (amount == 0) {
            users[depositor].claimedReward += uint128(unClaimedReward);
            totalPaidToUserRewards += unClaimedReward;
            emit ValidatorRewardClaimed(depositor, withdrawAddress, unClaimedReward);
            require(unClaimedReward <= address(this).balance, "Please Contact stake.dxpool.com to fix");
            withdrawAddress.sendValue(unClaimedReward);
        } else {
            require(amount <= unClaimedReward, "Not enough unClaimed rewards");
            users[depositor].claimedReward += uint128(amount);
            totalPaidToUserRewards += amount;
            emit ValidatorRewardClaimed(depositor, withdrawAddress, amount);
            require(amount <= address(this).balance, "Please Contact stake.dxpool.com to fix");
            withdrawAddress.sendValue(amount);
        }
    }

    // claim rewards from the fee pool
    function claimReward(address payable withdrawAddress, uint256 amount) external nonReentrant {
        require(isOpenForWithdrawal, "Pool is not open for withdrawal");
        updatePool();
        _claimReward(msg.sender, withdrawAddress, amount);
    }

    /**
     * Admin Functions
     */
    function setStakeCommissionFeeRate(uint256 commissionFeeRate) external nonReentrant adminOnly {
        updatePool();
        stakeCommissionFeeRate = commissionFeeRate;
        emit CommissionFeeRateChanged(stakeCommissionFeeRate);
    }

    // Claim accumulated commission fees
    function claimStakeCommissionFee(address payable withdrawAddress, uint256 amount)
        external
        nonReentrant
        adminOnly
    {
        updatePool();
        uint256 totalCommissionFee = accTotalStakeCommissionFee / 1e6;
        uint256 unclaimedCommissionFee = totalCommissionFee - totalClaimedStakeCommissionFee;
        if (amount == 0) {
            totalClaimedStakeCommissionFee += unclaimedCommissionFee;
            emit CommissionClaimed(withdrawAddress, unclaimedCommissionFee);
            withdrawAddress.sendValue(unclaimedCommissionFee);
        } else {
            require(amount <= unclaimedCommissionFee, "Not enough unclaimed commission fee");
            totalClaimedStakeCommissionFee += amount;
            emit CommissionClaimed(withdrawAddress, amount);
            withdrawAddress.sendValue(amount);
        }
    }

    function _transferValidator(bytes calldata validatorPubKey, address to) internal {
        (address validatorOwner, ) = decodeValidatorInfo(validatorOwnerAndJoinTime[validatorPubKey]);
        require(validatorOwner != address(0), "Validator not in pool");
        require(to != address(0), "to address must be set to nonzero");
        require(to != validatorOwner, "cannot transfer validator owner to oneself");

        _leavePool(validatorPubKey);
        _enterPool(validatorPubKey, to);

        emit ValidatorTransferred(validatorPubKey, validatorOwner, to, block.timestamp);
    }

    function transferValidatorByAdmin(bytes calldata validatorPubkeys,address[] calldata toAddresses) external nonReentrant adminOnly {
        require(validatorPubkeys.length == toAddresses.length * 48, "validatorPubkeys byte array length incorrect");
        for (uint256 i = 0; i < toAddresses.length; i++) {
            _transferValidator(
                validatorPubkeys[i * 48 : (i + 1) * 48],
                toAddresses[i]
            );
        }
    }

    // Admin handle emergency situations where we want to temporarily pause all withdrawals.
    function closePoolForWithdrawal() external nonReentrant adminOnly {
        require(isOpenForWithdrawal, "Pool is already closed for withdrawal");
        isOpenForWithdrawal = false;
    }

    function openPoolForWithdrawal() external nonReentrant adminOnly {
        require(!isOpenForWithdrawal, "Pool is already open for withdrawal");
        isOpenForWithdrawal = true;
    }

    function changeOperator(address newOperatorAddress) external nonReentrant adminOnly {
        require(newOperatorAddress != address(0));
        operatorAddress = newOperatorAddress;
        emit OperatorChanged(operatorAddress);
    }

    function emergencyWithdraw (address[] calldata depositor, address[] calldata withdrawAddress, uint256 maxAmount)
        external
        nonReentrant
        adminOnly
    {
        require(withdrawAddress.length == depositor.length || withdrawAddress.length == 1, "withdrawAddress length incorrect");
        updatePool();
        if (withdrawAddress.length == 1) {
            for (uint256 i = 0; i < depositor.length; i++) {
                _claimReward(depositor[i], payable(withdrawAddress[0]), maxAmount);
            }
        } else {
            for (uint256 i = 0; i < depositor.length; i++) {
                _claimReward(depositor[i], payable(withdrawAddress[i]), maxAmount);
            }
        }
    }

    function saveToColdWallet(address wallet, uint256 amount) external nonReentrant adminOnly {
        require(amount <= address(this).balance, "Not enough balance");
        totalTransferredToColdWallet += amount;
        payable(wallet).sendValue(amount);
    }

    function loadFromColdWallet() external payable nonReentrant adminOnly {
        require(msg.value <= totalTransferredToColdWallet, "Too much transferred from cold wallet");
        totalTransferredToColdWallet -= msg.value;
    }

    function getTotalValidatorsCount() external view returns (uint256) {
        return totalValidatorsCount;
    }

    function getPoolInfo() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (
            lastRewardBlock,
            getAccRewardPerValidator(),
            totalValidatorsCount,
            totalClaimedStakeCommissionFee,
            totalPaidToUserRewards,
            totalTransferredToColdWallet,
            isOpenForWithdrawal
        );
    }

    function getUserInfo(address user) external view returns (uint256, uint256, uint256, uint256) {
        return (
            users[user].validatorCount,
            users[user].totalReward,
            users[user].debit,
            users[user].claimedReward
        );
    }

    function getStakeCommissionFeeInfo() external view returns (uint256, uint256, uint256) {
        // view function
        uint256 totalCommissionFee = getAccStakeCommissionFee();
        uint256 unclaimedCommissionFee = totalCommissionFee - totalClaimedStakeCommissionFee;
        return (
            totalCommissionFee,
            unclaimedCommissionFee,
            totalClaimedStakeCommissionFee
        );
    }

    function justifyValidatorInPool(bytes calldata validatorPubkey) external view returns (bool, uint256) {
        if (validatorOwnerAndJoinTime[validatorPubkey] == 0) {
            return (false, 0);
        } else {
            (, uint256 timeStamp) = decodeValidatorInfo(validatorOwnerAndJoinTime[validatorPubkey]);
            return (true, timeStamp);
        }
    }
    /**
     * Modifiers
     */
    modifier operatorOnly() {
        require(msg.sender == operatorAddress, "Only Dxpool staking operator allowed");
        _;
    }

    modifier adminOnly() {
        require(msg.sender == adminAddress, "Only Dxpool staking admin allowed");
        _;
    }
}