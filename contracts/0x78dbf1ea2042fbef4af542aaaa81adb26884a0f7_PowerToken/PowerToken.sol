/**
 *Submitted for verification at Etherscan.io on 2023-10-09
*/

// SPDX-License-Identifier: BSD-3-Clause
// File: lib/ipor-power-tokens/contracts/security/StorageLib.sol


pragma solidity 0.8.20;

/// @title Storage IDs associated with the IPOR Protocol Router.
library StorageLib {
    uint256 constant STORAGE_SLOT_BASE = 1_000_000;

    // append only
    enum StorageId {
        /// @dev The address of the contract owner.
        Owner,
        AppointedOwner,
        Paused,
        PauseGuardians,
        ReentrancyStatus
    }

    struct OwnerStorage {
        address value;
    }

    struct AppointedOwnerStorage {
        address appointedOwner;
    }

    struct PausedStorage {
        uint256 value;
    }

    struct ReentrancyStatusStorage {
        uint256 value;
    }

    function getOwner() internal pure returns (OwnerStorage storage owner) {
        uint256 slot = _getStorageSlot(StorageId.Owner);
        assembly {
            owner.slot := slot
        }
    }

    function getAppointedOwner()
        internal
        pure
        returns (AppointedOwnerStorage storage appointedOwner)
    {
        uint256 slot = _getStorageSlot(StorageId.AppointedOwner);
        assembly {
            appointedOwner.slot := slot
        }
    }

    function getPaused() internal pure returns (PausedStorage storage paused) {
        uint256 slot = _getStorageSlot(StorageId.Paused);
        assembly {
            paused.slot := slot
        }
    }

    function getPauseGuardianStorage()
        internal
        pure
        returns (mapping(address => uint256) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.PauseGuardians);
        assembly {
            store.slot := slot
        }
    }

    function getReentrancyStatus() internal pure returns (ReentrancyStatusStorage storage status) {
        uint256 slot = _getStorageSlot(StorageId.ReentrancyStatus);
        assembly {
            status.slot := slot
        }
    }

    function _getStorageSlot(StorageId storageId) private pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}

// File: lib/ipor-power-tokens/contracts/security/PauseManager.sol


pragma solidity 0.8.20;


library PauseManager {
    function addPauseGuardians(address[] calldata guardians) internal {
        uint256 length = guardians.length;
        if (length == 0) {
            return;
        }
        mapping(address => uint256) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        for (uint256 i; i < length; ) {
            pauseGuardians[guardians[i]] = 1;
            unchecked {
                ++i;
            }
        }
        emit PauseGuardiansAdded(guardians);
    }

    function removePauseGuardians(address[] calldata guardians) internal {
        uint256 length = guardians.length;
        if (length == 0) {
            return;
        }
        mapping(address => uint256) storage pauseGuardians = StorageLib.getPauseGuardianStorage();

        for (uint256 i; i < length; ) {
            pauseGuardians[guardians[i]] = 0;
            unchecked {
                ++i;
            }
        }
        emit PauseGuardiansRemoved(guardians);
    }

    function isPauseGuardian(address _guardian) internal view returns (bool) {
        mapping(address => uint256) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        return pauseGuardians[_guardian] == 1;
    }

    event PauseGuardiansAdded(address[] indexed guardians);

    event PauseGuardiansRemoved(address[] indexed guardians);
}

// File: lib/ipor-power-tokens/contracts/libraries/math/MathOperation.sol


pragma solidity 0.8.20;

library MathOperation {
    //@notice Division with the rounding up on last position, x, and y is with MD
    function division(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x + (y / 2)) / y;
    }
}

// File: lib/ipor-power-tokens/contracts/libraries/errors/Errors.sol


pragma solidity 0.8.20;

library Errors {
    /// @notice Error thrown when the lpToken address is not supported
    /// @dev List of supported LpTokens is defined in {LiquidityMining._lpTokens}
    string public constant LP_TOKEN_NOT_SUPPORTED = "PT_701";
    /// @notice Error thrown when the caller / msgSender is not a Pause Manager address.
    /// @dev Pause Manager can be defined by the smart contract's Onwer
    string public constant CALLER_NOT_PAUSE_MANAGER = "PT_704";
    /// @notice Error thrown when the account's base balance is too low
    string public constant ACCOUNT_BASE_BALANCE_IS_TOO_LOW = "PT_705";
    /// @notice Error thrown when the account's Lp Token balance is too low
    string public constant ACCOUNT_LP_TOKEN_BALANCE_IS_TOO_LOW = "PT_706";
    /// @notice Error thrown when the account's delegated balance is too low
    string public constant ACC_DELEGATED_TO_LIQUIDITY_MINING_BALANCE_IS_TOO_LOW = "PT_707";
    /// @notice Error thrown when the account's available Power Token balance is too low
    string public constant ACC_AVAILABLE_POWER_TOKEN_BALANCE_IS_TOO_LOW = "PT_708";
    /// @notice Error thrown when the account doesn't have the rewards (Staked Tokens / Power Tokens) to claim
    string public constant NO_REWARDS_TO_CLAIM = "PT_709";
    /// @notice Error thrown when the cooldown is not finished.
    string public constant COOL_DOWN_NOT_FINISH = "PT_710";
    /// @notice Error thrown when the aggregate power up indicator is going to be negative during the calculation.
    string public constant AGGREGATE_POWER_UP_COULD_NOT_BE_NEGATIVE = "PT_711";
    /// @notice Error thrown when the block number used in the function is lower than previous block number stored in the liquidity mining indicators.
    string public constant BLOCK_NUMBER_LOWER_THAN_PREVIOUS_BLOCK_NUMBER = "PT_712";
    /// @notice Account Composite Multiplier indicator is greater or equal to Composit Multiplier indicator, but it should be lower or equal
    string public constant ACCOUNT_COMPOSITE_MULTIPLIER_GT_COMPOSITE_MULTIPLIER = "PT_713";
    /// @notice The fee for unstacking of Power Tokens should be number between (0, 1e18)
    string public constant UNSTAKE_WITHOUT_COOLDOWN_FEE_IS_TO_HIGH = "PT_714";
    /// @notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "PT_715";
    /// @notice General problem, contract is wrong
    string public constant WRONG_CONTRACT_ID = "PT_716";
    /// @notice Value not greater than zero
    string public constant VALUE_NOT_GREATER_THAN_ZERO = "PT_717";
    /// @notice Appeared when input of two arrays length mismatch
    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "PT_718";
    /// @notice msg.sender is not an appointed owner, it cannot confirm their ownership
    string public constant SENDER_NOT_APPOINTED_OWNER = "PT_719";
    /// @notice msg.sender is not an appointed owner, it cannot confirm their ownership
    string public constant ROUTER_INVALID_SIGNATURE = "PT_720";
    string public constant INPUT_ARRAYS_EMPTY = "PT_721";
    string public constant CALLER_NOT_ROUTER = "PT_722";
    string public constant CALLER_NOT_GUARDIAN = "PT_723";
    string public constant CONTRACT_PAUSED = "PT_724";
    string public constant REENTRANCY = "PT_725";
    string public constant CALLER_NOT_OWNER = "PT_726";
}

