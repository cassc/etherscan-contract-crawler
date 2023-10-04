// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../libraries/Types.sol";

interface IPlayer {
    function getVIPTier(address _account) external view returns (uint256);
    function getProfile(address _account) external view returns (Types.Player memory, uint256);
    function getLevel(address _account) external view returns (uint256);
    function getXp(address _account) external view returns (uint256);
}