/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../types/RewardSubmission.sol";

// SPDX-License-Identifier: GPL-3.0-only

interface RocketRewardsPoolInterface {
    function getRewardIndex() external view returns(uint256);
    function getRPLBalance() external view returns(uint256);
    function getPendingRPLRewards() external view returns (uint256);
    function getPendingETHRewards() external view returns (uint256);
    function getClaimIntervalTimeStart() external view returns(uint256);
    function getClaimIntervalTime() external view returns(uint256);
    function getClaimIntervalsPassed() external view returns(uint256);
    function getClaimingContractPerc(string memory _claimingContract) external view returns(uint256);
    function getClaimingContractsPerc(string[] memory _claimingContracts) external view returns (uint256[] memory);
    function getTrustedNodeSubmitted(address _trustedNodeAddress, uint256 _rewardIndex) external view returns (bool);
    function getSubmissionCount(RewardSubmission calldata _submission) external view returns (uint256);
    function submitRewardSnapshot(RewardSubmission calldata _submission) external;
    function executeRewardSnapshot(RewardSubmission calldata _submission) external;
}