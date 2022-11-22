// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ICoinFlipBNB {

    enum Status {
        Closed,
        Open,
        Standby,
        Voided,
        Claimable
    }

    struct Bet {
        address player;
        uint80 amount; 
        uint8 choice; // (0) heads or (1) tails;
    }

    struct Session {
        uint32 sessionId;
        uint32 startTime;
        uint32 endTime;
        uint80 minBet;
        uint80 maxBet;
        uint128 headsBNB;
        uint128 tailsBNB;
        uint128 collectedBNB;
        uint128 BNBForDisbursal;
        uint128 totalPayouts;
        uint128 totalRefunds;
        uint16 headsCount;
        uint16 tailsCount;
        uint8 flipResult;
        Status status;
    }

    event SessionOpened(
        uint256 indexed sessionId,
        uint256 startTime,
        uint256 endTime,
        uint256 minBet,
        uint256 maxBet
    );

    event BetPlaced(
        address indexed player, 
        uint256 indexed sessionId, 
        uint256 amount,
        uint8 choice
    );

    event SessionClosed(
        uint256 indexed sessionId, 
        uint256 endTime,
        uint256 headsCount,
        uint256 tailsCount,
        uint256 headsBNB,
        uint256 tailsBNB,
        uint256 collectedBNB
    );

    event SessionVoided(
        uint256 indexed sessionId,
        uint256 endTime,
        uint256 headsCount,
        uint256 tailsCount,
        uint256 headsBNB,
        uint256 tailsBNB,
        uint256 collectedBNB
    );

    event CoinFlipped(
        uint256 indexed sessionId,
        uint256 flipResult
    );

    event RewardClaimed(
        address indexed player,
        uint256 indexed sessionId,
        uint256 amount
    );

    event RefundClaimed(
        address indexed player,
        uint256 indexed sessionId,
        uint256 amount
    );

    event AppleBurned(
        uint256 indexed sessionId,
        uint256 amount
    );

    event Received(
        address indexed From, 
        uint256 Amount
    );

    event EmergencyVoid(
        uint80 timestamp,
        uint256 sessionId
    );

    function setDefaultParams(uint32 _defaultLength, uint80 _defaultMinBet, uint80 _defaultMaxBet) external;
    function setCoinFlipBNBRNGAddress(address _address) external;
    function setVRFSubscription(address payable _address) external;
    function setWETH(address _weth) external;
    function setDevWallet(address _address) external;
    function setMaxMinDuration(uint32 _max, uint32 _min) external;
    function setAutoSessionStart(bool _bool) external;
    function setAutoSettle(bool _bool) external;
    function setCosts(uint256 _cost, uint256 _auto) external;
    function viewSessionById(uint256 _sessionId) external view returns (Session memory);
    function setDevFee(uint128 _devFee) external;
    function setOperator(address _operator, bool _bool) external;
    function getEnteredSessionsLength(address _better) external view returns (uint256);
    function getBetHistory(address _better, uint256 _sessionId) external view returns 
    (uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function startSession(uint32 _endTime, uint80 _minBet, uint80 _maxBet) external;
    function bet(uint128 _amount, uint8 _choice) external payable;
    function closeSession(uint256 _sessionId, bool shouldStopTask) external;
    function flipCoinAndMakeClaimable(uint32 _sessionId) external returns (uint8);
    function canAutoCloseChecker(uint256 _sessionId) external view returns (bool canExec, bytes memory execPayload);
    function autoCloseSession(uint256 _sessionId) external;
    function autoFlip(uint256 _sessionId, uint8 _flipResult) external;
    function manualStopTask(bytes32 taskId) external;
    function claimRewardPerSession(uint32 _sessionId) external;
    function claimRefundForVoidedSession(uint256 _sessionId) external;
    function emergencyVoid(bool _startNew) external;
    function calculatePayout(address _address, uint256 _sessionId) external view returns (uint256);
    receive() external payable;
    fallback() external payable;
}