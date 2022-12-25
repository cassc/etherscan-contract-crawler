// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor()  {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

contract SZNGameV2 is Ownable, Operator {

    struct Game {
        uint gameId;
        address player1;
        address player2;
        address winner;
        bool canceled;
        uint bid;
        uint8 bidType;
        uint started;
        uint finished;
    }

    mapping(uint8 => uint) public _gameIds;
    mapping(uint => Game) public _games;

    mapping(uint8 => uint) public _bids;
    mapping(uint8 => uint) public _gameQueue;
    mapping(address => uint) public _walletGameIds;

    address public _sznAddress;

    event GameCreated(uint gameId, address player1);
    event GameStarted(uint gameId, address player1, address player2);

    constructor(address sznAddress)  {
        _sznAddress = sznAddress;
    }

    function myGame() external view returns (Game memory) {
        uint gameId = _walletGameIds[msg.sender];
        require(gameId != 0);
        return _games[gameId];
    }


    function connectGame(uint8 bidType) external {
        require(_walletGameIds[_msgSender()] == 0, "You already have a game");

        if (_bids[bidType] > 0) {
            ERC20(_sznAddress).transferFrom(_msgSender(), address(this), _bids[bidType]);
        }
        if (_gameQueue[bidType] != 0) {
            startGame(_gameQueue[bidType]);
        } else {
            _gameIds[bidType] += 1;
            createGame(_gameIds[bidType], bidType);
        }
    }

    function createGame(uint gameId, uint8 bidType) internal {
        _games[gameId].gameId = gameId;
        _games[gameId].bid = _bids[bidType];
        _games[gameId].player1 = _msgSender();
        _games[gameId].bidType = bidType;

        _walletGameIds[_msgSender()] = gameId;
        _gameQueue[bidType] = gameId;
        emit GameCreated(gameId, _games[gameId].player1);
    }

    function startGame(uint gameId) internal {
        _games[gameId].player2 = _msgSender();
        _games[gameId].started = block.number;

        _walletGameIds[_msgSender()] = gameId;
        _gameQueue[_games[gameId].bidType] = 0;
        emit GameStarted(gameId, _games[gameId].player1, _games[gameId].player2);
    }

    function cancelGameWaiting(uint gameId) external {
        checkGameCreated(gameId);
        require(_games[gameId].canceled == false, "Already cancelled");

        _games[gameId].canceled = true;
        _gameQueue[_games[gameId].bidType] = 0;
        _walletGameIds[_msgSender()] = 0;
        if (_games[gameId].bid > 0) {
            transferToken(_msgSender(), _games[gameId].bid);
        }
    }

    function endGame(uint gameId, address winner) external onlyOperator {
        if (_games[gameId].winner == address(0)) {
            checkGameActive(gameId);
            require(_games[gameId].player1 == winner || _games[gameId].player2 == winner);

            if (_games[gameId].bid > 0) {
                uint rewards = _games[gameId].bid * 2 * 3 / 4;
                uint burnRewards = _games[gameId].bid * 2 * 1 / 4;

                transferToken(winner, rewards);
                transferToken(address(0xdead), burnRewards);
            }
            finishGame(gameId, winner);
        }
    }

    function endDrawGame(uint gameId) external onlyOperator {
        if (_games[gameId].winner == address(0)) {

            checkGameActive(gameId);

            if (_games[gameId].bid > 0) {
                transferToken(_games[gameId].player1, _games[gameId].bid);
                transferToken(_games[gameId].player2, _games[gameId].bid);
            }

            finishGame(gameId, address(0xdead));
        }
    }

    function checkGameActive(uint gameId) internal {
        require(_games[gameId].started != 0);
        require(_games[gameId].finished == 0);
    }

    function checkGameCreated(uint gameId) internal {
        require(_games[gameId].started == 0);
        require(_games[gameId].player1 == _msgSender());
        require(_games[gameId].player2 == address(0));
    }

    function finishGame(uint gameId, address winner) internal {
        _games[gameId].finished = block.number;
        _games[gameId].winner = winner;

        _walletGameIds[_games[gameId].player1] = 0;
        _walletGameIds[_games[gameId].player2] = 0;
    }

    function transferToken(address to, uint tokens) internal {
        ERC20(_sznAddress).transfer(to, tokens);
    }

    function setBid(uint8 bidType, uint bid) external onlyOperator {
        require(bid > 0);
        _bids[bidType] = bid;
    }
}