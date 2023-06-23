// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./extensions/CrossRateLstOracle.sol";

// AggregatorV3Interface 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8 stETH/USD
contract WstETHOracle is CrossRateLstOracle {

    function initialize(AggregatorV3Interface _aggregatorAddress, address _wstETH, IMasterVault _masterVault, IRatioAdapter _ratioAdapter) external initializer {
        __LstOracle__init(_masterVault);
        __CrossRateLstOracle__init(_aggregatorAddress, _wstETH, _ratioAdapter);
    }
}