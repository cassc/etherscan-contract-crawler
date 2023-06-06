// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IStorage
 * @notice Interface for Storage
 */
interface IStorage {

    /**
     * @notice Lets an authorised module add a guardian to a vault.
     * @param _vault - The target vault.
     * @param _guardian - The guardian to add.
     */
    function setGuardian(address _vault, address _guardian) external;

    /**
     * @notice Lets an authorised module revoke a guardian from a vault.
     * @param _vault - The target vault.
     */
    function revokeGuardian(address _vault) external;

    /**
     * @notice Function to be used to add heir address to bequeath vault ownership.
     * @param _vault - The target vault.
     */
    function setHeir(address _vault, address _newHeir) external;

    /**
     * @notice Function to be called when voting has to be toggled.
     * @param _vault - The target vault.
     */
    function toggleVoting(address _vault) external;

    /**
     * @notice Set or unsets lock for a vault contract.
     * @param _vault - The target vault.
     * @param _lock - Lock needed to be set.
     */
    function setLock(address _vault, bool _lock) external;

    /**
     * @notice Sets a new time delay for a vault contract.
     * @param _vault - The target vault.
     * @param _newTimeDelay - The new time delay.
     */
    function setTimeDelay(address _vault, uint256 _newTimeDelay) external;

    /**
     * @notice Checks if an account is a guardian for a vault.
     * @param _vault - The target vault.
     * @param _guardian - The account address to be checked.
     * @return true if the account is a guardian for a vault.
     */
    function isGuardian(address _vault, address _guardian) external view returns (bool);

    /**
     * @notice Returns guardian address.
     * @param _vault - The target vault.
     * @return the address of the guardian account if guardian is added else returns zero address.
     */
    function getGuardian(address _vault) external view returns (address);

    /**
     * @notice Returns boolean indicating state of the vault.
     * @param _vault - The target vault.
     * @return true if the vault is locked, else returns false.
     */
    function isLocked(address _vault) external view returns (bool);

    /**
     * @notice Returns boolean indicating if voting is enabled.
     * @param _vault - The target vault.
     * @return true if voting is enabled, else returns false.
     */
    function votingEnabled(address _vault) external view returns (bool);

    /**
     * @notice Returns uint256 time delay in seconds for a vault
     * @param _vault - The target vault.
     * @return uint256 time delay in seconds for a vault.
     */
    function getTimeDelay(address _vault) external view returns (uint256);

    /**
     * @notice Returns an heir address for a vault.
     * @param _vault - The target vault.
     */
    function getHeir(address _vault) external view returns(address);
}