// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

/**
 * @notice Wallet configuration for the recovery mechanism.
 *
 * @param isLocked  Boolean if the wallet is currently locked.
 * @param timestamp The time (block.timestamp) when the wallet was locked.
 */
struct WalletConfig {
    bool isLocked;
    uint256 timestamp;
}

/**
 * @title   LaserState
 *
 * @author  Rodrigo Herrera I.
 *
 * @notice  Has all the state(storage) for a Laser wallet and implements
 *          Smart Social Recovery.
 *
 * @dev    This interface has all events, errors, and external function for LaserState.
 */
interface ILaserState {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event WalletLocked();

    event WalletUnlocked();

    event WalletRecovered(address newOwner);

    event OwnerChanged(address newOwner);

    event SingletonChanged(address newSingleton);

    event NewGuardian(address newGuardian);

    event GuardianRemoved(address removedGuardian);

    event NewRecoveryOwner(address NewRecoveryOwner);

    event RecoveryOwnerRemoved(address removedRecoveryOwner);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error LS__recover__timeLock();

    error LS__recover__invalidAddress();

    error LS__changeOwner__invalidAddress();

    error LS__changeSingleton__invalidAddress();

    error LS__addGuardian__invalidAddress();

    error LS__removeGuardian__invalidAddress();

    error LS__removeGuardian__incorrectPreviousGuardian();

    error LS__removeGuardian__underflow();

    error LS__addRecoveryOwner__invalidAddress();

    error LS__removeRecoveryOwner__invalidAddress();

    error LS__removeRecoveryOwner__incorrectPreviousGuardian();

    error LS__removeRecoveryOwner__underflow();

    error LS__initGuardians__underflow();

    error LS__initGuardians__invalidAddress();

    error LS__initRecoveryOwners__underflow();

    error LS__initRecoveryOwners__invalidAddress();

    error LS__activateWallet__walletInitialized();

    error LS__activateWallet__invalidOwnerAddress();

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    function singleton() external view returns (address);

    function owner() external view returns (address);

    function nonce() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Locks the wallet. Can only be called by a recovery owner + recovery owner
     *         or recovery owner + guardian.
     *
     * @dev    Restricted, can only be called by address(this).
     */
    function lock() external;

    /**
     * @notice Unlocks the wallet. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev    Restricted, can only be called by address(this).
     */
    function unlock() external;

    /**
     * @notice Recovers the wallet. Can only be called by the recovery owner + recovery owner
     *         or recovery owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newOwner  Address of the new owner.
     */
    function recover(address newOwner) external;

    /**
     * @notice Changes the owner of the wallet. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newOwner  Address of the new owner.
     */
    function changeOwner(address newOwner) external;

    /**
     * @notice Changes the singleton. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newSingleton  Address of the new singleton.
     */
    function changeSingleton(address newSingleton) external;

    /**
     * @notice Adds a new guardian. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newGuardian  Address of the new guardian.
     */
    function addGuardian(address newGuardian) external;

    /**
     * @notice Removes a guardian. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param prevGuardian      Address of the previous guardian in the linked list.
     * @param guardianToRemove  Address of the guardian to be removed.
     */
    function removeGuardian(address prevGuardian, address guardianToRemove) external;

    /**
     * @notice Adds a new recovery owner. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newRecoveryOwner  Address of the new recovery owner.
     */
    function addRecoveryOwner(address newRecoveryOwner) external;

    /**
     * @notice Removes a recovery owner. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param prevRecoveryOwner      Address of the previous recovery owner in the linked list.
     * @param recoveryOwnerToRemove  Address of the recovery owner to be removed.
     */
    function removeRecoveryOwner(address prevRecoveryOwner, address recoveryOwnerToRemove) external;

    /**
     * @return Array of guardians for this wallet.
     */
    function getGuardians() external view returns (address[] memory);

    /**
     * @return Array of recovery owners for this wallet.
     */
    function getRecoveryOwners() external view returns (address[] memory);

    /**
     * @return Boolean if the wallet is locked.
     */
    function isLocked() external view returns (bool);

    /**
     * @return The time (block.timestamp) when the wallet was locked.
     */
    function getConfigTimestamp() external view returns (uint256);
}