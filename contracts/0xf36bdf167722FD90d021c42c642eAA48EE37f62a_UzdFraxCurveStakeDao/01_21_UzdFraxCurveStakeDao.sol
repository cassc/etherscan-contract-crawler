//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FraxCurveStakeDaoApsStrat2.sol";

contract UzdFraxCurveStakeDao is FraxCurveStakeDaoApsStratBase {
    constructor(Config memory config)
    FraxCurveStakeDaoApsStratBase(
            config,
            Constants.ZUNAMI_POOL_ADDRESS,
            Constants.ZUNAMI_STABLE_ADDRESS,
            Constants.FRAX_USDC_ADDRESS,
            Constants.FRAX_USDC_LP_ADDRESS,
            Constants.CRV_FRAX_UZD_ADDRESS,
            Constants.CRV_FRAX_UZD_LP_ADDRESS,
            Constants.SDT_UZD_VAULT_ADDRESS,
            Constants.UZD_ADDRESS,
            address(0)
        )
    {}
}