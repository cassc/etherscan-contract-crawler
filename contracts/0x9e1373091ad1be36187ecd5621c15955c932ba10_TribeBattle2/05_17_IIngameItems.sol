// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIngameItems {
    function getGemWinsInMonsterBattle(uint256 battleId, address winner) external;
    function getTotemWinsInMonsterBattle(uint256 battleId, address winner) external;
    function getGhostWinsInMonsterBattle(uint256 battleId, address winner) external;
    function addGemToPlayer(uint256 battleId, address _address) external;
    function removeGemFromPlayer(address _address) external;
    function moveGem(address fromAddress, address toAddress) external;
    function adminAddGemToPlayerForBattle(uint256 battleId, address _address) external;
    function adminAddGemToPlayer(address _address) external;
    function viewGemCountForPlayer(address owner) view external returns (uint256);
    function addTotemToPlayer(uint256 battleId, address _address) external;
    function removeTotemFromPlayer(address _address) external;
    function moveTotem(address fromAddress, address toAddress) external;
    function adminAddTotemToPlayerForBattle(uint256 battleId, address _address) external;
    function adminAddTotemToPlayer(address _address) external;
    function viewTotemCountForPlayer(address owner)view external returns (uint256);
    function addGhostToPlayer(uint256 battleId, address _address) external;
    function removeGhostFromPlayer(address _address) external;
    function moveGhost(address fromAddress, address toAddress) external;
    function adminAddGhostToPlayerForBattle(uint256 battleId, address _address) external;
    function adminAddGhostToPlayer(address _address) external;
    function viewGhostCountForPlayer(address owner) view external returns (uint256);
    function viewAllCountsForPlayer(address owner) view external returns (uint256[] memory);
    function viewAllWinsForPlayerInBattle(uint256 battleId, address owner) view external returns (uint256[] memory);
}