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

import "../../types/NodeDetails.sol";

interface RocketNodeManagerInterface {

    // Structs
    struct TimezoneCount {
        string timezone;
        uint256 count;
    }

    function getNodeCount() external view returns (uint256);
    function getNodeCountPerTimezone(uint256 offset, uint256 limit) external view returns (TimezoneCount[] memory);
    function getNodeAt(uint256 _index) external view returns (address);
    function getNodeExists(address _nodeAddress) external view returns (bool);
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodeTimezoneLocation(address _nodeAddress) external view returns (string memory);
    function registerNode(string calldata _timezoneLocation) external;
    function getNodeRegistrationTime(address _nodeAddress) external view returns (uint256);
    function setTimezoneLocation(string calldata _timezoneLocation) external;
    function setRewardNetwork(address _nodeAddress, uint256 network) external;
    function getRewardNetwork(address _nodeAddress) external view returns (uint256);
    function getFeeDistributorInitialised(address _nodeAddress) external view returns (bool);
    function initialiseFeeDistributor() external;
    function getAverageNodeFee(address _nodeAddress) external view returns (uint256);
    function setSmoothingPoolRegistrationState(bool _state) external;
    function getSmoothingPoolRegistrationState(address _nodeAddress) external returns (bool);
    function getSmoothingPoolRegistrationChanged(address _nodeAddress) external returns (uint256);
    function getSmoothingPoolRegisteredNodeCount(uint256 _offset, uint256 _limit) external view returns (uint256);
    function getNodeDetails(address _nodeAddress) external view returns (NodeDetails memory);
    function getNodeAddresses(uint256 _offset, uint256 _limit) external view returns (address[] memory);
}