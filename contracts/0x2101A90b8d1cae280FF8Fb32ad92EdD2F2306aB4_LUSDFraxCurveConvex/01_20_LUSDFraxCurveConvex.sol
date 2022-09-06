//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/Constants.sol';
import './FraxCurveConvexStratBase.sol';

contract LUSDFraxCurveConvex is FraxCurveConvexStratBase {
    constructor(Config memory config)
        FraxCurveConvexStratBase(
            config,
            Constants.FRAX_USDC_ADDRESS,
            Constants.FRAX_USDC_LP_ADDRESS,
            Constants.CRV_FRAX_LUSD_ADDRESS,
            Constants.CRV_FRAX_LUSD_LP_ADDRESS,
            Constants.CVX_FRAX_LUSD_REWARDS_ADDRESS,
            Constants.CVX_FRAX_LUSD_PID,
            Constants.LUSD_ADDRESS,
            address(0),
            address(0)
        )
    {}
}