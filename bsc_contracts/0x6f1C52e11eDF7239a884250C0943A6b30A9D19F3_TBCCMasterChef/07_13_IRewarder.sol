// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRewarder {
    function onTFTReward(
        uint256 _pid,
        address _user,
        address _recipient,
        uint256 _tbccAmount,
        uint256 _newLpAmount
    ) external;

    function pendingTokens(
        uint256 _pid,
        address _user,
        uint256 _sushiAmount
    ) external view returns (address[] memory, uint256[] memory);
}