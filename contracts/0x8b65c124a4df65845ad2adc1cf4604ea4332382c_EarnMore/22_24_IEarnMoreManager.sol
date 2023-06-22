// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IEarnMoreManager {
    function getPercentEarnMoreInfo()
        external
        view
        returns (uint256 exludePercent, uint256 earnMorePercent);

    function getVeInfo()
        external
        view
        returns (uint256 maxVePortion, uint256 maxVeMultiplier);

    function treasury() external view returns (address);

    function transferReward(
        address account,
        uint256 amount
    ) external returns (bool);
}