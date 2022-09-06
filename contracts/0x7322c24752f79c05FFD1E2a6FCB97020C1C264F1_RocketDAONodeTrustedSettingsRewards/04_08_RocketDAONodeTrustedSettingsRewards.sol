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

import "./RocketDAONodeTrustedSettings.sol";
import "../../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsRewardsInterface.sol";
import "../../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsRewardsInterface.sol";


// The Trusted Node DAO Rewards settings

contract RocketDAONodeTrustedSettingsRewards is RocketDAONodeTrustedSettings, RocketDAONodeTrustedSettingsRewardsInterface {

    using SafeMath for uint;

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAONodeTrustedSettings(_rocketStorageAddress, "rewards") {
        // Set version
        version = 2;
    }

    // Initialise
    function initialise() public override onlyLatestContract("rocketUpgradeOneDotOne", msg.sender) {
        // Initialise settings on deployment
        require(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed"))), "Already initialised");
        // Enable main net rewards
        setBool(keccak256(abi.encodePacked(settingNameSpace, "rewards.network.enabled", uint256(0))), true);
        // Settings initialised
        setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
    }

    // Update a setting, overrides inherited setting method with extra checks for this contract
    function setSettingBool(string memory _settingPath, bool _value) override public onlyDAONodeTrustedProposal {
        // Some safety guards for certain settings
        if(getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // oDAO should never disable main net rewards
            if(keccak256(abi.encodePacked(_settingPath)) == keccak256(abi.encodePacked("rewards.network.enabled", uint256(0)))) {
                revert("Cannot disable network 0");
            }
        }
        // Update setting now
        setBool(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    }


    // Getters

    function getNetworkEnabled(uint256 _network) override external view returns (bool) {
        return getBool(keccak256(abi.encodePacked(settingNameSpace, "rewards.network.enabled", _network)));
    }
}