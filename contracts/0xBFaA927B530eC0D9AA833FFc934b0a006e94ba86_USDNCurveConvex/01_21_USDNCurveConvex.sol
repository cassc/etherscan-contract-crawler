//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/Constants.sol';
import './CurveConvexStrat2.sol';

contract USDNCurveConvex is CurveConvexStrat2 {
    constructor(Config memory config)
        CurveConvexStrat2(
            config,
            Constants.CRV_USDN_ADDRESS,
            Constants.CRV_USDN_LP_ADDRESS,
            Constants.CVX_USDN_REWARDS_ADDRESS,
            Constants.CVX_USDN_PID,
            Constants.USDN_ADDRESS,
            address(0),
            address(0)
        )
    {}
}