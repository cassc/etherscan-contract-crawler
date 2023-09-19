/**
 *Submitted for verification at Etherscan.io on 2023-08-24
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// License: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
    if (_initialized < type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }

  /**
   * @dev Internal function that returns the initialized version. Returns `_initialized`
   */
  function _getInitializedVersion() internal view returns (uint8) {
    return _initialized;
  }

  /**
   * @dev Internal function that returns the initialized version. Returns `_initializing`
   */
  function _isInitializing() internal view returns (bool) {
    return _initializing;
  }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// License: MIT
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
  function __Context_init() internal onlyInitializing {}

  function __Context_init_unchained() internal onlyInitializing {}

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

// License: MIT
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

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File @openzeppelin/contracts-upgradeable/interfaces/IERC2981[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
  /**
   * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
   * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
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
}

// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
  function __ERC1967Upgrade_init() internal onlyInitializing {}

  function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

  // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
  bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Emitted when the implementation is upgraded.
   */
  event Upgraded(address indexed implementation);

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
  function _upgradeToAndCall(
    address newImplementation,
    bytes memory data,
    bool forceCall
  ) internal {
    _upgradeTo(newImplementation);
    if (data.length > 0 || forceCall) {
      _functionDelegateCall(newImplementation, data);
    }
  }

  /**
   * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
   *
   * Emits an {Upgraded} event.
   */
  function _upgradeToAndCallUUPS(
    address newImplementation,
    bytes memory data,
    bool forceCall
  ) internal {
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
   * @dev Emitted when the admin account has changed.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

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
   * @dev Emitted when the beacon is upgraded.
   */
  event BeaconUpgraded(address indexed beacon);

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
  function _upgradeBeaconToAndCall(
    address newBeacon,
    bytes memory data,
    bool forceCall
  ) internal {
    _setBeacon(newBeacon);
    emit BeaconUpgraded(newBeacon);
    if (data.length > 0 || forceCall) {
      _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
    }
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
    require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

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
  function __UUPSUpgradeable_init() internal onlyInitializing {}

  function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

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
   */
  function upgradeTo(address newImplementation) external virtual onlyProxy {
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
   */
  function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
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

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
  function __ERC165_init() internal onlyInitializing {}

  function __ERC165_init_unchained() internal onlyInitializing {}

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165Upgradeable).interfaceId;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/token/common/ERC[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
  function __ERC2981_init() internal onlyInitializing {}

  function __ERC2981_init_unchained() internal onlyInitializing {}

  struct RoyaltyInfo {
    address receiver;
    uint96 royaltyFraction;
  }

  RoyaltyInfo private _defaultRoyaltyInfo;
  mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165Upgradeable, ERC165Upgradeable)
    returns (bool)
  {
    return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @inheritdoc IERC2981Upgradeable
   */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
    RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

    if (royalty.receiver == address(0)) {
      royalty = _defaultRoyaltyInfo;
    }

    uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

    return (royalty.receiver, royaltyAmount);
  }

  /**
   * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
   * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
   * override.
   */
  function _feeDenominator() internal pure virtual returns (uint96) {
    return 10000;
  }

  /**
   * @dev Sets the royalty information that all ids in this contract will default to.
   *
   * Requirements:
   *
   * - `receiver` cannot be the zero address.
   * - `feeNumerator` cannot be greater than the fee denominator.
   */
  function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
    require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
    require(receiver != address(0), "ERC2981: invalid receiver");

    _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
  }

  /**
   * @dev Removes default royalty information.
   */
  function _deleteDefaultRoyalty() internal virtual {
    delete _defaultRoyaltyInfo;
  }

  /**
   * @dev Sets the royalty information for a specific token id, overriding the global default.
   *
   * Requirements:
   *
   * - `receiver` cannot be the zero address.
   * - `feeNumerator` cannot be greater than the fee denominator.
   */
  function _setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) internal virtual {
    require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
    require(receiver != address(0), "ERC2981: Invalid parameters");

    _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
  }

  /**
   * @dev Resets royalty information for the token id back to the global default.
   */
  function _resetTokenRoyalty(uint256 tokenId) internal virtual {
    delete _tokenRoyaltyInfo[tokenId];
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[48] private __gap;
}

// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
   * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
   * understand this adds an external call which potentially creates a reentrancy vulnerability.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
  /**
   * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
   * by `operator` from `from`, this function is called.
   *
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   *
   * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 result) {
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
        return prod0 / denominator;
      }

      // Make sure the result is less than 2^256. Also prevents denominator == 0.
      require(denominator > prod1);

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
  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator,
    Rounding rounding
  ) internal pure returns (uint256) {
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
      if (value >= 10**64) {
        value /= 10**64;
        result += 64;
      }
      if (value >= 10**32) {
        value /= 10**32;
        result += 32;
      }
      if (value >= 10**16) {
        value /= 10**16;
        result += 16;
      }
      if (value >= 10**8) {
        value /= 10**8;
        result += 8;
      }
      if (value >= 10**4) {
        value /= 10**4;
        result += 4;
      }
      if (value >= 10**2) {
        value /= 10**2;
        result += 2;
      }
      if (value >= 10**1) {
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
      return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
   * Returns 0 if given 0.
   */
  function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
    unchecked {
      uint256 result = log256(value);
      return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
    }
  }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
  bytes16 private constant _SYMBOLS = "0123456789abcdef";
  uint8 private constant _ADDRESS_LENGTH = 20;

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    unchecked {
      uint256 length = MathUpgradeable.log10(value) + 1;
      string memory buffer = new string(length);
      uint256 ptr;
      /// @solidity memory-safe-assembly
      assembly {
        ptr := add(buffer, add(32, length))
      }
      while (true) {
        ptr--;
        /// @solidity memory-safe-assembly
        assembly {
          mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
        }
        value /= 10;
        if (value == 0) break;
      }
      return buffer;
    }
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    unchecked {
      return toHexString(value, MathUpgradeable.log256(value) + 1);
    }
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }

  /**
   * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
   */
  function toHexString(address addr) internal pure returns (string memory) {
    return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
  }
}

// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is
  Initializable,
  ContextUpgradeable,
  ERC165Upgradeable,
  IERC721Upgradeable,
  IERC721MetadataUpgradeable
{
  using AddressUpgradeable for address;
  using StringsUpgradeable for uint256;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
    __ERC721_init_unchained(name_, symbol_);
  }

  function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165Upgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Upgradeable).interfaceId ||
      interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), "ERC721: address zero is not a valid owner");
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    address owner = _ownerOf(tokenId);
    require(owner != address(0), "ERC721: invalid token ID");
    return owner;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721Upgradeable.ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not token owner or approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    _requireMinted(tokenId);

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
    _safeTransfer(from, to, tokenId, data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  /**
   * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
   */
  function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
    return _owners[tokenId];
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _ownerOf(tokenId) != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    address owner = ERC721Upgradeable.ownerOf(tokenId);
    return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _mint(to, tokenId);
    require(_checkOnERC721Received(address(0), to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId, 1);

    // Check that tokenId was not minted by `_beforeTokenTransfer` hook
    require(!_exists(tokenId), "ERC721: token already minted");

    unchecked {
      // Will not overflow unless all 2**256 token ids are minted to the same owner.
      // Given that tokens are minted one by one, it is impossible in practice that
      // this ever happens. Might change if we allow batch minting.
      // The ERC fails to describe this case.
      _balances[to] += 1;
    }

    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId, 1);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   * This is an internal function that does not check if the sender is authorized to operate on the token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721Upgradeable.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId, 1);

    // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
    owner = ERC721Upgradeable.ownerOf(tokenId);

    // Clear approvals
    delete _tokenApprovals[tokenId];

    unchecked {
      // Cannot overflow, as that would require more tokens to be burned/transferred
      // out than the owner initially received through minting and transferring in.
      _balances[owner] -= 1;
    }
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);

    _afterTokenTransfer(owner, address(0), tokenId, 1);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId, 1);

    // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
    require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];

    unchecked {
      // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
      // `from`'s balance is the number of token held, which is at least one before the current
      // transfer.
      // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
      // all 2**256 token ids to be minted, which in practice is impossible.
      _balances[from] -= 1;
      _balances[to] += 1;
    }
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "ERC721: approve to caller");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), "ERC721: invalid token ID");
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns (bool) {
    if (to.isContract()) {
      try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
        return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
   * - When `from` is zero, the tokens will be minted for `to`.
   * - When `to` is zero, ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256, /* firstTokenId */
    uint256 batchSize
  ) internal virtual {
    if (batchSize > 1) {
      if (from != address(0)) {
        _balances[from] -= batchSize;
      }
      if (to != address(0)) {
        _balances[to] += batchSize;
      }
    }
  }

  /**
   * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
   * - When `from` is zero, the tokens were minted for `to`.
   * - When `to` is zero, ``from``'s tokens were burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual {}

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[44] private __gap;
}

// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
  /**
   * @dev Returns the total amount of tokens stored by the contract.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
   * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
   * Use along with {totalSupply} to enumerate all tokens.
   */
  function tokenByIndex(uint256 index) external view returns (uint256);
}

// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
  function __ERC721Enumerable_init() internal onlyInitializing {}

  function __ERC721Enumerable_init_unchained() internal onlyInitializing {}

  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165Upgradeable, ERC721Upgradeable)
    returns (bool)
  {
    return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
    require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
    require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
    return _allTokens[index];
  }

  /**
   * @dev See {ERC721-_beforeTokenTransfer}.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

    if (batchSize > 1) {
      // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
      revert("ERC721Enumerable: consecutive transfers not supported");
    }

    uint256 tokenId = firstTokenId;

    if (from == address(0)) {
      _addTokenToAllTokensEnumeration(tokenId);
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      _removeTokenFromAllTokensEnumeration(tokenId);
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721Upgradeable.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to add a token to this extension's token tracking data structures.
   * @param tokenId uint256 ID of the token to be added to the tokens list
   */
  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  /**
   * @dev Private function to remove a token from this extension's token tracking data structures.
   * This has O(1) time complexity, but alters the order of the _allTokens array.
   * @param tokenId uint256 ID of the token to be removed from the tokens list
   */
  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
    // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
    // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    // This also deletes the contents at the last position of the array
    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[46] private __gap;
}

// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {ERC2981-_setDefaultRoyalty}, and/or individually for
 * specific token ids via {ERC2981-_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721RoyaltyUpgradeable is Initializable, ERC2981Upgradeable, ERC721Upgradeable {
  function __ERC721Royalty_init() internal onlyInitializing {}

  function __ERC721Royalty_init_unchained() internal onlyInitializing {}

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, ERC2981Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
   */
  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    _resetTokenRoyalty(tokenId);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

// License: MIT
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

// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts/utils/[email protected]

// License: MIT
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

// File @openzeppelin/contracts/token/ERC20/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
   * `transferFrom`. This is semantically equivalent to an infinite approval.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * NOTE: Does not update the allowance if the current allowance
   * is the maximum `uint256`.
   *
   * Requirements:
   *
   * - `from` and `to` cannot be the zero address.
   * - `from` must have a balance of at least `amount`.
   * - the caller must have allowance for ``from``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, allowance(owner, spender) + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    address owner = _msgSender();
    uint256 currentAllowance = allowance(owner, spender);
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
      _approve(owner, spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  /**
   * @dev Moves `amount` of tokens from `from` to `to`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `from` must have a balance of at least `amount`.
   */
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(from, to, amount);

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[from] = fromBalance - amount;
      // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
      // decrementing then incrementing.
      _balances[to] += amount;
    }

    emit Transfer(from, to, amount);

    _afterTokenTransfer(from, to, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    unchecked {
      // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
      _balances[account] += amount;
    }
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      _balances[account] = accountBalance - amount;
      // Overflow not possible: amount <= accountBalance <= totalSupply.
      _totalSupply -= amount;
    }

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
   *
   * Does not update the allowance amount in case of infinite allowance.
   * Revert if not enough allowance is available.
   *
   * Might emit an {Approval} event.
   */
  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      unchecked {
        _approve(owner, spender, currentAllowance - amount);
      }
    }
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * has been transferred to `to`.
   * - when `from` is zero, `amount` tokens have been minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// File @openzeppelin/contracts-upgradeable/utils/cryptography/[email protected]

// License: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProofUpgradeable {
  /**
   * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
   * defined by `root`. For this, a `proof` must be provided, containing
   * sibling hashes on the branch from the leaf to the root of the tree. Each
   * pair of leaves and each pair of pre-images are assumed to be sorted.
   */
  function verify(
    bytes32[] memory proof,
    bytes32 root,
    bytes32 leaf
  ) internal pure returns (bool) {
    return processProof(proof, leaf) == root;
  }

  /**
   * @dev Calldata version of {verify}
   *
   * _Available since v4.7._
   */
  function verifyCalldata(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32 leaf
  ) internal pure returns (bool) {
    return processProofCalldata(proof, leaf) == root;
  }

  /**
   * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
   * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
   * hash matches the root of the tree. When processing the proof, the pairs
   * of leafs & pre-images are assumed to be sorted.
   *
   * _Available since v4.4._
   */
  function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
      computedHash = _hashPair(computedHash, proof[i]);
    }
    return computedHash;
  }

  /**
   * @dev Calldata version of {processProof}
   *
   * _Available since v4.7._
   */
  function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
      computedHash = _hashPair(computedHash, proof[i]);
    }
    return computedHash;
  }

  /**
   * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
   * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
   *
   * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
   *
   * _Available since v4.7._
   */
  function multiProofVerify(
    bytes32[] memory proof,
    bool[] memory proofFlags,
    bytes32 root,
    bytes32[] memory leaves
  ) internal pure returns (bool) {
    return processMultiProof(proof, proofFlags, leaves) == root;
  }

  /**
   * @dev Calldata version of {multiProofVerify}
   *
   * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
   *
   * _Available since v4.7._
   */
  function multiProofVerifyCalldata(
    bytes32[] calldata proof,
    bool[] calldata proofFlags,
    bytes32 root,
    bytes32[] memory leaves
  ) internal pure returns (bool) {
    return processMultiProofCalldata(proof, proofFlags, leaves) == root;
  }

  /**
   * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
   * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
   * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
   * respectively.
   *
   * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
   * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
   * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
   *
   * _Available since v4.7._
   */
  function processMultiProof(
    bytes32[] memory proof,
    bool[] memory proofFlags,
    bytes32[] memory leaves
  ) internal pure returns (bytes32 merkleRoot) {
    // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
    // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
    // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
    // the merkle tree.
    uint256 leavesLen = leaves.length;
    uint256 totalHashes = proofFlags.length;

    // Check proof validity.
    require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

    // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
    // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
    bytes32[] memory hashes = new bytes32[](totalHashes);
    uint256 leafPos = 0;
    uint256 hashPos = 0;
    uint256 proofPos = 0;
    // At each step, we compute the next hash using two values:
    // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
    //   get the next hash.
    // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
    //   `proof` array.
    for (uint256 i = 0; i < totalHashes; i++) {
      bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
      bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
      hashes[i] = _hashPair(a, b);
    }

    if (totalHashes > 0) {
      return hashes[totalHashes - 1];
    } else if (leavesLen > 0) {
      return leaves[0];
    } else {
      return proof[0];
    }
  }

  /**
   * @dev Calldata version of {processMultiProof}.
   *
   * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
   *
   * _Available since v4.7._
   */
  function processMultiProofCalldata(
    bytes32[] calldata proof,
    bool[] calldata proofFlags,
    bytes32[] memory leaves
  ) internal pure returns (bytes32 merkleRoot) {
    // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
    // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
    // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
    // the merkle tree.
    uint256 leavesLen = leaves.length;
    uint256 totalHashes = proofFlags.length;

    // Check proof validity.
    require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

    // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
    // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
    bytes32[] memory hashes = new bytes32[](totalHashes);
    uint256 leafPos = 0;
    uint256 hashPos = 0;
    uint256 proofPos = 0;
    // At each step, we compute the next hash using two values:
    // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
    //   get the next hash.
    // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
    //   `proof` array.
    for (uint256 i = 0; i < totalHashes; i++) {
      bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
      bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
      hashes[i] = _hashPair(a, b);
    }

    if (totalHashes > 0) {
      return hashes[totalHashes - 1];
    } else if (leavesLen > 0) {
      return leaves[0];
    } else {
      return proof[0];
    }
  }

  function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
    return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
  }

  function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      value := keccak256(0x00, 0x40)
    }
  }
}

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

// License: MIT
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

// File contracts/interfaces/IAttributes.sol

// License: MIT
pragma solidity 0.8.17;

// Author: Francesco Sullo <[email protected]>

interface IAttributes {
  enum Rarity {
    COMMON,
    UNCOMMON,
    RARE,
    EPIC,
    LEGENDARY
  }
}

// File @openzeppelin/contracts/utils/[email protected]

// License: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
  struct Counter {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    unchecked {
      counter._value += 1;
    }
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    require(value > 0, "Counter: decrement overflow");
    unchecked {
      counter._value = value - 1;
    }
  }

  function reset(Counter storage counter) internal {
    counter._value = 0;
  }
}

// File contracts/interfaces/IBCNFT.sol

// License: MIT
pragma solidity 0.8.17;

// Authors: Francesco Sullo <[email protected]>
// (c) Superpower Labs Inc

interface IBCNFT {
  function setFactory(address factory_, bool enabled) external;

  function endMinting() external;

  function mintEnded() external view returns (bool);

  function maxSupply() external view returns (uint256);
}

// File @ndujalabs/erc721attributable/contracts/[email protected]

// License: MIT
pragma solidity ^0.8.4;

// Author:
// Francesco Sullo <francesc[email protected]>

/**
   @title IERC721AttributablePlayer Player of an attributable asset
    Version: 0.0.2
   ERC165 interfaceId is 0x72261e7d
   */
interface IERC721AttributablePlayer {
  /**
    @dev returns the attributes in a readable way
    @param _asset The address of the asset played by the game
    @param _id The id of the asset
    @return A string with type of the attribute, name and value

    The expected format is a string like `uint16 level:23;uin256 power:2543344` which
    can be easily converted by a marketplace in a JSON object.

    Here an example of implementation (using OpenZeppelin /utils/Strings.sol)

    function attributesOf(
      address _nft,
      uint256 tokenId
    ) external view override
    returns (string memory) {
      uint256 _attributes = IERC721Attributable(_nft).attributesOf(tokenId, address(this), 0);
      if (_attributes != 0) {
        return
          string(
            abi.encodePacked(
              "uint8 version:",
              Strings.toString(uint8(_attributes)),
              ";uint8 level:",
              Strings.toString(uint16(_attributes >> 8)),
              ";uint32 stamina:",
              Strings.toString(uint32(_attributes >> 16)),
              ";address winner:",
              Strings.toHexString(uint160(_attributes >> 48), 20)
            )
          );
      } else {
        return "";
      }
    }

  */
  function attributesOf(address _asset, uint256 _id) external view returns (string memory);
}

// File @ndujalabs/erc721attributable/contracts/[email protected]

