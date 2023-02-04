//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardManager {
    function handle(
        address reward,
        uint256 amount,
        address feeToken
    ) external;

    function valuate(
        address reward,
        uint256 amount,
        address feeToken
    ) external view returns (uint256);
}