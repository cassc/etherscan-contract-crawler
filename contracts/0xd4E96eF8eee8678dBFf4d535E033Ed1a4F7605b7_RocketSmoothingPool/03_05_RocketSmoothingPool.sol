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

import "../RocketBase.sol";
import "../../interface/rewards/RocketSmoothingPoolInterface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/*
Receives priority fees and MEV via fee_recipient

NOTE: This contract intentionally does not use RocketVault to store ETH because there is no way to account for ETH being
added to this contract via fee_recipient. This also means if this contract is upgraded, the ETH must be manually
transferred from this contract to the upgraded one.
*/

contract RocketSmoothingPool is RocketBase, RocketSmoothingPoolInterface {

    // Libs
    using SafeMath for uint256;

    // Events
    event EtherWithdrawn(string indexed by, address indexed to, uint256 amount, uint256 time);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
    }

    // Allow receiving ETH
    receive() payable external {}

    // Withdraws ETH to given address
    // Only accepts calls from Rocket Pool network contracts
    function withdrawEther(address _to, uint256 _amount) override external onlyLatestNetworkContract {
        // Valid amount?
        require(_amount > 0, "No valid amount of ETH given to withdraw");
        // Get contract name
        string memory contractName = getContractName(msg.sender);
        // Send the ETH
        (bool result,) = _to.call{value: _amount}("");
        require(result, "Failed to withdraw ETH");
        // Emit ether withdrawn event
        emit EtherWithdrawn(contractName, _to, _amount, block.timestamp);
    }
}