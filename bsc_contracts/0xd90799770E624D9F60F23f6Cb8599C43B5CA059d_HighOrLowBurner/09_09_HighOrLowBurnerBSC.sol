//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract HighOrLowBurner is Ownable, VRFConsumerBaseV2 {
    enum Direction {
        Under,
        Over
    }

    struct Fees {
        uint16 treasury;
        uint16 burn;
        uint16 swap;
    }

    struct Token {
        bool isActive;
        Fees fee;
        address router;
        address[] path;
        uint256 minBet;
        uint256 maxBet;
        uint256 swapValue;
        uint256 currentBalance;
    }

    struct Game {
        Direction direction; //0-under, 1-over
        uint8 rolledNumber;
        uint32 timestamp;
        address betToken;
        address player;
        uint256 betAmount;
        uint256 wonAmount;
    }

    mapping(address => Token) public tokenInfo;
    mapping(address => mapping(uint256 => Game)) public games;
    mapping(uint256 => Game) public idToGame;
    mapping(address => uint256) public totalPlayed;
    mapping(uint256 => uint256) internal requestToGame;

    uint8 public rollOver = 55;
    uint8 public rollUnder = 45;
    uint256 public gameId;

    address public treasury = 0x0Ba7D8d8A8B39c49215bc6EC45C8b0718593e466;
    address[] public activeTokens;

    /** BSC MAINNET */
    uint64 internal subscriptionId;
    VRFCoordinatorV2Interface internal coordinator;
    address internal vrfCoordinator = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
    bytes32 internal keyHash = 0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04;
    uint32 internal callbackGasLimit = 2500000;
    uint16 internal requestConfirmations = 3;
    uint32 internal numWords = 1;

    event DicePlayed(
        uint256 indexed gameId,
        address indexed player,
        address indexed token,
        uint256 amount,
        Direction direction,
        uint256 timestamp
    );
    event GameResult(
        uint256 indexed gameId,
        address indexed player,
        Direction direction,
        uint256 result,
        uint256 amount
    );

    constructor(uint64 _subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        subscriptionId = _subscriptionId;
        coordinator = VRFCoordinatorV2Interface(vrfCoordinator);

        address _token = 0x02678125Fb30d0fE77fc9D10Ea531f8b4348c603; //LVM
        address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //PCS ROUTER

        address[] memory _path = new address[](2);
        _path[0] = _token;
        _path[1] = IUniswapV2Router02(_router).WETH();

        tokenInfo[_token] = Token({
            isActive: true,
            fee: Fees({ treasury: 90, burn: 300, swap: 10 }),
            router: _router,
            path: _path,
            minBet: 1000 * 10 ** 9,
            maxBet: 20000 * 10 ** 9,
            swapValue: 50000 * 10 ** 9,
            currentBalance: 0
        });

        IERC20(_token).approve(_router, type(uint256).max);
        activeTokens.push(_token);
    }

    function setToken(
        address _token,
        bool _isActive,
        uint256 _swapValue,
        address _router,
        address[] memory _path,
        uint256 _minBet,
        uint256 _maxBet,
        Fees memory _fee
    ) external onlyOwner {
        Token storage tkn = tokenInfo[_token];

        if (_isActive) {
            if (!tkn.isActive) {
                IERC20(_token).approve(_router, type(uint256).max);
                activeTokens.push(_token);
            }
        } else {
            for (uint256 i = 0; i < activeTokens.length; i++) {
                if (activeTokens[i] == _token) {
                    activeTokens[i] = activeTokens[activeTokens.length - 1];
                    activeTokens.pop();
                }
            }
        }

        tkn.isActive = _isActive;
        tkn.swapValue = _swapValue;
        tkn.minBet = _minBet;
        tkn.maxBet = _maxBet;
        tkn.fee = _fee;
        tkn.router = _router;
        tkn.path = _path;
    }

    function setDiceInfo(uint8 _newOver, uint8 _newUnder) external onlyOwner {
        rollOver = _newOver;
        rollUnder = _newUnder;
    }

    function setChainlinkParams(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) external onlyOwner {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
    }

    function playDice(Direction _overOrUnder, address _token, uint256 _betAmount) external {
        Token memory tkn = tokenInfo[_token];
        Game storage game = idToGame[gameId];
        IERC20(_token).transferFrom(msg.sender, address(this), _betAmount);

        require(tkn.isActive, "Invalid playing token");
        require(_betAmount <= tkn.maxBet && _betAmount >= tkn.minBet, "Amount exceeds limit");
        require(
            IERC20(_token).balanceOf(address(this)) - tkn.currentBalance >= _betAmount * 2,
            "Not enough funds to payout win"
        );

        uint256 srequestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        requestToGame[srequestId] = gameId;

        game.player = msg.sender;
        game.betAmount = _betAmount;
        game.direction = _overOrUnder;
        game.betToken = _token;
        game.timestamp = uint32(block.timestamp);

        emit DicePlayed(gameId, msg.sender, _token, _betAmount, _overOrUnder, block.timestamp);

        gameId++;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 _gameId = requestToGame[requestId];
        Game storage game = idToGame[_gameId];
        Token storage tkn = tokenInfo[game.betToken];

        uint256 randomNum = randomWords[0] % 101;
        game.rolledNumber = uint8(randomNum);
        games[game.player][totalPlayed[game.player]] = Game(
            game.direction,
            game.rolledNumber,
            game.timestamp,
            game.betToken,
            game.player,
            game.betAmount,
            game.wonAmount
        );
        totalPlayed[game.player]++;

        if (
            (game.direction == Direction.Under && randomNum <= rollUnder) ||
            (game.direction == Direction.Over && randomNum >= rollOver)
        ) {
            game.wonAmount = game.betAmount * 2;
            games[game.player][totalPlayed[game.player]].wonAmount = game.wonAmount;
            IERC20(game.betToken).transfer(game.player, game.wonAmount);
        } else {
            IERC20 token = IERC20(game.betToken);
            uint256 amount = game.betAmount;

            uint256 treasuryFee = (amount * tkn.fee.treasury) / 1000;
            uint256 burnFee = (amount * tkn.fee.burn) / 1000;
            uint256 swapFee = (amount * tkn.fee.swap) / 1000;

            token.transfer(treasury, treasuryFee);
            token.transfer(address(0xdead), burnFee);
            tkn.currentBalance += swapFee;

            if (tkn.currentBalance >= tkn.swapValue) {
                IUniswapV2Router02 router = IUniswapV2Router02(tkn.router);
                router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    tkn.currentBalance,
                    0,
                    tkn.path,
                    treasury,
                    block.timestamp + 60
                );
                tkn.currentBalance = 0;
            }
        }

        emit GameResult(_gameId, game.player, game.direction, game.rolledNumber, game.wonAmount);
    }

    function rescueTokens(address _token, uint256 _amount) external onlyOwner {
        if (_token == address(0x0)) {
            payable(owner()).transfer(_amount);
            return;
        }
        IERC20 token = IERC20(_token);
        token.transfer(owner(), _amount);
    }

    function getActiveTokens() external view returns (address[] memory) {
        return activeTokens;
    }
}