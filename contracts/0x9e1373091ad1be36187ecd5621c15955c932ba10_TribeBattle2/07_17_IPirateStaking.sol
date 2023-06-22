// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPirateStaking {
    function getAddressesByTribe(uint8 tribe) external view returns (address[] memory);
    function getCountPerTribe(uint8 tribe) external view returns (uint256);
    function getTribeCountForPlayer(address player, uint8 tribe) external view returns (uint256);
    function getStakedPiratesForPlayer(address player) external view returns (uint256[] memory);
}