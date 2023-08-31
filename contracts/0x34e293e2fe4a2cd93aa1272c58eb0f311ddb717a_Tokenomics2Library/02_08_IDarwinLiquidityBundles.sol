pragma solidity ^0.8.4;

// SPDX-License-Identifier: BSL-1.1

import {IDarwinMasterChef} from "./IMasterChef.sol";

interface IDarwinLiquidityBundles {

    struct User {
        uint256 lpAmount;
        uint256 lockEnd;
        uint256 bundledEth;
        uint256 bundledToken;
        bool inMasterchef;
    }

    event EnterBundle(
        address indexed user,
        uint256 amountToken,
        uint256 amountETH,
        uint256 timestamp,
        uint256 lockEnd
    );

    event ExitBundle(
        address indexed user,
        uint256 amountToken,
        uint256 amountETH,
        uint256 timestamp
    );

    event StakeInMasterchef(
        address indexed user,
        uint256 liquidity,
        uint256 timestamp
    );

    event HarvestAndRelock(
        address indexed user,
        uint256 amountDarwin,
        uint256 timestamp
    );

    function initialize(address _darwinRouter, IDarwinMasterChef _masterChef, address _WETH) external;
    function update(address _lpToken) external;
}