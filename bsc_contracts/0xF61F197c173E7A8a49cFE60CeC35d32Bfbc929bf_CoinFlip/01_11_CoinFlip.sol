// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./external/gelato/OpsReady.sol";
import "./interfaces/ICoinFlipRNG.sol";
import "./interfaces/IApple.sol";

// contract that allows users to bet on a coin flip. RNG contract must be deployed first. 

contract CoinFlip is Ownable, ReentrancyGuard, OpsReady {

    //----- Interfaces/Addresses -----

    ICoinFlipRNG public CoinFlipRNG;
    IApple public AppleInterface;
    address CoinFlipRNGAddress;
    address payable VRFSubscription;
    address payable devWallet;

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
    uint32 private minDuration = 600;
    uint128 public burnFee = 500; // 500 = 5%
    uint32 public currentSessionId;
    uint256 public SEED_COST = 0.00025 ether;
    uint256 public DEV_FEE = .0005 ether;
    uint256 public AUTO_COST = .00025 ether;
    uint128 constant accuracyFactor = 1 * 10**12;
    bool public autoStartSessionEnabled = true; // automatic bool to determine whether or not new sessions start automatically when closeSession is called
    bool public autoSettle = true;
    uint256 public totalAppleBurned;

    //----- Default Parameters for Session -------

    uint32 private defaultLength = 30 minutes; // in SECONDS
    uint80 private defaultMaxBet = 1000000 ether; 
    uint80 private defaultMinBet = 1 ether; // > 0

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
        uint128 headsApple;
        uint128 tailsApple;
        uint128 collectedApple;
        uint128 appleForDisbursal;
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
        uint256 headsApple,
        uint256 tailsApple,
        uint256 collectedApple
    );

    event SessionVoided(
        uint256 indexed sessionId,
        uint256 endTime,
        uint256 headsCount,
        uint256 tailsCount,
        uint256 headsApple,
        uint256 tailsApple,
        uint256 collectedApple
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

    constructor(
        address _RNG,
        address payable _VRFSub,
        address _Apple,
        address payable _ops
    ) OpsReady(_ops) {
        AppleInterface = IApple(_Apple);
        CoinFlipRNGAddress = _RNG;
        CoinFlipRNG = ICoinFlipRNG(_RNG);
        VRFSubscription = _VRFSub;
        devWallet = payable(msg.sender);
        Operators[msg.sender] = true;
        Operators[_ops] = true;
        Operators[_RNG] = true;
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

    modifier onlyRNG() {
        require(msg.sender == CoinFlipRNGAddress, "Only RNG allowed");
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

    function setDefaultParams(uint32 _defaultLength, uint80 _defaultMaxBet, uint80 _defaultMinBet) external onlyOwner {
        require(_defaultLength >= minDuration && _defaultLength <= maxDuration , "Not within max/min time");
        require(_defaultMinBet > 0 , "Min bet must be > 0");
        defaultLength = _defaultLength;
        defaultMaxBet = _defaultMaxBet;
        defaultMinBet = _defaultMinBet;
    }

    // dev: set the address of the RNG contract interface
    function setCoinFlipRNGAddress(address _address) external onlyOwner {
        CoinFlipRNGAddress = _address;
        CoinFlipRNG = ICoinFlipRNG(_address);
        Operators[_address] = true;
    }

    function setVRFSubscription(address payable _address) external onlyOwner {
        VRFSubscription = _address;
    }

    function setApple(address _address) external onlyOwner {
        AppleInterface = IApple(_address);
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

    function setSeedAndDevCost(uint256 _cost, uint256 _auto, uint256 _fee) external onlyOwner {
        SEED_COST = _cost;
        AUTO_COST = _auto;
        DEV_FEE = _fee;
    }

    function rescueBNB(uint256 _amount) external onlyOwner {
        devWallet.transfer(_amount);
    }
    
    function viewSessionById(uint256 _sessionId) external view returns (Session memory) {
        return _sessions[_sessionId];
    }

    function setBurnFee(uint128 _burnFee) external onlyOwner {
        require(_burnFee > 99 && _burnFee < 1001 , "fee must be between 1 and 10%");
        burnFee = _burnFee;
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
                _sessions[_sessionId].headsApple,
                _sessions[_sessionId].tailsApple,
                _sessions[_sessionId].flipResult);
    }

    // ------------------- Coin Flip Function ----------------------

    // @dev: return 1 or 0
    function flipCoin() internal returns (uint8) {
        uint8 result = uint8(CoinFlipRNG.flipCoin());
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
            headsApple: 0,
            tailsApple: 0,
            collectedApple: 0,
            appleForDisbursal: 0,
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
        require(msg.value == DEV_FEE + SEED_COST + AUTO_COST , "invalid eth");
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
            _sessions[currentSessionId].headsApple += _amount;
        } else {
            Bets[msg.sender][currentSessionId].player = msg.sender;
            Bets[msg.sender][currentSessionId].amount = uint80(_amount);
            Bets[msg.sender][currentSessionId].choice = 1;  
            _sessions[currentSessionId].tailsCount++;
            _sessions[currentSessionId].tailsApple += _amount;
        }

        AppleInterface.burnFrom(msg.sender, _amount);
        _sessions[currentSessionId].collectedApple += _amount;
        HasBet[msg.sender][currentSessionId] = true;
        EnteredSessions[msg.sender].push(currentSessionId);
        devWallet.transfer(DEV_FEE);
        VRFSubscription.transfer(SEED_COST);

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
                _sessions[_sessionId].headsApple,
                _sessions[_sessionId].tailsApple,
                _sessions[_sessionId].collectedApple
            );
        } else {
            CoinFlipRNG.requestRandomWords(_sessionId);
            _sessions[_sessionId].status = Status.Closed;
            emit SessionClosed(
                _sessionId,
                block.timestamp,
                _sessions[_sessionId].headsCount,
                _sessions[_sessionId].tailsCount,
                _sessions[_sessionId].headsApple,
                _sessions[_sessionId].tailsApple,
                _sessions[_sessionId].collectedApple
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

        uint256 amountToBurn;
        // @dev: collectedApple = sum of Heads and Tails apple bet for session
        // @dev: appleForDisbursal = apple getting minted out to winners
        if (sessionFlipResult == 0) { // if heads wins
            _sessions[_sessionId].appleForDisbursal = ((_sessions[_sessionId].tailsApple) * (10000 - burnFee)) / 10000;
            amountToBurn = (_sessions[_sessionId].tailsApple) - (_sessions[_sessionId].appleForDisbursal);
        } else { // if tails..
            _sessions[_sessionId].appleForDisbursal = ((_sessions[_sessionId].headsApple) * (10000 - burnFee)) / 10000;
            amountToBurn = (_sessions[_sessionId].headsApple) - (_sessions[_sessionId].appleForDisbursal);
        }

        totalAppleBurned += amountToBurn;
                
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
                _sessions[_sessionId].headsApple,
                _sessions[_sessionId].tailsApple,
                _sessions[_sessionId].collectedApple
            );
        } else {
            CoinFlipRNG.requestRandomWords(_sessionId);
            _sessions[_sessionId].status = Status.Closed;
            emit SessionClosed(
                _sessionId,
                block.timestamp,
                _sessions[_sessionId].headsCount,
                _sessions[_sessionId].tailsCount,
                _sessions[_sessionId].headsApple,
                _sessions[_sessionId].tailsApple,
                _sessions[_sessionId].collectedApple
            );
        }

        stopTask(settleTaskId[_sessionId]);
    }

    function autoFlip(uint256 _sessionId, uint8 _flipResult) external nonReentrant onlyRNG {
        require(_sessionId <= currentSessionId , "Nonexistent session!");
        require(_sessions[_sessionId].status == Status.Closed , "Session must be closed first!");
        require(_flipResult == 0 || _flipResult == 1, "Invalid result");

        _sessions[_sessionId].status = Status.Standby;
        _sessions[_sessionId].flipResult = _flipResult;

        uint256 amountToBurn;
        // @dev: collectedApple = sum of Heads and Tails apple bet for session
        // @dev: appleForDisbursal = apple getting minted out to winners
        if (_flipResult == 0) { // if heads wins
            _sessions[_sessionId].appleForDisbursal = ((_sessions[_sessionId].tailsApple) * (10000 - burnFee)) / 10000;
            amountToBurn = (_sessions[_sessionId].tailsApple) - (_sessions[_sessionId].appleForDisbursal);
        } else { // if tails..
            _sessions[_sessionId].appleForDisbursal = ((_sessions[_sessionId].headsApple) * (10000 - burnFee)) / 10000;
            amountToBurn = (_sessions[_sessionId].headsApple) - (_sessions[_sessionId].appleForDisbursal);
        }

        totalAppleBurned += amountToBurn;
                
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
                playerWeight = (playerBet * accuracyFactor) / (_sessions[_sessionId].headsApple); // ratio of adjusted winner bet amt. / all apple bet for session
            } else if (_sessions[_sessionId].flipResult == 1) {
                playerWeight = (playerBet * accuracyFactor) / (_sessions[_sessionId].tailsApple); // ratio of adjusted winner bet amt. / all apple bet for session
            }

            uint128 payout = ((playerWeight * (_sessions[_sessionId].appleForDisbursal)) / accuracyFactor) + playerBet;
            AppleInterface.mint(msg.sender, payout);
            
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
        AppleInterface.mint(msg.sender, refundAmount);

        HasBeenRefunded[msg.sender][_sessionId] = true;
        PlayerRefundPerSession[msg.sender][_sessionId] += refundAmount;
        _sessions[_sessionId].totalRefunds += refundAmount;
        emit RefundClaimed(msg.sender, _sessionId, refundAmount); 

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
                playerWeight = (playerBet * accuracyFactor) / (_sessions[_sessionId].headsApple); // ratio of adjusted winner bet amt. / sum of all winning heads bets
            } else if (_sessions[_sessionId].flipResult == 1) {
                playerWeight = (playerBet * accuracyFactor) / (_sessions[_sessionId].tailsApple); // ratio of adjusted winner bet amt. / sum of all winning tails bets
            }

            uint256 payout = ((playerWeight * (_sessions[_sessionId].appleForDisbursal)) / accuracyFactor) + playerBet;
            return payout;
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}