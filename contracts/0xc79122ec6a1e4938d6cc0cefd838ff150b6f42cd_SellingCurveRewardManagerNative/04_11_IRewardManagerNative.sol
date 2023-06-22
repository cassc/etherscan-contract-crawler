//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardManagerNative {
    function handle(
        address reward,
        uint256 amount,
        bool wrapped
    ) external;

    function valuate(address reward, uint256 amount) external view returns (uint256);
}