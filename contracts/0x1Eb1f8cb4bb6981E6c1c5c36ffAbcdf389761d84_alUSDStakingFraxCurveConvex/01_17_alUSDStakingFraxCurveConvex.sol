//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../../../utils/Constants.sol';
import './StakingFraxCurveConvexStratBase.sol';

contract alUSDStakingFraxCurveConvex is StakingFraxCurveConvexStratBase {
    constructor(Config memory config)
        StakingFraxCurveConvexStratBase(
            config,
            Constants.FRAX_USDC_ADDRESS,
            Constants.FRAX_USDC_LP_ADDRESS,
            Constants.CRV_FRAX_alUSD_ADDRESS,
            Constants.CRV_FRAX_alUSD_LP_ADDRESS,
            Constants.CVX_FRAX_alUSD_PID // 19
        )
    {}
}