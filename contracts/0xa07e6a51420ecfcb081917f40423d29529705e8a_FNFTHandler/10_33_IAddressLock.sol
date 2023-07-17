// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRegistryProvider.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @title Provider interface for Revest FNFTs
 * @dev Address locks MUST be non-upgradeable to be considered for trusted status
 * @author Revest
 */
interface IAddressLock is IRegistryProvider, IERC165{

    /// Creates a lock to the specified lockID
    /// @param fnftId the fnftId to map this lock to. Not recommended for typical locks, as it will break on splitting
    /// @param lockId the lockId to map this lock to. Recommended uint for storing references to lock configurations
    /// @param arguments an abi.encode() bytes array. Allows frontend to encode and pass in an arbitrary set of parameters
    /// @dev creates a lock for the specified lockId. Will be called during the creation process for address locks when the address
    ///      of a contract implementing this interface is passed in as the "trigger" address for minting an address lock. The bytes
    ///      representing any parameters this lock requires are passed through to this method, where abi.decode must be call on them
    function createLock(uint fnftId, uint lockId, bytes memory arguments) external;

    /// Updates a lock at the specified lockId
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @param arguments an abi.encode() bytes array. Allows frontend to encode and pass in an arbitrary set of parameters
    /// @dev updates a lock for the specified lockId. Will be called by the frontend from the information section if an update is requested
    ///      can further accept and decode parameters to use in modifying the lock's config or triggering other actions
    ///      such as triggering an on-chain oracle to update
    function updateLock(uint fnftId, uint lockId, bytes memory arguments) external;

    /// Whether or not the lock can be unlocked
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @dev this method is called during the unlocking and withdrawal processes by the Revest contract - it is also used by the frontend
    ///      if this method is returning true and someone attempts to unlock or withdraw from an FNFT attached to the requested lock, the request will succeed
    /// @return whether or not this lock may be unlocked
    function isUnlockable(uint fnftId, uint lockId) external view returns (bool);

    /// Provides an encoded bytes arary that represents values this lock wants to display on the info screen
    /// Info to decode these values is provided in the metadata file
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @dev used by the frontend to fetch on-chain data on the state of any given lock
    /// @return a bytes array that represents the result of calling abi.encode on values which the developer wants to appear on the frontend
    function getDisplayValues(uint fnftId, uint lockId) external view returns (bytes memory);

    /// Maps to a URL, typically IPFS-based, that contains information on how to encode and decode paramters sent to and from this lock
    /// Please see additional documentation for JSON config info
    /// @dev this method will be called by the frontend only but is crucial to properly implement for proper minting and information workflows
    /// @return a URL to the JSON file containing this lock's metadata schema
    function getMetadata() external view returns (string memory);

    /// Whether or not this lock will need updates and should display the option for them
    /// @dev this will be called by the frontend to determine if update inputs and buttons should be displayed
    /// @return whether or not the locks created by this contract will need updates
    function needsUpdate() external view returns (bool);
}