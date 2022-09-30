//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IGameplayCoordinator {
    function isBotBusy(uint256 id) external returns(bool);
    function makeBotBusy(uint256 botId) external;
    function makeBotUnbusy(uint256 botId) external;
    function isBotInGame(uint256 botId) external returns(bool);
}