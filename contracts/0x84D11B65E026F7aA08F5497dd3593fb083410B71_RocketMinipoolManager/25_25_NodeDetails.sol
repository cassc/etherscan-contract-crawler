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

// SPDX-License-Identifier: GPL-3.0-only

// A struct containing all the information on-chain about a specific node

struct NodeDetails {
    bool exists;
    uint256 registrationTime;
    string timezoneLocation;
    bool feeDistributorInitialised;
    address feeDistributorAddress;
    uint256 rewardNetwork;
    uint256 rplStake;
    uint256 effectiveRPLStake;
    uint256 minimumRPLStake;
    uint256 maximumRPLStake;
    uint256 minipoolLimit;
    uint256 minipoolCount;
    uint256 balanceETH;
    uint256 balanceRETH;
    uint256 balanceRPL;
    uint256 balanceOldRPL;
    address withdrawalAddress;
    address pendingWithdrawalAddress;
    bool smoothingPoolRegistrationState;
    uint256 smoothingPoolRegistrationChanged;
}