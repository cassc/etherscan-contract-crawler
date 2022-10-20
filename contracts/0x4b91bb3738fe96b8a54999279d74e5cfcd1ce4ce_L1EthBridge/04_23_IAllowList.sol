pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



interface IAllowList {
    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice public access is changed
    event UpdatePublicAccess(address indexed target, bool newStatus);

    /// @notice permission to call is changed
    event UpdateCallPermission(address indexed caller, address indexed target, bytes4 indexed functionSig, bool status);

    /// @notice pendingOwner is changed
    /// @dev Also emitted when the new owner is accepted and in this case, `newPendingOwner` would be zero address
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    /// @notice Owner changed
    event NewOwner(address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    function pendingOwner() external view returns (address);

    function owner() external view returns (address);

    function isAccessPublic(address _target) external view returns (bool);

    function hasSpecialAccessToCall(
        address _caller,
        address _target,
        bytes4 _functionSig
    ) external view returns (bool);

    function canCall(
        address _caller,
        address _target,
        bytes4 _functionSig
    ) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                           ALLOW LIST LOGIC
    //////////////////////////////////////////////////////////////*/

    function setBatchPublicAccess(address[] calldata _targets, bool[] calldata _enables) external;

    function setPublicAccess(address _target, bool _enable) external;

    function setBatchPermissionToCall(
        address[] calldata _callers,
        address[] calldata _targets,
        bytes4[] calldata _functionSigs,
        bool[] calldata _enables
    ) external;

    function setPermissionToCall(
        address _caller,
        address _target,
        bytes4 _functionSig,
        bool _enable
    ) external;

    function setPendingOwner(address _newPendingOwner) external;

    function acceptOwner() external;
}