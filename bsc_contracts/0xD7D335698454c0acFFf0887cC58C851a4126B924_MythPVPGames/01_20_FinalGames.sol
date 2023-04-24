// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "ERC20.sol";
import "MythToken.sol";

contract MythPVPGames {
    address payable public owner;
    address payable public myth;
    address public bobAddress;

    uint256 public mythFee = 980;
    uint256 public totalWagered;
    uint256 public totalClaimed;
    uint256 public gameCount;

    mapping(uint256 => uint256) public gameIdToLobbyId;
    mapping(uint256 => Lobby) public Lobbys;
    mapping(uint256 => mapping(uint256 => uint256))
        public lootboxLobbyToLootboxId;

    mapping(uint256 => mapping(uint256 => uint256)) public blockCountToLobbyId;

    mapping(uint256 => uint256) public blockNumberCount;
    mapping(address => uint256) public unclaimedRewardsOfUser;
    mapping(uint256 => bool) public lootboxLobbyInUse;
    mapping(uint256 => bool) public resolvedBlocks;
    mapping(uint256 => CaseData) public caseDataFromId;
    mapping(uint256 => mapping(uint256 => PrizeData))
        public prizeFromCaseIdAndPosition;

    mapping(address => bool) public isResolver;
    struct Lobby {
        uint256 gameCount;
        uint256 gameType;
        uint256 gameConfig;
        uint256 cost;
        uint256 lootboxCount;
        uint256 lootboxLobbyId;
        uint256 lobbyState; // 0 for open, 1 for placed , 2 for resolving.. after resolve puts back to 0
        address gameStarter;
        address gameCaller1;
        address gameCaller2;
        address gameCaller3;
    }
    struct PrizeData {
        uint256 lowTicket;
        uint256 highTicket;
        uint256 prizeAmount;
    }
    struct CaseData {
        uint256 prizeCount;
        uint256 caseCost;
    }

    event mythClaimed(address user, uint256 amount);

    event gameResolved(
        uint256 gameCount,
        uint256 totalwinnings,
        uint256 blockNumber,
        address winner1,
        address winner2,
        bytes32 seed
    );

    event roundResolved(
        uint256 gameCount,
        uint256 roundNumber,
        uint256 rolled1,
        uint256 rolled2,
        uint256 rolled3,
        uint256 rolled4
    );
    event gameStarted(
        address user,
        uint256 lobbyId,
        uint256 gameCount,
        uint256 gameType,
        uint256 gameConfig,
        uint256 cost,
        uint256[] lootboxIds
    );
    event winningsAdded(address winner, uint256 amount);

    event lobbyJoined(uint256 lobbyId, address joiner, uint256 position);

    event gameCalled(
        uint256 gameCount,
        uint256 blockNumber,
        address caller1,
        address caller2,
        address caller3
    );

    constructor(address _myth, address _bob) {
        owner = payable(msg.sender);
        myth = payable(_myth);
        bobAddress = _bob;
    }

    function findNextAvailable() public view returns (uint256) {
        uint256 counter = 1;
        while (true) {
            Lobby memory tempLobby = Lobbys[counter];
            if (tempLobby.lobbyState == 0) {
                return counter;
            }
            counter++;
        }
    }

    function alterCaseData(
        uint256 _caseId,
        uint256 _caseCost,
        uint256[] calldata _lowTickets,
        uint256[] calldata _highTickets,
        uint256[] calldata _prizeAmounts
    ) external {
        require(msg.sender == owner, "only owner");
        require(
            _lowTickets.length == _highTickets.length &&
                _highTickets.length == _prizeAmounts.length,
            "Lists are not equal lengths"
        );
        for (uint256 i = 0; i < _lowTickets.length; i++) {
            prizeFromCaseIdAndPosition[_caseId][i] = PrizeData(
                _lowTickets[i],
                _highTickets[i],
                _prizeAmounts[i]
            );
        }
        caseDataFromId[_caseId] = CaseData(_lowTickets.length, _caseCost);
    }

    function findNextAvailableLootBoxLobby() internal returns (uint256) {
        uint256 counter = 1;
        while (true) {
            bool tempLobby = lootboxLobbyInUse[counter];
            if (tempLobby == false) {
                lootboxLobbyInUse[counter] = true;
                return counter;
            }
            counter++;
        }
    }

    function changeResolver(address _address, bool _bool) external {
        require(msg.sender == owner, "only owner");
        isResolver[_address] = _bool;
    }

    function changeFee(uint256 amount) external {
        require(msg.sender == owner, "only owner");
        mythFee = amount;
    }

    function changeBobAddress(address _address) external {
        require(msg.sender == owner, "only owner");
        bobAddress = _address;
    }

    function getPrizeFromTicket(
        uint256 _caseId,
        uint256 _ticket
    ) public view returns (uint256) {
        uint256 prizeCountTemp = caseDataFromId[_caseId].prizeCount;
        for (uint256 i = 0; i < prizeCountTemp; i++) {
            PrizeData memory tempPrize = prizeFromCaseIdAndPosition[_caseId][i];
            if (
                tempPrize.lowTicket <= _ticket &&
                tempPrize.highTicket >= _ticket
            ) {
                return tempPrize.prizeAmount;
            }
        }
        return 0;
    }

    function resolveBlock(uint256 blockNumber, bytes32 seed) external {
        require(
            isResolver[msg.sender],
            "Only valid resolvers can resolve blocks"
        );
        require(block.number > blockNumber, "Block number not reached yet");
        require(
            blockNumberCount[blockNumber] > 0,
            "Nothing to resolve in this block"
        );
        require(resolvedBlocks[blockNumber] == false, "Block Already resolved");
        resolvedBlocks[blockNumber] = true;
        for (uint256 i = 0; i < blockNumberCount[blockNumber]; i++) {
            uint256 currentLobbyId = blockCountToLobbyId[blockNumber][i];
            Lobby memory tempLobby = Lobbys[currentLobbyId];
            require(tempLobby.lobbyState == 2, "Lobby not in 2 state");
            delete Lobbys[currentLobbyId].lobbyState;
            if (tempLobby.gameType == 0) {
                resolveCoinFlip(currentLobbyId, blockNumber, seed);
            } else if (tempLobby.gameType == 1) {
                resolveDice(currentLobbyId, blockNumber, seed);
            } else if (tempLobby.gameType == 2) {
                resolveDeath(currentLobbyId, blockNumber, seed);
            } else if (tempLobby.gameType == 3) {
                resolveLootBox(currentLobbyId, blockNumber, seed);
            }
        }
    }

    function withdrawWinnings() external {
        uint256 userRewards = unclaimedRewardsOfUser[msg.sender];
        require(userRewards > 0, "No rewards to claim");
        unclaimedRewardsOfUser[msg.sender] = 0;
        uint256 rewardPerCent = ((userRewards - (userRewards % 100000)) / 1000);
        mintTokens(msg.sender, rewardPerCent * mythFee);
        totalClaimed += rewardPerCent * mythFee;
        emit mythClaimed(msg.sender, rewardPerCent * mythFee);
    }

    function getWinningsFromSoloOpening(
        bytes32 resolutionSeed,
        uint256 lobbyId
    ) internal returns (uint256) {
        Lobby memory tempLobby = Lobbys[lobbyId];
        uint256 tempTotal;
        for (uint256 i = 0; i < tempLobby.lootboxCount; i++) {
            uint256 caseId = lootboxLobbyToLootboxId[tempLobby.lootboxLobbyId][
                i
            ];
            uint256 rolledTicket = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, i))
            ) % 100000;

            emit roundResolved(tempLobby.gameCount, i, rolledTicket, 0, 0, 0);
            tempTotal += getPrizeFromTicket(caseId, rolledTicket);
        }
        return tempTotal;
    }

    function tieBreaker(
        bytes32 resolutionSeed,
        uint256 gameId
    ) public view returns (bool) {
        return
            uint256(keccak256(abi.encodePacked(resolutionSeed, gameId))) % 2 ==
            0;
    }

    function getWinningsFrom1v1(
        bytes32 resolutionSeed,
        uint256 lobbyId
    ) internal returns (uint256, address) {
        Lobby memory tempLobby = Lobbys[lobbyId];
        uint256 tempTotal1;
        uint256 tempTotal2;
        for (uint256 i = 0; i < tempLobby.lootboxCount; i++) {
            uint256 caseId = lootboxLobbyToLootboxId[tempLobby.lootboxLobbyId][
                i
            ];
            uint256 rolledTicket = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, i))
            ) % 100000;
            uint256 rolledTicket2 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 100 - i))
            ) % 100000;

            emit roundResolved(
                tempLobby.gameCount,
                i,
                rolledTicket,
                rolledTicket2,
                0,
                0
            );
            tempTotal1 += getPrizeFromTicket(caseId, rolledTicket);
            tempTotal2 += getPrizeFromTicket(caseId, rolledTicket2);
        }
        bool creatorWinner;
        if (tempTotal1 == tempTotal2) {
            creatorWinner = tieBreaker(resolutionSeed, tempLobby.gameCount);
        } else {
            creatorWinner = tempTotal1 > tempTotal2;
        }
        if (creatorWinner) {
            return (tempTotal1 + tempTotal2, tempLobby.gameStarter);
        } else {
            return (tempTotal1 + tempTotal2, tempLobby.gameCaller1);
        }
    }

    function getWinningsFrom1v1v1(
        bytes32 resolutionSeed,
        uint256 lobbyId
    ) internal returns (uint256, address) {
        Lobby memory tempGame = Lobbys[lobbyId];
        uint256 tempTotal1;
        uint256 tempTotal2;
        uint256 tempTotal3;
        for (uint256 i = 0; i < tempGame.lootboxCount; i++) {
            uint256 caseId = lootboxLobbyToLootboxId[tempGame.lootboxLobbyId][
                i
            ];
            uint256 rolledTicket = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, i))
            ) % 100000;
            uint256 rolledTicket2 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 100 - i))
            ) % 100000;
            uint256 rolledTicket3 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 200 - i))
            ) % 100000;

            emit roundResolved(
                tempGame.gameCount,
                i,
                rolledTicket,
                rolledTicket2,
                rolledTicket3,
                0
            );
            tempTotal1 += getPrizeFromTicket(caseId, rolledTicket);
            tempTotal2 += getPrizeFromTicket(caseId, rolledTicket2);
            tempTotal3 += getPrizeFromTicket(caseId, rolledTicket3);
        }
        uint256 tempWinnings = tempTotal1 + tempTotal2 + tempTotal3;
        if (tempTotal1 == tempTotal2 && tempTotal1 == tempTotal3) {
            uint256 tieBreak = uint256(
                keccak256(abi.encodePacked(resolutionSeed, tempGame.gameCount))
            ) % 3;
            if (tieBreak == 0) {
                return (tempWinnings, tempGame.gameStarter);
            } else if (tieBreak == 1) {
                return (tempWinnings, tempGame.gameCaller1);
            } else if (tieBreak == 2) {
                return (tempWinnings, tempGame.gameCaller2);
            }
        } else if (tempTotal1 > tempTotal2 && tempTotal1 > tempTotal3) {
            return (tempWinnings, tempGame.gameStarter);
        } else if (tempTotal2 > tempTotal1 && tempTotal2 > tempTotal3) {
            return (tempWinnings, tempGame.gameCaller1);
        } else if (tempTotal3 > tempTotal1 && tempTotal3 > tempTotal2) {
            return (tempWinnings, tempGame.gameCaller2);
        } else {
            if (tempTotal1 == tempTotal2) {
                if (tieBreaker(resolutionSeed, tempGame.gameCount)) {
                    return (tempWinnings, tempGame.gameStarter);
                } else {
                    return (tempWinnings, tempGame.gameCaller1);
                }
            } else if (tempTotal3 == tempTotal2) {
                if (tieBreaker(resolutionSeed, tempGame.gameCount)) {
                    return (tempWinnings, tempGame.gameCaller1);
                } else {
                    return (tempWinnings, tempGame.gameCaller2);
                }
            } else {
                if (tieBreaker(resolutionSeed, tempGame.gameCount)) {
                    return (tempWinnings, tempGame.gameStarter);
                } else {
                    return (tempWinnings, tempGame.gameCaller2);
                }
            }
        }
    }

    function getWinningsFrom2v2(
        bytes32 resolutionSeed,
        uint256 lobbyId
    ) internal returns (uint256, address, address) {
        Lobby memory tempGame = Lobbys[lobbyId];
        uint256 tempTotal1;
        uint256 tempTotal2;
        for (uint256 i = 0; i < tempGame.lootboxCount; i++) {
            uint256 caseId = lootboxLobbyToLootboxId[tempGame.lootboxLobbyId][
                i
            ];
            uint256 rolledTicket = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, i))
            ) % 100000;
            uint256 rolledTicket2 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 100 - i))
            ) % 100000;
            uint256 rolledTicket3 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 200 - i))
            ) % 100000;
            uint256 rolledTicket4 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 300 - i))
            ) % 100000;

            emit roundResolved(
                tempGame.gameCount,
                i,
                rolledTicket,
                rolledTicket2,
                rolledTicket3,
                rolledTicket4
            );
            tempTotal1 += getPrizeFromTicket(caseId, rolledTicket);
            tempTotal1 += getPrizeFromTicket(caseId, rolledTicket2);
            tempTotal2 += getPrizeFromTicket(caseId, rolledTicket3);
            tempTotal2 += getPrizeFromTicket(caseId, rolledTicket4);
        }
        bool creatorWinner;
        if (tempTotal1 == tempTotal2) {
            creatorWinner = tieBreaker(resolutionSeed, tempGame.gameCount);
        } else {
            creatorWinner = tempTotal1 > tempTotal2;
        }
        uint256 tempWinnings = (tempTotal1 + tempTotal2) / 2;
        if (creatorWinner) {
            return (tempWinnings, tempGame.gameStarter, tempGame.gameCaller1);
        } else {
            return (tempWinnings, tempGame.gameCaller2, tempGame.gameCaller3);
        }
    }

    function resolveLootBox(
        uint256 lobbyId,
        uint256 blocknumber,
        bytes32 seed
    ) internal returns (bool) {
        Lobby memory tempLobby = Lobbys[lobbyId];
        lootboxLobbyInUse[tempLobby.lootboxLobbyId] = false;
        uint256 tempWinnings;
        address tempWinner;
        address tempWinner2;
        if (tempLobby.gameConfig == 0) {
            uint256 soloWinnings = getWinningsFromSoloOpening(seed, lobbyId);
            payoutWinner(soloWinnings, tempLobby.gameStarter);
            emit gameResolved(
                tempLobby.gameCount,
                soloWinnings,
                blocknumber,
                tempLobby.gameStarter,
                0x0000000000000000000000000000000000000000,
                seed
            );
        } else if (tempLobby.gameConfig == 1) {
            (tempWinnings, tempWinner) = getWinningsFrom1v1(seed, lobbyId);
            payoutWinner(tempWinnings, tempWinner);
            emit gameResolved(
                tempLobby.gameCount,
                tempWinnings,
                blocknumber,
                tempWinner,
                0x0000000000000000000000000000000000000000,
                seed
            );
        } else if (tempLobby.gameConfig == 2) {
            (tempWinnings, tempWinner) = getWinningsFrom1v1v1(seed, lobbyId);
            payoutWinner(tempWinnings, tempWinner);
            emit gameResolved(
                tempLobby.gameCount,
                tempWinnings,
                blocknumber,
                tempWinner,
                0x0000000000000000000000000000000000000000,
                seed
            );
        } else {
            (tempWinnings, tempWinner, tempWinner2) = getWinningsFrom2v2(
                seed,
                lobbyId
            );
            payoutWinner(tempWinnings, tempWinner);
            payoutWinner(tempWinnings, tempWinner2);
            emit gameResolved(
                tempLobby.gameCount,
                tempWinnings,
                blocknumber,
                tempWinner,
                tempWinner2,
                seed
            );
        }
    }

    function resolveDeathRoll(
        bytes32 _resolutionSeed,
        uint256 nonce
    ) internal view returns (bool) {
        uint256 localNonce = 0;
        uint256 currentNumber = 1000;
        while (true) {
            uint256 roll = uint256(
                keccak256(abi.encodePacked(_resolutionSeed, nonce, localNonce))
            ) % currentNumber;
            localNonce++;
            if (roll == 0) {
                break;
            } else {
                currentNumber = roll;
            }
        }
        return localNonce % 2 == 0;
    }

    function resolveDiceDuel(
        bytes32 _resolutionSeed,
        uint256 nonce
    ) internal view returns (bool) {
        uint8 counter = 0;
        while (true) {
            uint256 roll1 = uint256(
                keccak256(abi.encodePacked(_resolutionSeed, nonce, counter + 1))
            ) % 6;
            uint256 roll2 = uint256(
                keccak256(abi.encodePacked(_resolutionSeed, nonce, counter + 2))
            ) % 6;
            uint256 roll3 = uint256(
                keccak256(abi.encodePacked(_resolutionSeed, nonce, counter + 3))
            ) % 6;
            uint256 roll4 = uint256(
                keccak256(abi.encodePacked(_resolutionSeed, nonce, counter + 4))
            ) % 6;
            if (roll1 + roll2 == roll3 + roll4) {
                counter += 4;
            } else {
                return (roll1 + roll2 > roll3 + roll4);
            }
        }
    }

    function resolveDice(
        uint256 lobbyId,
        uint256 blocknumber,
        bytes32 seed
    ) internal {
        Lobby memory tempLobby = Lobbys[lobbyId];
        bool creatorWinner = resolveDiceDuel(seed, lobbyId);
        if (creatorWinner) {
            payoutWinner(tempLobby.cost * 2, tempLobby.gameStarter);
            emit gameResolved(
                tempLobby.gameCount,
                tempLobby.cost * 2,
                blocknumber,
                tempLobby.gameStarter,
                0x0000000000000000000000000000000000000000,
                seed
            );
        } else {
            payoutWinner(tempLobby.cost * 2, tempLobby.gameCaller1);
            emit gameResolved(
                tempLobby.gameCount,
                tempLobby.cost * 2,
                blocknumber,
                tempLobby.gameCaller1,
                0x0000000000000000000000000000000000000000,
                seed
            );
        }
    }

    function resolveDeath(
        uint256 lobbyId,
        uint256 blocknumber,
        bytes32 seed
    ) internal {
        Lobby memory tempLobby = Lobbys[lobbyId];
        bool creatorWinner = resolveDeathRoll(seed, lobbyId);
        if (creatorWinner) {
            payoutWinner(tempLobby.cost * 2, tempLobby.gameStarter);
            emit gameResolved(
                tempLobby.gameCount,
                tempLobby.cost * 2,
                blocknumber,
                tempLobby.gameStarter,
                0x0000000000000000000000000000000000000000,
                seed
            );
        } else {
            payoutWinner(tempLobby.cost * 2, tempLobby.gameCaller1);
            emit gameResolved(
                tempLobby.gameCount,
                tempLobby.cost * 2,
                blocknumber,
                tempLobby.gameCaller1,
                0x0000000000000000000000000000000000000000,
                seed
            );
        }
    }

    function resolveCoinFlip(
        uint256 lobbyId,
        uint256 blocknumber,
        bytes32 seed
    ) internal {
        Lobby memory tempLobby = Lobbys[lobbyId];
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(seed, lobbyId))
        ) % 2;
        bool creatorWinner = tempLobby.gameConfig == randomNumber;
        if (creatorWinner) {
            payoutWinner(tempLobby.cost * 2, tempLobby.gameStarter);
            emit gameResolved(
                tempLobby.gameCount,
                tempLobby.cost * 2,
                blocknumber,
                tempLobby.gameStarter,
                0x0000000000000000000000000000000000000000,
                seed
            );
        } else {
            payoutWinner(tempLobby.cost * 2, tempLobby.gameCaller1);
            emit gameResolved(
                tempLobby.gameCount,
                tempLobby.cost * 2,
                blocknumber,
                tempLobby.gameCaller1,
                0x0000000000000000000000000000000000000000,
                seed
            );
        }
    }

    function payoutWinner(uint256 _amount, address _winner) internal {
        if (_winner != bobAddress) {
            unclaimedRewardsOfUser[_winner] += _amount;
        }
        emit winningsAdded(_winner, _amount);
    }

    function getCostOfLootboxes(
        uint256[] calldata _lootboxIds
    ) public view returns (uint256) {
        uint256 tempTotal;
        for (uint256 i = 0; i < _lootboxIds.length; i++) {
            uint256 tempCost = caseDataFromId[_lootboxIds[i]].caseCost;
            require(tempCost > 0, "case has no cost");
            tempTotal += tempCost;
        }
        return tempTotal;
    }

    function burnTokens(address user, uint256 amount) internal {
        MythToken mythContract = MythToken(myth);
        mythContract.burnTokens(amount, user);
    }

    function mintTokens(address user, uint256 amount) internal {
        MythToken mythContract = MythToken(myth);
        mythContract.mintTokens(amount, user);
    }

    function callLobby(uint256 gameId, uint256 position) external {
        uint256 lobbyId = gameIdToLobbyId[gameId];
        Lobby memory tempLobby = Lobbys[lobbyId];
        require(position >= 1 && position <= 3, "Please choose valid position");
        require(tempLobby.lobbyState == 1, "Can only call for placed lobbys");
        burnTokens(msg.sender, tempLobby.cost);
        totalWagered += tempLobby.cost;
        if (tempLobby.gameType != 3) {
            Lobbys[lobbyId].gameCaller1 = msg.sender;
            Lobbys[lobbyId].lobbyState = 2;
            updateBlock(lobbyId);
            emit gameCalled(
                gameId,
                block.number,
                msg.sender,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000
            );
        } else {
            if (tempLobby.gameConfig == 1) {
                Lobbys[lobbyId].gameCaller1 = msg.sender;
                Lobbys[lobbyId].lobbyState = 2;
                updateBlock(lobbyId);
                emit gameCalled(
                    gameId,
                    block.number,
                    msg.sender,
                    0x0000000000000000000000000000000000000000,
                    0x0000000000000000000000000000000000000000
                );
            } else if (tempLobby.gameConfig == 2) {
                if (
                    tempLobby.gameCaller1 ==
                    0x0000000000000000000000000000000000000000
                ) {
                    Lobbys[lobbyId].gameCaller1 = msg.sender;
                    emit lobbyJoined(gameId, msg.sender, 0);
                } else {
                    Lobbys[lobbyId].gameCaller2 = msg.sender;
                    Lobbys[lobbyId].lobbyState = 2;
                    updateBlock(lobbyId);
                    emit gameCalled(
                        gameId,
                        block.number,
                        Lobbys[lobbyId].gameCaller1,
                        msg.sender,
                        0x0000000000000000000000000000000000000000
                    );
                }
            } else {
                if (position == 1) {
                    require(
                        tempLobby.gameCaller1 ==
                            0x0000000000000000000000000000000000000000,
                        "Cannot fill position"
                    );
                    Lobbys[lobbyId].gameCaller1 = msg.sender;
                    emit lobbyJoined(gameId, msg.sender, 1);
                } else {
                    require(
                        tempLobby.gameCaller2 ==
                            0x0000000000000000000000000000000000000000 ||
                            tempLobby.gameCaller3 ==
                            0x0000000000000000000000000000000000000000,
                        "Cannot fill position"
                    );
                    if (
                        tempLobby.gameCaller2 ==
                        0x0000000000000000000000000000000000000000
                    ) {
                        Lobbys[lobbyId].gameCaller2 = msg.sender;
                        emit lobbyJoined(gameId, msg.sender, 2);
                    } else {
                        Lobbys[lobbyId].gameCaller3 = msg.sender;
                        emit lobbyJoined(gameId, msg.sender, 3);
                    }
                }
                if (isLobbyFull(lobbyId)) {
                    Lobbys[lobbyId].lobbyState = 2;
                    updateBlock(lobbyId);
                    emit gameCalled(
                        gameId,
                        block.number,
                        Lobbys[lobbyId].gameCaller1,
                        Lobbys[lobbyId].gameCaller2,
                        Lobbys[lobbyId].gameCaller3
                    );
                }
            }
        }
    }

    function isLobbyFull(uint256 _lobbyId) public view returns (bool) {
        Lobby memory tempLobby = Lobbys[_lobbyId];
        if (
            tempLobby.gameCaller1 == 0x0000000000000000000000000000000000000000
        ) {
            return false;
        }
        if (
            tempLobby.gameCaller2 == 0x0000000000000000000000000000000000000000
        ) {
            return false;
        }
        if (
            tempLobby.gameCaller3 == 0x0000000000000000000000000000000000000000
        ) {
            return false;
        }
        return true;
    }

    function callBob(uint256 gameId) public {
        uint256 lobbyId = gameIdToLobbyId[gameId];
        Lobby memory tempLobby = Lobbys[lobbyId];
        require(
            msg.sender == tempLobby.gameStarter || msg.sender == owner,
            "You cant call bob for this lobby"
        );
        require(tempLobby.lobbyState == 1, "Can only call for placed lobbys");
        Lobbys[lobbyId].lobbyState = 2;
        if (tempLobby.gameType != 3) {
            Lobbys[lobbyId].gameCaller1 = bobAddress;
        } else {
            if (
                tempLobby.gameCaller1 ==
                0x0000000000000000000000000000000000000000
            ) {
                Lobbys[lobbyId].gameCaller1 = bobAddress;
            }
            if (
                tempLobby.gameCaller2 ==
                0x0000000000000000000000000000000000000000
            ) {
                Lobbys[lobbyId].gameCaller2 = bobAddress;
            }
            if (
                tempLobby.gameCaller3 ==
                0x0000000000000000000000000000000000000000
            ) {
                Lobbys[lobbyId].gameCaller3 = bobAddress;
            }
        }
        updateBlock(lobbyId);
        emit gameCalled(
            gameId,
            block.number,
            Lobbys[lobbyId].gameCaller1,
            Lobbys[lobbyId].gameCaller2,
            Lobbys[lobbyId].gameCaller3
        );
    }

    function updateBlock(uint256 nextId) internal {
        blockCountToLobbyId[block.number][
            blockNumberCount[block.number]
        ] = nextId;
        blockNumberCount[block.number]++;
    }

    function startGame(
        uint256 gameType,
        uint256 gameConfig,
        uint256 cost,
        uint256[] calldata caseIds,
        bool pvp
    ) external {
        //GameType 0 - coinflip, 1 - dice, 2 - death, 3 - lootboxes
        //GameConfig coinflip - the side, lootboxes - the player config ( 0 - solo, 1 - 1v1, 2 - 1v1v1, 3 - 2v2)
        require(gameType >= 0 && gameType <= 3, "Select proper game Type");
        require(
            gameConfig >= 0 && gameConfig <= 3,
            "Select proper game Config"
        );
        uint256 lobbyId = findNextAvailable();
        gameIdToLobbyId[gameCount] = lobbyId;
        uint256 lootboxLobbyId = 0;
        bool soloMode = false;
        if (gameType == 3) {
            require(
                getCostOfLootboxes(caseIds) == cost,
                "Cost Does not match loot box cost"
            );
            lootboxLobbyId = findNextAvailableLootBoxLobby();
            for (uint256 i = 0; i < caseIds.length; i++) {
                lootboxLobbyToLootboxId[lootboxLobbyId][i] = caseIds[i];
            }
            if (gameConfig == 0) {
                soloMode = true;
            }
        }
        burnTokens(msg.sender, cost);
        totalWagered += cost;
        Lobbys[lobbyId] = Lobby(
            gameCount,
            gameType,
            gameConfig,
            cost,
            caseIds.length,
            lootboxLobbyId,
            1,
            msg.sender,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
        );
        emit gameStarted(
            msg.sender,
            lobbyId,
            gameCount,
            gameType,
            gameConfig,
            cost,
            caseIds
        );

        if (soloMode) {
            updateBlock(block.number);
            emit gameCalled(
                gameCount,
                block.number,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000
            );
        } else if (!pvp) {
            callBob(lobbyId);
        }
        gameCount++;
    }
}