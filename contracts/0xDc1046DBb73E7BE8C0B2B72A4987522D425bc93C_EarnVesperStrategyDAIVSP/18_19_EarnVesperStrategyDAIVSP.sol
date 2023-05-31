// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./EarnVesperStrategyVSPDrip.sol";

// solhint-disable no-empty-blocks
/// @title Deposit DAI in a Vesper Grow Pool and earn interest in VSP.
contract EarnVesperStrategyDAIVSP is EarnVesperStrategyVSPDrip {
    string public constant NAME = "Earn-Vesper-Strategy-DAI-VSP";
    string public constant VERSION = "3.0.22";

    // Strategy will deposit collateral in
    // vaDAI = 0x0538C8bAc84E95A9dF8aC10Aad17DbE81b9E36ee
    // And collect drip in
    // VSP = 0x1b40183EFB4Dd766f11bDa7A7c3AD8982e998421
    constructor(address _pool, address _swapManager)
        EarnVesperStrategy(
            _pool,
            _swapManager,
            0x0538C8bAc84E95A9dF8aC10Aad17DbE81b9E36ee,
            0x1b40183EFB4Dd766f11bDa7A7c3AD8982e998421
        )
    {}
}