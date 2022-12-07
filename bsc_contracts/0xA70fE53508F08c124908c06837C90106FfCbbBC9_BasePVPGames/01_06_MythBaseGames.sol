// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "ERC20.sol";
import "MythToken.sol";

contract BasePVPGames {
    address payable public owner;

    uint256 public gameCount;
    address public bobAddress;
    address payable public mythAddress;
    bool public startGames = true;
    bool public callBobGames = true;
    bool public withdrawEnabled = true;
    mapping(address => uint256) public bobBalanceOfToken;
    mapping(address => uint256) public ownerPercent;
    mapping(address => uint256) public bountyPercent;
    mapping(address => uint256) public pooledRewardsBounty;
    mapping(address => uint256) public pooledRewardsOwner;
    mapping(address => mapping(address => bool)) public canClaimBountyPool;
    mapping(address => mapping(address => bool)) public canClaimOwnerPool;
    // address payable public bountyPool;
    mapping(address => uint256) public minBetOfToken;
    mapping(address => uint256) public maxBetOfToken;
    mapping(address => mapping(address => uint256))
        public unclaimedRewardsOfUser;
    mapping(uint256 => bool) public resolvedBlocks;
    mapping(address => bool) public resolverAddresses;
    mapping(uint256 => gameStruct) public gameDataFromId;
    mapping(uint256 => uint256) public gameIdFromCountNumber;
    mapping(uint256 => bool) public activeGameId;
    mapping(uint256 => uint256) public blockNumberGameCount;
    mapping(uint256 => mapping(uint256 => uint256))
        public gameIdFromBlockNumberAndItter;

    struct gameStruct {
        uint8 gameType;
        uint8 challengerSide;
        uint8 gameState; // 0 means placed by challenger, 1 means called by caller, 2 means resolved
        uint256 gameCount;
        uint256 wagerAmount;
        uint256 blockInitialized;
        address betCurrency;
        address challenger;
        address caller;
    }
    event betLimitChanged(bool isMin, address currency, uint256 amount);
    event winningsAdded(address winner, address currency, uint256 amount);
    event gameCancelled(uint256 gameCount);
    event feesPaid(address currency, uint256 amount, bool isBounty);
    event feesClaimed(
        address currency,
        address claimer,
        uint256 amount,
        bool isBounty
    );
    event gameCalled(
        uint256 gameCount,
        uint256 blockNumberInitialized,
        address caller
    );
    event gameResolved(
        uint256 gameCount,
        bool challengerWinner,
        bytes32 resolutionSeed
    );
    event gameStarted(
        uint8 gameType,
        uint8 challengerSide,
        uint256 wagerAmount,
        uint256 gameCount,
        uint256 gameId,
        address challenger,
        address currency
    );
    event bobBalanceChanged(address currency, uint256 amount);
    event claimedWinnings(address winner, address currency, uint256 amount);

    constructor(address _myth) {
        owner = payable(msg.sender);
        mythAddress = payable(_myth);
    }

    function enableGames(bool _enable) external {
        require(msg.sender == owner, "only owner");
        startGames = _enable;
    }

    function enableBob(bool _enable) external {
        require(msg.sender == owner, "only owner");
        callBobGames = _enable;
    }

    function enableWithdraw(bool _enable) external {
        require(msg.sender == owner, "only owner");
        withdrawEnabled = _enable;
    }

    function changeBountyClaimer(
        address _token,
        address _claimer,
        bool _claimable
    ) external {
        require(msg.sender == owner, "only owner");
        canClaimBountyPool[_claimer][_token] = _claimable;
    }

    function changeOwnerClaimer(
        address _token,
        address _claimer,
        bool _claimable
    ) external {
        require(msg.sender == owner, "only owner");
        canClaimOwnerPool[_claimer][_token] = _claimable;
    }

    function changePercents(
        address _token,
        uint256 _bounty,
        uint256 _owner
    ) external {
        require(msg.sender == owner, "only owner");
        ownerPercent[_token] = _owner;
        bountyPercent[_token] = _bounty;
    }

    function changeMinBet(uint256 _amount, address _token) external {
        require(msg.sender == owner, "only owner");
        minBetOfToken[_token] = _amount;
        emit betLimitChanged(true, _token, _amount);
    }

    function changeMaxBet(uint256 _amount, address _token) external {
        require(msg.sender == owner, "only owner");
        maxBetOfToken[_token] = _amount;
        emit betLimitChanged(false, _token, _amount);
    }

    function changeResolver(address _address, bool _bool) external {
        require(msg.sender == owner, "only owner");
        resolverAddresses[_address] = _bool;
    }

    function changeBobAddress(address _address) external {
        require(msg.sender == owner, "only owner");
        bobAddress = _address;
    }

    function depoBob(address _token, uint256 _amount) external payable {
        require(msg.sender == owner, "only owner");
        if (_token == address(0)) {
            bobBalanceOfToken[address(0)] += msg.value;
            emit bobBalanceChanged(address(0), bobBalanceOfToken[address(0)]);
        } else {
            ERC20 tokenContract = ERC20(_token);
            tokenContract.transferFrom(msg.sender, address(this), _amount);
            bobBalanceOfToken[_token] += _amount;
            emit bobBalanceChanged(_token, bobBalanceOfToken[_token]);
        }
    }

    function changeBobsBalance(address _token, uint256 _amount) external {
        require(msg.sender == owner, "only owner");
        bobBalanceOfToken[_token] = _amount;
        emit bobBalanceChanged(_token, _amount);
    }

    function withdrawFees(
        address _token,
        uint256 _amount,
        bool _bounty
    ) external payable {
        if (_bounty) {
            require(
                canClaimBountyPool[msg.sender][_token],
                "Cannot Claim this tokens from bounty pool"
            );
            require(
                pooledRewardsBounty[_token] >= _amount,
                "Not enough pooled"
            );
            if (_token == address(0)) {
                pooledRewardsBounty[_token] -= _amount;
                (bool successUser, ) = msg.sender.call{value: _amount}("");
                require(successUser, "Transfer to user failed");
            } else {
                pooledRewardsBounty[_token] -= _amount;
                ERC20 tokenContract = ERC20(_token);
                tokenContract.transfer(msg.sender, _amount);
            }
        } else {
            require(
                canClaimOwnerPool[msg.sender][_token],
                "Cannot Claim this tokens from owner pool"
            );
            require(pooledRewardsOwner[_token] >= _amount, "Not enough pooled");
            if (_token == address(0)) {
                pooledRewardsOwner[_token] -= _amount;
                (bool successUser, ) = msg.sender.call{value: _amount}("");
                require(successUser, "Transfer to user failed");
            } else {
                pooledRewardsOwner[_token] -= _amount;
                ERC20 tokenContract = ERC20(_token);
                tokenContract.transfer(msg.sender, _amount);
            }
        }
        emit feesClaimed(_token, msg.sender, _amount, _bounty);
    }

    function rescueTokens(address _token, uint256 _amount) external payable {
        require(msg.sender == owner, "only owner");
        if (_token == address(0)) {
            (bool successUser, ) = msg.sender.call{value: _amount}("");
            require(successUser, "Transfer to user failed");
        } else {
            ERC20 tokenContract = ERC20(_token);
            tokenContract.transfer(msg.sender, _amount);
        }
    }

    function viewBalance(address _token) public view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        } else {
            ERC20 tokenContract = ERC20(_token);
            tokenContract.balanceOf(address(this));
        }
    }

    function getUserRewards(address _currency, address _user)
        public
        view
        returns (uint256)
    {
        return unclaimedRewardsOfUser[_user][_currency];
    }

    function cancelGame(uint256 _gameCount) public payable {
        require(msg.value == 0, "Dont send bnb");
        uint256 _gameId = gameIdFromCountNumber[_gameCount];
        gameStruct memory tempGame = gameDataFromId[_gameId];
        require(
            tempGame.challenger == msg.sender || msg.sender == owner,
            "Only creator of game can cancel it"
        );

        require(tempGame.gameState == 0, "Game must be in placed state");
        gameDataFromId[_gameId].gameState = 2;
        if (tempGame.betCurrency == address(0)) {
            (bool successUser, ) = tempGame.challenger.call{
                value: tempGame.wagerAmount
            }("");
            require(successUser, "Transfer to user failed");
        } else if (tempGame.betCurrency == mythAddress) {
            MythToken mythContract = MythToken(mythAddress);
            mythContract.mintTokens(tempGame.wagerAmount, tempGame.challenger);
        } else {
            ERC20 tokenContract = ERC20(tempGame.betCurrency);
            tokenContract.transfer(tempGame.challenger, tempGame.wagerAmount);
        }
        activeGameId[_gameId] = false;
        emit gameCancelled(_gameCount);
    }

    function callBob(uint256 _gameCount) public {
        require(callBobGames, "Bob is not enabled");
        uint256 _gameId = gameIdFromCountNumber[_gameCount];
        gameStruct memory tempGame = gameDataFromId[_gameId];
        require(tempGame.gameState == 0, "Game must be in placed state");
        require(
            tempGame.challenger == msg.sender,
            "Only creator of game can call bob"
        );
        require(
            tempGame.wagerAmount <= maxBetOfToken[tempGame.betCurrency],
            "Bet too big for Bob"
        );
        if (tempGame.betCurrency != mythAddress) {
            require(
                bobBalanceOfToken[tempGame.betCurrency] >= tempGame.wagerAmount,
                "Bob Doesn't have enough"
            );
            bobBalanceOfToken[tempGame.betCurrency] -= tempGame.wagerAmount;
            emit bobBalanceChanged(
                tempGame.betCurrency,
                bobBalanceOfToken[tempGame.betCurrency]
            );
        }

        tempGame.caller = bobAddress;
        tempGame.blockInitialized = block.number;
        tempGame.gameState = 1;
        gameDataFromId[_gameId] = tempGame;
        uint256 currentBlockCount = blockNumberGameCount[block.number];
        gameIdFromBlockNumberAndItter[block.number][
            currentBlockCount
        ] = _gameId;
        blockNumberGameCount[block.number] += 1;
        emit gameCalled(tempGame.gameCount, block.number, bobAddress);
    }

    function callTokenGame(uint256 _gameCount) external {
        require(startGames, "Games are not enabled");
        uint256 _gameId = gameIdFromCountNumber[_gameCount];
        gameStruct memory tempGame = gameDataFromId[_gameId];
        require(address(0) != tempGame.betCurrency, "Bet Currency is BNB");
        require(tempGame.wagerAmount > 0, "This Game Has No Wager");
        require(tempGame.gameState == 0, "Game must be in placed state");
        tempGame.caller = msg.sender;
        tempGame.blockInitialized = block.number;
        tempGame.gameState = 1;
        gameDataFromId[_gameId] = tempGame;
        if (tempGame.betCurrency == mythAddress) {
            MythToken mythContract = MythToken(mythAddress);
            mythContract.burnTokens(tempGame.wagerAmount, msg.sender);
        } else {
            ERC20 tokenContract = ERC20(tempGame.betCurrency);
            tokenContract.transferFrom(
                msg.sender,
                address(this),
                tempGame.wagerAmount
            );
        }
        uint256 currentBlockCount = blockNumberGameCount[block.number];
        gameIdFromBlockNumberAndItter[block.number][
            currentBlockCount
        ] = _gameId;
        blockNumberGameCount[block.number] += 1;
        emit gameCalled(tempGame.gameCount, block.number, msg.sender);
    }

    function callGame(uint256 _gameCount) external payable {
        require(startGames, "Games are not enabled");

        uint256 _gameId = gameIdFromCountNumber[_gameCount];
        gameStruct memory tempGame = gameDataFromId[_gameId];
        require(address(0) == tempGame.betCurrency, "Bet Currency is not BNB");
        require(msg.value == tempGame.wagerAmount, "Send Wager Amount");
        require(tempGame.wagerAmount > 0, "This Game Has No Wager");
        require(tempGame.gameState == 0, "Game must be in placed state");
        tempGame.caller = msg.sender;
        tempGame.blockInitialized = block.number;
        tempGame.gameState = 1;
        gameDataFromId[_gameId] = tempGame;
        uint256 currentBlockCount = blockNumberGameCount[block.number];
        gameIdFromBlockNumberAndItter[block.number][
            currentBlockCount
        ] = _gameId;
        blockNumberGameCount[block.number] += 1;
        emit gameCalled(tempGame.gameCount, block.number, msg.sender);
    }

    function resolveBlock(uint256 _blockNumber, bytes32 _resolutionSeed)
        external
    {
        require(
            resolverAddresses[msg.sender],
            "Only resolvers can resolve blocks"
        );
        require(!resolvedBlocks[_blockNumber], "Block Already resolved");
        require(blockNumberGameCount[_blockNumber] > 0, "No games to resolve");
        require(_blockNumber < block.number, "Block not reached yet");
        resolvedBlocks[_blockNumber] = true;
        bool challengerWinner;
        for (uint256 i = 0; i < blockNumberGameCount[_blockNumber]; i++) {
            uint256 currentGameId = gameIdFromBlockNumberAndItter[_blockNumber][
                i
            ];
            gameStruct memory tempGame = gameDataFromId[currentGameId];
            if (tempGame.gameState != 1) continue;
            if (tempGame.gameType == 1) {
                challengerWinner = resolveFlip(
                    _resolutionSeed,
                    tempGame.gameCount,
                    tempGame.challengerSide
                );
            } else if (tempGame.gameType == 2) {
                challengerWinner = resolveDiceDuel(
                    _resolutionSeed,
                    tempGame.gameCount
                );
            } else if (tempGame.gameType == 3) {
                challengerWinner = resolveDeathRoll(
                    _resolutionSeed,
                    tempGame.gameCount
                );
            }
            challengerWinner
                ? payoutWinner(
                    tempGame.wagerAmount * 2,
                    tempGame.challenger,
                    tempGame.betCurrency
                )
                : payoutWinner(
                    tempGame.wagerAmount * 2,
                    tempGame.caller,
                    tempGame.betCurrency
                );
            gameDataFromId[currentGameId].gameState = 2;
            activeGameId[currentGameId] = false;
            emit gameResolved(
                tempGame.gameCount,
                challengerWinner,
                _resolutionSeed
            );
        }
    }

    function payoutWinner(
        uint256 _amount,
        address _winner,
        address _currency
    ) internal {
        if (_winner != bobAddress) {
            unclaimedRewardsOfUser[_winner][_currency] += _amount;
        } else {
            bobBalanceOfToken[_currency] += _amount;
            emit bobBalanceChanged(_currency, bobBalanceOfToken[_currency]);
        }
        emit winningsAdded(_winner, _currency, _amount);
    }

    function withdrawTokenWinnings(address _token) external {
        require(_token != address(0), "Cant be 0 Address");
        require(withdrawEnabled, "Withdraws are not enabled");
        uint256 currentRewards = unclaimedRewardsOfUser[msg.sender][_token];
        require(currentRewards > 1, "No pending rewards");
        unclaimedRewardsOfUser[msg.sender][_token] = 0;
        uint256 rewardPerCent = ((currentRewards - (currentRewards % 100000)) /
            1000);
        if (_token != mythAddress) {
            ERC20 tokenContract = ERC20(_token);

            uint256 _ownerPercent = ownerPercent[_token];
            uint256 _bountyPercent = bountyPercent[_token];
            if (_bountyPercent > 0) {
                pooledRewardsBounty[_token] += rewardPerCent * (_bountyPercent);
                emit feesPaid(_token, rewardPerCent * (_bountyPercent), true);
            }
            if (_ownerPercent > 0) {
                pooledRewardsOwner[_token] += rewardPerCent * (_ownerPercent);
                emit feesPaid(_token, rewardPerCent * (_ownerPercent), false);
            }

            tokenContract.transfer(
                msg.sender,
                rewardPerCent * (1000 - (_bountyPercent + _ownerPercent))
            );
            emit claimedWinnings(
                msg.sender,
                _token,
                rewardPerCent * (1000 - (_bountyPercent + _ownerPercent))
            );
        } else {
            MythToken mythContract = MythToken(mythAddress);
            mythContract.mintTokens(rewardPerCent * 980, msg.sender);
            emit claimedWinnings(msg.sender, _token, rewardPerCent * 980);
        }
    }

    function withdrawWinnings() external payable {
        require(withdrawEnabled, "Withdraws are not enabled");
        require(msg.value == 0, "Dont send bnb");
        require(
            unclaimedRewardsOfUser[msg.sender][address(0)] > 1,
            "No pending rewards"
        );
        require(
            unclaimedRewardsOfUser[msg.sender][address(0)] <=
                address(this).balance,
            "Smart Contract Doesnt have enough funds"
        );
        uint256 rewardsForPlayer = unclaimedRewardsOfUser[msg.sender][
            address(0)
        ];
        unclaimedRewardsOfUser[msg.sender][address(0)] = 0;
        uint256 rewardPerCent = ((rewardsForPlayer -
            (rewardsForPlayer % 100000)) / 1000);
        uint256 _ownerPercent = ownerPercent[address(0)];
        uint256 _bountyPercent = bountyPercent[address(0)];
        if (_bountyPercent > 0) {
            pooledRewardsBounty[address(0)] += rewardPerCent * (_bountyPercent);
            emit feesPaid(address(0), rewardPerCent * (_bountyPercent), true);
        }
        if (_ownerPercent > 0) {
            pooledRewardsOwner[address(0)] += rewardPerCent * (_ownerPercent);
            emit feesPaid(address(0), rewardPerCent * (_ownerPercent), false);
        }
        (bool successUser, ) = msg.sender.call{
            value: (rewardPerCent * (1000 - (_bountyPercent + _ownerPercent)))
        }("");
        require(successUser, "Transfer to user failed");
        emit claimedWinnings(
            msg.sender,
            address(0),
            rewardPerCent * (1000 - (_bountyPercent + _ownerPercent))
        );
    }

    function resolveDeathRoll(bytes32 _resolutionSeed, uint256 nonce)
        internal
        view
        returns (bool)
    {
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

    function resolveFlip(
        bytes32 _resolutionSeed,
        uint256 nonce,
        uint8 _side
    ) internal view returns (bool) {
        uint8 roll = uint8(
            uint256(keccak256(abi.encodePacked(_resolutionSeed, nonce))) % 2
        );
        return roll == _side;
    }

    function resolveDiceDuel(bytes32 _resolutionSeed, uint256 nonce)
        internal
        view
        returns (bool)
    {
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

    function startTokenGame(
        uint8 _gameType,
        uint8 _side,
        uint256 _amount,
        address _currency,
        bool _pvp
    ) external {
        require(startGames, "Games are not enabled");
        require(minBetOfToken[_currency] <= _amount, "Bet too small");
        require(_gameType >= 1 && _gameType <= 3, "Select correct gametype");
        require(_side >= 0 && _side <= 1, "Select correct side");
        uint256 counter = 1;
        while (true) {
            if (activeGameId[counter]) {
                counter += 1;
                continue;
            } else {
                if (_currency != mythAddress) {
                    ERC20 tokenContract = ERC20(_currency);
                    tokenContract.transferFrom(
                        msg.sender,
                        address(this),
                        _amount
                    );
                } else {
                    MythToken mythContract = MythToken(mythAddress);
                    mythContract.burnTokens(_amount, msg.sender);
                }

                activeGameId[counter] = true;
                gameIdFromCountNumber[gameCount] = counter;
                gameDataFromId[counter] = gameStruct(
                    _gameType,
                    _side,
                    0,
                    gameCount,
                    _amount,
                    0,
                    _currency,
                    msg.sender,
                    address(0)
                );
                emit gameStarted(
                    _gameType,
                    _side,
                    _amount,
                    gameCount,
                    counter,
                    msg.sender,
                    _currency
                );
                break;
            }
        }
        if (!_pvp) {
            callBob(gameCount);
        }
        gameCount++;
    }

    function startGame(
        uint8 _gameType,
        uint8 _side,
        bool _pvp
    ) external payable {
        require(startGames, "Games are not enabled");
        require(msg.value >= minBetOfToken[address(0)], "Bet too small");
        require(_gameType >= 1 && _gameType <= 3, "Select correct gametype");
        require(_side >= 0 && _side <= 1, "Select correct side");
        uint256 counter = 1;
        while (true) {
            if (activeGameId[counter]) {
                counter += 1;
                continue;
            } else {
                activeGameId[counter] = true;
                gameIdFromCountNumber[gameCount] = counter;
                gameDataFromId[counter] = gameStruct(
                    _gameType,
                    _side,
                    0,
                    gameCount,
                    msg.value,
                    0,
                    address(0),
                    msg.sender,
                    address(0)
                );
                emit gameStarted(
                    _gameType,
                    _side,
                    msg.value,
                    gameCount,
                    counter,
                    msg.sender,
                    address(0)
                );
                break;
            }
        }
        if (!_pvp) {
            callBob(gameCount);
        }
        gameCount++;
    }
}