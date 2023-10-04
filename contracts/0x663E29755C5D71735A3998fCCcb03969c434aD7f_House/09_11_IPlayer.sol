// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IPlayer {
    function getVIPTier(address _account) external view returns (uint256);
    function getLevel(address _account) external view returns (uint256);
    function giveXP(address _account, uint256 _xp) external;
    function setReferral(address _account, address _referral) external;
    function getReferral(address _account) external view returns (address);
}