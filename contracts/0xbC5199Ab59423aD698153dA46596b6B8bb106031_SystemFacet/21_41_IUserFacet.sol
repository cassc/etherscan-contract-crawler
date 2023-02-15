// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Users
 * @notice Manage user entity
 * @dev Use manage user entity
 */
interface IUserFacet {
    /**
     * @notice Get the platform ID of `addr` account
     * @dev Convert address to platform ID
     * @param addr Account address
     * @return userId Unique platform ID
     */
    function getUserIdFromAddress(address addr) external pure returns (bytes32 userId);

    /**
     * @notice Get the token address from ID of the external token
     * @dev Convert the bytes32 external token ID to its respective ERC20 contract address
     * @param _externalTokenId The ID assigned to an external token
     * @return tokenAddress Contract address
     */
    function getAddressFromExternalTokenId(bytes32 _externalTokenId) external pure returns (address tokenAddress);

    /**
     * @notice Set the entity for the user
     * @dev Assign the user an entity. The entity must exist in order to associate it with a user.
     * @param _userId Unique platform ID of the user account
     * @param _entityId Unique platform ID of the entity
     */
    function setEntity(bytes32 _userId, bytes32 _entityId) external;

    /**
     * @notice Get the entity for the user
     * @dev Gets the entity related to the user
     * @param _userId Unique platform ID of the user account
     * @return entityId Unique platform ID of the entity
     */
    function getEntity(bytes32 _userId) external view returns (bytes32 entityId);
}