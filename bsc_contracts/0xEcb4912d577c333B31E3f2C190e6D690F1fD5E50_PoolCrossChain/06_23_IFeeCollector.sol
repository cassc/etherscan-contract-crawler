// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/IAsset.sol";

interface IFeeCollector {
    function collectFees(IAsset asset_, uint256 amount_) external;
}