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

interface RocketDAONodeTrustedSettingsMembersInterface {
    function getQuorum() external view returns (uint256);
    function getRPLBond() external view returns(uint256);
    function getMinipoolUnbondedMax() external view returns(uint256);
    function getMinipoolUnbondedMinFee() external view returns(uint256);
    function getChallengeCooldown() external view returns(uint256);
    function getChallengeWindow() external view returns(uint256);
    function getChallengeCost() external view returns(uint256);
}