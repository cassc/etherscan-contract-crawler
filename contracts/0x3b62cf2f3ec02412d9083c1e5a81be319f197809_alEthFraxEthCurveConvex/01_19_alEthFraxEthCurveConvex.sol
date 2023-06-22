//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../../../../utils/Constants.sol';
import './FrxEthCurveConvexStratBase.sol';

contract alEthFraxEthCurveConvex is FrxEthCurveConvexStratBase {
    constructor(Config memory config)
        FrxEthCurveConvexStratBase(
            config,
            Constants.CRV_FRAX_alETH_ADDRESS,
            Constants.CRV_FRAX_alETH_LP_ADDRESS,
            Constants.CVX_FRAX_alETH_REWARDS_ADDRESS,
            Constants.CVX_FRAX_alETH_PID
        )
    {}
}