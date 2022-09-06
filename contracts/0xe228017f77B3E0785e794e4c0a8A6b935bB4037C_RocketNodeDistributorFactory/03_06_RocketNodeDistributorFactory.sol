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

import "../RocketBase.sol";
import "./RocketNodeDistributor.sol";
import "./RocketNodeDistributorStorageLayout.sol";
import "../../interface/node/RocketNodeDistributorFactoryInterface.sol";

contract RocketNodeDistributorFactory is RocketBase, RocketNodeDistributorFactoryInterface {
    // Events
    event ProxyCreated(address _address);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    function getProxyBytecode() override public pure returns (bytes memory) {
        return type(RocketNodeDistributor).creationCode;
    }

    // Calculates the predetermined distributor contract address from given node address
    function getProxyAddress(address _nodeAddress) override external view returns(address) {
        bytes memory contractCode = getProxyBytecode();
        bytes memory initCode = abi.encodePacked(contractCode, abi.encode(_nodeAddress, rocketStorage));

        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), uint256(0), keccak256(initCode)));

        return address(uint160(uint(hash)));
    }

    // Uses CREATE2 to deploy a RocketNodeDistributor at predetermined address
    function createProxy(address _nodeAddress) override external onlyLatestContract("rocketNodeManager", msg.sender) {
        // Salt is not required as the initCode is already unique per node address (node address is constructor argument)
        RocketNodeDistributor dist = new RocketNodeDistributor{salt: ''}(_nodeAddress, address(rocketStorage));
        emit ProxyCreated(address(dist));
    }
}