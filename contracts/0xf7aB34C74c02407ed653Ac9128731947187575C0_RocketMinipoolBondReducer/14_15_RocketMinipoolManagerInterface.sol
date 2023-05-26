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
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/MinipoolDeposit.sol";
import "../../types/MinipoolDetails.sol";
import "./RocketMinipoolInterface.sol";

interface RocketMinipoolManagerInterface {
    function getMinipoolCount() external view returns (uint256);
    function getStakingMinipoolCount() external view returns (uint256);
    function getFinalisedMinipoolCount() external view returns (uint256);
    function getActiveMinipoolCount() external view returns (uint256);
    function getMinipoolRPLSlashed(address _minipoolAddress) external view returns (bool);
    function getMinipoolCountPerStatus(uint256 offset, uint256 limit) external view returns (uint256, uint256, uint256, uint256, uint256);
    function getPrelaunchMinipools(uint256 offset, uint256 limit) external view returns (address[] memory);
    function getMinipoolAt(uint256 _index) external view returns (address);
    function getNodeMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeActiveMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeFinalisedMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeStakingMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeStakingMinipoolCountBySize(address _nodeAddress, uint256 _depositSize) external view returns (uint256);
    function getNodeMinipoolAt(address _nodeAddress, uint256 _index) external view returns (address);
    function getNodeValidatingMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeValidatingMinipoolAt(address _nodeAddress, uint256 _index) external view returns (address);
    function getMinipoolByPubkey(bytes calldata _pubkey) external view returns (address);
    function getMinipoolExists(address _minipoolAddress) external view returns (bool);
    function getMinipoolDestroyed(address _minipoolAddress) external view returns (bool);
    function getMinipoolPubkey(address _minipoolAddress) external view returns (bytes memory);
    function updateNodeStakingMinipoolCount(uint256 _previousBond, uint256 _newBond, uint256 _previousFee, uint256 _newFee) external;
    function getMinipoolWithdrawalCredentials(address _minipoolAddress) external pure returns (bytes memory);
    function createMinipool(address _nodeAddress, uint256 _salt) external returns (RocketMinipoolInterface);
    function createVacantMinipool(address _nodeAddress, uint256 _salt, bytes calldata _validatorPubkey, uint256 _bondAmount, uint256 _currentBalance) external returns (RocketMinipoolInterface);
    function removeVacantMinipool() external;
    function getVacantMinipoolCount() external view returns (uint256);
    function getVacantMinipoolAt(uint256 _index) external view returns (address);
    function destroyMinipool() external;
    function incrementNodeStakingMinipoolCount(address _nodeAddress) external;
    function decrementNodeStakingMinipoolCount(address _nodeAddress) external;
    function incrementNodeFinalisedMinipoolCount(address _nodeAddress) external;
    function setMinipoolPubkey(bytes calldata _pubkey) external;
    function getMinipoolDepositType(address _minipoolAddress) external view returns (MinipoolDeposit);
}