// License: MIT
pragma solidity ^0.8.4;

// Author:
// Francesco Sullo <[email protected]>

/**
   @title IERC721Attributable Cross-player On-chain Attributes
    Version: 0.0.4
   ERC165 interfaceId is 0xc79cd306
   */
interface IERC721Attributable {
  /**
     @dev Emitted when the attributes for an id and a player is set.
          The function must be called by the owner of the asset to authorize a player to set
          attributes on it. The rules for that are left to the asset.

          This event is important because allows a marketplace to know that there are
          dynamic attributes set on the NFT by a specific contract (the player) so that
          the marketplace can query the player to get the attributes of the NFT in within
          the game.
   */
  event AttributesInitializedFor(uint256 indexed _id, address indexed _player);

  /**
   @dev Emitted when the attributes for an id are updated.
   */
  event AttributesUpdated(uint256 indexed _id);

  /**
     @dev It returns the on-chain attributes of a specific id
       This function is called by the player, which is able to decode the uint and
       transform them in whatever is necessary for the game.
     @param _id The id of the token for whom to query the on-chain attributes
     @param _player The address of the player's contract
     @param _index The index in the array of attributes
     @return The encoded attributes of the token
   */
  function attributesOf(
    uint256 _id,
    address _player,
    uint256 _index
  ) external view returns (uint256);

  /**
     @notice Authorize a player initializing the attributes of a token to a non zero value
     @dev It must be called by the owner of the nft

       To avoid that nft owners give themselves arbitrary values, they must not
       be able to set up the values, but only to create the array that later
       will be filled by the player.

       Since by default the value in the array would be zero, the initial value
       must be a non-zero value. This way the player can see if the data are initialized
       checking that the attributesOf a certain id is != 0.

       The function must emit the AttributesInitializedFor event

     @param _id The id of the token for whom to authorize the player
     @param _player The address of the player contract
   */
  function initializeAttributesFor(uint256 _id, address _player) external;

  /**
     @notice Sets the attributes of a token after the initialization
     @dev It modifies attributes by id for a specific player. It must
       be called by the player's contract, after an NFT has been initialized.

       The owner of the NFT must not be able to update the attributes.

       It must revert if the asset is not initialized for that player (the msg.sender).

       The function must emit the AttributesUpdated event

     @param _id The id of the token for whom to change the attributes
     @param _index The index of the array where the attribute is updated
     @param _attributes The encoded attributes
   */
  function updateAttributes(
    uint256 _id,
    uint256 _index,
    uint256 _attributes
  ) external;
}

// File contracts/interfaces/IERC6454.sol

// License: MIT

/// @title EIP-6454 Minimalistic Non-Transferable interface for NFTs
/// @dev See https://eips.ethereum.org/EIPS/eip-6454
/// @dev Note: the ERC-165 identifier for this interface is 0x91a6262f.
/// @authors Bruno Škvorc (@Swader), Francesco Sullo (@sullof), Steven Pineda (@steven2308), Stevan Bogosavljevic (@stevyhacker), Jan Turk (@ThunderDeliverer)

pragma solidity ^0.8.9;

interface IERC6454 {
  /**
   * @notice Used to check whether the given token is transferable or not.
   * @dev If this function returns `false`, the transfer of the token MUST revert execution.
   * @dev If the tokenId does not exist, this method MUST revert execution, unless the token is being checked for
   *  minting.
   * @dev The `from` parameter MAY be used to also validate the approval of the token for transfer, but anyone
   *  interacting with this function SHOULD NOT rely on it as it is not mandated by the proposal.
   * @param tokenId ID of the token being checked
   * @param from Address from which the token is being transferred
   * @param to Address to which the token is being transferred
   * @return Boolean value indicating whether the given token is transferable
   */
  function isTransferable(
    uint256 tokenId,
    address from,
    address to
  ) external view returns (bool);
}

// File contracts/interfaces/IERC6982.sol

// License: CC0-1.0
pragma solidity ^0.8.9;

// ERC165 interfaceId 0x6b61a747
interface IERC6982 {
  // This event MUST be emitted upon deployment of the contract, establishing
  // the default lock status for any tokens that will be minted in the future.
  // If the default lock status changes for any reason, this event
  // MUST be re-emitted to update the default status for all tokens.
  // Note that emitting a new DefaultLocked event does not affect the lock
  // status of any tokens for which a Locked event has previously been emitted.
  event DefaultLocked(bool locked);

  // This event MUST be emitted whenever the lock status of a specific token
  // changes, effectively overriding the default lock status for this token.
  event Locked(uint256 indexed tokenId, bool locked);

  // This function returns the current default lock status for tokens.
  // It reflects the value set by the latest DefaultLocked event.
  function defaultLocked() external view returns (bool);

  // This function returns the lock status of a specific token.
  // If no Locked event has been emitted for a given tokenId, it MUST return
  // the value that defaultLocked() returns, which represents the default
  // lock status.
  // This function MUST revert if the token does not exist.
  function locked(uint256 tokenId) external view returns (bool);
}

// File contracts/interfaces/IERC721Lockable.sol

// License: MIT
pragma solidity ^0.8.9;

// Author:
// Francesco Sullo <[email protected]>

// ERC165 interface id is 0x2e4e0d27
interface IERC721Lockable is IERC6982, IERC6454 {
  event LockerSet(address locker);
  event LockerRemoved(address locker);
  event ForcefullyUnlocked(uint256 tokenId);

  // tells if a token is locked. Removed to extend IERC6982
  // function locked(uint256 tokenID) external view returns (bool);

  // tells the address of the contract which is locking a token
  function lockerOf(uint256 tokenID) external view returns (address);

  // tells if a contract is a locker
  function isLocker(address _locker) external view returns (bool);

  // set a locker, if the actor that is locking it is a contract, it
  // should be approved
  // It should emit a LockerSet event
  function setLocker(address pool) external;

  // remove a locker
  // It should emit a LockerRemoved event
  function removeLocker(address pool) external;

  // tells if an NFT has any locks on it
  // The function is called internally and externally
  function hasLocks(address owner) external view returns (bool);

  // locks an NFT
  // It should emit a Locked event
  function lock(uint256 tokenID) external;

  // unlocks an NFT
  // It should emit a Unlocked event
  function unlock(uint256 tokenID) external;

  // unlock an NFT if the locker is removed
  // This is an emergency function called by the token owner or a DAO
  // It should emit a ForcefullyUnlocked event
  function unlockIfRemovedLocker(uint256 tokenID) external;
}

