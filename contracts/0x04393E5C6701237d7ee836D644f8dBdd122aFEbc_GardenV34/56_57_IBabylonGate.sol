// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IBabylonGate
 * @author Babylon Finance
 *
 * Interface for interacting with the Guestlists
 */
interface IBabylonGate {
    /* ============ Functions ============ */

    function setGardenAccess(
        address _user,
        address _garden,
        uint8 _permission
    ) external returns (uint256);

    function setCreatorPermissions(address _user, bool _canCreate) external returns (uint256);

    function grantGardenAccessBatch(
        address _garden,
        address[] calldata _users,
        uint8[] calldata _perms
    ) external returns (bool);

    function maxNumberOfInvites() external view returns (uint256);

    function setMaxNumberOfInvites(uint256 _maxNumberOfInvites) external;

    function grantCreatorsInBatch(address[] calldata _users, bool[] calldata _perms) external returns (bool);

    function canCreate(address _user) external view returns (bool);

    function canJoinAGarden(address _garden, address _user) external view returns (bool);

    function canVoteInAGarden(address _garden, address _user) external view returns (bool);

    function canAddStrategiesInAGarden(address _garden, address _user) external view returns (bool);
}