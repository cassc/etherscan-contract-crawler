// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./EarnVesperStrategy.sol";

// solhint-disable no-empty-blocks
/// @title Deposit DAI in a Vesper Grow Pool and earn interest in WBTC.
contract EarnVesperStrategyDAIWBTC is EarnVesperStrategy {
    string public constant NAME = "Earn-Vesper-Strategy-DAI-WBTC";
    string public constant VERSION = "3.0.15";

    // Strategy will deposit collateral in
    // vaDAI (beta) = 0x0538C8bAc84E95A9dF8aC10Aad17DbE81b9E36ee
    // And collect drip in
    // WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    constructor(address _pool, address _swapManager)
        EarnVesperStrategy(
            _pool,
            _swapManager,
            0x0538C8bAc84E95A9dF8aC10Aad17DbE81b9E36ee,
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
        )
    {}
}