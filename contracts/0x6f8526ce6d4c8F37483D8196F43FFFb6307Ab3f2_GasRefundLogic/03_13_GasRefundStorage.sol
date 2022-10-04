//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct GasRefundState {
    uint256 funds;
}

library GasRefundStorage {
    bytes32 constant STORAGE_NAME = keccak256("humanboundtoken.v1:gasrefund");

    function _getState() internal view returns (GasRefundState storage gasRefundState) {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            gasRefundState.slot := position
        }
    }
}