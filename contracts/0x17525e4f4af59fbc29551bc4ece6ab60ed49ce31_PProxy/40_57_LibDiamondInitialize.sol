// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Mick de Graaf
*
* Tracks if the contract is already intialized or not
/******************************************************************************/

import "../interfaces/IDiamondCut.sol";

library LibDiamondInitialize {
    bytes32 constant DIAMOND_INITIALIZE_STORAGE_POSITION = keccak256("diamond.standard.initialize.diamond.storage");

    struct InitializedStorage {
        bool initialized;
    }

    function diamondInitializeStorage() internal pure returns (InitializedStorage storage ids) {
        bytes32 position = DIAMOND_INITIALIZE_STORAGE_POSITION;
        assembly {
            ids.slot := position
        }
    }

}