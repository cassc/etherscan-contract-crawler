// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./LstOracle.sol";
import "./extensions/Cross2RateLstOracle.sol";

// 0x536218f9E9Eb48863970252233c8F271f554C2d0 rETH/ETH
// 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 ETH/USD
contract RethOracle is Cross2RateLstOracle {
    function initialize(AggregatorV3Interface _aggregatorAddress1, AggregatorV3Interface _aggregatorAddress2, IMasterVault _masterVault) external initializer {
        __LstOracle__init(_masterVault);
        __Cross2RateLstOracle__init(_aggregatorAddress1, _aggregatorAddress2);
    }
}