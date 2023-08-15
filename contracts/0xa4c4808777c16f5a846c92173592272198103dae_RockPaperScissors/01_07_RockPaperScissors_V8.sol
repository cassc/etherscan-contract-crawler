// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.17;

contract RockPaperScissors is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Moves {
        None,
        Rock,
        Paper,
        Scissors
    }

    enum Stages {
        None,
        WaitForOpponent,
        WaitForReveal,
        ReadyForFinalize,
        Draw,
        DrawWaitForOpponent,
        Done
    }

    /**
     * @dev Winner outcomes
     */
    enum WinnerOutcomes {
        None,
        PlayerA,
        PlayerB,
        Draw
    }

    struct Player {
        address playerAddress;
        Moves move;
        bytes32 encrMove;
    }

    /**
     * @dev game metadata
     */
    struct GameData {
        uint256 gameId;
        address currency;
        uint256 gameBalance;
        Player playerA;
        Player playerB;
        Stages stage;
        WinnerOutcomes winner;
        uint64 revealDeadline;
        bool active;
    }

    /// --- Variables
    uint256 gameIds;
    /// @dev fee amount in percent (BP 1000 = 10%)
    uint256 public fee;
    /// @dev min bet amount in wei
    uint256 public minBetAmount;
    /// @dev deadline for reveal move in game
    uint64 public revealTime;

    /// --- mappings
    /**
     * @notice Keep game data
     *
     * uint256 = gameId
     * GameData = game metadata
     */
    mapping(uint256 => GameData) public gamesData;

    /**
     * @notice Show if game has active draw status
     * uint256 = gameId
     * bool = status draw
     */
    mapping(uint256 => bool) public draws;

    /// --- errors
    error EarlyCall();
    error OnlyCreator();
    error ZeroAddress();
    error InvalidMove();
    error NotActiveDraw();
    error AlreadyRevealed();
    error AlreadyConnected();
    error InvalidBetAmount();
    error IncorrectGameStage();
    error AlreadyMovedInDraw();
    error RevealDeadlinePassed();
    error InvalidStageForReveal();
    error InvalidStageForJoinGame();
    error CallerNotGameParticipant();
    error NonActiveOrNonexistentGame();
    error InvalidData(bytes32, bytes32);
    error WrongSender();

    /// --- events
    event RevealTimeSettled(uint256 indexed timestamp);
    event MinBetValueSettled(uint256 indexed minBetAmount);
    event FeeAmountWithdrawn(uint256 indexed amount, address indexed currency);
    event TokenTransferred(
        address indexed from,
        address indexed to,
        address indexed currency,
        uint256 amount
    );
    event YouHaveDraw(uint256 indexed id);
    event FeeAmountSettled(uint256 indexed id);
    event DrawReadyForReveal(
        uint256 indexed id,
        address indexed playerA,
        address indexed playerB
    );
    event GameDataAdded(uint256 indexed id, address indexed creator);
    event PlayerConnectedToGame(
        uint256 indexed id,
        address indexed player,
        address playerA,
        address playerB
    );
    event GameCanceled(
        uint256 indexed id,
        address indexed player,
        uint256 indexed amount
    );
    event GameCreated(
        uint256 indexed id,
        address indexed creator,
        address indexed currency
    );
    event GameBalanceWithdrawn(
        uint256 indexed id,
        address indexed receiver,
        uint256 indexed amount
    );
    event MoveRevealed(
        uint256 indexed id,
        address indexed player,
        Moves indexed value,
        address playerA,
        address playerB
    );
    event HiddenMoveAddedToDraw(
        uint256 indexed id,
        address indexed playerAddress,
        bytes32 indexed hiddenMove,
        address playerA,
        address playerB
    );
    event TechnicalDefeatWithdrawn(
        uint256 indexed id,
        address indexed sender,
        address player,
        uint256 indexed paybackAmount
    );
    event JointTechnicalDefeatWithdrawn(
        uint256 indexed id,
        address indexed sender,
        uint256 indexed amount,
        address playerA,
        address playerB
    );
    event WinnerPaid(
        uint256 indexed id,
        address indexed winner,
        uint256 amount,
        address indexed secondPlayer,
        uint256 fee,
        address currency
    );

    /// --- modifiers
    /// @dev check if game is active
    modifier isGameExist(uint256 _gameId) {
        if (!gamesData[_gameId].active) revert NonActiveOrNonexistentGame();
        _;
    }

    /// @dev check if caller is game participant
    modifier onlyParticipant(uint256 _gameId) {
        address _playerA;
        address _playerB;
        (_playerA, _playerB) = getGamePlayersAddress(_gameId);

        if (_playerA != msg.sender && _playerB != msg.sender)
            revert CallerNotGameParticipant();
        _;
    }

    /// --- Constructor
    constructor(
        uint64 _revealTime,
        uint256 _fee,
        uint256 _minBetAmount,
        address _owner
    ) ReentrancyGuard() {
        setRevealTime(_revealTime);
        setFee(_fee);
        setMinBetAmount(_minBetAmount);
        setOwner(_owner);
    }

    /**
     * @dev Create new instance of game and add hashed PlayerA move data.
     * @param hiddenMove hash of caller move generated uot of blockchain
     * @param currency address of token or address(0) for ETH
     * @param amount bet amount
     *
     * @notice
     * hiddenMove === keccak256(abi.encodePacked(salt, move, msg.sender))
     * where:
     * salt === secret created by caller
     * move === caller choice from list "Rock", "Paper", "Scissors" only
     * msg.sender === sender address
     */

    function createGame(
        bytes32 hiddenMove,
        address currency,
        uint256 amount,
        address playerB
    ) external {
        // check if amount > minBetTokenAmount
        if (amount < minBetAmount) revert InvalidBetAmount();

        // check if currency is not a zeroAddress
        if (currency == address(0)) revert ZeroAddress();

        // protect from private game self-connection
        if (msg.sender == playerB) revert AlreadyConnected();

        // return new game id
        uint256 gameId = _addGameData(
            msg.sender,
            hiddenMove,
            currency,
            amount,
            playerB
        );

        // transfer tokens to contract
        IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);

        emit GameCreated(gameId, msg.sender, currency);
    }

    /// @dev Add game data to storage
    function _addGameData(
        address _creator,
        bytes32 _hiddenMove,
        address _currency,
        uint256 _amount,
        address _playerB
    ) internal returns (uint256) {
        gameIds ++;
        uint256 newGameId = gameIds;

        GameData storage data = gamesData[newGameId];
        data.gameId = newGameId;
        data.currency = _currency;
        data.gameBalance = _amount;

        data.playerA = Player({
            playerAddress: _creator,
            move: Moves.None,
            encrMove: _hiddenMove
        });

        data.stage = Stages.WaitForOpponent;
        data.active = true;

        gamesData[newGameId] = data;

        if (_playerB != address(0)) {
            data.playerB.playerAddress = _playerB;

            emit CreatedPrivateGame(newGameId, _creator, _playerB);
        }

        emit GameDataAdded(newGameId, _creator);

        return newGameId;
    }

    event CreatedPrivateGame(
        uint256 indexed id,
        address indexed playerA,
        address indexed playerB
    );

    /**
     * @dev Added PlayerB to existing game.
     *
     * @param gameId game Id which caller want participate.
     * @param hiddenMove hash of caller move generated uot of blockchain.
     *
     * @notice
     * hiddenMove === keccak256(abi.encodePacked(salt, move, msg.sender))
     * where:
     * salt === secret created by caller
     * move === caller choice from list "Rock", "Paper", "Scissors" only
     * msg.sender === sender address
     */
    function connectToGame(
        uint256 gameId,
        bytes32 hiddenMove
    ) external isGameExist(gameId) {
        GameData storage data = gamesData[gameId];
        // check game stage
        if (Stages.WaitForOpponent != data.stage)
            revert InvalidStageForJoinGame();

        // protect from self-connection
        if (msg.sender == data.playerA.playerAddress) revert AlreadyConnected();

        // add second player data to game data
        if (data.playerB.playerAddress == address(0)) {
            data.playerB.playerAddress = msg.sender;
            _addPlayerDataToGame(gameId, hiddenMove);
        } else {
            if (data.playerB.playerAddress != msg.sender) revert WrongSender();
            _addPlayerDataToGame(gameId, hiddenMove);
        }

        // transfer tokens to contract
        IERC20(data.currency).safeTransferFrom(
            msg.sender,
            address(this),
            data.gameBalance
        );

        data.gameBalance += data.gameBalance;

        emit PlayerConnectedToGame(
            gameId,
            msg.sender,
            data.playerA.playerAddress,
            data.playerB.playerAddress
        );
    }

    /// @dev Add player data to game data
    function _addPlayerDataToGame(
        uint256 _gameId,
        bytes32 _hiddenMove
    ) internal {
        GameData storage data = gamesData[_gameId];

        data.playerB.move = Moves.None;
        data.playerB.encrMove = _hiddenMove;
        data.stage = Stages.WaitForReveal;
        data.revealDeadline = uint64(block.timestamp + revealTime);

        gamesData[_gameId] = data;
    }

    /**
     * @notice Reveal data.
     * @param move caller choice from list "Rock", "Paper", "Scissors" only
     * @param salt secret created by caller.
     */
    function revealMove(
        uint256 gameId,
        Moves move,
        string memory salt
    ) external isGameExist(gameId) onlyParticipant(gameId) {
        // check move
        if (move != Moves.Rock && move != Moves.Paper && move != Moves.Scissors)
            revert InvalidMove();
        // check stage
        if (Stages.WaitForReveal != gamesData[gameId].stage)
            revert InvalidStageForReveal();
        // check deadline
        if (block.timestamp > gamesData[gameId].revealDeadline)
            revert RevealDeadlinePassed();

        // generate incr move for sender
        bytes32 encrMove = keccak256(abi.encodePacked(salt, move, msg.sender));

        Stages _stage = _revealPlayerMove(gameId, encrMove, move);

        if (_stage == Stages.ReadyForFinalize) {
            WinnerOutcomes winner = getWhoWon(gameId);
            if (winner == WinnerOutcomes.Draw) {
                draws[gameId] = true;
                gamesData[gameId].stage = Stages.Draw;

                delete gamesData[gameId].playerA.encrMove;
                delete gamesData[gameId].playerB.encrMove;
                delete gamesData[gameId].playerA.move;
                delete gamesData[gameId].playerB.move;

                emit YouHaveDraw(gameId);
            } else {
                _finalizeGame(gameId, gamesData[gameId], winner);
            }
        }
    }

    /// @dev Reveal player move & return new stage after second reveal
    function _revealPlayerMove(
        uint256 gameId,
        bytes32 encrMove,
        Moves _move
    ) private returns (Stages stage) {
        GameData storage data = gamesData[gameId];
        if (msg.sender == data.playerA.playerAddress) {
            if (data.playerA.move != Moves.None) revert AlreadyRevealed();
            if (encrMove != data.playerA.encrMove)
                revert InvalidData(encrMove, data.playerA.encrMove);
            // add move to game data
            data.playerA.move = _move;
        } else {
            if (data.playerB.move != Moves.None) revert AlreadyRevealed();
            if (encrMove != data.playerB.encrMove)
                revert InvalidData(encrMove, data.playerB.encrMove);
            data.playerB.move = _move;
        }

        if (
            data.playerA.move != Moves.None && data.playerB.move != Moves.None
        ) {
            data.stage = Stages.ReadyForFinalize;
        }

        gamesData[gameId] = data;

        emit MoveRevealed(
            gameId,
            msg.sender,
            _move,
            data.playerA.playerAddress,
            data.playerB.playerAddress
        );

        return data.stage;
    }

    /// @dev Finalize game & transfer funds to winner & fee to owner. If draw - init draw stage
    function _finalizeGame(
        uint256 gameId,
        GameData storage data,
        WinnerOutcomes winner
    ) internal {
        data.active = false;

        uint256 feeAmount = (data.gameBalance * fee) / 10000;
        uint256 winnerPot = data.gameBalance - feeAmount;

        data.gameBalance = 0;

        // get winner address
        address winnerAddress = winner == WinnerOutcomes.PlayerA
            ? data.playerA.playerAddress
            : data.playerB.playerAddress;
        // get lose address
        address loseAddress = winner == WinnerOutcomes.PlayerA
            ? data.playerB.playerAddress
            : data.playerA.playerAddress;

        if (draws[gameId]) {
            delete draws[gameId];
        }

        data.winner = winner;
        data.stage = Stages.Done;

        gamesData[gameId] = data;

        // transfer feeAmount to owner address
        _safeTransferToken(gamesData[gameId].currency, owner(), feeAmount);
        emit FeeAmountWithdrawn(feeAmount, gamesData[gameId].currency);

        // transfer tokens to winner
        _safeTransferToken(
            gamesData[gameId].currency,
            winnerAddress,
            winnerPot
        );

        emit WinnerPaid(
            gameId,
            winnerAddress,
            winnerPot,
            loseAddress,
            feeAmount,
            data.currency
        );
    }

    /// @dev Add encrypted move to draw game. If both players added moves - init reveal stage
    function addDrawMove(
        uint256 gameId,
        bytes32 newHiddenMove
    ) external isGameExist(gameId) onlyParticipant(gameId) {
        if (!draws[gameId]) revert NotActiveDraw();
        GameData memory data = gamesData[gameId];

        if (msg.sender == data.playerA.playerAddress) {
            // check if player already moved
            if (data.playerA.encrMove != bytes32(0))
                revert AlreadyMovedInDraw();

            data.playerA.encrMove = newHiddenMove;
            data.stage = Stages.DrawWaitForOpponent;

            if (data.playerB.encrMove != bytes32(0)) {
                data.stage = Stages.WaitForReveal;
                emit DrawReadyForReveal(
                    gameId,
                    data.playerA.playerAddress,
                    data.playerB.playerAddress
                );
            }
        } else {
            // check if player already moved
            if (data.playerB.encrMove != bytes32(0))
                revert AlreadyMovedInDraw();

            data.playerB.encrMove = newHiddenMove;
            data.stage = Stages.DrawWaitForOpponent;

            if (data.playerA.encrMove != bytes32(0)) {
                data.stage = Stages.WaitForReveal;
                emit DrawReadyForReveal(
                    gameId,
                    data.playerA.playerAddress,
                    data.playerB.playerAddress
                );
            }
        }
        gamesData[gameId] = data;

        emit HiddenMoveAddedToDraw(
            gameId,
            msg.sender,
            newHiddenMove,
            data.playerA.playerAddress,
            data.playerB.playerAddress
        );
    }

    /**
     * @dev Cancel game by ID and return money to player A.
     *
     * @param gameId specific gameId for cancel
     */
    function cancelGame(uint256 gameId) external isGameExist(gameId) {
        if (gamesData[gameId].playerA.playerAddress != msg.sender)
            revert OnlyCreator();

        _cancelGame(gameId);
    }

    ///@dev Cancel game by ID and return money to game creator. No fee.
    function _cancelGame(uint256 gameId) internal {
        GameData memory data = gamesData[gameId];

        if (data.stage != Stages.WaitForOpponent) revert IncorrectGameStage();

        uint256 amount = gamesData[gameId].gameBalance;

        data.gameBalance = 0;
        data.stage = Stages.Done;
        data.active = false;

        gamesData[gameId] = data;

        _withdrawGameBalance(gameId, amount, msg.sender);

        emit GameCanceled(gameId, msg.sender, amount);
    }

    /**
     * @dev technical defeat by timeout
     */
    function technicalDefeat(
        uint256 gameId
    ) external isGameExist(gameId) onlyParticipant(gameId) {
        if (gamesData[gameId].playerB.playerAddress == address(0)) {
            _cancelGame(gameId);
            return;
        }

        _technicalDefeat(gameId);
    }

    ///@dev technical defeat by timeout expirations
    function _technicalDefeat(uint256 gameId) internal {
        GameData memory data = gamesData[gameId];
        if (block.timestamp < data.revealDeadline) revert EarlyCall();

        uint256 feeAmount = (data.gameBalance * fee) / 10000;
        uint256 payBackAmount = data.gameBalance - feeAmount;

        // transfer feeAmount to owner address
        _safeTransferToken(gamesData[gameId].currency, owner(), feeAmount);
        emit FeeAmountWithdrawn(feeAmount, gamesData[gameId].currency);

        data.gameBalance = 0;
        data.stage = Stages.Done;
        data.active = false;

        gamesData[gameId] = data;

        if (
            data.playerB.move == Moves.None && data.playerA.move == Moves.None
        ) {
            uint256 eachPlayerPayBackAmount = payBackAmount / 2;

            _withdrawGameBalance(
                gameId,
                eachPlayerPayBackAmount,
                data.playerA.playerAddress
            );
            _withdrawGameBalance(
                gameId,
                eachPlayerPayBackAmount,
                data.playerB.playerAddress
            );

            emit JointTechnicalDefeatWithdrawn(
                gameId,
                msg.sender,
                eachPlayerPayBackAmount,
                data.playerA.playerAddress,
                data.playerB.playerAddress
            );
        } else {
            address winnerAddress = data.playerA.move == Moves.None
                ? data.playerB.playerAddress
                : data.playerA.playerAddress;

            // technical defeat winner
            gamesData[gameId].winner = winnerAddress ==
                data.playerA.playerAddress
                ? WinnerOutcomes.PlayerA
                : WinnerOutcomes.PlayerB;

            _withdrawGameBalance(gameId, payBackAmount, winnerAddress);

            emit TechnicalDefeatWithdrawn(
                gameId,
                msg.sender,
                winnerAddress,
                payBackAmount
            );
        }
    }

    /**
     * @dev Withdraw game balance to player
     *
     * @param gameId specific gameId for withdraw
     */
    function _withdrawGameBalance(
        uint256 gameId,
        uint256 amount,
        address receiver
    ) internal {
        _safeTransferToken(gamesData[gameId].currency, receiver, amount);

        emit GameBalanceWithdrawn(gameId, receiver, amount);
    }

    /// @dev return game wi address by game id
    function _calcWinner(
        Moves movePlayerA,
        Moves movePlayerB
    ) private pure returns (WinnerOutcomes winner) {
        if (movePlayerA == movePlayerB) {
            winner = WinnerOutcomes.Draw;
        } else if (
            (movePlayerA == Moves.Rock && movePlayerB == Moves.Scissors) ||
            (movePlayerA == Moves.Paper && movePlayerB == Moves.Rock) ||
            (movePlayerA == Moves.Scissors && movePlayerB == Moves.Paper)
        ) {
            winner = WinnerOutcomes.PlayerA;
        } else {
            winner = WinnerOutcomes.PlayerB;
        }

        return winner;
    }

    /// @dev return active games ids in range for pagination by game id
    function getActiveGamesIds(
        uint256 from,
        uint256 to
    ) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](to - from);
        uint256 counter = 0;

        for (uint256 i = from; i < to; i++) {
            if (gamesData[i].active) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    /// @dev return active games ids in range for pagination by game id without Player B
    function getActiveGamesWithoutPlayerB(
        uint256 from,
        uint256 to
    ) public view returns (GameData[] memory) {
        GameData[] memory _gamesData = new GameData[](to - from);
        uint256 counter = 0;

        for (uint256 i = from; i <= to; i++) {
            (, address playerB) = getGamePlayersAddress(i);
            if (gamesData[i].active && playerB == address(0)) {
                _gamesData[counter] = getGameData(i);
                counter++;
            }
        }
        return _gamesData;
    }

    /// @dev return games data for pagination by game id in range
    function getGamesData(
        uint256 from,
        uint256 to
    ) public view returns (GameData[] memory) {
        GameData[] memory _gamesData = new GameData[](to + 1 - from);
        uint256 counter = 0;

        for (uint256 i = from; i <= to; i++) {
            _gamesData[counter] = getGameData(i);
            counter++;
        }

        return _gamesData;
    }

    /// @dev get game players address
    function getGamePlayersAddress(
        uint256 gameId
    ) public view returns (address playerA, address playerB) {
        GameData memory gameData = gamesData[gameId];
        playerA = gameData.playerA.playerAddress;
        playerB = gameData.playerB.playerAddress;

        return (playerA, playerB);
    }

    /// @dev return participant's moves of the game
    function getGamePlayersMoves(
        uint256 gameId
    ) public view returns (Moves moveA, Moves moveB) {
        return (gamesData[gameId].playerA.move, gamesData[gameId].playerB.move);
    }

    /// @dev return game stage
    function getGameStage(uint256 gameId) public view returns (Stages stage) {
        return gamesData[gameId].stage;
    }

    /// @dev return all data of the game
    function getGameData(uint256 gameId) public view returns (GameData memory) {
        return gamesData[gameId];
    }

    /// @dev return current game id (last created game)
    function getCurrentGameId() public view returns (uint256) {
        return gameIds;
    }

    /// @dev return game balance
    function getGameBalance(uint256 gameId) public view returns (uint256) {
        return (gamesData[gameId].gameBalance);
    }

    /// @dev return if game is active
    function isGameActive(uint256 gameId) public view virtual returns (bool) {
        return gamesData[gameId].active;
    }

    /// @dev return winner of the game
    function getWhoWon(
        uint256 gameId
    ) public view returns (WinnerOutcomes winner) {
        GameData memory game = gamesData[gameId];
        winner = _calcWinner(game.playerA.move, game.playerB.move);

        return winner;
    }

    /// --- Owner methods ---
    /// @dev set min bet amount
    function setMinBetAmount(uint256 _minBetAmount) public onlyOwner {
        if (_minBetAmount <= 0 wei) revert InvalidBetAmount();

        minBetAmount = _minBetAmount;

        emit MinBetValueSettled(_minBetAmount);
    }

    /// --- Owner methods ---
    /// @dev set owner
    function setOwner(address _owner) public onlyOwner {
        transferOwnership(_owner);
    }

    /**
     * @dev Contract owner initiate technical defeat by timeout.
     *
     * @param _gameIds array of game ids
     */
    function technicalDefeatOwner(
        uint256[] memory _gameIds
    ) external onlyOwner {
        for (uint256 i = 0; i < _gameIds.length; i++) {
            _technicalDefeat(_gameIds[i]);
        }
    }

    /**
     * @dev Set limit amount of game for user
     * @param newFee percent of fee for game
     */
    function setFee(uint256 newFee) public onlyOwner {

        fee = newFee;

        emit FeeAmountSettled(newFee);
    }

    /**
     * @dev Set current reveal time
     * @param newTime time of deadline for reveal
     */
    function setRevealTime(uint64 newTime) public onlyOwner {
        revealTime = newTime;
        emit RevealTimeSettled(revealTime);
    }

    function _safeTransferToken(
        address _currency,
        address _to,
        uint256 _amount
    ) private nonReentrant {
        if (_to == address(0)) revert ZeroAddress();
        IERC20(_currency).safeTransfer(_to, _amount);

        emit TokenTransferred(msg.sender, _to, _currency, _amount);
    }
}