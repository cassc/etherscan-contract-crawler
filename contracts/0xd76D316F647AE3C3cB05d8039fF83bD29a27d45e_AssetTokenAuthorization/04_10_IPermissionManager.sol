// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @author Swarm Markets
/// @title IPermissionManager
/// @notice Provided interface to interact with Swarm Permission Manager
/// @notice authorization to a given address
interface IPermissionManager {
    function hasTier2(address _account) external view returns (bool);

    function isSuspended(address _account) external view returns (bool);

    function isRejected(address _account) external view returns (bool);

    function assignItem(uint256 _itemId, address[] memory _accounts) external;

    function getSecurityTokenId(address _tokenContract) external view returns (uint256);

    function generateSecurityTokenId(address _tokenContract) external returns (uint256);

    function editLastSecurityTokenId(uint256 _newId) external;

    function hasSecurityToken(address _user, uint256 itemId) external view returns (bool);
}