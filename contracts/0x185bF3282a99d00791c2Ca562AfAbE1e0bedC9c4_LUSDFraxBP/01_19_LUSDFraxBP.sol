//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/Constants.sol';
import './CurveConvexFraxBasePool.sol';

contract LUSDFraxBP is CurveConvexFraxBasePool {
    constructor(Config memory config)
        CurveConvexFraxBasePool(
            config,
            Constants.FRAXBP_LUSD_ADDRESS,
            Constants.FRAXBP_LUSD_LP_ADDRESS,
            Constants.FRAXBP_LUSD_REWARDS_ADDRESS,
            Constants.FRAXBP_LUSD_PID,
            Constants.LUSD_ADDRESS,
            address(0),
            address(0)
        )
    {}
}