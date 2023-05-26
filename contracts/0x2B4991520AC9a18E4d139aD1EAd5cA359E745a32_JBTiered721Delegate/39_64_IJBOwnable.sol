// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBOwnable {
    // event OwnershipTransferred(
    //     address indexed previousOwner,
    //     address indexed newOwner
    // );
    event PermissionIndexChanged(uint8 newIndex);

    function jbOwner()
        external
        view
        returns (
            address owner,
            uint88 projectOwner,
            uint8 permissionIndex
        );

    function transferOwnershipToProject(uint256 _projectId) external;

    function setPermissionIndex(uint8 _permissionIndex) external;
}