// File: lib/ipor-power-tokens/contracts/libraries/ContractValidator.sol


pragma solidity 0.8.20;


library ContractValidator {
    function checkAddress(address addr) internal pure returns (address) {
        require(addr != address(0), Errors.WRONG_ADDRESS);
        return addr;
    }
}

// File: lib/ipor-power-tokens/contracts/interfaces/IProxyImplementation.sol


pragma solidity 0.8.20;

interface IProxyImplementation {
    /// @notice Retrieves the address of the implementation contract for UUPS proxy.
    /// @return The address of the implementation contract.
    /// @dev The function returns the value stored in the implementation storage slot.
    function getImplementation() external view returns (address);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: lib/ipor-power-tokens/contracts/interfaces/IGovernanceToken.sol


pragma solidity 0.8.20;


/// @title Interface of the Staked Token.
interface IGovernanceToken is IERC20 {
    /**
     * @dev Contract id.
     * The keccak-256 hash of "io.ipor.IporToken" decreased by 1
     */
    function getContractId() external pure returns (bytes32);
}

// File: @openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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

// File: @openzeppelin/contracts-upgradeable/interfaces/IERC1967Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;







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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

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

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


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

// File: lib/ipor-power-tokens/contracts/security/MiningOwnableUpgradeable.sol


pragma solidity 0.8.20;



contract MiningOwnableUpgradeable is OwnableUpgradeable {
    address private _appointedOwner;

    event AppointedToTransferOwnership(address indexed appointedOwner);

    modifier onlyAppointedOwner() {
        require(_appointedOwner == msg.sender, Errors.SENDER_NOT_APPOINTED_OWNER);
        _;
    }

    function transferOwnership(address appointedOwner) public override onlyOwner {
        require(appointedOwner != address(0), Errors.WRONG_ADDRESS);
        _appointedOwner = appointedOwner;
        emit AppointedToTransferOwnership(appointedOwner);
    }

    function confirmTransferOwnership() public onlyAppointedOwner {
        _appointedOwner = address(0);
        _transferOwnership(msg.sender);
    }

    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(address(0));
        _appointedOwner = address(0);
    }
}

// File: @openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// File: lib/ipor-power-tokens/contracts/interfaces/types/PowerTokenTypes.sol


pragma solidity 0.8.20;

/// @title Struct used across Liquidity Mining.
library PowerTokenTypes {
    struct PwTokenCooldown {
        // @dev The timestamp when the account can redeem Power Tokens
        uint256 endTimestamp;
        // @dev The amount of Power Tokens which can be redeemed without fee when the cooldown reaches `endTimestamp`
        uint256 pwTokenAmount;
    }

    struct UpdateGovernanceToken {
        address beneficiary;
        uint256 governanceTokenAmount;
    }
}

// File: lib/ipor-power-tokens/contracts/interfaces/IPowerTokenInternal.sol


pragma solidity 0.8.20;


/// @title PowerToken smart contract interface
interface IPowerTokenInternal {
    /// @notice Returns the current version of the PowerToken smart contract
    /// @return Current PowerToken smart contract version
    function getVersion() external pure returns (uint256);

    /// @notice Gets the total supply base amount
    /// @return total supply base amount, represented with 18 decimals
    function totalSupplyBase() external view returns (uint256);

    /// @notice Calculates the internal exchange rate between the Staked Token and total supply of a base amount
    /// @return Current exchange rate between the Staked Token and the total supply of a base amount, represented with 18 decimals.
    function calculateExchangeRate() external view returns (uint256);

    /// @notice Method for seting up the unstaking fee
    /// @param unstakeWithoutCooldownFee fee percentage, represented with 18 decimals.
    function setUnstakeWithoutCooldownFee(uint256 unstakeWithoutCooldownFee) external;

    /// @notice method returning address of the Staked Token
    function getGovernanceToken() external view returns (address);

    /// @notice Pauses the smart contract, it can only be executed by the Owner
    /// @dev Emits {Paused} event.
    function pause() external;

    /// @notice Unpauses the smart contract, it can only be executed by the Owner
    /// @dev Emits {Unpaused}.
    function unpause() external;

    /// @notice Method for granting allowance to the Router
    /// @param erc20Token address of the ERC20 token
    function grantAllowanceForRouter(address erc20Token) external;

    /// @notice Method for revoking allowance to the Router
    /// @param erc20Token address of the ERC20 token
    function revokeAllowanceForRouter(address erc20Token) external;

    /// @notice Gets the power token cool down time in seconds.
    /// @return uint256 cool down time in seconds
    function COOL_DOWN_IN_SECONDS() external view returns (uint256);

    /// @notice Adds a new pause guardian to the contract.
    /// @param guardians The addresses of the new pause guardians.
    /// @dev Only the contract owner can call this function.
    function addPauseGuardians(address[] calldata guardians) external;

    /// @notice Removes a pause guardian from the contract.
    /// @param guardians The addresses of the pause guardians to be removed.
    /// @dev Only the contract owner can call this function.
    function removePauseGuardians(address[] calldata guardians) external;

    /// @notice Checks if an address is a pause guardian.
    /// @param guardian The address to be checked.
    /// @return A boolean indicating whether the address is a pause guardian (true) or not (false).
    function isPauseGuardian(address guardian) external view returns (bool);

    /// @notice Emitted when the user receives rewards from the LiquidityMining
    /// @dev Receiving rewards does not change Internal Exchange Rate of Power Tokens in PowerToken smart contract.
    /// @param account address
    /// @param rewardsAmount amount of Power Tokens received from LiquidityMining
    event RewardsReceived(address account, uint256 rewardsAmount);

    /// @notice Emitted when the fee for immediate unstaking is modified.
    /// @param newFee new value of the fee, represented with 18 decimals
    event UnstakeWithoutCooldownFeeChanged(uint256 newFee);

