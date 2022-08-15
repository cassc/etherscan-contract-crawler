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

// SPDX-License-Identifier: GPL-3.0-only

interface RocketRewardsRelayInterface {
    function relayRewards(uint256 _intervalIndex, bytes32 _merkleRoot, uint256 _rewardsRPL, uint256 _rewardsETH) external;
    function claim(address _nodeAddress, uint256[] calldata _intervalIndex, uint256[] calldata _amountRPL, uint256[] calldata _amountETH, bytes32[][] calldata _merkleProof) external;
    function claimAndStake(address _nodeAddress, uint256[] calldata _intervalIndex, uint256[] calldata _amountRPL, uint256[] calldata _amountETH, bytes32[][] calldata _merkleProof, uint256 _stakeAmount) external;
    function isClaimed(uint256 _intervalIndex, address _claimer) external view returns (bool);
}