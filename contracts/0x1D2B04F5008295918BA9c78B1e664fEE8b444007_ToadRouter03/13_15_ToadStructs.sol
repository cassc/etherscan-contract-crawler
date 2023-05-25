// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

contract ToadStructs {
    /**
     * token: The token
     * dexId: the position of the dex struct in the list provided - should be the same between input and output token 
     */
    struct AggPath {
        address token;
        uint96 dexId;
    }
    /**
     * DexData - a list of UniV2 dexes referred to in AggPath - shared between gasPath and path
     * initcode: the initcode to feed the create2 seed
     * factory: the factory address to feed the create2 seed
     */
    struct DexData {
        bytes32 initcode;
        address factory;
    }
    /**
     * FeeStruct - a batch of fees to be paid in gas and optionally to another account
     */
    struct FeeStruct {
        uint256 gasReturn;
        address feeReceiver;
        uint96 fee;
    }
}