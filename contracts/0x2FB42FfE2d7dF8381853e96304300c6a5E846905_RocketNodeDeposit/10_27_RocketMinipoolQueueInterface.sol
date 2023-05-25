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

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/MinipoolDeposit.sol";

interface RocketMinipoolQueueInterface {
    function getTotalLength() external view returns (uint256);
    function getContainsLegacy() external view returns (bool);
    function getLengthLegacy(MinipoolDeposit _depositType) external view returns (uint256);
    function getLength() external view returns (uint256);
    function getTotalCapacity() external view returns (uint256);
    function getEffectiveCapacity() external view returns (uint256);
    function getNextCapacityLegacy() external view returns (uint256);
    function getNextDepositLegacy() external view returns (MinipoolDeposit, uint256);
    function enqueueMinipool(address _minipool) external;
    function dequeueMinipoolByDepositLegacy(MinipoolDeposit _depositType) external returns (address minipoolAddress);
    function dequeueMinipools(uint256 _maxToDequeue) external returns (address[] memory minipoolAddress);
    function removeMinipool(MinipoolDeposit _depositType) external;
    function getMinipoolAt(uint256 _index) external view returns(address);
    function getMinipoolPosition(address _minipool) external view returns (int256);
}