// File contracts/interfaces/IBCNFTBase.sol

// License: MIT
pragma solidity 0.8.17;

// Author: Francesco Sullo <[email protected]>

interface IBCNFTBase is IERC721Lockable, IERC721Attributable {
  event TokenURIFrozen();
  event TokenURIUpdated(string uri);

  function updateTokenURI(string memory uri) external;

  function freezeTokenURI() external;

  function contractURI() external view returns (string memory);
}

// File contracts/tokens/BCNFTBase.sol

// License: MIT
pragma solidity 0.8.17;

// The staking part is taken from Everdragons2GenesisV2 contract
// https://github.com/ndujaLabs/everdragons2-core/blob/main/contracts/Everdragons2GenesisV2.sol

// Author: Francesco Sullo <[email protected]>
// (c) Superpower Labs Inc.

/*
About ownership and upgradeability

There is a strategy for it. Following OpenZeppelin best practices, we will deploy
the contracts and then transfer the ownership of the proxy-contract to a
Gnosis safe multi-sig wallet. Any subsequent upgrades will be performed
according to this process. Here is the guide we will follow to transfer ownership
to the multi-sig wallet and later deploy new implementations:
https://docs.openzeppelin.com/defender/guide-upgrades

To split the risks, a few more multi-sign wallets will become the owners of
the contracts in this suite.

Regarding the time lock, we are not implementing an explicit process because when
a bug is discovered (which is the primary reason why we are using upgradeable
contracts), the speed of response is crucial to avoid disaster.
For example, the recent crash of the UST could have been mitigated if they
did not have to wait for the fixed lockup time before intervening.

*/

