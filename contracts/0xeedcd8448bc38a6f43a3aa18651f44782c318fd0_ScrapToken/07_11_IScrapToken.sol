// SPDX-License-Identifier: MIT
/*
  _____   _____ _____ ___   _   ___ ___ ____
 |   \ \ / / __|_   _/ _ \ /_\ | _ \ __|_  /
 | |) \ V /\__ \ | || (_) / _ \|  _/ _| / /
 |___/ |_| |___/ |_| \___/_/ \_\_| |___/___|

*/

pragma solidity ^0.8.7;

interface IScrapToken {

    function updateReward(address _from, address _to, uint256 _tokenId) external;

    function getClaimableReward(address _account) external view returns(uint256);

    function claimReward() external;
}