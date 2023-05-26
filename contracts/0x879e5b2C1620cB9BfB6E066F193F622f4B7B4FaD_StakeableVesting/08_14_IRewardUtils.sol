//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IGetterUtils.sol";

interface IRewardUtils is IGetterUtils {
    event MintedReward(
        uint256 indexed epochIndex,
        uint256 amount,
        uint256 newApr,
        uint256 totalStake
        );

    function mintReward()
        external;
}