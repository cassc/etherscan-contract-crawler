// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IGmxPositionRouter } from '../interfaces/IGmxPositionRouter.sol';

library GmxHelpers {
    function getIncreasePositionRequestsData(
        IGmxPositionRouter gmxPositionRouter,
        bytes32 key
    )
        internal
        view
        returns (address account, address inputToken, uint256 amountIn)
    {
        (account, , amountIn, , , , , , , , , ) = IGmxPositionRouter(
            gmxPositionRouter
        ).increasePositionRequests(key);

        address[] memory path = IGmxPositionRouter(gmxPositionRouter)
            .getIncreasePositionRequestPath(key);

        if (path.length > 0) {
            inputToken = path[0];
        }
    }
}