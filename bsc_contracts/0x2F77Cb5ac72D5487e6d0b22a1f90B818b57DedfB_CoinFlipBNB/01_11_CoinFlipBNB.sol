// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./external/gelato/OpsReady.sol";
import "./interfaces/ICoinFlipBNBRNG.sol";
import "./interfaces/IWETH.sol";

// contract that allows users to bet on a coin flip. RNG contract must be deployed first. 

contract CoinFlipBNB is Ownable, ReentrancyGuard, OpsReady {

    //----- Interfaces/Addresses -----

    ICoinFlipBNBRNG public CoinFlipBNBRNG;
    address CoinFlipBNBRNGAddress;
    address payable VRFSubscription;
    address payable devWallet;
    address public weth;

    //----- Mappings -----------------

    mapping(address => mapping(uint256 => Bet)) public Bets; // keeps track of each players bet for each sessionId
    mapping(address => mapping(uint256 => bool)) public HasBet; // keeps track of whether or not a user has bet in a certain session #
    mapping(address => mapping(uint256 => bool)) public HasClaimed; // keeps track of users and whether or not they have claimed reward for a session
    mapping(address => mapping(uint256 => bool)) public HasBeenRefunded; // keeps track of whether or not a user has been refunded for a particular session
    mapping(address => mapping(uint256 => uint256)) public PlayerRewardPerSession; // keeps track of player rewards per session
    mapping(address => mapping(uint256 => uint256)) public PlayerRefundPerSession; // keeps track of player refunds per session
    mapping(address => uint256) public TotalRewards; // a user's total collected payouts (lifetime)
    mapping(uint256 => Session) public _sessions; // mapping for session id to unlock corresponding session params
    mapping(address => bool) public Operators; // contract operators 
    mapping(address => uint256[]) public EnteredSessions; // list of session ID's that a particular address has bet in
    mapping(uint256 => bytes32) public settleTaskId;
   
    //----- Lottery State Variables ---------------

    uint32 private maxDuration = 21600;
    uint32 private minDuration = 0;
    uint128 public devFee = 500; // 500 = 5%
    uint32 public currentSessionId;
    uint256 public SEED_COST = 0.0025 ether;
    uint256 public AUTO_COST = .00025 ether;
    uint128 constant accuracyFactor = 1 * 10**12;
    bool public autoStartSessionEnabled = true; // automatic bool to determine whether or not new sessions start automatically when closeSession is called
    bool public autoSettle = true;

    //----- Default Parameters for Session -------

    uint32 private defaultLength = 60 minutes; 
    uint80 private defaultMaxBet = 100000 ether; 
    uint80 private defaultMinBet = .0001 ether; // > 0

    // status for betting sessions
    enum Status {
        Closed,
        Open,
        Standby,
        Voided,
        Claimable
    }

    // player bet
    struct Bet {
        address player;
        uint80 amount; 
        uint8 choice; // (0) heads or (1) tails;
    }
    
    // params for each bet session
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

    //----- Events --------------

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

    constructor(
        address _RNG,
        address payable _VRFSub,
        address payable _ops,
        address _weth
    ) OpsReady(_ops) {
        CoinFlipBNBRNGAddress = _RNG;
        CoinFlipBNBRNG = ICoinFlipBNBRNG(_RNG);
        VRFSubscription = _VRFSub;
        devWallet = payable(msg.sender);
        Operators[msg.sender] = true;
        Operators[_ops] = true;
        Operators[_RNG] = true;
        weth = _weth;
    }

    //---------------------------- MODIFIERS-------------------------

    // @dev: disallows contracts from entering
    modifier notContract() {
        require(!_isContract(msg.sender), "no contract");
        require(msg.sender == tx.origin, "no proxy");
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || Operators[msg.sender] , "Not owner or operator");
        _;
    }

    modifier onlyBNBRNG() {
        require(msg.sender == CoinFlipBNBRNGAddress, "Only BNB RNG allowed");
        _;
    }

    // @dev: returns the size of the code of an address. If > 0, address is a contract.
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    // ------------------- Setters/Getters ------------------------

    function setDefaultParams(uint32 _defaultLength, uint80 _defaultMinBet, uint80 _defaultMaxBet) external onlyOwner {
        require(_defaultLength >= minDuration && _defaultLength <= maxDuration , "Not within max/min time");
        require(_defaultMinBet > 0 , "Min bet must be > 0");
        defaultLength = _defaultLength;
        defaultMaxBet = _defaultMaxBet;
        defaultMinBet = _defaultMinBet;
    }

    // dev: set the address of the RNG contract interface
    function setCoinFlipBNBRNGAddress(address _address) external onlyOwner {
        CoinFlipBNBRNGAddress = _address;
        CoinFlipBNBRNG = ICoinFlipBNBRNG(_address);
        Operators[_address] = true;
    }

    function setVRFSubscription(address payable _address) external onlyOwner {
        VRFSubscription = _address;
    }

    function setWETH(address _weth) external onlyOwner {
        weth = _weth;
    }

    function setDevWallet(address _address) external onlyOwner {
        devWallet = payable(_address);
    }

    function setMaxMinDuration(uint32 _max, uint32 _min) external onlyOwner {
        maxDuration = _max;
        minDuration = _min;
    }

    function setAutoSessionStart(bool _bool) external onlyOwner {
        autoStartSessionEnabled = _bool;
    }

    function setAutoSettle(bool _bool) external onlyOwner {
        autoSettle = _bool;
    }

    function setCosts(uint256 _cost, uint256 _auto) external onlyOwner {
        SEED_COST = _cost;
        AUTO_COST = _auto;
    }

    function viewSessionById(uint256 _sessionId) external view returns (Session memory) {
        return _sessions[_sessionId];
    }

    function setDevFee(uint128 _devFee) external onlyOwner {
        require(_devFee > 99 && _devFee < 1001 , "fee must be between 1 and 10%");
        devFee = _devFee;
    }

    function setOperator(address _operator, bool _bool) external onlyOwner {
        Operators[_operator] = _bool;
    }

    function getEnteredSessionsLength(address _better) external view returns (uint256) {
        return EnteredSessions[_better].length;
    }

    function getBetHistory(address _better, uint256 _sessionId) external view returns 
    (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (Bets[_better][_sessionId].amount, 
                Bets[_better][_sessionId].choice,
                _sessions[_sessionId].startTime,
                _sessions[_sessionId].endTime,
                _sessions[_sessionId].headsBNB,
                _sessions[_sessionId].tailsBNB,
                _sessions[_sessionId].flipResult);
    }

    // ------------------- Coin Flip Function ----------------------

    // @dev: return 1 or 0
    function flipCoin() internal returns (uint8) {
        uint8 result = uint8(CoinFlipBNBRNG.flipCoin());
        _sessions[currentSessionId].status = Status.Standby;
        return result;
    }

    // ------------------- AutoSessionFxn ---------------------

    function autoStartSession() internal {
        require(autoStartSessionEnabled , "enable auto start");
        startSession(uint32(block.timestamp) + defaultLength, defaultMinBet, defaultMaxBet);
    }

    // ------------------- Start Session ---------------------- 

    function startSession(
        uint32 _endTime,
        uint80 _minBet,
        uint80 _maxBet) 
        public
        onlyOwnerOrOperator()
        {
        require(
            (currentSessionId == 0) || 
            (_sessions[currentSessionId].status == Status.Claimable) || 
            (_sessions[currentSessionId].status == Status.Voided),
            "Session must be closed, claimable, or voided"
        );

        require(
            ((_endTime - block.timestamp) >= minDuration) && ((_endTime - block.timestamp) <= maxDuration),
            "Session length outside of range"
        );

        
        currentSessionId++;

        _sessions[currentSessionId] = Session({
            status: Status.Open,
            sessionId: currentSessionId,
            startTime: uint32(block.timestamp),
            endTime: _endTime,
            minBet: _minBet,
            maxBet: _maxBet,
            headsCount: 0,
            tailsCount: 0,
            headsBNB: 0,
            tailsBNB: 0,
            collectedBNB: 0,
            BNBForDisbursal: 0,
            totalPayouts: 0,
            totalRefunds: 0,
            flipResult: 2 // init to 2 to avoid conflict with 0 (heads) or 1 (tails). is set to 0 or 1 later depending on coin flip result.
        });

        if(autoSettle) { startTask(currentSessionId); }
        
        emit SessionOpened(
            currentSessionId,
            block.timestamp,
            _endTime,
            _minBet,
            _maxBet
        );
    }

    // ------------------- Bet Function ----------------------

    // heads = 0, tails = 1
    function bet(uint128 _amount, uint8 _choice) external payable nonReentrant notContract() {
        require(msg.value == (_amount + SEED_COST + AUTO_COST), "invalid eth");
        require(_sessions[currentSessionId].status == Status.Open , "not open");
        require(_amount >= _sessions[currentSessionId].minBet && _amount <= _sessions[currentSessionId].maxBet , "Bet not within limits");
        require(_choice == 1 || _choice == 0, "0 or 1");
        require(!HasBet[msg.sender][currentSessionId] , "already bet");
        require(block.timestamp <= _sessions[currentSessionId].endTime, "Betting has ended!");
        
        if (_choice == 0) {
            Bets[msg.sender][currentSessionId].player = msg.sender;
            Bets[msg.sender][currentSessionId].amount = uint80(_amount);
            Bets[msg.sender][currentSessionId].choice = 0;
            _sessions[currentSessionId].headsCount++;
            _sessions[currentSessionId].headsBNB += _amount;
        } else {
            Bets[msg.sender][currentSessionId].player = msg.sender;
            Bets[msg.sender][currentSessionId].amount = uint80(_amount);
            Bets[msg.sender][currentSessionId].choice = 1;  
            _sessions[currentSessionId].tailsCount++;
            _sessions[currentSessionId].tailsBNB+= _amount;
        }

        _sessions[currentSessionId].collectedBNB += _amount;
        HasBet[msg.sender][currentSessionId] = true;
        EnteredSessions[msg.sender].push(currentSessionId);

        _safeTransferETHWithFallback(VRFSubscription, SEED_COST);
        
        emit BetPlaced(
            msg.sender,
            currentSessionId,
            _amount,
            _choice
        );
    }

    // --------------------- CLOSE SESSION -----------------

    function closeSession(uint256 _sessionId, bool shouldStopTask) external nonReentrant {
        require(_sessions[_sessionId].status == Status.Open , "Session must be open first");
        require(block.timestamp > _sessions[_sessionId].endTime, "Lottery not over");
        
        if (_sessions[_sessionId].headsCount == 0 || _sessions[_sessionId].tailsCount == 0) {
            _sessions[_sessionId].status = Status.Voided;
            if (autoStartSessionEnabled) {autoStartSession();}
            emit SessionVoided(
                _sessionId,
                block.timestamp,
                _sessions[_sessionId].headsCount,
                _sessions[_sessionId].tailsCount,
                _sessions[_sessionId].headsBNB,
                _sessions[_sessionId].tailsBNB,
                _sessions[_sessionId].collectedBNB
            );
        } else {
            CoinFlipBNBRNG.requestRandomWords(_sessionId);
            _sessions[_sessionId].status = Status.Closed;
            emit SessionClosed(
                _sessionId,
                block.timestamp,
                _sessions[_sessionId].headsCount,
                _sessions[_sessionId].tailsCount,
                _sessions[_sessionId].headsBNB,
                _sessions[_sessionId].tailsBNB,
                _sessions[_sessionId].collectedBNB
            );
        }

        if(shouldStopTask) { stopTask(settleTaskId[_sessionId]); }
    }

    // -------------------- Flip Coin & Announce Result ----------------

    function flipCoinAndMakeClaimable(uint32 _sessionId) external nonReentrant onlyOwnerOrOperator returns (uint8) {
        require(_sessionId <= currentSessionId , "Nonexistent session!");
        require(_sessions[_sessionId].status == Status.Closed , "Session must be closed first!");
        uint8 sessionFlipResult = flipCoin();
        _sessions[_sessionId].flipResult = sessionFlipResult;

        uint256 amountToDev;
        
        if (sessionFlipResult == 0) { // if heads wins
            _sessions[_sessionId].BNBForDisbursal = ((_sessions[_sessionId].tailsBNB) * (10000 - devFee)) / 10000;
            amountToDev = (_sessions[_sessionId].tailsBNB) - (_sessions[_sessionId].BNBForDisbursal);
        } else { // if tails..
            _sessions[_sessionId].BNBForDisbursal = ((_sessions[_sessionId].headsBNB) * (10000 - devFee)) / 10000;
            amountToDev = (_sessions[_sessionId].headsBNB) - (_sessions[_sessionId].BNBForDisbursal);
        }

        _safeTransferETHWithFallback(devWallet, amountToDev);     
        _sessions[_sessionId].status = Status.Claimable;
        emit CoinFlipped(_sessionId, sessionFlipResult);
        if (autoStartSessionEnabled) {autoStartSession();}
        return sessionFlipResult;
    }

    // -------------------- Automation Functions ----------------

    function startTask(uint256 _sessionId) internal {
        settleTaskId[_sessionId] = IOps(ops).createTaskNoPrepayment(
            address(this), 
            this.autoCloseSession.selector,
            address(this),
            abi.encodeWithSelector(this.canAutoCloseChecker.selector, _sessionId),
            ETH
        );
    }

    function canAutoCloseChecker(uint256 _sessionId) external view returns (bool canExec, bytes memory execPayload) {
        canExec = (_sessions[_sessionId].status == Status.Open && block.timestamp > _sessions[_sessionId].endTime);
        
        execPayload = abi.encodeWithSelector(
            this.autoCloseSession.selector,
            _sessionId
        );
    }

    function autoCloseSession(uint256 _sessionId) external onlyOps {
        require(_sessions[_sessionId].status == Status.Open , "Session must be open first");
        require(block.timestamp > _sessions[_sessionId].endTime, "Lottery not over");
        
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        _transfer(fee, feeToken);

        if (_sessions[_sessionId].headsCount == 0 || _sessions[_sessionId].tailsCount == 0) {
            _sessions[_sessionId].status = Status.Voided;
            if (autoStartSessionEnabled) {autoStartSession();}
            emit SessionVoided(
                _sessionId,
                block.timestamp,
                _sessions[_sessionId].headsCount,
                _sessions[_sessionId].tailsCount,
                _sessions[_sessionId].headsBNB,
                _sessions[_sessionId].tailsBNB,
                _sessions[_sessionId].collectedBNB
            );
        } else {
            CoinFlipBNBRNG.requestRandomWords(_sessionId);
            _sessions[_sessionId].status = Status.Closed;
            emit SessionClosed(
                _sessionId,
                block.timestamp,
                _sessions[_sessionId].headsCount,
                _sessions[_sessionId].tailsCount,
                _sessions[_sessionId].headsBNB,
                _sessions[_sessionId].tailsBNB,
                _sessions[_sessionId].collectedBNB
            );
        }

        stopTask(settleTaskId[_sessionId]);
    }

    function autoFlip(uint256 _sessionId, uint8 _flipResult) external nonReentrant onlyBNBRNG {
        require(_sessionId <= currentSessionId , "Nonexistent session!");
        require(_sessions[_sessionId].status == Status.Closed , "Session must be closed first!");
        require(_flipResult == 0 || _flipResult == 1, "Invalid result");

        _sessions[_sessionId].status = Status.Standby;
        _sessions[_sessionId].flipResult = _flipResult;

        uint256 amountToDev;

        if (_flipResult == 0) { // if heads wins
            _sessions[_sessionId].BNBForDisbursal = ((_sessions[_sessionId].tailsBNB) * (10000 - devFee)) / 10000;
            amountToDev = (_sessions[_sessionId].tailsBNB) - (_sessions[_sessionId].BNBForDisbursal);
        } else { // if tails..
            _sessions[_sessionId].BNBForDisbursal = ((_sessions[_sessionId].headsBNB) * (10000 - devFee)) / 10000;
            amountToDev = (_sessions[_sessionId].headsBNB) - (_sessions[_sessionId].BNBForDisbursal);
        }

        _safeTransferETHWithFallback(devWallet, amountToDev);     
        _sessions[_sessionId].status = Status.Claimable;
        emit CoinFlipped(_sessionId, _flipResult);
        if (autoStartSessionEnabled) {autoStartSession();}
    }

    function stopTask(bytes32 taskId) internal {
        IOps(ops).cancelTask(taskId);
    }

    function manualStopTask(bytes32 taskId) external onlyOwnerOrOperator {
        stopTask(taskId);
    }

    // ------------------ Claim Reward Function ---------------------

    function claimRewardPerSession(uint32 _sessionId) external nonReentrant notContract() {
        require(_sessions[_sessionId].status == Status.Claimable , "Session is not claimable!");
        require(HasBet[msg.sender][_sessionId] , "didn't bet in this session"); // make sure they've bet
        require(!HasClaimed[msg.sender][_sessionId] , "Already claimed"); // make sure they can't claim twice
        require(Bets[msg.sender][_sessionId].choice == _sessions[_sessionId].flipResult , "didn't win"); // make sure they won

            uint128 playerWeight;
            uint128 playerBet = Bets[msg.sender][_sessionId].amount; // how much a user bet

            if (_sessions[_sessionId].flipResult == 0) {
                playerWeight = (playerBet * accuracyFactor) / (_sessions[_sessionId].headsBNB); 
            } else if (_sessions[_sessionId].flipResult == 1) {
                playerWeight = (playerBet * accuracyFactor) / (_sessions[_sessionId].tailsBNB); 
            }

            uint128 payout = ((playerWeight * (_sessions[_sessionId].BNBForDisbursal)) / accuracyFactor) + playerBet;
            _safeTransferETHWithFallback(msg.sender, payout);    
            
            _sessions[_sessionId].totalPayouts += payout;
            PlayerRewardPerSession[msg.sender][_sessionId] = payout;
            TotalRewards[msg.sender] += payout;
            HasClaimed[msg.sender][_sessionId] = true;
            emit RewardClaimed(msg.sender, _sessionId, payout);   
    }

    // ------------------ Refund Fxn for Voided Sessions ----------------

    // sessions are voided if there isn't at least one tails bet and one heads bet. In this case, betters receive full refunds
    function claimRefundForVoidedSession(uint256 _sessionId) external nonReentrant notContract() {
        require(_sessions[_sessionId].status == Status.Voided , "session not voided");
        require(HasBet[msg.sender][_sessionId] , "didnt bet");
        require(PlayerRewardPerSession[msg.sender][_sessionId] == 0 && !HasBeenRefunded[msg.sender][_sessionId], "Already claimed reward/refund!"); 

        uint128 refundAmount = Bets[msg.sender][_sessionId].amount;
        _safeTransferETHWithFallback(msg.sender, refundAmount);    

        HasBeenRefunded[msg.sender][_sessionId] = true;
        PlayerRefundPerSession[msg.sender][_sessionId] += refundAmount;
        _sessions[_sessionId].totalRefunds += refundAmount;
        emit RefundClaimed(msg.sender, _sessionId, refundAmount); 

    }

    // ------------------ EMERGENCY VOID ----------------

    // emergency fxn to void a session immediately
    function emergencyVoid(bool _startNew) external onlyOwnerOrOperator() {
        require(_sessions[currentSessionId].status == Status.Open , "session must be open");
        _sessions[currentSessionId].status = Status.Voided;
        if (_startNew) {autoStartSession();}
        emit EmergencyVoid(uint80(block.timestamp), currentSessionId);
    }

    // ------------------ Read Fxn to Calculate Payout ------------------

    function calculatePayout(address _address, uint256 _sessionId) external view returns (uint256) {
        uint256 calculatedPayout;

        if (_sessions[_sessionId].status != Status.Claimable ||
            !HasBet[_address][_sessionId] ||
            Bets[_address][_sessionId].choice != _sessions[_sessionId].flipResult) {
            calculatedPayout = 0; 
            return calculatedPayout;
        } else {
            uint256 playerWeight;
            uint256 playerBet = Bets[_address][_sessionId].amount; // how much a user bet

            if (_sessions[_sessionId].flipResult == 0) {
                playerWeight = (playerBet * accuracyFactor) / (_sessions[_sessionId].headsBNB); 
            } else if (_sessions[_sessionId].flipResult == 1) {
                playerWeight = (playerBet * accuracyFactor) / (_sessions[_sessionId].tailsBNB); 
            }

            uint256 payout = ((playerWeight * (_sessions[_sessionId].BNBForDisbursal)) / accuracyFactor) + playerBet;
            return payout;
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    receive() external payable onlyOwnerOrOperator() {
        require(msg.value <= 0.1 ether , "too much BNB");
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {revert();}
}