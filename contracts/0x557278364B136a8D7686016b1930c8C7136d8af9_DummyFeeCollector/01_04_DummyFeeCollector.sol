// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/IAsset.sol";

contract DummyFeeCollector {
    event FeeShouldCollect(IAsset asset, uint256 amount);

    function collectFees(IAsset asset_, uint256 amount_) external {
        emit FeeShouldCollect(asset_, amount_);
    }
}