// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./lib/WattsBurnerUpgradable.sol";

contract Slottery is WattsBurnerUpgradable {
    struct SlotteryGame {
        uint40 id;
        uint40 deadline;
        uint16 rounds;
        uint16 spinNum;
        uint104 entryPrice;
        uint40 startTime;
    }

    mapping(uint256 => SlotteryGame) public slotteryGames;
    mapping(address => mapping(uint256 => bool)) public userToGameEntries;
    mapping(uint256 => uint256) public slotteryGameToPrizePool;

    event GameCreated(uint256 indexed id, uint256 deadline, uint256 rounds, uint256 spinNum, uint256 entryPrice, uint256 startTime);
    event GameModified(uint256 indexed id, uint256 deadline, uint256 rounds, uint256 spinNum, uint256 entryPrice, uint256 startTime);
    event GameEntered(uint256 indexed gameId, address indexed user);

    constructor(address[] memory _admins, address _watts, address _transferExtender)
    WattsBurnerUpgradable(_admins, _watts, _transferExtender) {}

    function initialize(address[] memory _admins, address _watts, address _transferExtender) public initializer {
        watts_burner_initialize(_admins, _watts, _transferExtender);
    }

    function CreateGame(
        uint40 id,
        uint40 deadline,
        uint16 rounds,
        uint16 spinNum,
        uint104 entryPrice,
        uint40 startTime
    ) external onlyRole(GameAdminRole) {
        SlotteryGame storage game = slotteryGames[id];
        require(game.id == 0, "Game ID already in use");

        game.id = id;
        game.deadline = deadline;
        game.rounds = rounds;
        game.spinNum = spinNum;
        game.entryPrice = entryPrice;
        game.startTime = startTime;

        emit GameCreated(id, deadline, rounds, spinNum, entryPrice, startTime);
    }

    function ModifyGame(
        uint40 id,
        uint40 deadline,
        uint16 rounds,
        uint16 spinNum,
        uint104 entryPrice,
        uint40 startTime
    ) external onlyRole(GameAdminRole) {
        SlotteryGame storage game = slotteryGames[id];
        require(game.id != 0, "Cannot modify a non initialized game");
        require(block.timestamp < game.startTime, "Cannot modify a started game");

        game.deadline = deadline;

        game.rounds = rounds;
        game.spinNum = spinNum;
        game.entryPrice = entryPrice;
        game.startTime = startTime;

        emit GameModified(id, deadline, rounds, spinNum, entryPrice, startTime);
    }

    function EnterGame(uint256 id) external {
        SlotteryGame memory game = slotteryGames[id];
        require(game.id != 0, "Cannot enter a non initialized game");
        require(block.timestamp < game.deadline, "Cannot enter a finished game");
        require(!userToGameEntries[msg.sender][game.id], "User already enter game");
        
        slotteryGameToPrizePool[game.id] += game.entryPrice;
        _collectWatts(game.entryPrice);

        userToGameEntries[msg.sender][game.id] = true;

        emit GameEntered(id, msg.sender);
    }

    function ReleasePrizePoolToWinner(uint256 gameId, address winner, uint256 amountFromPrizePool) external onlyRole(GameAdminRole) {
        require(slotteryGameToPrizePool[gameId] >= amountFromPrizePool, "Game prize pool insufficient");
        slotteryGameToPrizePool[gameId] -= amountFromPrizePool;
        _releaseWatts(winner, amountFromPrizePool);
    }

    function BurnRemainingWattsInPrizePool(uint256 gameId) external onlyRole(GameAdminRole) {
        uint256 burnAmount = slotteryGameToPrizePool[gameId];
        delete slotteryGameToPrizePool[gameId];
        _burnContractWatts(burnAmount);
    }

    function getPrizePoolForGames(uint256[] memory gameIds) external view returns(uint256[] memory) {
        require(gameIds.length > 0);
        uint256[] memory pools = new uint256[](gameIds.length);
        for (uint i = 0; i < gameIds.length; i++) {
            pools[i] = slotteryGameToPrizePool[gameIds[i]];
        }
        return pools;
    }
}