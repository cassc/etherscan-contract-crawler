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

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./RocketNodeDistributorStorageLayout.sol";
import "../../interface/RocketStorageInterface.sol";
import "../../interface/node/RocketNodeManagerInterface.sol";
import "../../interface/node/RocketNodeDistributorInterface.sol";

contract RocketNodeDistributorDelegate is RocketNodeDistributorStorageLayout, RocketNodeDistributorInterface {
    // Import libraries
    using SafeMath for uint256;

    // Events
    event FeesDistributed(address _nodeAddress, uint256 _userAmount, uint256 _nodeAmount, uint256 _time);

    // Constants
    uint8 public constant version = 1;
    uint256 constant calcBase = 1 ether;

    // Precomputed constants
    bytes32 immutable rocketNodeManagerKey;
    bytes32 immutable rocketTokenRETHKey;

    constructor() {
        // Precompute storage keys
        rocketNodeManagerKey = keccak256(abi.encodePacked("contract.address", "rocketNodeManager"));
        rocketTokenRETHKey = keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"));
        // These values must be set by proxy contract as this contract should only be delegatecalled
        rocketStorage = RocketStorageInterface(address(0));
        nodeAddress = address(0);
    }

    function distribute() override external {
        // Get contracts
        RocketNodeManagerInterface rocketNodeManager = RocketNodeManagerInterface(rocketStorage.getAddress(rocketNodeManagerKey));
        address rocketTokenRETH = rocketStorage.getAddress(rocketTokenRETHKey);
        // Get withdrawal address and the node's average node fee
        address withdrawalAddress = rocketStorage.getNodeWithdrawalAddress(nodeAddress);
        uint256 averageNodeFee = rocketNodeManager.getAverageNodeFee(nodeAddress);
        // Calculate what portion of the balance is the node's
        uint256 halfBalance = address(this).balance.div(2);
        uint256 nodeShare = halfBalance.add(halfBalance.mul(averageNodeFee).div(calcBase));
        uint256 userShare = address(this).balance.sub(nodeShare);
        // Transfer user share
        payable(rocketTokenRETH).transfer(userShare);
        // Transfer node share
        (bool success,) = withdrawalAddress.call{value : address(this).balance}("");
        require(success);
        // Emit event
        emit FeesDistributed(nodeAddress, userShare, nodeShare, block.timestamp);
    }
}