    /// @notice Emmited when PauseManager's address had been changed by its owner.
    /// @param newLiquidityMining PauseManager's new address
    event LiquidityMiningChanged(address indexed newLiquidityMining);

    /// @notice Emmited when the PauseManager's address is changed by its owner.
    /// @param newPauseManager PauseManager's new address
    event PauseManagerChanged(address indexed newPauseManager);

    /// @notice Emitted when owner grants allowance for router
    /// @param erc20Token address of ERC20 token
    /// @param router address of router
    event AllowanceGranted(address indexed erc20Token, address indexed router);

    /// @notice Emitted when owner revokes allowance for router
    /// @param erc20Token address of ERC20 token
    /// @param router address of router
    event AllowanceRevoked(address indexed erc20Token, address indexed router);
}

// File: lib/ipor-power-tokens/contracts/interfaces/IPowerToken.sol


pragma solidity 0.8.20;


/// @title The Interface for the interaction with the PowerToken - smart contract responsible
/// for managing Power Token (pwToken), Swapping Staked Token for Power Tokens, and
/// delegating Power Tokens to other components.
interface IPowerToken {
    /// @notice Gets the name of the Power Token
    /// @return Returns the name of the Power Token.
    function name() external pure returns (string memory);

    /// @notice Contract ID. The keccak-256 hash of "io.ipor.PowerToken" decreased by 1
    /// @return Returns the ID of the contract
    function getContractId() external pure returns (bytes32);

    /// @notice Gets the symbol of the Power Token.
    /// @return Returns the symbol of the Power Token.
    function symbol() external pure returns (string memory);

    /// @notice Returns the number of the decimals used by Power Token. By default it's 18 decimals.
    /// @return Returns the number of decimals: 18.
    function decimals() external pure returns (uint8);

    /// @notice Gets the total supply of the Power Token.
    /// @dev Value is calculated in runtime using baseTotalSupply and internal exchange rate.
    /// @return Total supply of Power tokens, represented with 18 decimals
    function totalSupply() external view returns (uint256);

    /// @notice Gets the balance of Power Tokens for a given account
    /// @param account account address for which the balance of Power Tokens is fetched
    /// @return Returns the amount of the Power Tokens owned by the `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Gets the delegated balance of the Power Tokens for a given account.
    /// Tokens are delegated from PowerToken to LiquidityMining smart contract (reponsible for rewards distribution).
    /// @param account account address for which the balance of delegated Power Tokens is checked
    /// @return  Returns the amount of the Power Tokens owned by the `account` and delegated to the LiquidityMining contracts.
    function delegatedToLiquidityMiningBalanceOf(address account) external view returns (uint256);

    /// @notice Gets the rate of the fee from the configuration. This fee is applied when the owner of Power Tokens wants to unstake them immediately.
    /// @dev Fee value represented in as a percentage with 18 decimals
    /// @return value, a percentage represented with 18 decimal
    function getUnstakeWithoutCooldownFee() external view returns (uint256);

    /// @notice Gets the state of the active cooldown for the sender.
    /// @dev If PowerTokenTypes.PowerTokenCoolDown contains only zeros it represents no active cool down.
    /// Struct containing information on when the cooldown end and what is the quantity of the Power Tokens locked.
    /// @param account account address that owns Power Tokens in the cooldown
    /// @return Object PowerTokenTypes.PowerTokenCoolDown represents active cool down
    function getActiveCooldown(
        address account
    ) external view returns (PowerTokenTypes.PwTokenCooldown memory);

    /// @notice Initiates a cooldown for the specified account.
    /// @dev This function allows an account to initiate a cooldown period for a specified amount of Power Tokens.
    ///      During the cooldown period, the specified amount of Power Tokens cannot be redeemed or transferred.
    /// @param account The account address for which the cooldown is initiated.
    /// @param pwTokenAmount The amount of Power Tokens to be put on cooldown.
    function cooldownInternal(address account, uint256 pwTokenAmount) external;

    /// @notice Cancels the cooldown for the specified account.
    /// @dev This function allows an account to cancel the active cooldown period for their Power Tokens,
    ///      enabling them to freely redeem or transfer their Power Tokens.
    /// @param account The account address for which the cooldown is to be canceled.
    function cancelCooldownInternal(address account) external;

    /// @notice Redeems Power Tokens for the specified account.
    /// @dev This function allows an account to redeem their Power Tokens, transferring the specified
    ///      amount of Power Tokens back to the account's staked token balance.
    ///      The redemption is subject to the cooldown period, and the account must wait for the cooldown
    ///      period to finish before being able to redeem the Power Tokens.
    /// @param account The account address for which Power Tokens are to be redeemed.
    /// @return transferAmount The amount of Power Tokens that have been redeemed and transferred back to the staked token balance.
    function redeemInternal(address account) external returns (uint256 transferAmount);

    /// @notice Adds staked tokens to the specified account.
    /// @dev This function allows the specified account to add staked tokens to their Power Token balance.
    ///      The staked tokens are converted to Power Tokens based on the internal exchange rate.
    /// @param updateGovernanceToken An object of type PowerTokenTypes.UpdateGovernanceToken containing the details of the staked token update.
    function addGovernanceTokenInternal(
        PowerTokenTypes.UpdateGovernanceToken memory updateGovernanceToken
    ) external;

    /// @notice Removes staked tokens from the specified account, applying a fee.
    /// @dev This function allows the specified account to remove staked tokens from their Power Token balance,
    ///      while deducting a fee from the staked token amount. The fee is determined based on the cooldown period.
    /// @param updateGovernanceToken An object of type PowerTokenTypes.UpdateGovernanceToken containing the details of the staked token update.
    /// @return governanceTokenAmountToTransfer The amount of staked tokens to be transferred after applying the fee.
    function removeGovernanceTokenWithFeeInternal(
        PowerTokenTypes.UpdateGovernanceToken memory updateGovernanceToken
    ) external returns (uint256 governanceTokenAmountToTransfer);

    /// @notice Delegates a specified amount of Power Tokens from the caller's balance to the Liquidity Mining contract.
    /// @dev This function allows the caller to delegate a specified amount of Power Tokens to the Liquidity Mining contract,
    ///      enabling them to participate in liquidity mining and earn rewards.
    /// @param account The address of the account delegating the Power Tokens.
    /// @param pwTokenAmount The amount of Power Tokens to delegate.
    function delegateInternal(address account, uint256 pwTokenAmount) external;

