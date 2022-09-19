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
    mapping(uint256 => uint256) public slotteryGameToRewardType; // 0 is custom | 1 is prize pool

    uint256 public prizePoolPercentageBase;
    bytes32 public AUTOMATED_AGENT_ROLE;

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
        uint40 startTime,
        uint256 prizeType
    ) external onlyRole(GameAdminRole) {
        SlotteryGame storage game = slotteryGames[id];
        require(game.id == 0, "Game ID already in use");
        require(prizeType < 2, "Incorrect prize type");

        game.id = id;
        game.deadline = deadline;
        game.rounds = rounds;
        game.spinNum = spinNum;
        game.entryPrice = entryPrice;
        game.startTime = startTime;

        if (prizeType != 0)
            slotteryGameToRewardType[game.id] = prizeType;

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
        
        if (slotteryGameToRewardType[id] == 1) {
            slotteryGameToPrizePool[game.id] += game.entryPrice;
            _collectWatts(game.entryPrice);
        } else {
            _burnWatts(game.entryPrice);
        }

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

    function TriggerAutomatedWattsRelease(uint256 gameId, address[] memory recipients, uint256[] memory percentages)
        external
        onlyRole(GameAdminRole)
        onlyRole(AUTOMATED_AGENT_ROLE) {
            uint256 prizePoolSize = slotteryGameToPrizePool[gameId];
            require(prizePoolSize > 0, "Game prize pool empty");
            require(recipients.length > 0, "No recipients specified");
            require(percentages.length > 0, "No percentages specified");

            uint256 totalReleased;
            for (uint i = 0; i < recipients.length; i++) {
                address recipient = recipients[i];
                uint256 percentage = percentages[i];
                uint256 toRelease = prizePoolSize * percentage / prizePoolPercentageBase;
                totalReleased += toRelease;
                _releaseWatts(recipient, toRelease);
            }
            require(totalReleased <= prizePoolSize, "Released amount exceeds prize pool size");
            slotteryGameToPrizePool[gameId] -= totalReleased;
        }

    function InitializeRole() external onlyRole(GameAdminRole) onlyRole(DEFAULT_ADMIN_ROLE) {
        AUTOMATED_AGENT_ROLE = keccak256("AUTOMATED_AGENT_ROLE");
        prizePoolPercentageBase = 100;
    }

    function getPrizePoolForGames(uint256[] memory gameIds) external view returns(uint256[] memory) {
        require(gameIds.length > 0);
        uint256[] memory pools = new uint256[](gameIds.length);
        for (uint i = 0; i < gameIds.length; i++) {
            pools[i] = slotteryGameToPrizePool[gameIds[i]];
        }
        return pools;
    }

    function editSlotteryGameType(uint256 slotteryId, uint256 gameType) 
        external 
        onlyRole(GameAdminRole) 
        onlyRole(DEFAULT_ADMIN_ROLE) {
        slotteryGameToRewardType[slotteryId] = gameType;
    }
}