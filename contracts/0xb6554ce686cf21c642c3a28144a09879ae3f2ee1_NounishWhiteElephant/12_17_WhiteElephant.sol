// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {WhiteElephantNFT} from "./WhiteElephantNFT.sol";

contract WhiteElephant {
    /// @dev when game already Exists
    error GameExists();
    /// @dev when msg.sender is not `currentParticipantTurn`
    error NotTurn();
    /// @dev when tokenID was not minted in game
    error InvalidTokenIDForGame();
    /// @dev when tokenID has already been stolen twice
    error MaxSteals();
    /// @dev when tokenID was just stolen
    error JustStolen();
    /// @dev when game is over
    error GameOver();

    event StartGame(bytes32 indexed gameID, Game game);
    event Open(bytes32 indexed gameID, address indexed player, uint256 indexed tokenId);
    event Steal(bytes32 indexed gameID, address indexed stealer, uint256 indexed tokenId, address stolenFrom);

    struct Game {
        /// @dev the addresses in this game, ordered how they should have turns
        address[] participants;
        /// @dev any unique value, probably timestamp best
        uint256 nonce;
    }

    // used to prevent stealing back immediately
    // cannot be stollen if curRound == round
    // and trying to steal lastStolenID
    struct LastStealInfo {
        // which NFT was last stole
        uint64 lastStolenID;
        uint8 round;
    }

    struct GameState {
        // starts at 0
        // for whose turn, use participants[round - 1]
        uint8 round;
        bool gameOver;
        // used to track who goes next after a steal
        address nextToGo;
        LastStealInfo lastStealInfo;
    }

    WhiteElephantNFT public nft;

    /// @notice how many times has a tokenID been stolen
    mapping(uint256 => uint256) public timesStolen;
    /// @notice what game a given tokenID was minted in
    mapping(uint256 => bytes32) public tokenGameID;
    mapping(bytes32 => GameState) internal _state;

    /// @notice starts a game
    /// @dev does not check participant addresses, address(0) or other incorrect
    /// address could render game unable to progress
    /// @dev reverts if `game` exists
    /// @param game Game specification, {participants: address[], nonce: uint256}
    /// @return _gameID the unique identifier for the game
    function startGame(Game calldata game) public payable virtual returns (bytes32 _gameID) {
        _gameID = gameID(game);

        if (_state[_gameID].round != 0) {
            revert GameExists();
        }

        _state[_gameID].round = 1;

        emit StartGame(_gameID, game);
    }

    /// @notice open a new gift
    /// @param game the game the participant caller is in and wishes to open in
    /// game = {participants: address[], nonce: uint256}
    function open(Game calldata game) public virtual {
        bytes32 _gameID = gameID(game);

        _checkGameOver(_gameID);

        _checkTurn(_gameID, game);

        uint8 newRoundCount = _state[_gameID].round + 1;
        _state[_gameID].round = newRoundCount;
        if (newRoundCount > game.participants.length) {
            _state[_gameID].gameOver = true;
        }

        _state[_gameID].nextToGo = address(0);

        uint256 tokenID = nft.mint(msg.sender);
        tokenGameID[tokenID] = _gameID;

        emit Open(_gameID, msg.sender, tokenID);
    }

    /// @notice Steals NFT from another participant
    /// @dev reverts if tokenID not minted in `game`
    /// @dev reverts if token has been stolen twice already
    /// @dev reverts if tokenID was just stolen
    /// @param game the game the participant is in and wishes to steal in
    /// game = {participants: address[], nonce: uint256}
    /// @param tokenID that token they wish to steal, must have been minted by another participant in same game
    function steal(Game calldata game, uint256 tokenID) public virtual {
        bytes32 _gameID = gameID(game);

        _checkGameOver(_gameID);

        _checkTurn(_gameID, game);

        if (_gameID != tokenGameID[tokenID]) {
            revert InvalidTokenIDForGame();
        }

        if (timesStolen[tokenID] == 2) {
            revert MaxSteals();
        }

        uint8 currentRound = _state[_gameID].round;
        if (_state[_gameID].round == _state[_gameID].lastStealInfo.round) {
            if (_state[_gameID].lastStealInfo.lastStolenID == tokenID) {
                revert JustStolen();
            }
        }

        timesStolen[tokenID] += 1;
        _state[_gameID].lastStealInfo = LastStealInfo({lastStolenID: uint64(tokenID), round: currentRound});

        address currentOwner = nft.ownerOf(tokenID);
        _state[_gameID].nextToGo = currentOwner;

        nft.steal(currentOwner, msg.sender, tokenID);

        emit Steal(_gameID, msg.sender, tokenID, currentOwner);
    }

    /// @notice returns the state of the given game ID
    /// @param _gameID the game identifier, from gameID(game)
    /// @return state the state of the game
    /// struct GameState {
    ///   uint8 round;
    ///   bool gameOver;
    ///   address nextToGo;
    ///    LastStealInfo lastStealInfo;
    /// }
    /// struct LastStealInfo {
    ///     uint64 lastStolenID;
    ///     uint8 round;
    /// }
    function state(bytes32 _gameID) public view virtual returns (GameState memory) {
        return _state[_gameID];
    }

    /// @notice returns which address can call open or steal next in a given game
    /// @param _gameID the id of the game
    /// @param game the game
    /// game = {participants: address[], nonce: uint256}
    /// @return participant the address that is up to go next
    function currentParticipantTurn(bytes32 _gameID, Game calldata game) public view virtual returns (address) {
        if (_state[_gameID].gameOver) {
            return address(0);
        }
        
        address next = _state[_gameID].nextToGo;
        if (next != address(0)) return next;

        return game.participants[_state[_gameID].round - 1];
    }

    /// @notice returns the unique identifier for a given game
    /// @param game, {participants: address[], nonce: uint256}
    /// @return gameID the id of the game
    function gameID(Game calldata game) public pure virtual returns (bytes32) {
        return keccak256(abi.encode(game));
    }

    function _checkTurn(bytes32 _gameID, Game calldata game) internal view {
        if (currentParticipantTurn(_gameID, game) != msg.sender) {
            revert NotTurn();
        }
    }

    function _checkGameOver(bytes32 _gameID) internal view {
        if (_state[_gameID].gameOver) {
            revert GameOver();
        }
    }
}