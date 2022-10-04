//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct EthereumAccessTokenState {
    // store the address of the EAT verifier
    address verifier;
}

library EthereumAccessTokenStorage {
    bytes32 constant STORAGE_NAME = keccak256("extendable:ethereumaccesstoken");

    function _getState() internal view returns (EthereumAccessTokenState storage eatState) {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            eatState.slot := position
        }
    }
}