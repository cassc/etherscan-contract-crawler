// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../access/Access.sol";
import "../common/Utils.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/ILaserState.sol";

/**
 * @title   LaserState
 *
 * @author  Rodrigo Herrera I.
 *
 * @notice  Has all the state(storage) for a Laser wallet and implements
 *          Smart Social Recovery.
 */
contract LaserState is ILaserState, Access {
    address internal constant POINTER = address(0x1); // POINTER for the link list.

    /*//////////////////////////////////////////////////////////////
                          LASER WALLET STORAGE
    //////////////////////////////////////////////////////////////*/

    address public singleton;

    address public owner;

    uint256 public nonce;

    uint256 internal guardianCount;

    uint256 internal recoveryOwnerCount;

    mapping(address => address) public guardians;

    mapping(address => address) public recoveryOwners;

    WalletConfig walletConfig;

    /**
     * @notice Locks the wallet. Can only be called by a recovery owner + recovery owner
     *         or recovery owner + guardian.
     *
     * @dev    Restricted, can only be called by address(this).
     */
    function lock() external access {
        walletConfig.isLocked = true;
        walletConfig.timestamp = block.timestamp;

        emit WalletLocked();
    }

    /**
     * @notice Unlocks the wallet. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev    Restricted, can only be called by address(this).
     */
    function unlock() external access {
        walletConfig.isLocked = false;
        walletConfig.timestamp = 0;

        emit WalletUnlocked();
    }

    /**
     * @notice Recovers the wallet. Can only be called by the recovery owner + recovery owner
     *         or recovery owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newOwner  Address of the new owner.
     */
    function recover(address newOwner) external access {
        uint256 elapsedTime = block.timestamp - walletConfig.timestamp;

        if (5 days > elapsedTime) revert LS__recover__timeLock();

        if (newOwner.code.length != 0 || newOwner == owner || newOwner == address(0)) {
            revert LS__recover__invalidAddress();
        }

        owner = newOwner;
        walletConfig.isLocked = false;
        walletConfig.timestamp = 0;

        emit WalletRecovered(newOwner);
    }

    /**
     * @notice Changes the owner of the wallet. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newOwner  Address of the new owner.
     */
    function changeOwner(address newOwner) external access {
        if (newOwner.code.length != 0 || newOwner == owner || newOwner == address(0)) {
            revert LS__changeOwner__invalidAddress();
        }

        owner = newOwner;

        emit OwnerChanged(newOwner);
    }

    /**
     * @notice Changes the singleton. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newSingleton  Address of the new singleton.
     */
    function changeSingleton(address newSingleton) external access {
        //bytes4(keccak256("I_AM_LASER"))
        if (
            newSingleton == singleton ||
            newSingleton == address(this) ||
            !IERC165(newSingleton).supportsInterface(0xae029e0b)
        ) revert LS__changeSingleton__invalidAddress();

        singleton = newSingleton;

        emit SingletonChanged(newSingleton);
    }

    /**
     * @notice Adds a new guardian. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newGuardian  Address of the new guardian.
     */
    function addGuardian(address newGuardian) external access {
        if (
            newGuardian == address(0) ||
            newGuardian == owner ||
            guardians[newGuardian] != address(0) ||
            recoveryOwners[newGuardian] != address(0) ||
            newGuardian == POINTER
        ) revert LS__addGuardian__invalidAddress();

        if (newGuardian.code.length > 0) {
            if (!IERC165(newGuardian).supportsInterface(0x1626ba7e)) {
                revert LS__addGuardian__invalidAddress();
            }
        }

        guardians[newGuardian] = guardians[POINTER];
        guardians[POINTER] = newGuardian;

        unchecked {
            guardianCount++;
        }

        emit NewGuardian(newGuardian);
    }

    /**
     * @notice Removes a guardian. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param prevGuardian      Address of the previous guardian in the linked list.
     * @param guardianToRemove  Address of the guardian to be removed.
     */
    function removeGuardian(address prevGuardian, address guardianToRemove) external access {
        if (guardianToRemove == POINTER) {
            revert LS__removeGuardian__invalidAddress();
        }

        if (guardians[prevGuardian] != guardianToRemove) {
            revert LS__removeGuardian__incorrectPreviousGuardian();
        }

        // There needs to be at least 1 guardian.
        if (guardianCount - 1 < 1) revert LS__removeGuardian__underflow();

        guardians[prevGuardian] = guardians[guardianToRemove];
        guardians[guardianToRemove] = address(0);

        unchecked {
            guardianCount--;
        }

        emit GuardianRemoved(guardianToRemove);
    }

    /**
     * @notice Adds a new recovery owner. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newRecoveryOwner  Address of the new recovery owner.
     */
    function addRecoveryOwner(address newRecoveryOwner) external access {
        if (
            newRecoveryOwner == address(0) ||
            newRecoveryOwner == owner ||
            recoveryOwners[newRecoveryOwner] != address(0) ||
            guardians[newRecoveryOwner] != address(0) ||
            newRecoveryOwner == POINTER
        ) revert LS__addRecoveryOwner__invalidAddress();

        if (newRecoveryOwner.code.length > 0) {
            if (!IERC165(newRecoveryOwner).supportsInterface(0x1626ba7e)) {
                revert LS__addRecoveryOwner__invalidAddress();
            }
        }

        recoveryOwners[newRecoveryOwner] = recoveryOwners[POINTER];
        recoveryOwners[POINTER] = newRecoveryOwner;

        unchecked {
            recoveryOwnerCount++;
        }

        emit NewRecoveryOwner(newRecoveryOwner);
    }

    /**
     * @notice Removes a recovery owner. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param prevRecoveryOwner      Address of the previous recovery owner in the linked list.
     * @param recoveryOwnerToRemove  Address of the recovery owner to be removed.
     */
    function removeRecoveryOwner(address prevRecoveryOwner, address recoveryOwnerToRemove) external access {
        if (recoveryOwnerToRemove == POINTER) {
            revert LS__removeRecoveryOwner__invalidAddress();
        }

        if (recoveryOwners[prevRecoveryOwner] != recoveryOwnerToRemove) {
            revert LS__removeRecoveryOwner__incorrectPreviousGuardian();
        }

        // There needs to be at least 1 recovery owner.
        if (recoveryOwnerCount - 1 < 1) revert LS__removeRecoveryOwner__underflow();

        recoveryOwners[prevRecoveryOwner] = recoveryOwners[recoveryOwnerToRemove];
        recoveryOwners[recoveryOwnerToRemove] = address(0);

        unchecked {
            recoveryOwnerCount--;
        }

        emit RecoveryOwnerRemoved(recoveryOwnerToRemove);
    }

    /**
     * @return Array of guardians for this wallet.
     */
    function getGuardians() external view returns (address[] memory) {
        address[] memory guardiansArray = new address[](guardianCount);
        address currentGuardian = guardians[POINTER];

        uint256 index = 0;
        while (currentGuardian != POINTER) {
            guardiansArray[index] = currentGuardian;
            currentGuardian = guardians[currentGuardian];
            index++;
        }
        return guardiansArray;
    }

    /**
     * @return Array of recovery owners for this wallet.
     */
    function getRecoveryOwners() external view returns (address[] memory) {
        address[] memory recoveryOwnersArray = new address[](recoveryOwnerCount);
        address currentRecoveryOwner = recoveryOwners[POINTER];

        uint256 index = 0;
        while (currentRecoveryOwner != POINTER) {
            recoveryOwnersArray[index] = currentRecoveryOwner;
            currentRecoveryOwner = recoveryOwners[currentRecoveryOwner];
            index++;
        }
        return recoveryOwnersArray;
    }

    /**
     * @return Boolean if the wallet is locked.
     */
    function isLocked() external view returns (bool) {
        return walletConfig.isLocked;
    }

    /**
     * @return The time (block.timestamp) when the wallet was locked.
     */
    function getConfigTimestamp() external view returns (uint256) {
        return walletConfig.timestamp;
    }

    /**
     * @notice Inits the guardians.
     *
     * @param _guardians Array of guardian addresses.
     */
    function initGuardians(address[] calldata _guardians) internal {
        uint256 guardiansLength = _guardians.length;
        // There needs to be at least 1 guardian.
        if (guardiansLength < 1) revert LS__initGuardians__underflow();

        address currentGuardian = POINTER;

        for (uint256 i = 0; i < guardiansLength; ) {
            address guardian = _guardians[i];
            if (
                guardian == owner ||
                guardian == address(0) ||
                guardian == POINTER ||
                guardian == currentGuardian ||
                guardians[guardian] != address(0)
            ) revert LS__initGuardians__invalidAddress();

            if (guardian.code.length > 0) {
                // If the guardian is a smart contract wallet, it needs to support EIP1271.
                if (!IERC165(guardian).supportsInterface(0x1626ba7e)) {
                    revert LS__initGuardians__invalidAddress();
                }
            }

            unchecked {
                i++;
            }
            guardians[currentGuardian] = guardian;
            currentGuardian = guardian;
        }

        guardians[currentGuardian] = POINTER;
        guardianCount = guardiansLength;
    }

    /**
     * @notice Inits the recovery owners.
     *
     * @param _recoveryOwners Array of recovery owner addresses.
     */
    function initRecoveryOwners(address[] calldata _recoveryOwners) internal {
        uint256 recoveryOwnersLength = _recoveryOwners.length;
        // There needs to be at least 1 recovery owner.
        if (recoveryOwnersLength < 1) revert LS__initRecoveryOwners__underflow();

        address currentRecoveryOwner = POINTER;

        for (uint256 i = 0; i < recoveryOwnersLength; ) {
            address recoveryOwner = _recoveryOwners[i];
            if (
                recoveryOwner == owner ||
                recoveryOwner == address(0) ||
                recoveryOwner == POINTER ||
                recoveryOwner == currentRecoveryOwner ||
                recoveryOwners[recoveryOwner] != address(0) ||
                guardians[recoveryOwner] != address(0)
            ) revert LS__initRecoveryOwners__invalidAddress();

            if (recoveryOwner.code.length > 0) {
                // If the recovery owner is a smart contract wallet, it needs to support EIP1271.
                if (!IERC165(recoveryOwner).supportsInterface(0x1626ba7e)) {
                    revert LS__initRecoveryOwners__invalidAddress();
                }
            }

            unchecked {
                i++;
            }
            recoveryOwners[currentRecoveryOwner] = recoveryOwner;
            currentRecoveryOwner = recoveryOwner;
        }

        recoveryOwners[currentRecoveryOwner] = POINTER;
        recoveryOwnerCount = recoveryOwnersLength;
    }

    /**
     * @notice Activates the wallet for the first time.
     *
     * @dev    Cannot be called after initialization.
     */
    function activateWallet(
        address _owner,
        address[] calldata _guardians,
        address[] calldata _recoveryOwners
    ) internal {
        // If owner is not address(0), the wallet is already active.
        if (owner != address(0)) revert LS__activateWallet__walletInitialized();

        if (_owner.code.length != 0) {
            revert LS__activateWallet__invalidOwnerAddress();
        }

        // We set the owner. There is no need for further verification.
        owner = _owner;

        // We init the guardians.
        initGuardians(_guardians);

        // We init the recovery owners.
        initRecoveryOwners(_recoveryOwners);
    }
}