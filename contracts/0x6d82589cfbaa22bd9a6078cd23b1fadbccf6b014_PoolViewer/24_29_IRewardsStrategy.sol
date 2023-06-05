// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IRewardsStrategy {
    function getNftRewardsShare() external view returns (uint256 nftShare);
}