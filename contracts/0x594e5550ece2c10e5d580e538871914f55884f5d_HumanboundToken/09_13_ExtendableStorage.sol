//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Storage struct used to hold state for Extendable contracts
 */
struct ExtendableState {
    // Array of full interfaceIds extended by the Extendable contract instance
    bytes4[] implementedInterfaceIds;

    // Array of function selectors extended by the Extendable contract instance
    mapping(bytes4 => bytes4[]) implementedFunctionsByInterfaceId;

    // Mapping of interfaceId/functionSelector to the extension address that implements it
    mapping(bytes4 => address) extensionContracts;
}

/**
 * @dev Storage library to access storage slot for the state struct
 */
library ExtendableStorage {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:extendable-state");

    function _getState()
        internal 
        view
        returns (ExtendableState storage extendableState) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            extendableState.slot := position
        }
    }
}