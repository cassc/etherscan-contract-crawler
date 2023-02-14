//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./TokenTypes.sol";
import "./ExecutionTypes.sol";

/**
 * Swap data strutures to submit for execution
 */
library SwapTypes {

    /**
     * Individual router called to execute some action. Only approved 
     * router addresses will execute successfully
     */
    struct RouterRequest {
        //router contract that handles the specific route data
        address router;

        //any spend allowance approval required
        address spender;

        //the amount to send to the router
        TokenTypes.TokenAmount routeAmount;

        //the data to use for calling the router
        bytes routerData;
    }

    /**
     * Swap request that is restricted to only relay-based executions. This prevents
     * applying discounts through sybil attacks and affiliate addresses.
     */
    struct SwapRequest {

        //general execution request details
        ExecutionTypes.ExecutionRequest executionRequest;

        //input token and amount
        TokenTypes.TokenAmount tokenIn;

        //expected min output and amount
        TokenTypes.TokenAmount tokenOut;

        //array of routes to call to perform swaps
        RouterRequest[] routes;
    }

    /**
     * This is used when the caller is also the trader.
     */
    struct SelfSwap {
        //fee token paying in
        IERC20 feeToken;

        //input token and full amount
        /*
         * NOTE: it's possible to swap native asset vs. wrapped asset when self-submitting. Could
         * use some standard "ETH" address to represent native asset and then verify value sent
         * with txn. Then wrap that in the token for swapping as part of the trade.
         */
        TokenTypes.TokenAmount tokenIn;

        //output token and minimum amount out expected
        TokenTypes.TokenAmount tokenOut;

        //the routers to call
        RouterRequest[] routes;
    }
}