contract BCNFTBase is
  IBCNFTBase,
  Initializable,
  ERC721Upgradeable,
  ERC721RoyaltyUpgradeable,
  ERC721EnumerableUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable
{
  using AddressUpgradeable for address;

  error NotALocker();
  error NotTheOwner();
  error AssetDoesNotExist();
  error AlreadyInitiated();
  error NotTheAssetOwner();
  error NotTheAssetOwnerNorTheGame();
  error PlayerAlreadyAuthorized();
  error PlayerNotAuthorized();
  error FrozenTokenURI();
  error NotAContract();
  error NotAnAttributablePlayer();
  error NotADeactivatedLocker();
  error WrongLocker();
  error NotLockedAsset();
  error LockedAsset();
  error AtLeastOneLockedAsset();
  error LockerNotApproved();
  error TokenNotFound();

  string private _baseTokenURI;
  bool private _baseTokenURIFrozen;

  mapping(address => bool) private _lockers;
  mapping(uint256 => address) private _lockedBy;

  mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _tokenAttributes;

  modifier onlyLocker() {
    if (!_lockers[_msgSender()]) {
      revert NotALocker();
    }
    _;
  }

  modifier tokenExists(uint256 id) {
    if (!_exists(id)) {
      revert AssetDoesNotExist();
    }
    _;
  }

  // solhint-disable-next-line
  function __BCNFTBase_init(
    string memory name,
    string memory symbol,
    string memory tokenUri
  ) internal initializer {
    __ERC721_init(name, symbol);
    __ERC721Enumerable_init();
    __Ownable_init();
    _baseTokenURI = tokenUri;
    __UUPSUpgradeable_init();
    emit DefaultLocked(false);
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
    if (!isTransferable(tokenId, from, to)) {
      revert LockedAsset();
    }
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  // ERC165 implementation
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721RoyaltyUpgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
  {
    return
      interfaceId == type(IERC6982).interfaceId ||
      interfaceId == type(IERC6454).interfaceId ||
      interfaceId == type(IERC721Attributable).interfaceId ||
      interfaceId == type(IERC721Lockable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function updateTokenURI(string memory uri) external override onlyOwner {
    if (_baseTokenURIFrozen) {
      revert FrozenTokenURI();
    }
    // after revealing, this allows to set up a final uri
    _baseTokenURI = uri;
    emit TokenURIUpdated(uri);
  }

  function freezeTokenURI() external override onlyOwner {
    _baseTokenURIFrozen = true;
    emit TokenURIFrozen();
  }

  function contractURI() public view override returns (string memory) {
    return string(abi.encodePacked(_baseTokenURI, "0"));
  }

  // IERC6982 / IERC721Lockable
  //
  // When a contract is locked, only the locker is approved
  // The advantage of locking an NFT instead of staking is that
  // The owner keeps the ownership of it and can use that, for example,
  // to access services on Discord via Collab.land verification.

  function defaultLocked() public view virtual returns (bool) {
    return false;
  }

  function locked(uint256 tokenId) public view override returns (bool) {
    return _lockedBy[tokenId] != address(0) || defaultLocked();
  }

  function lockerOf(uint256 tokenId) external view override returns (address) {
    return _lockedBy[tokenId];
  }

  function isLocker(address locker) public view override returns (bool) {
    return _lockers[locker];
  }

  function setLocker(address locker) external override onlyOwner {
    if (!locker.isContract()) {
      revert NotAContract();
    }
    _lockers[locker] = true;
    emit LockerSet(locker);
  }

  function removeLocker(address locker) external override onlyOwner {
    if (!_lockers[locker]) {
      revert NotALocker();
    }
    delete _lockers[locker];
    emit LockerRemoved(locker);
  }

  function hasLocks(address owner) public view override returns (bool) {
    uint256 balance = balanceOf(owner);
    for (uint256 i = 0; i < balance; i++) {
      uint256 id = tokenOfOwnerByIndex(owner, i);
      if (locked(id)) {
        return true;
      }
    }
    return false;
  }

  function lock(uint256 tokenId) external override onlyLocker {
    if (getApproved(tokenId) != _msgSender() && !isApprovedForAll(ownerOf(tokenId), _msgSender())) {
      revert LockerNotApproved();
    }
    _lockedBy[tokenId] = _msgSender();
    emit Locked(tokenId, true);
  }

  function unlock(uint256 tokenId) external override onlyLocker {
    // will revert if token does not exist
    if (_lockedBy[tokenId] != _msgSender()) {
      revert WrongLocker();
    }
    delete _lockedBy[tokenId];
    emit Locked(tokenId, false);
  }

  // emergency function in case a compromised locker is removed
  function unlockIfRemovedLocker(uint256 tokenId) external override onlyOwner {
    if (!locked(tokenId)) {
      revert NotLockedAsset();
    }
    if (_lockers[_lockedBy[tokenId]]) {
      revert NotADeactivatedLocker();
    }
    delete _lockedBy[tokenId];
    emit ForcefullyUnlocked(tokenId);
  }

  // To obtain the lockability, the standard approval and transfer
  // functions of an ERC721 must be overridden, taking in consideration
  // the locking status of the NFT.

  // The _beforeTokenTransfer hook is enough to guarantee that a locked
  // NFT cannot be transferred. Overriding the approval functions, following
  // OpenZeppelin best practices, avoid the user to spend useless gas.

  function approve(address to, uint256 tokenId) public override(IERC721Upgradeable, ERC721Upgradeable) {
    if (locked(tokenId)) {
      revert LockedAsset();
    }
    super.approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view override(IERC721Upgradeable, ERC721Upgradeable) returns (address) {
    if (locked(tokenId)) {
      return address(0);
    }
    return super.getApproved(tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override(IERC721Upgradeable, ERC721Upgradeable) {
    if (approved && hasLocks(_msgSender())) {
      revert AtLeastOneLockedAsset();
    }
    super.setApprovalForAll(operator, approved);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    override(IERC721Upgradeable, ERC721Upgradeable)
    returns (bool)
  {
    if (hasLocks(owner)) {
      return false;
    }
    return super.isApprovedForAll(owner, operator);
  }

  // Attributable implementation

  function attributesOf(
    uint256 _id,
    address _player,
    uint256 _index
  ) external view override returns (uint256) {
    return _tokenAttributes[_id][_player][_index];
  }

  function initializeAttributesFor(uint256 _id, address _player) external override {
    if (_msgSender() != ownerOf(_id)) revert NotTheOwner();
    if (!_player.isContract()) revert NotAContract();
    if (!IERC165Upgradeable(_player).supportsInterface(type(IERC721AttributablePlayer).interfaceId))
      revert NotAnAttributablePlayer();
    if (_tokenAttributes[_id][_player][0] > 0) {
      revert PlayerAlreadyAuthorized();
    }
    _tokenAttributes[_id][_player][0] = 1;
    emit AttributesInitializedFor(_id, _player);
  }

  function updateAttributes(
    uint256 _id,
    uint256 _index,
    uint256 _attributes
  ) external override {
    if (_tokenAttributes[_id][_msgSender()][0] == 0) {
      revert PlayerNotAuthorized();
    }
    // notice that if the playes set the attributes to zero, it de-authorize itself
    // and not more changes will be allowed until the NFT owner authorize it again
    _tokenAttributes[_id][_msgSender()][_index] = _attributes;
  }

  // ERC Royalty standard

  function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721RoyaltyUpgradeable) {
    super._burn(tokenId);
    _resetTokenRoyalty(tokenId);
  }

  // IERC6454

  function isTransferable(
    uint256 tokenId,
    address from,
    address
  ) public view override returns (bool) {
    if (from != address(0) && !_exists(tokenId)) revert TokenNotFound();
    if (locked(tokenId)) return false;
    return true;
  }

  uint256[50] private __gap;
}

// File contracts/tokens/BCNFT.sol

// License: MIT
pragma solidity 0.8.17;

// Inspired by Everdragons2 NFTs, https://everdragons2.com
// Authors: Francesco Sullo <[email protected]>
// Collaborators: Jerry Bassat <[email protected]>
// (c) Superpower Labs Inc.

abstract contract BCNFT is IBCNFT, BCNFTBase {
  event MintingEnded();

  error Forbidden();
  error CannotMint();
  error ZeroAddress();
  error ParametersAlreadySetUp();
  error InvalidStart();
  error MintingHasEnded();

  using AddressUpgradeable for address;
  uint256 internal _maxSupply;
  bool private _mintEnded;

  address[] public factories;

  modifier onlyFactory() {
    if (!isFactory(_msgSender())) revert Forbidden();
    _;
  }

  function setFactory(address factory_, bool enabled) external override onlyOwner {
    if (!factory_.isContract()) revert NotAContract();
    if (enabled) {
      if (!isFactory(factory_)) {
        factories.push(factory_);
      }
    } else {
      if (isFactory(factory_)) {
        for (uint256 i = 0; i < factories.length; i++) {
          if (factories[i] == factory_) {
            factories[i] = address(0);
          }
        }
      }
    }
  }

  function isFactory(address factory_) public view returns (bool) {
    for (uint256 i = 0; i < factories.length; i++) {
      if (factories[i] != address(0)) {
        if (factories[i] == factory_) {
          return true;
        }
      }
    }
    return false;
  }

  function hasFactories() public view returns (bool) {
    for (uint256 i = 0; i < factories.length; i++) {
      if (factories[i] != address(0)) {
        return true;
      }
    }
    return false;
  }

  function endMinting() external override onlyOwner {
    // force the end of the minting
    _mintEnded = true;
    emit MintingEnded();
  }

  function mintEnded() public view override returns (bool) {
    return _mintEnded || totalSupply() >= maxSupply();
  }

  function maxSupply() public view override returns (uint256) {
    if (_mintEnded) {
      return totalSupply();
    } else {
      return _maxSupply;
    }
  }

  function canMint() public view returns (bool) {
    return !mintEnded() && totalSupply() < maxSupply();
  }
}

// File contracts/tokens/BCGenesisToken.sol

// License: MIT
pragma solidity 0.8.17;

// Authors: Francesco Sullo <[email protected]>
// (c) Superpower Labs Inc.

//import "hardhat/console.sol";

contract BCGenesisToken is BCNFT {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  function initialize(string memory tokenUri) public initializer {
    __BCNFTBase_init("BYTE CITY Genesis Body Part Token", "BCGBP", tokenUri);
    _maxSupply = 2400;
  }

  function burnBatch(uint256[4] calldata tokenIds) external onlyFactory {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _burn(tokenIds[i]);
    }
  }

  function mint(address to) external virtual onlyFactory {
    _tokenIdCounter.increment();
    // we start from tokenId #1
    uint256 tokenId = _tokenIdCounter.current();
    if (tokenId > maxSupply()) revert MintingHasEnded();
    _safeMint(to, tokenId);
  }
}

// File contracts/tokens/BCOracleToken.sol

// License: MIT
pragma solidity 0.8.17;

// Authors: Francesco Sullo <[email protected]>
// (c) Superpower Labs Inc.

contract BCOracleToken is BCNFT {
  uint256 private _nextTokenId;

  // version 2
  mapping(uint256 => IAttributes.Rarity) private _rarity;

  function initialize(string memory tokenUri) public initializer {
    __BCNFTBase_init("BYTE City Oracle Token", "BCOT", tokenUri);
    _maxSupply = 600;
    _nextTokenId = 1;
  }

  function nextTokenId() external view returns (uint256) {
    return _nextTokenId;
  }

  function mint(address to, IAttributes.Rarity rarity) external virtual onlyFactory returns (uint256) {
    if (mintEnded() || _nextTokenId == 0 || _nextTokenId > maxSupply()) revert CannotMint();
    _rarity[_nextTokenId] = rarity;
    _safeMint(to, _nextTokenId);
    return _nextTokenId++;
  }

  function rarityOf(uint256 tokenId) external view returns (IAttributes.Rarity) {
    if (!_exists(tokenId)) revert TokenNotFound();
    return _rarity[tokenId];
  }
}

// File hardhat/[email protected]

// License: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
  address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

  function _sendLogPayload(bytes memory payload) private view {
    uint256 payloadLength = payload.length;
    address consoleAddress = CONSOLE_ADDRESS;
    assembly {
      let payloadStart := add(payload, 32)
      let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
    }
  }

  function log() internal view {
    _sendLogPayload(abi.encodeWithSignature("log()"));
  }

  function logInt(int256 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
  }

  function logUint(uint256 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
  }

  function logString(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function logBool(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function logAddress(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function logBytes(bytes memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
  }

  function logBytes1(bytes1 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
  }

  function logBytes2(bytes2 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
  }

  function logBytes3(bytes3 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
  }

  function logBytes4(bytes4 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
  }

  function logBytes5(bytes5 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
  }

  function logBytes6(bytes6 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
  }

  function logBytes7(bytes7 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
  }

  function logBytes8(bytes8 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
  }

  function logBytes9(bytes9 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
  }

  function logBytes10(bytes10 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
  }

  function logBytes11(bytes11 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
  }

  function logBytes12(bytes12 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
  }

  function logBytes13(bytes13 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
  }

  function logBytes14(bytes14 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
  }

  function logBytes15(bytes15 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
  }

  function logBytes16(bytes16 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
  }

  function logBytes17(bytes17 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
  }

  function logBytes18(bytes18 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
  }

  function logBytes19(bytes19 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
  }

  function logBytes20(bytes20 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
  }

  function logBytes21(bytes21 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
  }

  function logBytes22(bytes22 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
  }

  function logBytes23(bytes23 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
  }

  function logBytes24(bytes24 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
  }

  function logBytes25(bytes25 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
  }

  function logBytes26(bytes26 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
  }

  function logBytes27(bytes27 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
  }

  function logBytes28(bytes28 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
  }

  function logBytes29(bytes29 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
  }

  function logBytes30(bytes30 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
  }

  function logBytes31(bytes31 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
  }

  function logBytes32(bytes32 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
  }

  function log(uint256 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
  }

  function log(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function log(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function log(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function log(uint256 p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
  }

  function log(uint256 p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
  }

  function log(uint256 p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
  }

  function log(uint256 p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
  }

  function log(string memory p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
  }

  function log(string memory p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
  }

  function log(string memory p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
  }

  function log(string memory p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
  }

  function log(bool p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
  }

  function log(bool p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
  }

  function log(bool p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
  }

  function log(bool p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
  }

  function log(address p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
  }

  function log(address p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
  }

  function log(address p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
  }

  function log(address p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
  }
}

// File contracts/BCFactory.sol

// License: MIT
pragma solidity 0.8.17;

// Author : Francesco Sullo < [email protected]>
// (c) Superpower Labs Inc.

contract BCFactory is OwnableUpgradeable, UUPSUpgradeable {
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  event OracleMinted(uint256 indexed id, uint256 partId1, uint256 partId2, uint256 partId3, uint256 partId4);
  event RootSet(bytes32 root1, bytes32 root2);

  error NotAndERC721(address);
  error ProofAlreadyUsed();
  error NotGenesisOwner();
  error OracleMintingFinished();
  error RootNotSet();
  error RootAlreadySet();
  error InvalidProof();
  error PhaseClosedOrNotOpenYet();
  error NotAllSameRarity();
  error NotAFullSet();
  error TooManyValues();
  error InvalidRarity();
  error BurningFailed();
  error TooManyTokens();
  error InvalidStart();
  error AllTokensHaveBeenMinted();
  error AlreadySet();
  error PreMintingLimitReached();

  enum Phase {
    NotOpened,
    GuaranteedAllowList,
    GeneralAllowList,
    Public,
    Closed
  }

  BCGenesisToken public genesisToken;
  BCOracleToken public oracleToken;

  bytes32 public merkleOneRoot;
  bytes32 public merkleTwoRoot;
  mapping(bytes32 => bool) public usedProofs;

  // Version 2

  uint256 public startAt;

  mapping(uint256 => uint256) internal _rarityIndex;

  uint256 private _factor;
  uint256 private _addend;
  uint256 private _rangeSize;
  uint256 private _treasuryWalletAndReservedAmount;

  function initialize(address genesis_, address oracle_) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    if (!IERC165Upgradeable(genesis_).supportsInterface(type(IERC721Upgradeable).interfaceId)) revert NotAndERC721(genesis_);
    if (!IERC165Upgradeable(oracle_).supportsInterface(type(IERC721Upgradeable).interfaceId)) revert NotAndERC721(oracle_);
    genesisToken = BCGenesisToken(genesis_);
    oracleToken = BCOracleToken(oracle_);
    // For initial testing, we use the following coprime.
    // They will be updated for mainnet distribution
    updateRevealParams(7, 19, 40);
  }

  function updateRevealParams(
    uint256 factor_,
    uint256 addend_,
    uint256 rangeSize_
  ) public onlyOwner {
    _factor = factor_;
    _addend = addend_;
    _rangeSize = rangeSize_;
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

  function setTreasury(address treasury_, uint256 reservedAmount) external onlyOwner {
    _treasuryWalletAndReservedAmount = (uint256(uint160(treasury_)) << 96) | reservedAmount;
  }

  function getTreasury() public view returns (address treasury_, uint256 reservedAmount) {
    treasury_ = address(uint160(_treasuryWalletAndReservedAmount >> 96));
    reservedAmount = uint256(uint96(_treasuryWalletAndReservedAmount));
  }

  function preMint(uint256 amount) external onlyOwner {
    if (currentPhase() != Phase.NotOpened) revert PhaseClosedOrNotOpenYet();
    (address treasury_, uint256 reservedAmount) = getTreasury();
    if (genesisToken.totalSupply() >= reservedAmount) revert PreMintingLimitReached();
    if (genesisToken.totalSupply() + amount > reservedAmount) {
      amount = reservedAmount - genesisToken.totalSupply();
    }
    for (uint256 i = 0; i < amount; i++) {
      genesisToken.mint(treasury_);
    }
  }

  function setRoot(bytes32 root1_, bytes32 root2_) external virtual onlyOwner {
    (, uint256 reservedAmount) = getTreasury();
    // allows to update the root, if no genesis has been minted yet
    if (genesisToken.totalSupply() > reservedAmount) revert RootAlreadySet();
    merkleOneRoot = root1_;
    merkleTwoRoot = root2_;
    emit RootSet(root1_, root2_);
  }

  function start(uint256 timestamp) external onlyOwner {
    if (timestamp < block.timestamp) revert InvalidStart();
    if (startAt > 0 && block.timestamp > startAt) revert AlreadySet();
    startAt = timestamp;
  }

  function currentPhase() public view virtual returns (Phase) {
    if (genesisToken.mintEnded()) return Phase.Closed;
    if (startAt == 0 || block.timestamp < startAt) return Phase.NotOpened;
    if (block.timestamp < startAt + 4 hours) return Phase.GuaranteedAllowList;
    if (block.timestamp < startAt + 8 hours) return Phase.GeneralAllowList;
    return Phase.Public;
  }

  function _encodeLeaf(address recipient, uint256 nonce) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(recipient, nonce));
  }

  function mintGenesis(
    bytes32[] calldata proof,
    uint256 nonce,
    bool isGuaranteed
  ) external {
    if (merkleOneRoot == 0) revert RootNotSet();
    Phase phase = currentPhase();
    if (phase < Phase.GuaranteedAllowList || phase > Phase.Public) revert PhaseClosedOrNotOpenYet();
    if (phase < Phase.Public) {
      _useProof(proof, nonce, _msgSender());
      if (isGuaranteed) {
        _validateProof(proof, nonce, merkleOneRoot);
      } else {
        if (phase < Phase.GeneralAllowList) revert PhaseClosedOrNotOpenYet();
        _validateProof(proof, nonce, merkleTwoRoot);
      }
    }
    if (genesisToken.totalSupply() >= 2400) revert AllTokensHaveBeenMinted();
    genesisToken.mint(_msgSender());
  }

  function _validateProof(
    bytes32[] calldata proof,
    uint256 nonce,
    bytes32 root
  ) internal view {
    if (!MerkleProofUpgradeable.verify(proof, root, _encodeLeaf(_msgSender(), nonce))) revert InvalidProof();
  }

  function _useProof(
    bytes32[] calldata proof,
    uint256 nonce,
    address sender
  ) internal {
    bytes32 key = keccak256(abi.encodePacked(proof, nonce, sender));
    if (usedProofs[key]) revert ProofAlreadyUsed();
    usedProofs[key] = true;
  }

  function genesisMinted() external view returns (uint256) {
    return genesisToken.totalSupply();
  }

  function hasProofBeenUsed(
    bytes32[] calldata proof,
    uint256 nonce,
    address sender
  ) external view returns (bool) {
    bytes32 key = keccak256(abi.encodePacked(proof, nonce, sender));
    return usedProofs[key];
  }

  function _isOwner(uint256 partId) internal view {
    if (genesisToken.ownerOf(partId) != _msgSender()) revert NotGenesisOwner();
  }

  function _validateBodyParts(
    uint256 partId1,
    uint256 partId2,
    uint256 partId3,
    uint256 partId4
  ) internal view returns (IAttributes.Rarity) {
    _isOwner(partId1);
    _isOwner(partId2);
    _isOwner(partId3);
    _isOwner(partId4);
    uint256 rarity_ = rarityByIndex(partId1);
    if (rarity_ != rarityByIndex(partId2) || rarity_ != rarityByIndex(partId3) || rarity_ != rarityByIndex(partId4)) {
      revert NotAllSameRarity();
    }
    if (part(partId1) + part(partId2) + part(partId3) + part(partId4) != 14) {
      revert NotAFullSet();
    }
    return IAttributes.Rarity(rarity_);
  }

  function mintOracle(
    uint256 partId1,
    uint256 partId2,
    uint256 partId3,
    uint256 partId4
  ) external {
    IAttributes.Rarity rarity = _validateBodyParts(partId1, partId2, partId3, partId4);
    uint256 oracleId = oracleToken.mint(_msgSender(), rarity);
    try genesisToken.burnBatch([partId1, partId2, partId3, partId4]) {
      // do nothing
    } catch {
      revert BurningFailed();
    }
    emit OracleMinted(oracleId, partId1, partId2, partId3, partId4);
  }

  function saveRarityIndex(uint256[] memory rarityIndex_) public onlyOwner {
    for (uint256 i = 0; i < rarityIndex_.length; i++) {
      _rarityIndex[i] = rarityIndex_[i];
    }
  }

  function part(uint256 genesisId) public view returns (uint256) {
    uint256 base = (genesisId - 1) / _rangeSize;
    uint256 diff = (base * _rangeSize);
    genesisId -= diff;
    uint256 factorInverse = 1;
    for (uint256 i = 1; i <= _rangeSize; i++) {
      if ((_factor * i) % _rangeSize == 1) {
        factorInverse = i;
        break;
      }
    }
    uint256 baseId = diff + ((((genesisId - 1 + _rangeSize - _addend) % _rangeSize) * factorInverse) % _rangeSize) + 1;
    return (((baseId - 1) % _rangeSize) / 10)**2;
  }

  function encode(uint256[] memory arr) public pure returns (uint256) {
    uint256 res;
    if (arr.length > 77) revert TooManyValues();
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i] > 4) revert InvalidRarity();
      res += arr[i] * (10**i);
    }
    return res;
  }

  function rarityByIndex(uint256 genesisTokenId_) public view returns (uint256) {
    uint256 index = (genesisTokenId_ - 1) / _rangeSize;
    uint256 val = _rarityIndex[0] / (10**index);
    return val % 10;
  }

  function getParams()
    external
    view
    returns (
      uint256 factor_,
      uint256 addend_,
      uint256 rangeSize_
    )
  {
    factor_ = _factor;
    addend_ = _addend;
    rangeSize_ = _rangeSize;
  }
}

// Flattened on 2023-08-24T13:12:23.482Z