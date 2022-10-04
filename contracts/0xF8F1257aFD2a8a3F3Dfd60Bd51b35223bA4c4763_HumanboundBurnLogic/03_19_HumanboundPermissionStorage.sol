//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct HumanboundPermissionState {
    address operator;
}

library HumanboundPermissionStorage {
    bytes32 constant STORAGE_NAME = keccak256("humanboundtoken.v1:permission");

    function _getState() internal view returns (HumanboundPermissionState storage permissionState) {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            permissionState.slot := position
        }
    }
}