// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFarmBooster {
    function getUserMultiplier(uint256 _tokenId) external view returns (uint256);

    function whiteList(uint256 _pid) external view returns (bool);

    function updatePositionBoostMultiplier(uint256 _tokenId) external returns (uint256 _multiplier);

    function removeBoostMultiplier(address _user, uint256 _tokenId, uint256 _pid) external;
}