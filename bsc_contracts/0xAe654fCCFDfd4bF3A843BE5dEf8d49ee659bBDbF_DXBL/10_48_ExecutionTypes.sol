//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./TokenTypes.sol";

/**
 * These types only relevant for relay-based submissions through protocol
 */
library ExecutionTypes {

    /**
     * Basic fee information which includes any payments to be made to affiliates.
     */
    struct FeeDetails {

        //the fee token to pay
        IERC20 feeToken;

        //affiliate address to pay affiliate fee
        address affiliate;

        //fee to pay affiliate
        uint affiliatePortion;
    }

    /**
     * Shared information in every execution request. This will evolve 
     * over time to support signatures and privacy proofs as the protocol
     * decentralizes
     */
    struct ExecutionRequest {
        //account requesting this execution
        address requester;

        //fees info
        FeeDetails fee;
    }
}