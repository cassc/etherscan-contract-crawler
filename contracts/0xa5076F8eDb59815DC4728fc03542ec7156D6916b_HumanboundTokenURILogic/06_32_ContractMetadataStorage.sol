//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct ContractMetadataState {
    string contractURI;
}

library ContractMetadataStorage {
    bytes32 constant STORAGE_NAME = keccak256("humanboundtoken.v1:contract-metadata");

    function _getState() internal view returns (ContractMetadataState storage contractMetadataState) {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            contractMetadataState.slot := position
        }
    }
}