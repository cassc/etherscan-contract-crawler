/**
 *Submitted for verification at Etherscan.io on 2023-10-09
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

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

// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

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

// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

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

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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

// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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

// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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

/// @title Technical interface for reading data related to the UUPS proxy pattern in Ipor Protocol.
interface IProxyImplementation {
    /// @notice Retrieves the address of the implementation contract for UUPS proxy.
    /// @return The address of the implementation contract.
    /// @dev The function returns the value stored in the implementation storage slot.
    function getImplementation() external view returns (address);
}

/// @title Struct used across various interfaces in IPOR Protocol.
library IporTypes {
    /// @notice enum describing Swap's state, ACTIVE - when the swap is opened, INACTIVE when it's closed
    enum SwapState {
        INACTIVE,
        ACTIVE
    }

    /// @notice enum describing Swap's duration, 28 days, 60 days or 90 days
    enum SwapTenor {
        DAYS_28,
        DAYS_60,
        DAYS_90
    }

    /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
    /// Namely, the interest that would be computed into IBT should the rebalance occur.
    struct  AccruedIpor {
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice IBT Price (IBT - Interest Bearing Token). For more information refer to the documentation:
        /// https://ipor-labs.gitbook.io/ipor-labs/interest-rate-derivatives/ibt
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
    }

    /// @notice Struct representing balances used internally for asset calculations
    /// @dev all balances in 18 decimals
    struct AmmBalancesMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool Balance. This balance is where the liquidity from liquidity providers and the opening fee are accounted for,
        /// @dev Amount of opening fee accounted in this balance is defined by _OPENING_FEE_FOR_TREASURY_PORTION_RATE param.
        uint256 liquidityPool;
        /// @notice Vault's balance, describes how much asset has been transferred to Asset Management Vault (AssetManagement)
        uint256 vault;
    }

    struct AmmBalancesForOpenSwapMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Total notional amount of all swaps on  Pay Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Total notional amount of all swaps on  Receive Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalReceiveFixed;
        /// @notice Liquidity Pool Balance.
        uint256 liquidityPool;
    }

    struct SpreadInputs {
        //// @notice Swap's assets DAI/USDC/USDT
        address asset;
        /// @notice Swap's notional value
        uint256 swapNotional;
        /// @notice demand spread factor used in demand spread calculation
        uint256 demandSpreadFactor;
        /// @notice Base spread
        int256 baseSpreadPerLeg;
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPoolBalance;
        /// @notice Ipor index value at the time of swap creation
        uint256 iporIndexValue;
        // @notice fixed rate cap for given leg for offered rate without demandSpread in 18 decimals
        uint256 fixedRateCapPerLeg;
    }
}

/// @title Spread interface for tenor 28 days service
interface ISpread28Days {
    /// @notice Calculates the quote value for pay fixed 28-day period based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value.
    function calculateAndUpdateOfferedRatePayFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Calculates the quote value to receive fixed 28-day period based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value to receive.
    function calculateAndUpdateOfferedRateReceiveFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);
}

/// @title Spread interface for tenor 28 days service
interface ISpread60Days {
    /// @notice Calculates the quote value for a fixed 60-day period on the pay-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the pay-fixed side.
    function calculateAndUpdateOfferedRatePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Calculates the quote value for a fixed 60-day period on the receive-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the receive-fixed side.
    function calculateAndUpdateOfferedRateReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);
}

/// @title Spread interface for tenor 90 days service
interface ISpread90Days {
    /// @notice Calculates the quote value for a fixed 90-day period on the pay-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the pay-fixed side.
    function calculateAndUpdateOfferedRatePayFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Calculates the quote value for a fixed 90-day period on the receive-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the receive-fixed side.
    function calculateAndUpdateOfferedRateReceiveFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);
}

/// @title Spread interface for tenor 28 days lens
interface ISpread28DaysLens {
    /// @notice Calculates the quote value for pay fixed 28-day period on the pay-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the pay-fixed side.
    function calculateOfferedRatePayFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external view returns (uint256 quoteValue);

    /// @notice Calculates the quote value for a fixed 28-day period on the receive-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the receive-fixed side.
    function calculateOfferedRateReceiveFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external view returns (uint256 quoteValue);

    /// @notice Returns the configuration values for the spread function used in the 28-day imbalance spread calculation.
    /// @return An array of configuration values for the spread function.
    function spreadFunction28DaysConfig() external pure returns (uint256[] memory);
}

/// @title Spread interface for tenor 60 days lens
interface ISpread60DaysLens {
    /// @notice Calculates the quote value for a fixed 60-day period on the pay-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the pay-fixed side.
    function calculateOfferedRatePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Calculates the quote value for a fixed 60-day period on the receive-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the receive-fixed side.
    function calculateOfferedRateReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Returns the configuration values for the spread function used in the 60-day imbalance spread calculation.
    /// @return An array of configuration values for the spread function.
    function spreadFunction60DaysConfig() external pure returns (uint256[] memory);
}

/// @title Spread interface for tenor 90 days lens
interface ISpread90DaysLens {
    /// @notice Calculates the quote value for a fixed 90-day period on the pay-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the pay-fixed side.
    function calculateOfferedRatePayFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Calculates the quote value for a fixed 90-day period on the receive-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the receive-fixed side.
    function calculateOfferedRateReceiveFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Returns the configuration values for the spread function used in the 90-day imbalance spread calculation.
    /// @return An array of configuration values for the spread function.
    function spreadFunction90DaysConfig() external pure returns (uint256[] memory);
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

/// @title Errors which occur inside AmmTreasury's method execution.
library AmmErrors {
    // 300-399-AMM
    /// @notice Liquidity Pool balance is equal 0.
    string public constant LIQUIDITY_POOL_IS_EMPTY = "IPOR_300";

    /// @notice Liquidity Pool balance is too low, should be equal or higher than 0.
    string public constant LIQUIDITY_POOL_AMOUNT_TOO_LOW = "IPOR_301";

    /// @notice Liquidity Pool Collateral Ratio exceeded. Liquidity Pool Collateral Ratio is higher than configured in AmmTreasury maximum liquidity pool collateral ratio.
    string public constant LP_COLLATERAL_RATIO_EXCEEDED = "IPOR_302";

    /// @notice Liquidity Pool Collateral Ratio Per Leg exceeded. Liquidity Pool Collateral Ratio per leg is higher than configured in AmmTreasury maximum liquidity pool collateral ratio per leg.
    string public constant LP_COLLATERAL_RATIO_PER_LEG_EXCEEDED = "IPOR_303";

    /// @notice Liquidity Pool Balance is too high
    string public constant LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH = "IPOR_304";

    /// @notice Swap cannot be closed because liquidity pool is too low for payid out cash. Situation should never happen where Liquidity Pool is insolvent.
    string public constant CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW = "IPOR_305";

    /// @notice Swap id used in input has incorrect value (like 0) or not exists.
    string public constant INCORRECT_SWAP_ID = "IPOR_306";

    /// @notice Swap has incorrect status.
    string public constant INCORRECT_SWAP_STATUS = "IPOR_307";

    /// @notice Leverage given as a parameter when opening swap is lower than configured in AmmTreasury minimum leverage.
    string public constant LEVERAGE_TOO_LOW = "IPOR_308";

    /// @notice Leverage given as a parameter when opening swap is higher than configured in AmmTreasury maxumum leverage.
    string public constant LEVERAGE_TOO_HIGH = "IPOR_309";

    /// @notice Total amount given as a parameter when opening swap is too low. Cannot be equal zero.
    string public constant TOTAL_AMOUNT_TOO_LOW = "IPOR_310";

    /// @notice Total amount given as a parameter when opening swap is lower than sum of liquidation deposit amount and ipor publication fee.
    string public constant TOTAL_AMOUNT_LOWER_THAN_FEE = "IPOR_311";

    /// @notice Amount of collateral used to open swap is higher than configured in AmmTreasury max swap collateral amount
    string public constant COLLATERAL_AMOUNT_TOO_HIGH = "IPOR_312";

    /// @notice Acceptable fixed interest rate defined by traded exceeded.
    string public constant ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED = "IPOR_313";

    /// @notice Swap Notional Amount is higher than Total Notional for specific leg.
    string public constant SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL = "IPOR_314";

    /// @notice Number of swaps per leg which are going to be liquidated is too high, is higher than configured in AmmTreasury liquidation leg limit.
    string public constant MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED = "IPOR_315";

    /// @notice Sum of SOAP and Liquidity Pool Balance is lower than zero.
    /// @dev SOAP can be negative, Sum of SOAP and Liquidity Pool Balance can be negative, but this is undesirable.
    string public constant SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW = "IPOR_316";

    /// @notice Calculation timestamp is earlier than last SOAP rebalance timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SOAP_REBALANCE_TIMESTAMP = "IPOR_317";

    /// @notice Calculation timestamp is lower than  Swap's open timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_318";

    /// @notice Closing timestamp is lower than Swap's open timestamp.
    string public constant CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_319";

    /// @notice Swap cannot be closed because sender is not a buyer nor liquidator.
    string public constant CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR = "IPOR_320";

    /// @notice Interest from Strategy is below zero.
    string public constant INTEREST_FROM_STRATEGY_EXCEEDED_THRESHOLD = "IPOR_321";

    /// @notice IPOR publication fee balance is too low.
    string public constant PUBLICATION_FEE_BALANCE_IS_TOO_LOW = "IPOR_322";

    /// @notice The caller must be the Token Manager (Smart Contract responsible for managing token total supply).
    string public constant CALLER_NOT_TOKEN_MANAGER = "IPOR_323";

    /// @notice Deposit amount is too low.
    string public constant DEPOSIT_AMOUNT_IS_TOO_LOW = "IPOR_324";

    /// @notice Vault balance is lower than deposit value.
    string public constant VAULT_BALANCE_LOWER_THAN_DEPOSIT_VALUE = "IPOR_325";

    /// @notice Treasury balance is too low.
    string public constant TREASURY_BALANCE_IS_TOO_LOW = "IPOR_326";

    /// @notice Swap cannot be closed because closing timestamp is lower than swap's open timestamp in general.
    string public constant CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY = "IPOR_327";

    /// @notice Swap cannot be closed because closing timestamp is lower than swap's open timestamp for buyer.
    string public constant CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY_FOR_BUYER = "IPOR_328";

    /// @notice Swap cannot be closed and unwind because is too late
    string public constant CANNOT_UNWIND_CLOSING_TOO_LATE = "IPOR_329";

    /// @notice Unsupported swap tenor
    string public constant UNSUPPORTED_SWAP_TENOR = "IPOR_330";

    /// @notice Sender is not AMM (is not a IporProtocolRouter contract)
    string public constant SENDER_NOT_AMM = "IPOR_331";

    /// @notice Storage id is not time weighted notional group
    string public constant STORAGE_ID_IS_NOT_TIME_WEIGHTED_NOTIONAL = "IPOR_332";

    /// @notice Spread function is not supported
    string public constant FUNCTION_NOT_SUPPORTED = "IPOR_333";

    /// @notice Unsupported direction
    string public constant UNSUPPORTED_DIRECTION = "IPOR_334";

    /// @notice Invalid notional
    string public constant INVALID_NOTIONAL = "IPOR_335";

    /// @notice Average interest rate cannot be zero when open swap
    string public constant AVERAGE_INTEREST_RATE_WHEN_OPEN_SWAP_CANNOT_BE_ZERO = "IPOR_336";

    /// @notice Average interest rate cannot be zero when close swap
    string public constant AVERAGE_INTEREST_RATE_WHEN_CLOSE_SWAP_CANNOT_BE_ZERO = "IPOR_337";

    /// @notice Submit ETH to stETH contract failed.
    string public constant STETH_SUBMIT_FAILED = "IPOR_338";

    /// @notice Collateral is not sufficient to cover unwind swap
    string public constant COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP = "IPOR_339";

    /// @notice Error when withdraw from asset management is not enough to cover transfer amount to buyer and/or beneficiary
    string public constant ASSET_MANAGEMENT_WITHDRAW_NOT_ENOUGH = "IPOR_340";
}

/// @title Spread storage library
library SpreadStorageLibs {
    using SafeCast for uint256;
    uint256 private constant STORAGE_SLOT_BASE = 10_000;

    /// Only allowed to append new value to the end of the enum
    enum StorageId {
        // address
        Owner,
        // address
        AppointedOwner,
        // uint256
        Paused,
        // WeightedNotionalStorage
        TimeWeightedNotional28DaysDai,
        TimeWeightedNotional28DaysUsdc,
        TimeWeightedNotional28DaysUsdt,
        TimeWeightedNotional60DaysDai,
        TimeWeightedNotional60DaysUsdc,
        TimeWeightedNotional60DaysUsdt,
        TimeWeightedNotional90DaysDai,
        TimeWeightedNotional90DaysUsdc,
        TimeWeightedNotional90DaysUsdt
    }

    /// @notice Struct which contains owner address of Spread Router
    struct OwnerStorage {
        address owner;
    }

    /// @notice Struct which contains pause flag on Spread Router
    struct PausedStorage {
        uint256 value;
    }

    /// @notice Struct which contains address of appointed owner of Spread Router
    struct AppointedOwnerStorage {
        address appointedOwner;
    }

    /// @notice Saves time weighted notional for a specific asset and tenor
    /// @param timeWeightedNotionalStorageId The storage ID of the time weighted notional
    /// @param timeWeightedNotional The time weighted notional to save
    function saveTimeWeightedNotionalForAssetAndTenor(
        StorageId timeWeightedNotionalStorageId,
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional
    ) internal {
        _checkTimeWeightedNotional(timeWeightedNotionalStorageId);
        uint256 timeWeightedNotionalPayFixedTemp;
        uint256 timeWeightedNotionalReceiveFixedTemp;
        unchecked {
            timeWeightedNotionalPayFixedTemp = timeWeightedNotional.timeWeightedNotionalPayFixed / 1e18;

            timeWeightedNotionalReceiveFixedTemp = timeWeightedNotional.timeWeightedNotionalReceiveFixed / 1e18;
        }

        uint96 timeWeightedNotionalPayFixed = timeWeightedNotionalPayFixedTemp.toUint96();
        uint32 lastUpdateTimePayFixed = timeWeightedNotional.lastUpdateTimePayFixed.toUint32();
        uint96 timeWeightedNotionalReceiveFixed = timeWeightedNotionalReceiveFixedTemp.toUint96();
        uint32 lastUpdateTimeReceiveFixed = timeWeightedNotional.lastUpdateTimeReceiveFixed.toUint32();
        uint256 slotAddress = _getStorageSlot(timeWeightedNotionalStorageId);
        assembly {
            let value := add(
                timeWeightedNotionalPayFixed,
                add(
                    shl(96, lastUpdateTimePayFixed),
                    add(shl(128, timeWeightedNotionalReceiveFixed), shl(224, lastUpdateTimeReceiveFixed))
                )
            )
            sstore(slotAddress, value)
        }
    }

    /// @notice Gets the time-weighted notional for a specific storage ID representing an asset and tenor
    /// @param timeWeightedNotionalStorageId The storage ID of the time weighted notional
    function getTimeWeightedNotionalForAssetAndTenor(
        StorageId timeWeightedNotionalStorageId
    ) internal view returns (SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional28Days) {
        _checkTimeWeightedNotional(timeWeightedNotionalStorageId);
        uint256 timeWeightedNotionalPayFixed;
        uint256 lastUpdateTimePayFixed;
        uint256 timeWeightedNotionalReceiveFixed;
        uint256 lastUpdateTimeReceiveFixed;
        uint256 slotAddress = _getStorageSlot(timeWeightedNotionalStorageId);
        assembly {
            let slotValue := sload(slotAddress)
            timeWeightedNotionalPayFixed := mul(and(slotValue, 0xFFFFFFFFFFFFFFFFFFFFFFFF), 1000000000000000000)
            lastUpdateTimePayFixed := and(shr(96, slotValue), 0xFFFFFFFF)
            timeWeightedNotionalReceiveFixed := mul(
                and(shr(128, slotValue), 0xFFFFFFFFFFFFFFFFFFFFFFFF),
                1000000000000000000
            )
            lastUpdateTimeReceiveFixed := and(shr(224, slotValue), 0xFFFFFFFF)
        }

        return
            SpreadTypes.TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: timeWeightedNotionalPayFixed,
                lastUpdateTimePayFixed: lastUpdateTimePayFixed,
                timeWeightedNotionalReceiveFixed: timeWeightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed: lastUpdateTimeReceiveFixed,
                storageId: timeWeightedNotionalStorageId
            });
    }

    /// @notice Gets all time weighted notional storage IDs
    function getAllStorageId() internal pure returns (StorageId[] memory storageIds, string[] memory keys) {
        storageIds = new StorageId[](9);
        keys = new string[](9);
        storageIds[0] = StorageId.TimeWeightedNotional28DaysDai;
        keys[0] = "TimeWeightedNotional28DaysDai";
        storageIds[1] = StorageId.TimeWeightedNotional28DaysUsdc;
        keys[1] = "TimeWeightedNotional28DaysUsdc";
        storageIds[2] = StorageId.TimeWeightedNotional28DaysUsdt;
        keys[2] = "TimeWeightedNotional28DaysUsdt";
        storageIds[3] = StorageId.TimeWeightedNotional60DaysDai;
        keys[3] = "TimeWeightedNotional60DaysDai";
        storageIds[4] = StorageId.TimeWeightedNotional60DaysUsdc;
        keys[4] = "TimeWeightedNotional60DaysUsdc";
        storageIds[5] = StorageId.TimeWeightedNotional60DaysUsdt;
        keys[5] = "TimeWeightedNotional60DaysUsdt";
        storageIds[6] = StorageId.TimeWeightedNotional90DaysDai;
        keys[6] = "TimeWeightedNotional90DaysDai";
        storageIds[7] = StorageId.TimeWeightedNotional90DaysUsdc;
        keys[7] = "TimeWeightedNotional90DaysUsdc";
        storageIds[8] = StorageId.TimeWeightedNotional90DaysUsdt;
        keys[8] = "TimeWeightedNotional90DaysUsdt";
    }

    /// @notice Gets the owner of the Spread Router
    /// @return owner The owner of the Spread Router
    function getOwner() internal pure returns (OwnerStorage storage owner) {
        uint256 slotAddress = _getStorageSlot(StorageId.Owner);
        assembly {
            owner.slot := slotAddress
        }
    }

    /// @notice Gets the appointed owner of the Spread Router
    /// @return appointedOwner The appointed owner of the Spread Router
    function getAppointedOwner() internal pure returns (AppointedOwnerStorage storage appointedOwner) {
        uint256 slotAddress = _getStorageSlot(StorageId.AppointedOwner);
        assembly {
            appointedOwner.slot := slotAddress
        }
    }

    /// @notice Gets the paused state of the Spread Router
    /// @return paused The paused state of the Spread Router
    function getPaused() internal pure returns (PausedStorage storage paused) {
        uint256 slotAddress = _getStorageSlot(StorageId.Paused);
        assembly {
            paused.slot := slotAddress
        }
    }

    function _getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        slot = uint256(storageId) + STORAGE_SLOT_BASE;
    }

    function _checkTimeWeightedNotional(StorageId storageId) internal pure {
        require(
            storageId == StorageId.TimeWeightedNotional28DaysDai ||
                storageId == StorageId.TimeWeightedNotional28DaysUsdc ||
                storageId == StorageId.TimeWeightedNotional28DaysUsdt ||
                storageId == StorageId.TimeWeightedNotional60DaysDai ||
                storageId == StorageId.TimeWeightedNotional60DaysUsdc ||
                storageId == StorageId.TimeWeightedNotional60DaysUsdt ||
                storageId == StorageId.TimeWeightedNotional90DaysDai ||
                storageId == StorageId.TimeWeightedNotional90DaysUsdc ||
                storageId == StorageId.TimeWeightedNotional90DaysUsdt,
            AmmErrors.STORAGE_ID_IS_NOT_TIME_WEIGHTED_NOTIONAL
        );
    }
}

library SpreadTypes {
    /// @notice structure used to save the weighted notional for the 28 days into storage
    /// timeWeightedNotionalPayFixed without decimals - uint96 - bytes 0-96
    /// lastUpdateTimePayFixed - uint32 - bytes 96-128
    /// timeWeightedNotionalReceiveFixed  without decimals - uint96 - bytes 128-224
    /// lastUpdateTimeReceiveFixed - uint32 - bytes 224-256
    struct WeightedNotionalStorage {
        bytes32 weightedNotional;
    }

    /// @notice Dto for the Weighted Notional
    struct TimeWeightedNotionalMemory {
        /// @notice timeWeightedNotionalPayFixed with 18 decimals
        uint256 timeWeightedNotionalPayFixed;
        /// @notice lastUpdateTimePayFixed timestamp in seconds
        uint256 lastUpdateTimePayFixed;
        /// @notice timeWeightedNotionalReceiveFixed with 18 decimals
        uint256 timeWeightedNotionalReceiveFixed;
        /// @notice lastUpdateTimeReceiveFixed timestamp in seconds
        uint256 lastUpdateTimeReceiveFixed;
        /// @notice storageId from SpreadStorageLibs
        SpreadStorageLibs.StorageId storageId;
    }

    /// @notice Technical structure used in Lens for the Weighted Notional params
    struct TimeWeightedNotionalResponse {
        /// @notice timeWeightedNotionalPayFixed time weighted notional params
        TimeWeightedNotionalMemory timeWeightedNotional;
        string key;
    }
}

/// @title Spread interface for storage lens
interface ISpreadStorageLens {
    /// @notice Gets the time-weighted notional for all supported assets and tenors.
    /// @return timeWeightedNotionalResponse The time-weighted notional for all supported assets and tenors.
    function getTimeWeightedNotional()
        external
        returns (SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse);
}

/// @title Types used in interfaces strictly related to AMM (Automated Market Maker).
/// @dev Used by IAmmTreasury and IAmmStorage interfaces.
library AmmTypes {
    /// @notice Struct describing AMM Pool's core addresses.
    struct AmmPoolCoreModel {
        /// @notice asset address
        address asset;
        /// @notice asset decimals
        uint256 assetDecimals;
        /// @notice ipToken address associated to the asset
        address ipToken;
        /// @notice AMM Storage address
        address ammStorage;
        /// @notice AMM Treasury address
        address ammTreasury;
        /// @notice Asset Management address
        address assetManagement;
        /// @notice IPOR Oracle address
        address iporOracle;
        /// @notice IPOR Risk Management Oracle address
        address iporRiskManagementOracle;
    }

    /// @notice Structure which represents Swap's data that will be saved in the storage.
    /// Refer to the documentation https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps for more information.
    struct NewSwap {
        /// @notice Account / trader who opens the Swap
        address buyer;
        /// @notice Epoch timestamp of when position was opened by the trader.
        uint256 openTimestamp;
        /// @notice Swap's collateral amount.
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount.
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Quantity of Interest Bearing Token (IBT) at moment when position was opened.
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened.
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit is retained when the swap is opened. It is then paid back to agent who closes the derivative at maturity.
        /// It can be both trader or community member. Trader receives the deposit back when he chooses to close the derivative before maturity.
        /// @dev value represented WITHOUT 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice Opening fee amount part which is allocated in Liquidity Pool Balance. This fee is calculated as a rate of the swap's collateral.
        /// @dev value represented in 18 decimals
        uint256 openingFeeLPAmount;
        /// @notice Opening fee amount part which is allocated in Treasury Balance. This fee is calculated as a rate of the swap's collateral.
        /// @dev value represented in 18 decimals
        uint256 openingFeeTreasuryAmount;
        /// @notice Swap's tenor, 0 - 28 days, 1 - 60 days or 2 - 90 days
        IporTypes.SwapTenor tenor;
    }

    /// @notice Struct representing swap item, used for listing and in internal calculations
    struct Swap {
        /// @notice Swap's unique ID
        uint256 id;
        /// @notice Swap's buyer
        address buyer;
        /// @notice Swap opening epoch timestamp
        uint256 openTimestamp;
        /// @notice Swap's tenor
        IporTypes.SwapTenor tenor;
        /// @notice Index position of this Swap in an array of swaps' identification associated to swap buyer
        /// @dev Field used for gas optimization purposes, it allows for quick removal by id in the array.
        /// During removal the last item in the array is switched with the one that just has been removed.
        uint256 idsIndex;
        /// @notice Swap's collateral
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit amount
        /// @dev value represented in 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        IporTypes.SwapState state;
    }

    /// @notice Struct representing amounts related to Swap that is presently being opened.
    /// @dev all values represented in 18 decimals
    struct OpenSwapAmount {
        /// @notice Total Amount of asset that is sent from buyer to AmmTreasury when opening swap.
        uint256 totalAmount;
        /// @notice Swap's collateral
        uint256 collateral;
        /// @notice Swap's notional
        uint256 notional;
        /// @notice Opening Fee - part allocated as a profit of the Liquidity Pool
        uint256 openingFeeLPAmount;
        /// @notice  Part of the fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO.
        /// @notice Opening Fee - part allocated in Treasury balance. Part of the fee set asside for subsidising the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 openingFeeTreasuryAmount;
        /// @notice Fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 iporPublicationFee;
        /// @notice Liquidation deposit is retained when the swap is opened. Value represented in 18 decimals.
        uint256 liquidationDepositAmount;
    }

    /// @notice Structure describes one swap processed by closeSwaps method, information about swap ID and flag if this swap was closed during execution closeSwaps method.
    struct IporSwapClosingResult {
        /// @notice Swap ID
        uint256 swapId;
        /// @notice Flag describe if swap was closed during this execution
        bool closed;
    }

    /// @notice Technical structure used for storing information about amounts used during redeeming assets from liquidity pool.
    struct RedeemAmount {
        /// @notice Asset amount represented in 18 decimals
        /// @dev Asset amount is a sum of wadRedeemFee and wadRedeemAmount
        uint256 wadAssetAmount;
        /// @notice Redeemed amount represented in decimals of asset
        uint256 redeemAmount;
        /// @notice Redeem fee value represented in 18 decimals
        uint256 wadRedeemFee;
        /// @notice Redeem amount represented in 18 decimals
        uint256 wadRedeemAmount;
    }

    /// @notice Swap direction (long = Pay Fixed and Receive a Floating or short = receive fixed and pay a floating)
    enum SwapDirection {
        /// @notice When taking the "long" position the trader will pay a fixed rate and receive a floating rate.
        /// for more information refer to the documentation https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps
        PAY_FIXED_RECEIVE_FLOATING,
        /// @notice When taking the "short" position the trader will pay a floating rate and receive a fixed rate.
        PAY_FLOATING_RECEIVE_FIXED
    }
    /// @notice List of closable statuses for a given swap
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Community
    enum SwapClosableStatus {
        SWAP_IS_CLOSABLE,
        SWAP_ALREADY_CLOSED,
        SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE,
        SWAP_CANNOT_CLOSE_CLOSING_TOO_EARLY_FOR_COMMUNITY
    }

    /// @notice Collection of swap attributes connected with IPOR Index and swap itself.
    /// @dev all values are in 18 decimals
    struct IporSwapIndicator {
        /// @notice IPOR Index value at the time of swap opening
        uint256 iporIndexValue;
        /// @notice IPOR Interest Bearing Token (IBT) price at the time of swap opening
        uint256 ibtPrice;
        /// @notice Swap's notional denominated in IBT
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened,
        /// it is quote from spread documentation
        uint256 fixedInterestRate;
    }

    /// @notice Risk indicators calculated for swap opening
    struct OpenSwapRiskIndicators {
        /// @notice Maximum collateral ratio in general
        uint256 maxCollateralRatio;
        /// @notice Maximum collateral ratio for a given leg
        uint256 maxCollateralRatioPerLeg;
        /// @notice Maximum leverage for a given leg
        uint256 maxLeveragePerLeg;
        /// @notice Base Spread for a given leg (without demand part)
        int256 baseSpreadPerLeg;
        /// @notice Fixed rate cap
        uint256 fixedRateCapPerLeg;
        /// @notice Demand spread factor used to calculate demand spread
        uint256 demandSpreadFactor;
    }

    /// @notice Structure containing information about swap's closing status, unwind values and PnL for a given swap and time.
    struct ClosingSwapDetails {
        /// @notice Swap's closing status
        AmmTypes.SwapClosableStatus closableStatus;
        /// @notice Flag indicating if swap unwind is required
        bool swapUnwindRequired;
        /// @notice Swap's unwind PnL Value, part of PnL corresponded to virtual swap (unwinded swap), represented in 18 decimals
        int256 swapUnwindPnlValue;
        /// @notice Unwind opening fee amount it is a sum of `swapUnwindFeeLPAmount` and `swapUnwindFeeTreasuryAmount`
        uint256 swapUnwindOpeningFeeAmount;
        /// @notice Part of unwind opening fee allocated as a profit of the Liquidity Pool
        uint256 swapUnwindFeeLPAmount;
        /// @notice Part of unwind opening fee allocated in Treasury Balance
        uint256 swapUnwindFeeTreasuryAmount;
        /// @notice Final Profit and Loss which takes into account the swap unwind and limits the PnL to the collateral amount. Represented in 18 decimals.
        int256 pnlValue;
    }
}

/// @notice The types used in the AmmTreasury's interface.
/// @dev All values, where applicable, are represented in 18 decimals.
library AmmInternalTypes {
    struct PnlValueStruct    {
        /// @notice PnL Value of the swap.
        int256 pnlValue;
        /// @notice flag indicating if unwind is required when closing swap.
        bool swapUnwindRequired;
        /// @notice Unwind amount of the swap.
        int256 swapUnwindAmount;
        /// @notice Unwind fee of the swap that will be added to the AMM liquidity pool balance.
        uint256 swapUnwindFeeLPAmount;
        /// @notice Unwind fee of the swap that will be added to the AMM treasury balance.
        uint256 swapUnwindFeeTreasuryAmount;
    }

    struct BeforeOpenSwapStruct {
        /// @notice Sum of all asset transfered when opening swap. It includes the collateral, fees and desposits.
        /// @dev The amount is represented in 18 decimals regardless of the decimals of the asset.
        uint256 wadTotalAmount;
        /// @notice Swap's collateral.
        uint256 collateral;
        /// @notice Swap's notional amount.
        uint256 notional;
        /// @notice The part of the opening fee that will be added to the liquidity pool balance.
        uint256 openingFeeLPAmount;
        /// @notice Part of the opening fee that will be added to the treasury balance.
        uint256 openingFeeTreasuryAmount;
        /// @notice Amount of asset set aside for the oracle subsidization.
        uint256 iporPublicationFeeAmount;
        /// @notice Refundable deposit blocked for the entity that will close the swap.
        /// For more information on how the liquidations work refer to the documentation.
        /// https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/liquidations
        /// @dev value represented without decimals, as an integer
        uint256 liquidationDepositAmount;
        /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
        /// Namely, the interest that would be computed into IBT should the rebalance occur.
        IporTypes.AccruedIpor accruedIpor;
    }

    /// @notice Risk indicators context data
    struct RiskIndicatorsContext {
        /// @notice Asset address for which the risk indicators are calculated.
        address asset;
        /// @notice Ipor Risk Management Oracle address.
        address iporRiskManagementOracle;
        /// @notice Tenor of the swap.
        IporTypes.SwapTenor tenor;
        /// @notice AMM Liquidity Pool balance.
        uint256 liquidityPoolBalance;
        /// @notice AMM Min Leverage allowed for a swap.
        uint256 minLeverage;
    }

    /// @notice Spread context data
    struct SpreadContext {
        /// @notice Asset address for which the spread is calculated.
        address asset;
        /// @notice Signature of spread method used to calculate spread.
        bytes4 spreadFunctionSig;
        /// @notice Tenor of the swap.
        IporTypes.SwapTenor tenor;
        /// @notice Swap's notional
        uint256 notional;
        /// @notice Minimum leverage allowed for a swap.
        uint256 minLeverage;
        /// @notice Ipor Index Value
        uint256 indexValue;
        /// @notice Risk Indicators data for a opened swap used to calculate spread.
        AmmTypes.OpenSwapRiskIndicators riskIndicators;
        /// @notice AMM Balance for a opened swap used to calculate spread.
        IporTypes.AmmBalancesForOpenSwapMemory balance;
    }

    /// @notice Open swap item - element of linked list of swaps
    struct OpenSwapItem {
        /// @notice Swap ID
        uint32 swapId;
        /// @notcie Next swap ID in linked list
        uint32 nextSwapId;
        /// @notice Previous swap ID in linked list
        uint32 previousSwapId;
        /// @notice Timestamp of the swap opening
        uint32 openSwapTimestamp;
    }

    /// @notice Open swap list structure
    struct OpenSwapList {
        /// @notice Head swap ID
        uint32 headSwapId;
        /// @notice Swaps mapping, where key is swap ID
        mapping(uint32 => OpenSwapItem) swaps;
    }
}

/// @title Spread interface for close swap, service
interface ISpreadCloseSwapService {
    /// @notice Updates the time-weighted notional on swap closure.
    /// @dev Updates the time-weighted notional for the specified asset and tenor based on the swap closure.
    /// @param asset The address of the asset involved in the swap.
    /// @param direction The direction of the swap: 0 for Pay Fixed, 1 for Receive Fixed.
    /// @param tenor The tenor of the swap.
    /// @param swapNotional The notional amount of the swap.
    /// @param closedSwap The memory struct containing the swap information.
    /// @param ammStorageAddress The address of the AMM storage.
    function updateTimeWeightedNotionalOnClose(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external;
}

library IporErrors {
    // 000-199 - general codes

    /// @notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_000";

    /// @notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_001";

    /// @notice General problem, addresses mismatch
    string public constant ADDRESSES_MISMATCH = "IPOR_002";

    /// @notice Sender's asset balance is too low to transfer and to open a swap
    string public constant SENDER_ASSET_BALANCE_TOO_LOW = "IPOR_003";

    /// @notice Value is not greater than zero
    string public constant VALUE_NOT_GREATER_THAN_ZERO = "IPOR_004";

    /// @notice Input arrays length mismatch
    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_005";

    /// @notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_006";

    /// @notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_007";

    /// @notice only Router can have access to function
    string public constant CALLER_NOT_IPOR_PROTOCOL_ROUTER = "IPOR_008";

    /// @notice Chunk size is equal to zero
    string public constant CHUNK_SIZE_EQUAL_ZERO = "IPOR_009";

    /// @notice Chunk size is too big
    string public constant CHUNK_SIZE_TOO_BIG = "IPOR_010";

    /// @notice Caller is not a  guardian
    string public constant CALLER_NOT_GUARDIAN = "IPOR_011";

    /// @notice Request contains invalid method signature, which is not supported by the Ipor Protocol Router
    string public constant ROUTER_INVALID_SIGNATURE = "IPOR_012";

    /// @notice Only AMM Treasury can have access to function
    string public constant CALLER_NOT_AMM_TREASURY = "IPOR_013";

    /// @notice Caller is not an owner
    string public constant CALLER_NOT_OWNER = "IPOR_014";

    /// @notice Method is paused
    string public constant METHOD_PAUSED = "IPOR_015";

    /// @notice Reentrancy appears
    string public constant REENTRANCY = "IPOR_016";

    /// @notice Asset is not supported
    string public constant ASSET_NOT_SUPPORTED = "IPOR_017";

    /// @notice Return back ETH failed in Ipor Protocol Router
    string public constant ROUTER_RETURN_BACK_ETH_FAILED = "IPOR_018";
}

library IporContractValidator {
    function checkAddress(address addr) internal pure returns (address) {
        require(addr != address(0), IporErrors.WRONG_ADDRESS);
        return addr;
    }
}

/// @title Interface for interaction with standalone IPOR smart contract by DAO government with common methods.
interface IIporContractCommonGov {
    /// @notice Pauses current smart contract. It can be executed only by the Owner.
    /// @dev Emits {Paused} event from AssetManagement.
    function pause() external;

    /// @notice Unpauses current smart contract. It can be executed only by the Owner
    /// @dev Emits {Unpaused} event from AssetManagement.
    function unpause() external;

    /// @notice Checks if given account is a pause guardian.
    /// @param account The address of the account to be checked.
    /// @return true if account is a pause guardian.
    function isPauseGuardian(address account) external view returns (bool);

    /// @notice Adds a pause guardian to the list of guardians. Function available only for the Owner.
    /// @param guardians The list of addresses of the pause guardians to be added.
    function addPauseGuardians(address[] calldata guardians) external;

    /// @notice Removes a pause guardian from the list of guardians. Function available only for the Owner.
    /// @param guardians The list of addresses of the pause guardians to be removed.
    function removePauseGuardians(address[] calldata guardians) external;
}

/// @title Storage ID's associated with the IPOR Protocol Router.
library StorageLib {
    uint256 constant STORAGE_SLOT_BASE = 1_000_000;

    // append only
    enum StorageId {
        /// @dev The address of the contract owner.
        Owner,
        AppointedOwner,
        Paused,
        PauseGuardian,
        ReentrancyStatus,
        RouterFunctionPaused,
        AmmSwapsLiquidators,
        AmmPoolsAppointedToRebalance,
        AmmPoolsParams
    }

    /// @notice Struct which contains owner address of IPOR Protocol Router.
    struct OwnerStorage {
        address owner;
    }

    /// @notice Struct which contains appointed owner address of IPOR Protocol Router.
    struct AppointedOwnerStorage {
        address appointedOwner;
    }

    /// @notice Struct which contains reentrancy status of IPOR Protocol Router.
    struct ReentrancyStatusStorage {
        uint256 value;
    }

    /// @notice Struct which contains information about swap liquidators.
    /// @dev First key is an asset (pool), second key is an liquidator address in the asset pool,
    /// value is a flag to indicate whether account is a liquidator.
    /// True - account is a liquidator, False - account is not a liquidator.
    struct AmmSwapsLiquidatorsStorage {
        mapping(address => mapping(address => bool)) value;
    }

    /// @notice Struct which contains information about accounts appointed to rebalance.
    /// @dev first key - asset address, second key - account address which is allowed to rebalance in the asset pool,
    /// value - flag to indicate whether account is allowed to rebalance. True - allowed, False - not allowed.
    struct AmmPoolsAppointedToRebalanceStorage {
        mapping(address => mapping(address => bool)) value;
    }

    struct AmmPoolsParamsValue {
        /// @dev max liquidity pool balance in the asset pool, represented without 18 decimals
        uint32 maxLiquidityPoolBalance;
        /// @dev The threshold for auto-rebalancing the pool. Value represented without 18 decimals.
        /// Value represents multiplication of 1000.
        uint32 autoRebalanceThresholdInThousands;
        /// @dev asset management ratio, represented without 18 decimals, value represents percentage with 2 decimals
        /// 65% = 6500, 99,99% = 9999, this is a percentage which stay in Amm Treasury in opposite to Asset Management
        /// based on AMM Treasury balance (100%).
        uint16 ammTreasuryAndAssetManagementRatio;
    }

    /// @dev key - asset address, value - struct AmmOpenSwapParamsValue
    struct AmmPoolsParamsStorage {
        mapping(address => AmmPoolsParamsValue) value;
    }

    /// @dev key - function sig, value - 1 if function is paused, 0 if not
    struct RouterFunctionPausedStorage {
        mapping(bytes4 => uint256) value;
    }

    /// @notice Gets Ipor Protocol Router owner address.
    function getOwner() internal pure returns (OwnerStorage storage owner) {
        uint256 slot = _getStorageSlot(StorageId.Owner);
        assembly {
            owner.slot := slot
        }
    }

    /// @notice Gets Ipor Protocol Router appointed owner address.
    function getAppointedOwner() internal pure returns (AppointedOwnerStorage storage appointedOwner) {
        uint256 slot = _getStorageSlot(StorageId.AppointedOwner);
        assembly {
            appointedOwner.slot := slot
        }
    }

    /// @notice Gets Ipor Protocol Router reentrancy status.
    function getReentrancyStatus() internal pure returns (ReentrancyStatusStorage storage reentrancyStatus) {
        uint256 slot = _getStorageSlot(StorageId.ReentrancyStatus);
        assembly {
            reentrancyStatus.slot := slot
        }
    }

    /// @notice Gets information if function is paused in Ipor Protocol Router.
    function getRouterFunctionPaused() internal pure returns (RouterFunctionPausedStorage storage paused) {
        uint256 slot = _getStorageSlot(StorageId.RouterFunctionPaused);
        assembly {
            paused.slot := slot
        }
    }

    /// @notice Gets point to pause guardian storage.
    function getPauseGuardianStorage() internal pure returns (mapping(address => bool) storage store) {
        uint256 slot = _getStorageSlot(StorageId.PauseGuardian);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to liquidators storage.
    /// @return store - point to liquidators storage.
    function getAmmSwapsLiquidatorsStorage() internal pure returns (AmmSwapsLiquidatorsStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmSwapsLiquidators);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to accounts appointed to rebalance storage.
    /// @return store - point to accounts appointed to rebalance storage.
    function getAmmPoolsAppointedToRebalanceStorage()
        internal
        pure
        returns (AmmPoolsAppointedToRebalanceStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsAppointedToRebalance);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to amm pools params storage.
    /// @return store - point to amm pools params storage.
    function getAmmPoolsParamsStorage() internal pure returns (AmmPoolsParamsStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsParams);
        assembly {
            store.slot := slot
        }
    }

    function _getStorageSlot(StorageId storageId) private pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}

/// @title Ipor Protocol Router Pause Manager library
library PauseManager {
    /// @notice Emitted when new pause guardian is added
    /// @param guardians List of addresses of guardian
    event PauseGuardiansAdded(address[] indexed guardians);

    /// @notice Emitted when pause guardian is removed
    /// @param guardians List of addresses of guardian
    event PauseGuardiansRemoved(address[] indexed guardians);

    /// @notice Checks if account is Ipor Protocol Router pause guardian
    /// @param account Address of guardian
    /// @return true if account is Ipor Protocol Router pause guardian
    function isPauseGuardian(address account) internal view returns (bool) {
        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        return pauseGuardians[account];
    }

    /// @notice Adds Ipor Protocol Router pause guardian
    /// @param newGuardians Addresses of guardians
    function addPauseGuardians(address[] calldata newGuardians) internal {
        uint256 length = newGuardians.length;
        if (length == 0) {
            return;
        }

        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();

        for (uint256 i; i < length; ) {
            pauseGuardians[newGuardians[i]] = true;
            unchecked {
                i++;
            }
        }
        emit PauseGuardiansAdded(newGuardians);
    }

    /// @notice Removes Ipor Protocol Router pause guardian
    /// @param guardians Addresses of guardians
    function removePauseGuardians(address[] calldata guardians) internal {
        uint256 length = guardians.length;

        if (length == 0) {
            return;
        }

        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();

        for (uint256 i; i < length; ) {
            pauseGuardians[guardians[i]] = false;
            unchecked {
                i++;
            }
        }
        emit PauseGuardiansRemoved(guardians);
    }
}

/// @title Contract responsible for managing access control for the Spread Router
contract SpreadAccessControl is IIporContractCommonGov {
    using IporContractValidator for address;

    event AppointedToTransferOwnership(address indexed appointedOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address internal immutable _iporProtocolRouter;

    constructor(address iporProtocolRouter) {
        _iporProtocolRouter = iporProtocolRouter.checkAddress();
    }

    /// @dev Throws an error if called by any account other than the owner.
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @dev Throws an error if called by any account other than the appointed owner.
    modifier onlyAppointedOwner() {
        require(
            SpreadStorageLibs.getAppointedOwner().appointedOwner == msg.sender,
            IporErrors.SENDER_NOT_APPOINTED_OWNER
        );
        _;
    }

    /// @dev Throws and error if called by any account other than the pause guardian.
    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    /// @notice Returns the address of the contract's owner.
    /// @return The address of the contract's owner.
    function owner() external view returns (address) {
        return SpreadStorageLibs.getOwner().owner;
    }

    /// @notice Transfers the ownership of the contract to a new appointed owner.
    /// @param newAppointedOwner The address of the new appointed owner.
    /// @dev Only the current contract owner can call this function.
    function transferOwnership(address newAppointedOwner) public onlyOwner {
        require(newAppointedOwner != address(0), IporErrors.WRONG_ADDRESS);
        SpreadStorageLibs.AppointedOwnerStorage storage appointedOwnerStorage = SpreadStorageLibs.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = newAppointedOwner;
        emit AppointedToTransferOwnership(newAppointedOwner);
    }

    /// @notice Confirms the transfer of the ownership by the appointed owner.
    /// @dev Only the appointed owner can call this function.
    function confirmTransferOwnership() public onlyAppointedOwner {
        SpreadStorageLibs.AppointedOwnerStorage storage appointedOwnerStorage = SpreadStorageLibs.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
        _transferOwnership(msg.sender);
    }

    /// @notice Renounces the ownership of the contract.
    /// @dev Only the contract owner can call this function.
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
        SpreadStorageLibs.AppointedOwnerStorage storage appointedOwnerStorage = SpreadStorageLibs.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
    }

    /// @notice Pauses the contract.
    /// @dev Only the pause guardian can call this function.
    function pause() external override onlyPauseGuardian {
        _pause();
    }

    /// @notice Unpauses the contract.
    /// @dev Only the contract owner can call this function.
    function unpause() external override onlyOwner {
        SpreadStorageLibs.getPaused().value = 0;
    }

    /// @notice Returns the current pause status of the contract.
    /// @return The pause status represented as a uint256 value (0 for not paused, 1 for paused).
    function paused() external view returns (uint256) {
        return uint256(SpreadStorageLibs.getPaused().value);
    }

    /// @notice Checks if an address is a pause guardian.
    /// @param account The address to be checked.
    /// @return A boolean indicating whether the address is a pause guardian (true) or not (false).
    function isPauseGuardian(address account) external view override returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    /// @notice Adds a new pause guardian to the contract.
    /// @param guardians The addresses of the new pause guardians.
    /// @dev Only the contract owner can call this function.
    function addPauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.addPauseGuardians(guardians);
    }

    /// @notice Removes a pause guardian from the contract.
    /// @param guardians The list addresses of the pause guardians to be removed.
    /// @dev Only the contract owner can call this function.
    function removePauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.removePauseGuardians(guardians);
    }

    /// @dev Internal function to check if the sender is the AMM address.
    function _onlyIporProtocolRouter() internal view {
        require(msg.sender == _iporProtocolRouter, AmmErrors.SENDER_NOT_AMM);
    }

    function _whenNotPaused() internal view {
        require(uint256(SpreadStorageLibs.getPaused().value) == 0, IporErrors.METHOD_PAUSED);
    }

    /// @dev Internal function to check if the sender is the contract owner.
    function _onlyOwner() internal view {
        require(SpreadStorageLibs.getOwner().owner == msg.sender, IporErrors.CALLER_NOT_OWNER);
    }

    function _pause() internal {
        SpreadStorageLibs.getPaused().value = 1;
    }

    /**
     * @dev Transfers the ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        SpreadStorageLibs.OwnerStorage storage ownerStorage = SpreadStorageLibs.getOwner();
        address oldOwner = ownerStorage.owner;
        ownerStorage.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// @title Single entry point for all spread models
contract SpreadRouter is UUPSUpgradeable, SpreadAccessControl, IProxyImplementation {
    using IporContractValidator for address;

    address internal immutable _spread28Days;
    address internal immutable _spread60Days;
    address internal immutable _spread90Days;
    address internal immutable _closeSwapService;
    address internal immutable _storageLens;

    struct DeployedContracts {
        address iporProtocolRouter;
        address spread28Days;
        address spread60Days;
        address spread90Days;
        address storageLens;
        address closeSwapService;
    }

    constructor(DeployedContracts memory deployedContracts) SpreadAccessControl(deployedContracts.iporProtocolRouter) {
        _spread28Days = deployedContracts.spread28Days.checkAddress();
        _spread60Days = deployedContracts.spread60Days.checkAddress();
        _spread90Days = deployedContracts.spread90Days.checkAddress();
        _storageLens = deployedContracts.storageLens.checkAddress();
        _closeSwapService = deployedContracts.closeSwapService.checkAddress();

        _disableInitializers();
    }

    function initialize(bool paused) public initializer {
        __UUPSUpgradeable_init_unchained();
        SpreadStorageLibs.OwnerStorage storage ownerStorage = SpreadStorageLibs.getOwner();
        ownerStorage.owner = msg.sender;

        if (paused) {
            _pause();
        }
    }

    function getConfiguration() external view returns (DeployedContracts memory deployedContracts) {
        deployedContracts.iporProtocolRouter = _iporProtocolRouter;
        deployedContracts.spread28Days = _spread28Days;
        deployedContracts.spread60Days = _spread60Days;
        deployedContracts.spread90Days = _spread90Days;
        deployedContracts.storageLens = _storageLens;
        deployedContracts.closeSwapService = _closeSwapService;
    }

    /// @notice Gets the implementation address for a given function signature.
    /// @param sig The function signature.
    /// @return The implementation address of spread model.
    function getRouterImplementation(bytes4 sig) public view returns (address) {
        if (
            sig == ISpread28Days.calculateAndUpdateOfferedRatePayFixed28Days.selector ||
            sig == ISpread28Days.calculateAndUpdateOfferedRateReceiveFixed28Days.selector
        ) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return _spread28Days;
        } else if (
            sig == ISpread60Days.calculateAndUpdateOfferedRatePayFixed60Days.selector ||
            sig == ISpread60Days.calculateAndUpdateOfferedRateReceiveFixed60Days.selector
        ) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return _spread60Days;
        } else if (
            sig == ISpread90Days.calculateAndUpdateOfferedRatePayFixed90Days.selector ||
            sig == ISpread90Days.calculateAndUpdateOfferedRateReceiveFixed90Days.selector
        ) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return _spread90Days;
        } else if (
            sig == ISpread28DaysLens.calculateOfferedRatePayFixed28Days.selector ||
            sig == ISpread28DaysLens.calculateOfferedRateReceiveFixed28Days.selector ||
            sig == ISpread28DaysLens.spreadFunction28DaysConfig.selector
        ) {
            return _spread28Days;
        } else if (
            sig == ISpread60DaysLens.calculateOfferedRatePayFixed60Days.selector ||
            sig == ISpread60DaysLens.calculateOfferedRateReceiveFixed60Days.selector ||
            sig == ISpread60DaysLens.spreadFunction60DaysConfig.selector
        ) {
            return _spread60Days;
        } else if (
            sig == ISpread90DaysLens.calculateOfferedRatePayFixed90Days.selector ||
            sig == ISpread90DaysLens.calculateOfferedRateReceiveFixed90Days.selector ||
            sig == ISpread90DaysLens.spreadFunction90DaysConfig.selector
        ) {
            return _spread90Days;
        } else if (sig == ISpreadStorageLens.getTimeWeightedNotional.selector) {
            return _storageLens;
        } else if (sig == ISpreadCloseSwapService.updateTimeWeightedNotionalOnClose.selector) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return _closeSwapService;
        }
        revert(AmmErrors.FUNCTION_NOT_SUPPORTED);
    }

    /// @notice Gets the implementation address of a Spread Router.
    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /// @dev Delegates the current call to `implementation`.
    /// This function does not return to its internal call site, it will return directly to the external caller.
    function _delegate(address implementation) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. This inline assembly block takes thefull control of memory
            // Because it will not return to Solidity code,
            // Solidity scratch pad at memory position 0 is overriden.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 since the size is not know at this point .
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external {
        _delegate(getRouterImplementation(msg.sig));
    }

    /**
     * @notice Function run at the time of the contract upgrade via proxy. Available only to the contract's owner.
     **/
    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}