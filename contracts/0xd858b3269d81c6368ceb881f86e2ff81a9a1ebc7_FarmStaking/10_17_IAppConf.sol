// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../Model.sol";

interface IAppConf {
    function getBurnAddr() external view returns(address);
    function getCoolAddr() external view returns(address);
    function validBlacklist(address addr) external view returns(bool);
    function validWhitelist(address addr) external view returns(bool);
    function getRewardNftToken() external view returns(address);
    function getRewardNftTokenGen() external view returns(uint8);
    function getRewardPeriod(uint8 gen) external view returns(uint256);
    function getRewardAmount(uint8 gen) external view returns(uint256);
    function getRewardType() external view returns(uint8);
    function validStakingNftToken(address nftToken) external view returns(bool);
    function getNftFactoryAddr() external view returns(address);
    function getFarmAddr() external view returns(Model.FarmAddr memory);
    function getNftTokenType(address nftToken) external view returns(uint8);
    function getNftTypeToken(uint8 nftType) external view returns(address);
    function validFarm(address farmAddr) external returns (bool);
    function getEnabledProxyClaim() external view returns(bool);
}