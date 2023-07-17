// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokeRewards.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokeStaker {
    //structs
    struct Staking {
        uint256 amountToke;
        uint256 numCycle;
    }

    struct DepositsInfo {
        address addr;
        bytes signature;
    }

    struct RewardsInfo {
        ITokeRewards rewardContract;
        IERC20 rewardAsset;
    }

    //getters
    function getRewardsInfo() external view returns (RewardsInfo[] memory);

    function getDepositsInfo() external view returns (DepositsInfo[] memory);

    //onlyOwner
    function addAssetInfo(RewardsInfo memory _rewardInfo, DepositsInfo memory _depositInfo) external;

    function removeLastAssetInfo() external;

    function setDepositInfo(uint256 element, DepositsInfo memory _depositInfo) external;

    function setRewardInfo(uint256 element, RewardsInfo memory _rewardsInfo) external;

    function stakeAndUpdateTokeCycle(Staking[] calldata _staking) external;

    function depositAndProcessTokeRewards(ITokeRewards.ClaimData[] calldata claimData) external;

    function withdrawToken(IERC20 _token) external;
}