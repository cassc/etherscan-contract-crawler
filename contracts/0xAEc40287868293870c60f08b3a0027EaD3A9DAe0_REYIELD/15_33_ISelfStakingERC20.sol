// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IUUPSERC20.sol";
import "./IOwned.sol";

interface ISelfStakingERC20 is IUUPSERC20
{
    event RewardAdded(uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event Excluded(address indexed user, bool excluded);

    error InvalidParameters();
    error TooMuch();
    error WrongRewardToken();
    error NotDelegatedClaimer();
    error NotRewardManager();
    error NotSelfStakingERC20Owner();

    function isSelfStakingERC20() external view returns (bool);
    function rewardToken() external view returns (IERC20);
    function isExcluded(address addr) external view returns (bool);
    function totalStakingSupply() external view returns (uint256);
    function rewardData() external view returns (uint256 lastRewardTimestamp, uint256 startTimestamp, uint256 endTimestamp, uint256 amountToDistribute);
    function pendingReward(address user) external view returns (uint256);
    function isDelegatedClaimer(address user) external view returns (bool);
    function isRewardManager(address user) external view returns (bool);

    function claim() external;
    
    function claimFor(address user) external;

    function addReward(uint256 amount, uint256 startTimestamp, uint256 endTimestamp) external;
    function addRewardPermit(uint256 amount, uint256 startTimestamp, uint256 endTimestamp, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function setExcluded(address user, bool excluded) external;
    function setDelegatedClaimer(address user, bool enable) external;
    function setRewardManager(address user, bool enable) external;
}