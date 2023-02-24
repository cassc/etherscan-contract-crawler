// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

contract ReentrancyGuard {

    bytes32 private constant REENTRANCY_MUTEX_POSITION = 0xe855346402235fdd185c890e68d2c4ecad599b88587635ee285bce2fda58dacb;

    string private constant ERROR_REENTRANT = "REENTRANCY_REENTRANT_CALL";

    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly { data := sload(position) }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly { sstore(position, data) }
    }


    modifier nonReentrant() {
        // Ensure mutex is unlocked
        require(!getStorageBool(REENTRANCY_MUTEX_POSITION), ERROR_REENTRANT);

        // Lock mutex before function call
        setStorageBool(REENTRANCY_MUTEX_POSITION,true);

        // Perform function call
        _;

        // Unlock mutex after function call
        setStorageBool(REENTRANCY_MUTEX_POSITION, false);
    }
}