    /// @notice Undelegated a specified amount of Power Tokens from the Liquidity Mining contract back to the caller's balance.
    /// @dev This function allows the caller to undelegate a specified amount of Power Tokens from the Liquidity Mining contract,
    ///      effectively removing them from participation in liquidity mining and stopping the earning of rewards.
    /// @param account The address of the account to undelegate the Power Tokens from.
    /// @param pwTokenAmount The amount of Power Tokens to undelegate.
    function undelegateInternal(address account, uint256 pwTokenAmount) external;

    /// @notice Emitted when the account stake/add [Staked] Tokens
    /// @param account account address that executed the staking
    /// @param governanceTokenAmount of Staked Token amount being staked into PowerToken contract
    /// @param internalExchangeRate internal exchange rate used to calculate the base amount
    /// @param baseAmount value calculated based on the governanceTokenAmount and the internalExchangeRate
    event GovernanceTokenAdded(
        address indexed account,
        uint256 governanceTokenAmount,
        uint256 internalExchangeRate,
        uint256 baseAmount
    );

    /// @notice Emitted when the account unstakes the Power Tokens
    /// @param account address that executed the unstaking
    /// @param pwTokenAmount amount of Power Tokens that were unstaked
    /// @param internalExchangeRate which was used to calculate the base amount
    /// @param fee amount subtracted from the pwTokenAmount
    event GovernanceTokenRemovedWithFee(
        address indexed account,
        uint256 pwTokenAmount,
        uint256 internalExchangeRate,
        uint256 fee
    );

    /// @notice Emitted when the sender delegates the Power Tokens to the LiquidityMining contract
    /// @param account address delegating the Power Tokens
    /// @param pwTokenAmounts amounts of Power Tokens delegated to respective lpTokens
    event Delegated(address indexed account, uint256 pwTokenAmounts);

    /// @notice Emitted when the sender undelegates Power Tokens from the LiquidityMining
    /// @param account address undelegating Power Tokens
    /// @param pwTokenAmounts amounts of Power Tokens undelegated form respective lpTokens
    event Undelegated(address indexed account, uint256 pwTokenAmounts);

    /// @notice Emitted when the sender sets the cooldown on Power Tokens
    /// @param pwTokenAmount amount of pwToken in cooldown
    /// @param endTimestamp end time of the cooldown
    event CooldownChanged(uint256 pwTokenAmount, uint256 endTimestamp);

    /// @notice Emitted when the sender redeems the pwTokens after the cooldown
    /// @param account address that executed the redeem function
    /// @param pwTokenAmount amount of the pwTokens that was transferred to the Power Token owner's address
    event Redeem(address indexed account, uint256 pwTokenAmount);
}

// File: lib/ipor-power-tokens/contracts/interfaces/types/LiquidityMiningTypes.sol


pragma solidity 0.8.20;

/// @title Structures used in the LiquidityMining.
library LiquidityMiningTypes {
    /// @title Struct pair representing delegated pwToken balance
    struct DelegatedPwTokenBalance {
        /// @notice lpToken address
        address lpToken;
        /// @notice The amount of Power Token delegated to lpToken staking pool
        /// @dev value represented in 18 decimals
        uint256 pwTokenAmount;
    }

    /// @title Global indicators used in rewards calculation.
    struct GlobalRewardsIndicators {
        /// @notice powerUp indicator aggregated
        /// @dev It can be changed many times during transaction, represented with 18 decimals
        uint256 aggregatedPowerUp;
        /// @notice composite multiplier in a block described in field blockNumber
        /// @dev It can be changed many times during transaction, represented with 27 decimals
        uint128 compositeMultiplierInTheBlock;
        /// @notice Composite multiplier updated in block {blockNumber} but calculated for PREVIOUS (!) block.
        /// @dev It can be changed once per block, represented with 27 decimals
        uint128 compositeMultiplierCumulativePrevBlock;
        /// @dev It can be changed once per block. Block number in which all other params of this structure are updated
        uint32 blockNumber;
        /// @notice value describing amount of rewards issued per block,
        /// @dev It can be changed at most once per block, represented with 8 decimals
        uint32 rewardsPerBlock;
        /// @notice amount of accrued rewards since inception
        /// @dev It can be changed at most once per block, represented with 18 decimals
        uint88 accruedRewards;
    }

    /// @title Params recorded for a given account. These params are used by the algorithm responsible for rewards distribution.
    /// @dev The structure in storage is updated when account interacts with the LiquidityMining smart contract (stake, unstake, delegate, undelegate, claim)
    struct AccountRewardsIndicators {
        /// @notice `composite multiplier cumulative` is calculated for previous block
        /// @dev represented in 27 decimals
        uint128 compositeMultiplierCumulativePrevBlock;
        /// @notice lpToken account's balance
        uint128 lpTokenBalance;
        /// @notive PowerUp is a result of logarithmic equastion,
        /// @dev  powerUp < 100 *10^18
        uint72 powerUp;
        /// @notice balance of Power Tokens delegated to LiquidityMining
        /// @dev delegatedPwTokenBalance < 10^26 < 2^87
        uint96 delegatedPwTokenBalance;
    }

    struct UpdateLpToken {
        address beneficiary;
        address lpToken;
        uint256 lpTokenAmount;
    }

    struct UpdatePwToken {
        address beneficiary;
        address lpToken;
        uint256 pwTokenAmount;
    }

    struct AccruedRewardsResult {
        address lpToken;
        uint256 rewardsAmount;
    }

    struct AccountRewardResult {
        address lpToken;
        uint256 rewardsAmount;
        uint256 allocatedPwTokens;
    }

    struct AccountIndicatorsResult {
        address lpToken;
        LiquidityMiningTypes.AccountRewardsIndicators indicators;
    }

    struct GlobalIndicatorsResult {
        address lpToken;
        LiquidityMiningTypes.GlobalRewardsIndicators indicators;
    }
}

// File: lib/ipor-power-tokens/contracts/interfaces/ILiquidityMining.sol


pragma solidity 0.8.20;


/// @title The interface for interaction with the LiquidityMining.
/// LiquidityMining is responsible for the distribution of the Power Token rewards to accounts
/// staking lpTokens and / or delegating Power Tokens to LiquidityMining. LpTokens can be staked directly to the LiquidityMining,
/// Power Tokens are a staked version of the [Staked] Tokens minted by the PowerToken smart contract.
interface ILiquidityMining {
    /// @notice Contract ID. The keccak-256 hash of "io.ipor.LiquidityMining" decreased by 1
    /// @return Returns an ID of the contract
    function getContractId() external pure returns (bytes32);

