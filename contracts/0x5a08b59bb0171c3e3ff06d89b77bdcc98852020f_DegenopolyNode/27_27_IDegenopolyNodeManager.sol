// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IDegenopolyNodeManager {
    function getMultiplierFor(address _account) external view returns (uint256);

    function balanceOf(
        address _account
    ) external view returns (uint256 balance);

    function claimableReward(
        address _account
    ) external view returns (uint256 pending);

    function mintNodeFamily(address _account) external;

    function burnNodeFamily(address _account) external;

    function addMultiplier(address _account, uint256 _multiplier) external;
}