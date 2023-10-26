// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IStakedCredmark {
    function setRewardsPool(address rewardsPool) external;

    function cmkBalance() external view returns (uint256);

    function cmkBalanceOf(address account) external view returns (uint256);

    function sharesToCmk(uint256 sharesAmount) external view returns (uint256 cmkAmount);

    function cmkToShares(uint256 cmkAmount) external view returns (uint256 sharesAmount);

    function createShare(uint256 cmkAmount) external returns (uint256);

    function removeShare(uint256 sharesAmount) external;
}