    /// @notice Returns the balance of staked lpTokens
    /// @param account the account's address
    /// @param lpToken the address of lpToken
    /// @return balance of the lpTokens staked by the sender
    function balanceOf(address account, address lpToken) external view returns (uint256);

    /// @notice It returns the balance of delegated Power Tokens for a given `account` and the list of lpToken addresses.
    /// @param account address for which to fetch the information about balance of delegated Power Tokens
    /// @param lpTokens list of lpTokens addresses(lpTokens)
    /// @return balances list of {LiquidityMiningTypes.DelegatedPwTokenBalance} structure, with information how much Power Token is delegated per lpToken address.
    function balanceOfDelegatedPwToken(
        address account,
        address[] memory lpTokens
    ) external view returns (LiquidityMiningTypes.DelegatedPwTokenBalance[] memory balances);

    /// @notice Calculates the accrued rewards for multiple LP tokens.
    /// @param lpTokens An array of LP token addresses.
    /// @return An array of `AccruedRewardsResult` structures, containing the LP token address and the accrued rewards amount.
    function calculateAccruedRewards(
        address[] calldata lpTokens
    ) external view returns (LiquidityMiningTypes.AccruedRewardsResult[] memory);

    /// @notice Calculates the rewards earned by an account for multiple LP tokens.
    /// @param account The address of the account for which to calculate rewards.
    /// @param lpTokens An array of LP token addresses.
    /// @return An array of `AccountRewardResult` structures, containing the LP token address, rewards amount, and allocated Power Token balance for the account.
    function calculateAccountRewards(
        address account,
        address[] calldata lpTokens
    ) external view returns (LiquidityMiningTypes.AccountRewardResult[] memory);

    /// @notice method allowing to update the indicators per asset (lpToken).
    /// @param account of which we should update the indicators
    /// @param lpTokens of the staking pools to update the indicators
    function updateIndicators(address account, address[] calldata lpTokens) external;

    /// @notice Adds LP tokens to the liquidity mining for multiple accounts.
    /// @param updateLpToken An array of `UpdateLpToken` structures, each containing the account address,
    /// LP token address, and LP token amount to be added.
    function addLpTokensInternal(
        LiquidityMiningTypes.UpdateLpToken[] memory updateLpToken
    ) external;

    /// @notice Adds Power tokens to the liquidity mining for multiple accounts.
    /// @param updatePwToken An array of `UpdatePwToken` structures, each containing the account address,
    /// LP token address, and Power token amount to be added.
    function addPwTokensInternal(
        LiquidityMiningTypes.UpdatePwToken[] memory updatePwToken
    ) external;

    /// @notice Removes LP tokens from the liquidity mining for multiple accounts.
    /// @param updateLpToken An array of `UpdateLpToken` structures, each containing the account address,
    /// LP token address, and LP token amount to be removed.
    function removeLpTokensInternal(
        LiquidityMiningTypes.UpdateLpToken[] memory updateLpToken
    ) external;

    /// @notice Removes Power Tokens from the liquidity mining for multiple accounts.
    /// @param updatePwToken An array of `UpdatePwToken` structures, each containing the account address,
    /// LP token address, and Power Token amount to be removed.
    function removePwTokensInternal(
        LiquidityMiningTypes.UpdatePwToken[] memory updatePwToken
    ) external;

    /// @notice Claims accumulated rewards for multiple LP tokens and transfers them to the specified account.
    /// @param account The account address to claim rewards for.
    /// @param lpTokens An array of LP token addresses for which rewards will be claimed.
    /// @return rewardsAmountToTransfer The total amount of rewards transferred to the account.
    function claimInternal(
        address account,
        address[] calldata lpTokens
    ) external returns (uint256 rewardsAmountToTransfer);

    /// @notice Retrieves the global indicators for multiple LP tokens.
    /// @param lpTokens An array of LP token addresses for which to retrieve the global indicators.
    /// @return An array of LiquidityMiningTypes.GlobalIndicatorsResult containing the global indicators for each LP token.
    function getGlobalIndicators(
        address[] calldata lpTokens
    ) external view returns (LiquidityMiningTypes.GlobalIndicatorsResult[] memory);

    /// @notice Retrieves the account indicators for a specific account and multiple LP tokens.
    /// @param account The address of the account for which to retrieve the account indicators.
    /// @param lpTokens An array of LP token addresses for which to retrieve the account indicators.
    /// @return An array of LiquidityMiningTypes.AccountIndicatorsResult containing the account indicators for each LP token.
    function getAccountIndicators(
        address account,
        address[] calldata lpTokens
    ) external view returns (LiquidityMiningTypes.AccountIndicatorsResult[] memory);

    /// @notice Emitted when the account stakes the lpTokens
    /// @param account Account's address in the context of which the activities of staking of lpTokens are performed
    /// @param lpToken address of lpToken being staked
    /// @param lpTokenAmount of lpTokens to stake, represented with 18 decimals
    event LpTokensStaked(address account, address lpToken, uint256 lpTokenAmount);

    /// @notice Emitted when the account claims the rewards
    /// @param account Account's address in the context of which activities of claiming are performed
    /// @param lpTokens The addresses of the lpTokens for which the rewards are claimed
    /// @param rewardsAmount Reward amount denominated in pwToken, represented with 18 decimals
    event Claimed(address account, address[] lpTokens, uint256 rewardsAmount);

    /// @notice Emitted when the account claims the allocated rewards
    /// @param account Account address in the context of which activities of claiming are performed
    /// @param allocatedRewards Reward amount denominated in pwToken, represented in 18 decimals
    event AllocatedTokensClaimed(address account, uint256 allocatedRewards);

    /// @notice Emitted when update was triggered for the account on the lpToken
    /// @param account Account address to which the update was triggered
    /// @param lpToken lpToken address to which the update was triggered
    event IndicatorsUpdated(address account, address lpToken);

    /// @notice Emitted when the lpToken is added to the LiquidityMining
    /// @param beneficiary Account address on behalf of which the lpToken is added
    /// @param lpToken lpToken address which is added
    /// @param lpTokenAmount Amount of lpTokens added, represented with 18 decimals
    event LpTokenAdded(address beneficiary, address lpToken, uint256 lpTokenAmount);

    /// @notice Emitted when the lpToken is removed from the LiquidityMining
    /// @param account address on behalf of which the lpToken is removed
    /// @param lpToken lpToken address which is removed
    /// @param lpTokenAmount Amount of lpTokens removed, represented with 18 decimals
    event LpTokensRemoved(address account, address lpToken, uint256 lpTokenAmount);

    /// @notice Emitted when the PwTokens is added to lpToken pool
    /// @param beneficiary Account address on behalf of which the PwToken is added
    /// @param lpToken lpToken address to which the PwToken is added
    /// @param pwTokenAmount Amount of PwTokens added, represented with 18 decimals
    event PwTokensAdded(address beneficiary, address lpToken, uint256 pwTokenAmount);

    /// @notice Emitted when the PwTokens is removed from lpToken pool
    /// @param account Account address on behalf of which the PwToken is removed
    /// @param lpToken lpToken address from which the PwToken is removed
    /// @param pwTokenAmount Amount of PwTokens removed, represented with 18 decimals
    event PwTokensRemoved(address account, address lpToken, uint256 pwTokenAmount);
}

// File: lib/ipor-power-tokens/contracts/tokens/PowerTokenInternal.sol


pragma solidity 0.8.20;
















abstract contract PowerTokenInternal is
    PausableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    MiningOwnableUpgradeable,
    IPowerTokenInternal,
    IProxyImplementation
{
    using ContractValidator for address;

    bytes32 internal constant _GOVERNANCE_TOKEN_ID =
        0xdba05ed67d0251facfcab8345f27ccd3e72b5a1da8cebfabbcccf4316e6d053c;

    /// @dev 14 days
    uint256 public constant COOL_DOWN_IN_SECONDS = 2 * 7 * 24 * 60 * 60;

    address public immutable routerAddress;
    address internal immutable _governanceToken;

    // @dev @deprecated
    address internal _liquidityMiningDeprecated;
    // @dev @deprecated use _STAKED_TOKEN_ADDRESS instead
    address internal _governanceTokenDeprecated;
    // @deprecated field is deprecated
    address internal _pauseManagerDeprecated;

    /// @dev account address -> base amount, represented with 18 decimals
    mapping(address => uint256) internal _baseBalance;

    /// @dev balance of Power Token delegated to LiquidityMining, information per account, balance represented with 18 decimals
    mapping(address => uint256) internal _delegatedToLiquidityMiningBalance;

    // account address -> {endTimestamp, amount}
    mapping(address => PowerTokenTypes.PwTokenCooldown) internal _cooldowns;

    uint256 internal _baseTotalSupply;
    /// @dev value represents percentage in 18 decimals, example 1e18 = 100%, 50% = 5 * 1e17
    uint256 internal _unstakeWithoutCooldownFee;

    constructor(address routerAddressInput, address governanceTokenInput) {
        _governanceToken = governanceTokenInput.checkAddress();
        routerAddress = routerAddressInput.checkAddress();
        require(
            IGovernanceToken(governanceTokenInput).getContractId() == _GOVERNANCE_TOKEN_ID,
            Errors.WRONG_CONTRACT_ID
        );
    }

    /// @dev Throws an error if called by any account other than the pause guardian.
    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), Errors.CALLER_NOT_GUARDIAN);
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == routerAddress, Errors.CALLER_NOT_ROUTER);
        _;
    }

    function initialize() public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();

        /// @dev 50% fee for unstake without cooldown
        _unstakeWithoutCooldownFee = 1e17 * 5;
    }

    function getVersion() external pure override returns (uint256) {
        return 2_001;
    }

    function totalSupplyBase() external view override returns (uint256) {
        return _baseTotalSupply;
    }

    function calculateExchangeRate() external view override returns (uint256) {
        return _calculateInternalExchangeRate();
    }

    function getGovernanceToken() external view override returns (address) {
        return _governanceToken;
    }

    function setUnstakeWithoutCooldownFee(
        uint256 unstakeWithoutCooldownFee
    ) external override onlyOwner {
        require(unstakeWithoutCooldownFee <= 1e18, Errors.UNSTAKE_WITHOUT_COOLDOWN_FEE_IS_TO_HIGH);
        _unstakeWithoutCooldownFee = unstakeWithoutCooldownFee;
        emit UnstakeWithoutCooldownFeeChanged(unstakeWithoutCooldownFee);
    }

    function pause() external override onlyPauseGuardian {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function grantAllowanceForRouter(address erc20Token) external override onlyOwner {
        require(erc20Token != address(0), Errors.WRONG_ADDRESS);

        IERC20(erc20Token).approve(routerAddress, type(uint256).max);
        emit AllowanceGranted(msg.sender, erc20Token);
    }

    function revokeAllowanceForRouter(address erc20Token) external override onlyOwner {
        require(erc20Token != address(0), Errors.WRONG_ADDRESS);

        IERC20(erc20Token).approve(routerAddress, 0);
        emit AllowanceRevoked(erc20Token, routerAddress);
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function addPauseGuardians(address[] calldata guardians) external onlyOwner {
        PauseManager.addPauseGuardians(guardians);
    }

    function removePauseGuardians(address[] calldata guardians) external onlyOwner {
        PauseManager.removePauseGuardians(guardians);
    }

    function isPauseGuardian(address guardian) external view returns (bool) {
        return PauseManager.isPauseGuardian(guardian);
    }

    function _calculateInternalExchangeRate() internal view returns (uint256) {
        uint256 baseTotalSupply = _baseTotalSupply;

        if (baseTotalSupply == 0) {
            return 1e18;
        }

        uint256 balanceOfGovernanceToken = IERC20Upgradeable(_governanceToken).balanceOf(
            address(this)
        );

        if (balanceOfGovernanceToken == 0) {
            return 1e18;
        }

        return MathOperation.division(balanceOfGovernanceToken * 1e18, baseTotalSupply);
    }

    function _calculateAmountWithCooldownFeeSubtracted(
        uint256 baseAmount
    ) internal view returns (uint256) {
        return MathOperation.division((1e18 - _unstakeWithoutCooldownFee) * baseAmount, 1e18);
    }

    function _calculateBaseAmountToPwToken(
        uint256 baseAmount,
        uint256 exchangeRate
    ) internal pure returns (uint256) {
        return MathOperation.division(baseAmount * exchangeRate, 1e18);
    }

    function _getAvailablePwTokenAmount(
        address account,
        uint256 exchangeRate
    ) internal view returns (uint256) {
        return
            _calculateBaseAmountToPwToken(_baseBalance[account], exchangeRate) -
            _delegatedToLiquidityMiningBalance[account] -
            _cooldowns[account].pwTokenAmount;
    }

    function _balanceOf(address account) internal view returns (uint256) {
        return
            _calculateBaseAmountToPwToken(_baseBalance[account], _calculateInternalExchangeRate());
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// File: lib/ipor-power-tokens/contracts/interfaces/ILiquidityMiningInternal.sol


pragma solidity 0.8.20;


/// @title The interface for interaction with the LiquidityMining contract. Contains mainly technical methods or methods used by PowerToken smart contract.
interface ILiquidityMiningInternal {
    /// @notice Returns the current version of the LiquidityMining contract
    /// @return Current LiquidityMining (Liquidity Rewards) version
    function getVersion() external pure returns (uint256);

    /// @notice Checks if lpToken is supported by the liquidity mining module.
    /// @param lpToken lpToken address
    /// @return returns true if lpToken is supported by the LiquidityMining, false otherwise
    function isLpTokenSupported(address lpToken) external view returns (bool);

    /// @notice Sets the global configuration indicator - rewardsPerBlock for a given lpToken
    /// @param lpToken address for which to setup `rewards per block`
    /// @param pwTokenAmount amount of the `rewards per block`, denominated in Power Token, represented with 8 decimals
    function setRewardsPerBlock(address lpToken, uint32 pwTokenAmount) external;

    /// @notice Adds LiquidityMining's support for a new lpToken
    /// @dev Can only be executed by the Owner
    /// @param lpToken address of the lpToken
    function newSupportedLpToken(address lpToken) external;

    /// @notice Deprecation lpToken from the list of tokens supported by the LiquidityMining contract
    /// @dev Can be executed only by the Owner. Note! That when lpToken is removed, the rewards cannot be claimed. To restore claiming, run function {addLpToken()} and {setRewardsPerBlock()}
    /// @param lpToken address of the lpToken
    function phasingOutLpToken(address lpToken) external;

    /// @notice Pauses current smart contract, it can only be executed by the Owner
    /// @dev Emits {Paused} event.
    function pause() external;

    /// @notice Unpauses current smart contract, it can only be executed by the Owner
    /// @dev Emits {Unpaused}.
    function unpause() external;

    /// @notice Grants maximum allowance for a specified ERC20 token to the Router contract.
    /// @param erc20Token The address of the ERC20 token for which the allowance is granted.
    /// @dev This function grants maximum allowance (type(uint256).max) for the specified ERC20 token to the
    /// Router contract.
    /// @dev Reverts if the `erc20Token` address is zero.
    function grantAllowanceForRouter(address erc20Token) external;

    /// @notice Revokes the allowance for a specified ERC20 token from the Router contract.
    /// @param erc20Token The address of the ERC20 token for which the allowance is to be revoked.
    /// @dev This function revokes the allowance for the specified ERC20 token from the Router contract by setting the allowance to zero.
    /// @dev Reverts if the `erc20Token` address is zero.
    function revokeAllowanceForRouter(address erc20Token) external;

    /// @notice Adds a new pause guardian to the contract.
    /// @param guardians The addresses of the new pause guardians.
    /// @dev Only the contract owner can call this function.
    function addPauseGuardians(address[] calldata guardians) external;

    /// @notice Removes a pause guardian from the contract.
    /// @param guardians The addresses of the pause guardians to be removed.
    /// @dev Only the contract owner can call this function.
    function removePauseGuardians(address[] calldata guardians) external;

    /// @notice Checks if an address is a pause guardian.
    /// @param guardian The address to be checked.
    /// @return A boolean indicating whether the address is a pause guardian (true) or not (false).
    function isPauseGuardian(address guardian) external view returns (bool);

    /// @notice Emitted when the account unstakes lpTokens
    /// @param account account unstaking tokens
    /// @param lpToken address of lpToken being unstaked
    /// @param lpTokenAmount of lpTokens to unstake, represented with 18 decimals
    event LpTokensUnstaked(address account, address lpToken, uint256 lpTokenAmount);

    /// @notice Emitted when the LiquidityMining's Owner changes the `rewards per block`
    /// @param lpToken address of lpToken for which the `rewards per block` is changed
    /// @param newPwTokenAmount new value of `rewards per block`, denominated in Power Token, represented in 8 decimals
    event RewardsPerBlockChanged(address lpToken, uint256 newPwTokenAmount);

    /// @notice Emitted when the LiquidityMining's Owner adds support for lpToken
    /// @param account address of LiquidityMining's Owner
    /// @param lpToken address of newly supported lpToken
    event NewLpTokenSupported(address account, address lpToken);

    /// @notice Emitted when the LiquidityMining's Owner removes ssupport for lpToken
    /// @param account address of LiquidityMining's Owner
    /// @param lpToken address of dropped lpToken
    event LpTokenSupportRemoved(address account, address lpToken);

    /// @notice Emitted when the account delegates Power Tokens to the LiquidityMining
    /// @param account performing delegation
    /// @param lpToken address of lpToken to which Power Token are delegated
    /// @param pwTokenAmount amount of Power Tokens delegated, represented with 18 decimals
    event PwTokenDelegated(address account, address lpToken, uint256 pwTokenAmount);

    /// @notice Emitted when the account undelegates Power Tokens from the LiquidityMining
    /// @param account undelegating
    /// @param lpToken address of lpToken
    /// @param pwTokenAmount amount of Power Token undelegated, represented with 18 decimals
    event PwTokenUndelegated(address account, address lpToken, uint256 pwTokenAmount);

    /// @notice Emitted when the PauseManager's address is changed by its owner.
    /// @param newPauseManager PauseManager's new address
    event PauseManagerChanged(address indexed newPauseManager);

    /// @notice Emitted when owner grants allowance for router
    /// @param erc20Token address of ERC20 token
    /// @param router address of router
    event AllowanceGranted(address indexed erc20Token, address indexed router);

    /// @notice Emitted when owner revokes allowance for router
    /// @param erc20Token address of ERC20 token
    /// @param router address of router
    event AllowanceRevoked(address indexed erc20Token, address indexed router);
}

// File: lib/ipor-power-tokens/contracts/tokens/PowerToken.sol


pragma solidity 0.8.20;




///@title Smart contract responsible for managing Power Token.
/// @notice Power Token is retrieved when the account stakes [Staked] Token.
/// PowerToken smart contract allows for staking, unstaking of [Staked] Token, delegating, undelegating of Power Token balance to LiquidityMining.
contract PowerToken is PowerTokenInternal, IPowerToken {
    constructor(
        address routerAddress,
        address governanceTokenAddress
    ) PowerTokenInternal(routerAddress, governanceTokenAddress) {
        _disableInitializers();
    }

    function name() external pure override returns (string memory) {
        return "Power IPOR";
    }

    function symbol() external pure override returns (string memory) {
        return "pwIPOR";
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function getContractId() external pure returns (bytes32) {
        return 0xbd22bf01cb7daed462db61de31bb111aabcdae27adc748450fb9a9ea1c419cce;
    }

    function totalSupply() external view override returns (uint256) {
        return MathOperation.division(_baseTotalSupply * _calculateInternalExchangeRate(), 1e18);
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balanceOf(account);
    }

    function delegatedToLiquidityMiningBalanceOf(
        address account
    ) external view override returns (uint256) {
        return _delegatedToLiquidityMiningBalance[account];
    }

    function getUnstakeWithoutCooldownFee() external view override returns (uint256) {
        return _unstakeWithoutCooldownFee;
    }

    function getActiveCooldown(
        address account
    ) external view returns (PowerTokenTypes.PwTokenCooldown memory) {
        return _cooldowns[account];
    }

    function cooldownInternal(
        address account,
        uint256 pwTokenAmount
    ) external override whenNotPaused onlyRouter {
        uint256 availablePwTokenAmount = _calculateBaseAmountToPwToken(
            _baseBalance[account],
            _calculateInternalExchangeRate()
        ) - _delegatedToLiquidityMiningBalance[account];

        require(
            availablePwTokenAmount >= pwTokenAmount,
            Errors.ACC_AVAILABLE_POWER_TOKEN_BALANCE_IS_TOO_LOW
        );

        _cooldowns[account] = PowerTokenTypes.PwTokenCooldown(
            block.timestamp + COOL_DOWN_IN_SECONDS,
            pwTokenAmount
        );
        emit CooldownChanged(pwTokenAmount, block.timestamp + COOL_DOWN_IN_SECONDS);
    }

    function cancelCooldownInternal(address account) external override whenNotPaused onlyRouter {
        delete _cooldowns[account];
        emit CooldownChanged(0, 0);
    }

    function redeemInternal(
        address account
    ) external override whenNotPaused onlyRouter returns (uint256 transferAmount) {
        PowerTokenTypes.PwTokenCooldown memory accountCooldown = _cooldowns[account];
        transferAmount = accountCooldown.pwTokenAmount;
        require(block.timestamp >= accountCooldown.endTimestamp, Errors.COOL_DOWN_NOT_FINISH);
        require(transferAmount > 0, Errors.VALUE_NOT_GREATER_THAN_ZERO);

        uint256 exchangeRate = _calculateInternalExchangeRate();
        uint256 baseAmountToUnstake = MathOperation.division(transferAmount * 1e18, exchangeRate);

        require(
            _baseBalance[account] >= baseAmountToUnstake,
            Errors.ACCOUNT_BASE_BALANCE_IS_TOO_LOW
        );

        _baseBalance[account] -= baseAmountToUnstake;
        _baseTotalSupply -= baseAmountToUnstake;

        delete _cooldowns[account];

        emit Redeem(account, transferAmount);
    }

    function addGovernanceTokenInternal(
        PowerTokenTypes.UpdateGovernanceToken memory updateGovernanceToken
    ) external onlyRouter {
        require(
            updateGovernanceToken.governanceTokenAmount != 0,
            Errors.VALUE_NOT_GREATER_THAN_ZERO
        );

        uint256 exchangeRate = _calculateInternalExchangeRate();

        uint256 baseAmount = MathOperation.division(
            updateGovernanceToken.governanceTokenAmount * 1e18,
            exchangeRate
        );

        _baseBalance[updateGovernanceToken.beneficiary] += baseAmount;
        _baseTotalSupply += baseAmount;

        emit GovernanceTokenAdded(
            updateGovernanceToken.beneficiary,
            updateGovernanceToken.governanceTokenAmount,
            exchangeRate,
            baseAmount
        );
    }

    function removeGovernanceTokenWithFeeInternal(
        PowerTokenTypes.UpdateGovernanceToken memory updateGovernanceToken
    ) external onlyRouter returns (uint256 governanceTokenAmountToTransfer) {
        require(
            updateGovernanceToken.governanceTokenAmount > 0,
            Errors.VALUE_NOT_GREATER_THAN_ZERO
        );

        address account = updateGovernanceToken.beneficiary;

        uint256 exchangeRate = _calculateInternalExchangeRate();
        uint256 availablePwTokenAmount = _getAvailablePwTokenAmount(account, exchangeRate);

        require(
            availablePwTokenAmount >= updateGovernanceToken.governanceTokenAmount,
            Errors.ACC_AVAILABLE_POWER_TOKEN_BALANCE_IS_TOO_LOW
        );

        uint256 baseAmountToUnstake = MathOperation.division(
            updateGovernanceToken.governanceTokenAmount * 1e18,
            exchangeRate
        );

        require(
            _baseBalance[account] >= baseAmountToUnstake,
            Errors.ACCOUNT_BASE_BALANCE_IS_TOO_LOW
        );

        _baseBalance[account] -= baseAmountToUnstake;
        _baseTotalSupply -= baseAmountToUnstake;

        governanceTokenAmountToTransfer = _calculateBaseAmountToPwToken(
            _calculateAmountWithCooldownFeeSubtracted(baseAmountToUnstake),
            exchangeRate
        );

        emit GovernanceTokenRemovedWithFee(
            account,
            updateGovernanceToken.governanceTokenAmount,
            exchangeRate,
            updateGovernanceToken.governanceTokenAmount - governanceTokenAmountToTransfer
        );
    }

    function delegateInternal(
        address account,
        uint256 pwTokenAmount
    ) external override whenNotPaused onlyRouter {
        require(
            _getAvailablePwTokenAmount(account, _calculateInternalExchangeRate()) >= pwTokenAmount,
            Errors.ACC_AVAILABLE_POWER_TOKEN_BALANCE_IS_TOO_LOW
        );

        _delegatedToLiquidityMiningBalance[account] += pwTokenAmount;
        emit Delegated(account, pwTokenAmount);
    }

    function undelegateInternal(
        address account,
        uint256 pwTokenAmount
    ) external override whenNotPaused onlyRouter {
        require(
            _delegatedToLiquidityMiningBalance[account] >= pwTokenAmount,
            Errors.ACC_DELEGATED_TO_LIQUIDITY_MINING_BALANCE_IS_TOO_LOW
        );

        _delegatedToLiquidityMiningBalance[account] -= pwTokenAmount;
        emit Undelegated(account, pwTokenAmount);
    }
}