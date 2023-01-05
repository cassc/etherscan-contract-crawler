// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./AggregatorV3Interface.sol";

/**
 * @title EscapeCryptoZoo pragma erimental ABIEncoderV2
 * @author BinanceTiger
 */
contract EscapeCryptoZoo is Ownable,Pausable,ReentrancyGuard{

    // BNB/USD
    AggregatorV3Interface public oracle;
    
    // Genesis Round Start
    bool public genesisStartOnce = false;
    
    // adminAddress
    address public adminAddress;
    // operatorAddress
    address public operatorAddress;
    // The total amount of handling fees not turned over to the treasury
    uint256 public treasuryAmount;

    // currentEpoch
    uint256 public currentEpoch;
    // The total amount of the airdrop prize pool, the airdrop prize pool is independent of the round
    uint256 public airDropAmount;
    // The probability of winning the airdrop is initially 0. Each time the total amount of meat purchased by a player is greater than 0.1BNB, the probability is +=0.5%
    uint256 public airDropProbability;

    // Information about each round,RoundNum => Round
    mapping(uint256 => Round) public rounds;
    // Player's play information and winning information for each round
    mapping(uint256 => mapping(address => PlayInfo)) public ledger;
    // The player epoch,round => player address
    mapping(uint256 => address[]) public roundPlayer;
    // Player's corresponding round information (which rounds have been played)
    mapping(address => uint256[]) public userRounds;

    // GlobalData
    GlobalData public globalData;

    // GlobalData
    struct GlobalData{
        // Calculate ratios
        uint256 tenThousandRate;
        // Treasuryfee (e.g. 300=3%)
        uint256 treasuryfee;
        // Round time (12h),60*60*12
        uint256 singleRoundSeconds;
        // Increases time per meat purchase
        uint256 addCountdownSeconds; // 15s
        // Bullet time to buy meat to increase time
        uint256 bulletTimeSeconds; // 2min
        // Airdrop increases probability
        uint256 airDropIncreases;

        // endRoundData
        // Last Winner bonus share ratio
        uint256 lastwinnerRate;
        // Community Fund Ratio
        uint256 communityfeeRate;
        // Team game rules information
        mapping (uint256 => TeamFee) teamFees;
        // AirDropData
        AirDropData airDropData;
    }

    // Team information
    struct TeamFee {
        // Real-time dividend ratio
        uint256 realTimeShareRate;
        // Inject bonus pool rate
        uint256 realTimePoolRate;
        // Dividend ratio after settlement
        uint256 winShareRate;
        // Inject bonus pool rate after settlement
        uint256 winPoolRate;
    }
    
    // AirDropData
    struct AirDropData {
        // Airdrop bonus share ratio
        uint256 airDropRate;   //10%
        // Minimum amount to participate in the airdrop lottery
        uint256 airDropJoinPrice;   //0.1BNB
        // Airdrop share ratio (0.1~1BNB)
        uint256 airDropShare10Rate;  //10%
        // Airdrop share ratio (1~10BNB)
        uint256 airDropShare30Rate;  //30%
        // Airdrop share ratio (10+BNB)
        uint256 airDropShare60Rate;  //60%
    }

    // Round data structure
    struct Round{
        // epoch
        uint256 epoch;
        // startTimestamp
        uint256 startTimestamp;
        // closeTimestamp
        uint256 closeTimestamp;
        // Is it officially settled
        bool settlemented;
        // Total meat in rounds
        uint256 roundMeatAmount;

        // Round Amount Statistics
        BonusStatistics bonusStatistics;
        // Team Statistics
        RoundTeamsStatistics roundTeamsStatistics;

        // After settlement, relevant core data after the round ends
        // WwinnerTeams
        Teams winnerTeams;
        // WinnerAddress
        address winnerAddress;
        // Total Jackpot Amount 47%
        uint256 roundWinLastWinAmount;
        // Community fund 3%
        uint256 roundWinCommunityFeeAmount;
        // The total amount of dividends for the winning team   40%/10%/25%
        uint256 roundWinFinalShareAmount;
        // The winning team will inject the total amount of the prize pool in the next round   10%/40%/25%
        uint256 roundWinNextRoundBonusAmount;
    }

    // Round Amount Statistics
    struct BonusStatistics{
        // Total amount of round 100%
        uint256 roundTotalAmount;
        // Handling fee amount 3%
        uint256 roundTreasuryFeeAmount;
        // Airdrop amount 10%
        uint256 roundAirDropAmount;
        // The total amount of the prize pool will be accumulated according to the selected team
        uint256 roundBonusAmount;
        // The total accumulated real-time dividend amount
        uint256 roundRealTimeShareAmount;
    }

    // Team Statistics
    struct RoundTeamsStatistics{
        // ShareAmount:Total team dividends
        // BonusAmount:Total team prize pool
        uint256 rabbitShareAmount;
        uint256 rabbitBonusAmount;
        uint256 zebraShareAmount;
        uint256 zebraBonusAmount;
        uint256 dogShareAmount;
        uint256 dogBonusAmount;
    }

    // Play record of each game
    struct PlayInfo{
        // Total bnb consumed
        uint256 consumeAmount;
        // Quantity of meat purchased
        uint256 buyMeatAmount;
        // The last team selected
        Teams chooseTeam;
        // The real-time dividend amount that has been claimed
        uint256 claimedRealTimeShareAmount;
        // The amount of real-time dividends that can be received
        uint256 canClaimRealTimeShareAmount;
        // The number of airdrop rewards, which can be accumulated and cleared after receiving
        uint256 airDropAmount;
        // The number of airdrops that have been claimed
        uint256 claimedAirDropAmount;
        // end about---
        // Whether the dividends after the round have been claimed
        bool isClaimedEndShare;
        // IsLastWinner
        bool isLastWinner;
        // IsClaimedLastBonus
        bool isClaimedLastBonus;
    }

    // Teams
    enum Teams {
        Rabbit,
        Zebra,
        Dog,
        UnPublished
    }

    event Pause(uint256 indexed epoch);
    event Unpause(uint256 indexed epoch);
    event TreasuryClaim(uint256 amount);
    event StartRound(uint256 indexed epoch);
    event NewOperatorAddress(address operator);
    event NewAdminAddress(address admin);
    event BuyMeat(address indexed sender, uint256 indexed epoch,uint256 meatQuantity, uint256 amount);
    event AirdropCalculate(address indexed sender,uint256 indexed epoch,uint256 rand,uint256 winNumber,uint256 winAirDropAmount);
    event InjectContractBnb(uint256 amount);
    event InjectAirDropBnb(uint256 amount);
    event InjectBonus(uint256 indexed epoch,uint256 amount);

    // Constructor
    constructor(
        address _adminAddress,
        address _operatorAddress
    ){
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        currentEpoch = 0;

        oracle = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);  // main

        // Rabbit
        globalData.teamFees[0] = TeamFee(6000,2700,4000,1000);
        // Zebra
        globalData.teamFees[1] = TeamFee(2700,6000,1000,4000);
        // Dog
        globalData.teamFees[2] = TeamFee(4350,4350,2500,2500);

        // airDropData
        globalData.airDropData.airDropRate = 1000;
        globalData.airDropData.airDropJoinPrice = 100000000000000000; // 0.1bnb
        globalData.airDropData.airDropShare10Rate = 1000;
        globalData.airDropData.airDropShare30Rate = 3000;
        globalData.airDropData.airDropShare60Rate = 6000;

        // globalData
        globalData.tenThousandRate = 10000;
        globalData.treasuryfee = 300;
        globalData.airDropIncreases = 50;
        
        globalData.singleRoundSeconds = 43200;  // 30min=1800,12h=43200
        globalData.addCountdownSeconds = 15;
        globalData.bulletTimeSeconds = 120;

        globalData.lastwinnerRate = 4700;
        globalData.communityfeeRate = 300;
    }

    // Admin operation permissions
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    // operator permissions
    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    // Non-Contract Verification Authority
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /** 
     * @notice Start genesis round
     * @dev Callable by admin or operator
     */
    function genesisStartRound(uint256 genesisStartTimeStamp) external whenNotPaused onlyOperator {
        require(!genesisStartOnce, "Can only run genesisStartRound once");
        require(genesisStartTimeStamp>block.timestamp, "The genesis startTimeStamp must be greater than blockTimestamp");
        _startRound(currentEpoch,0,genesisStartTimeStamp,Teams.UnPublished);
        genesisStartOnce = true;

        emit StartRound(currentEpoch);
    }

    /**
     * @notice Start the next round,the game generates the next round in the settlement.Previous before round must end
     * @param epoch:epoch
     * @param initBonusAmount:Bonus for round initiation
     * @param genesisStartTimeStamp:genesis startTimeStamp for round 0
     * @param winnerTeam:winnerTeam
     */
    function _startRound(uint256 epoch,uint256 initBonusAmount,uint256 genesisStartTimeStamp,Teams winnerTeam) internal {
        Round storage round = rounds[epoch];

        if(epoch == 0){ //First round warm-up time
            round.startTimestamp = genesisStartTimeStamp;
            round.closeTimestamp = genesisStartTimeStamp + globalData.singleRoundSeconds;
        }else{// After settlement, Start after 10 minutes
            round.startTimestamp = block.timestamp + 600;
            round.closeTimestamp = block.timestamp + 600 + globalData.singleRoundSeconds;
        }

        round.epoch = epoch;
        round.settlemented = false;
        round.roundMeatAmount = 0;
        
        if(epoch == 0){
            round.bonusStatistics = BonusStatistics(0,0,0,0,0);
            round.roundTeamsStatistics = RoundTeamsStatistics(0,0,0,0,0,0);
        }else{
            round.bonusStatistics = BonusStatistics(initBonusAmount,0,0,initBonusAmount,0);
            if(winnerTeam == Teams.Rabbit){
                round.roundTeamsStatistics = RoundTeamsStatistics(0,initBonusAmount,0,0,0,0);
            }else if(winnerTeam == Teams.Zebra){
                round.roundTeamsStatistics = RoundTeamsStatistics(0,0,0,initBonusAmount,0,0);
            }else if(winnerTeam == Teams.Dog){
                round.roundTeamsStatistics = RoundTeamsStatistics(0,0,0,0,0,initBonusAmount);
            }
        }

        round.winnerTeams = Teams.UnPublished;
        round.roundWinLastWinAmount = 0;
        round.roundWinCommunityFeeAmount = 0;
        round.roundWinFinalShareAmount = 0;
        round.roundWinNextRoundBonusAmount = 0;

        emit StartRound(epoch);
    }

    /**
     * @notice Query the unit price of meat(0.5USD)
     */
    function getMeatUnitPrice() public view returns (uint256){

        // Get the latest BNB/USD pair price
        (,int256 _oraclePrice,,,) = oracle.latestRoundData();

        // Calculation of BNB unit price(0.5USD)
        uint256 unitPrice = 1000000000000000000 / (uint256(_oraclePrice)/100000000) / 2;    
        
        return (unitPrice);
    }

    /**
     * @notice Query the total price of the purchased meat
     * @param meatQuantity:meatQuantity
     */
    function getBuyMeatTotalPrice(uint256 meatQuantity) public view returns (uint256){
        require(meatQuantity>=1, "The amount of meat needs to be greater than or equal to 1");

        uint256 _totalPrices = 0;
        uint256 _unitPirce = getMeatUnitPrice();

        _totalPrices = _unitPirce * meatQuantity;

        return (_totalPrices);
    }

    /**
     * @notice buyMeat
     * @param epoch:epoch
     * @param meatQuantity:meatQuantity
     * @param team:team
     */
    function buyMeat(uint256 epoch,uint256 meatQuantity,uint256 team) external payable whenNotPaused nonReentrant notContract {
        require(meatQuantity>=1, "The amount of meat needs to be greater than or equal to 1");
        require(epoch == currentEpoch, "Buy is too early/late");
        require(team <=2,"The team was chosen incorrectly");
        require(_bettable(epoch), "The Round not available");

        uint256 comparePriceMin = 0;
        uint256 amount = msg.value;

        comparePriceMin = getBuyMeatTotalPrice(meatQuantity);

        // Minimum Amount Validation
        require(amount>=comparePriceMin,"The payment amount is too low");

        // Update round data
        Round storage round = rounds[epoch];
        round.bonusStatistics.roundTotalAmount += amount;
        round.roundMeatAmount += meatQuantity;
        // The last player to buy meat is the last Winner
        round.winnerAddress = msg.sender;

        // Round Statistics
        uint256 _treasuryAmount = amount * globalData.treasuryfee / globalData.tenThousandRate;
        uint256 _airDropAmount = amount * globalData.airDropData.airDropRate / globalData.tenThousandRate;

        // Treasury Statistics for Fees   3%
        round.bonusStatistics.roundTreasuryFeeAmount += _treasuryAmount;
        // Round Airdrop (Statistics Only)  10%
        round.bonusStatistics.roundAirDropAmount += _airDropAmount;
        
        // Calculation of time difference
        uint256 timeDifference = round.closeTimestamp - block.timestamp;
        if(timeDifference>300){ // x>300
            if(timeDifference<(globalData.singleRoundSeconds-globalData.addCountdownSeconds)){//   x>300 && x<singleRoundSeconds-15
                round.closeTimestamp += globalData.addCountdownSeconds;
            }else{  // x>43185
                round.closeTimestamp += (globalData.singleRoundSeconds - timeDifference);// x>(singleRoundSeconds-15) + (max:15)
            }
        }else{  // <300s
            round.closeTimestamp += globalData.bulletTimeSeconds; 
        }

        // Global data adjustment
        // Fee 3%
        treasuryAmount += _treasuryAmount;
        // Total Airdrop Prize Pool 10%
        airDropAmount += _airDropAmount;

        // Update user's round data
        PlayInfo storage playInfo = ledger[epoch][msg.sender];
        playInfo.consumeAmount += amount;
        playInfo.buyMeatAmount += meatQuantity;

        uint256 realTimeBonus = 0;
        uint256 realTimeShareAmount = 0;

        if(team == 0){
            playInfo.chooseTeam = Teams.Rabbit;
            // Bonus pool injection after player buys meat  60%
            realTimeShareAmount = amount * globalData.teamFees[0].realTimeShareRate / globalData.tenThousandRate;
            // Real-time dividends after players buy meat    27%
            realTimeBonus = amount * globalData.teamFees[0].realTimePoolRate / globalData.tenThousandRate;
            // Team Statistics Accumulation
            round.roundTeamsStatistics.rabbitShareAmount += realTimeShareAmount;
            round.roundTeamsStatistics.rabbitBonusAmount += realTimeBonus;
            // The final winning team
            round.winnerTeams = Teams.Rabbit;
        }else if(team == 1){
            playInfo.chooseTeam = Teams.Zebra;
            // Bonus pool injection after player buys meat  27%
            realTimeShareAmount = amount * globalData.teamFees[1].realTimeShareRate / globalData.tenThousandRate;
            // Real-time dividends after players buy meat    60%
            realTimeBonus = amount * globalData.teamFees[1].realTimePoolRate / globalData.tenThousandRate;
            // Team Statistics Accumulation
            round.roundTeamsStatistics.zebraShareAmount += realTimeShareAmount;
            round.roundTeamsStatistics.zebraBonusAmount += realTimeBonus;
            // The final winning team
            round.winnerTeams = Teams.Zebra;
        }else if(team == 2){
            playInfo.chooseTeam = Teams.Dog;
            // Bonus pool injection after player buys meat  43.5%
            realTimeShareAmount = amount * globalData.teamFees[2].realTimePoolRate / globalData.tenThousandRate;
            // Real-time dividends after players buy meat    43.5%
            realTimeBonus = amount * globalData.teamFees[2].realTimePoolRate / globalData.tenThousandRate;
            // Team Statistics Accumulation
            round.roundTeamsStatistics.dogShareAmount += realTimeShareAmount;
            round.roundTeamsStatistics.dogBonusAmount += realTimeBonus;
            // The final winning team
            round.winnerTeams = Teams.Dog;
        }

        // The total prize pool of the round————the cumulative prize pool
        round.bonusStatistics.roundBonusAmount += realTimeBonus;
        // The total prize pool of the round————Real-time dividend accumulation
        round.bonusStatistics.roundRealTimeShareAmount += realTimeShareAmount;
        
        // Airdrop Calculations
        if(amount >= globalData.airDropData.airDropJoinPrice){
            _airdropCalculate(epoch,amount);
        }

        // Real-time dividends
        dividendsRealTime(epoch,realTimeShareAmount);
        
        // Update player's play record
        if(userRounds[msg.sender].length == 0){
            userRounds[msg.sender].push(epoch);
        }else{
            if (userRounds[msg.sender][userRounds[msg.sender].length-1] != currentEpoch){
                userRounds[msg.sender].push(epoch);
            }
        }
        
        emit BuyMeat(msg.sender, epoch, meatQuantity , amount);
    }

    /**
     * @notice Real-time dividends
     * @param epoch: epoch
     * @param realTimeShareAmount: realTimeShareAmount
     */
    function dividendsRealTime(uint256 epoch,uint256 realTimeShareAmount) internal {
        bool isPlayer = _isPlayer(epoch,msg.sender);
        address[] storage _address = roundPlayer[epoch];
        if(!isPlayer){
            _address.push(msg.sender);
        }

        for (uint256 index = 0; index < _address.length; index++) {
            address _tempAdr = _address[index];

            PlayInfo storage _playInfo = ledger[epoch][_tempAdr];
            _playInfo.canClaimRealTimeShareAmount += realTimeShareAmount * _playInfo.buyMeatAmount / rounds[epoch].roundMeatAmount;
        }
    }

    /**
     * @notice Judge whether there is a record in the corresponding round
     * @param epoch: epoch
     * @param adr: adr
     */
    function _isPlayer(uint256 epoch,address adr) internal view returns (bool) {
        address[] memory _address = roundPlayer[epoch];

        for (uint256 index = 0; index < _address.length; index++) {
            if (_address[index] == adr) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Airdrop calculation
     * @param epoch: epoch
     * @param amount: amount:The amount the player spent on purchases
     */
    function _airdropCalculate(uint256 epoch,uint256 amount) internal 
    {
        require(amount >= globalData.airDropData.airDropJoinPrice,"The amount is no enough");

        if(airDropProbability>0){
            // Generate random numbers that are sufficiently random 1~200
            uint256 _r1 = block.timestamp;
            uint256 _r2 = block.number;
            uint256 _r3 = uint256(uint256(keccak256(abi.encodePacked(block.coinbase))) / _r1);
            uint256 _r4 = uint256(uint256(keccak256(abi.encodePacked(msg.sender))) / _r1);
            
            uint256 rand = uint256(uint256(keccak256(abi.encodePacked(_r1,_r2,_r3,_r4))) % 199 ) + 1;            

            // Winning Numbers if airDropProbability = 5%,[1..200]
            uint256 winNumber = 200 * airDropProbability / globalData.tenThousandRate;
            // The winning amount
            uint256 winAirDropAmount = 0;

            if(rand <= winNumber){
                // Win the lottery, the probability is updated to 0
                airDropProbability = 0;

                // 0.1~1bnb
                if(amount>= globalData.airDropData.airDropJoinPrice && amount<1000000000000000000){
                    winAirDropAmount = airDropAmount * globalData.airDropData.airDropShare10Rate / globalData.tenThousandRate;
                }else if(amount>= 1000000000000000000 && amount<10000000000000000000){ //1~10bnb
                    winAirDropAmount = airDropAmount * globalData.airDropData.airDropShare30Rate / globalData.tenThousandRate;
                }else if(amount>= 10000000000000000000){ //10+bnb
                    winAirDropAmount = airDropAmount * globalData.airDropData.airDropShare60Rate / globalData.tenThousandRate;
                }

                // Update airdrop winning information
                PlayInfo storage playInfo = ledger[epoch][msg.sender];
                playInfo.airDropAmount += winAirDropAmount;
                airDropAmount -= winAirDropAmount;
            }else{
                // If you do not win the lottery, the system will add a 0.5% chance of winning
                airDropProbability += globalData.airDropIncreases;
            }

            emit AirdropCalculate(msg.sender, epoch, rand,winNumber,winAirDropAmount);
        }else{
            // If you do not win the lottery, the system will add a 0.5% chance of winning
            airDropProbability += globalData.airDropIncreases;
        }
    }

    /**
     * @notice Receive real-time dividends for rounds
     * @param epoch: epoch
     */
    function drawRealTimeShare(uint256 epoch) external nonReentrant notContract{
        uint256 reward = ledger[epoch][msg.sender].canClaimRealTimeShareAmount;
        if(reward > 0){
            // Have a play record
            if (ledger[epoch][msg.sender].consumeAmount > 0){
                ledger[epoch][msg.sender].claimedRealTimeShareAmount += reward;
                ledger[epoch][msg.sender].canClaimRealTimeShareAmount = 0;
                _safeTransferBNB(address(msg.sender), reward);
            }
        }
    }

    /**
     * @notice Claim Airdrop Bonus
     * @param epoch: epoch
     */
    function drawAirdropShare(uint256 epoch) external nonReentrant notContract{
        // Dividend amount
        uint256 reward = ledger[epoch][msg.sender].airDropAmount;
        // Have a play record
        if (ledger[epoch][msg.sender].consumeAmount > 0){
            // Have an airdrop balance to claim
            if (reward > 0) {
                // Blanking
                ledger[epoch][msg.sender].airDropAmount = 0;
                // accumulate
                ledger[epoch][msg.sender].claimedAirDropAmount += reward; 
                _safeTransferBNB(address(msg.sender), reward);
            }
        }
    }
    
    /**
     * @notice Receive dividends after the round is over
     * @param epoch: epoch
     */
    function drawFinalShare(uint256 epoch) external nonReentrant notContract{
        // The round needs to end
        if (rounds[epoch].settlemented){
            // Have a play record
            if (ledger[epoch][msg.sender].consumeAmount > 0){
                // unaccalimed
                if (!ledger[epoch][msg.sender].isClaimedEndShare){
                    // The amount of meat held / the total amount of meat * the bonus pool at the end of the round
                    uint256 reward = ledger[epoch][msg.sender].buyMeatAmount * rounds[epoch].roundWinFinalShareAmount / rounds[epoch].roundMeatAmount ;
                    if (reward > 0) {
                        ledger[epoch][msg.sender].isClaimedEndShare = true; // Set to claimed
                        _safeTransferBNB(address(msg.sender), reward);
                    }
                }
            }
        }
    }
    
    /**
     * @notice claim first prize
     * @param epoch: epoch
     */
    function drawFinalBonus(uint256 epoch) external nonReentrant notContract{
        // The round needs to end
        if (rounds[epoch].settlemented){
            // Have a play record
            if (ledger[epoch][msg.sender].consumeAmount > 0){
                // Won && not claimed
                if (ledger[epoch][msg.sender].isLastWinner && !ledger[epoch][msg.sender].isClaimedLastBonus){
                    // First Prize Amount
                    uint256 reward = rounds[epoch].roundWinLastWinAmount;
                    if (reward > 0) {
                        ledger[epoch][msg.sender].isClaimedLastBonus = true; // Set to claimed
                        _safeTransferBNB(address(msg.sender), reward);
                    }
                }
            }
        }
    }

    /** 
     * @notice Settle and start the next round
     * @dev Callable by operator
     */
    function executeRound() external whenNotPaused onlyOperator {
        // Increment currentEpoch to current round (n)
        require(genesisStartOnce,"Can only run after genesisStartRound is triggered");
        // Time check (settlement will be made after the round has ended)
        require(block.timestamp > rounds[currentEpoch].closeTimestamp,"The round is not over yet");
        // Duplicate settlement check
        require(!rounds[currentEpoch].settlemented,"The round has been settled");

        // Time resets if no one participates in the round
        if(rounds[currentEpoch].roundMeatAmount == 0){
            rounds[currentEpoch].closeTimestamp = block.timestamp + globalData.singleRoundSeconds;
        }else{
            // settlemented
            rounds[currentEpoch].settlemented = true;

            // lastWinner Amount = Prize Pool Amount * 47%
            rounds[currentEpoch].roundWinLastWinAmount = rounds[currentEpoch].bonusStatistics.roundBonusAmount * globalData.lastwinnerRate / globalData.tenThousandRate;
            // Community Fund 3%
            rounds[currentEpoch].roundWinCommunityFeeAmount = rounds[currentEpoch].bonusStatistics.roundBonusAmount * globalData.communityfeeRate / globalData.tenThousandRate;
            // Add up to treasuryfee
            treasuryAmount += rounds[currentEpoch].roundWinCommunityFeeAmount;

            uint256 _winShareRate = 0;
            uint256 _winPoolRate = 0;

            // Different team ratios
            if(rounds[currentEpoch].winnerTeams == Teams.Rabbit){
                _winShareRate = globalData.teamFees[0].winShareRate;    // 40%
                _winPoolRate = globalData.teamFees[0].winPoolRate;  // 10%
            }else if(rounds[currentEpoch].winnerTeams == Teams.Zebra){
                _winShareRate = globalData.teamFees[1].winShareRate;    // 10%
                _winPoolRate = globalData.teamFees[1].winPoolRate;  // 40%
            }else if(rounds[currentEpoch].winnerTeams == Teams.Dog){
                _winShareRate = globalData.teamFees[2].winShareRate;    // 25%
                _winPoolRate = globalData.teamFees[2].winPoolRate;  // 25%
            }

            // The total amount of dividends for the winning team
            rounds[currentEpoch].roundWinFinalShareAmount = rounds[currentEpoch].bonusStatistics.roundBonusAmount * _winShareRate / globalData.tenThousandRate;
            // The winning team will inject the total amount of the prize pool in the next round
            rounds[currentEpoch].roundWinNextRoundBonusAmount = rounds[currentEpoch].bonusStatistics.roundBonusAmount * _winPoolRate / globalData.tenThousandRate;

            // Update player profile
            ledger[currentEpoch][rounds[currentEpoch].winnerAddress].isLastWinner = true;

            // Start a new round
            currentEpoch += 1;
            _startRound(currentEpoch,rounds[currentEpoch-1].roundWinNextRoundBonusAmount,0,rounds[currentEpoch-1].winnerTeams);
        }
    }

    /**
     * @notice Returns round epochs length
     * @param user: user address
     */
    function getUserRoundsLength(address user) external view returns (uint256) {
        return userRounds[user].length;
    }

    /**
     * @notice Returns the round play information and winning information that the user has participated in
     * @param user: user address
     * @param cursor: cursor 
     * @param size: size
     */
    function getUserRounds(address user,uint256 cursor,uint256 size) external view 
        returns (uint256[] memory,PlayInfo[] memory,uint256[3][] memory)
    {
        uint256 length = size;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        PlayInfo[] memory playInfo = new PlayInfo[](length);
        uint256[3][] memory winInfo = new uint256[3][](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor + i];
            playInfo[i] = ledger[values[i]][user];
            
            uint256 rewardRealTimeShare = 0;
            if(playInfo[i].buyMeatAmount!=0 && rounds[values[i]].roundMeatAmount!=0 && rounds[values[i]].bonusStatistics.roundRealTimeShareAmount!=0){
                if(playInfo[i].canClaimRealTimeShareAmount>0){
                    rewardRealTimeShare = playInfo[i].canClaimRealTimeShareAmount;
                }
            }

            // 2、Airdrop amount (distributed)
            uint256 rewardAirdrop = playInfo[i].airDropAmount;

            // 3、Omit.. First prize amount (in round)

            // 4、Dividends after the round ends (distributed)
            uint256 rewardFinalBouns = 0;
            if(playInfo[i].buyMeatAmount!=0 && rounds[values[i]].roundMeatAmount!=0 && rounds[values[i]].roundWinFinalShareAmount!=0){
                rewardFinalBouns = playInfo[i].buyMeatAmount * rounds[values[i]].roundWinFinalShareAmount / rounds[values[i]].roundMeatAmount;
            }
            
            winInfo[i][0] = rewardRealTimeShare;
            winInfo[i][1] = rewardAirdrop;
            winInfo[i][2] = rewardFinalBouns;
        }

        // In playInfo, there are [the amount of real-time dividends received and the number of airdrops received] Round has dividends after the round ends, first prize
        return (values,playInfo,winInfo);
    }

    /**
     * @notice Admin injects contract fees (for errors such as receiving fees)
     */
    function injectContractBnb() external payable nonReentrant notContract onlyAdmin {
        emit InjectContractBnb(msg.value);
    }

    /**
     * @notice Admin injects airdrop fee
     */
    function injectAirDropBnb() external payable nonReentrant notContract onlyAdmin {
        airDropAmount += msg.value;
        emit InjectAirDropBnb(msg.value);
    }

    /**
     * @notice Admin injects zebra bonus
     * @param epoch: epoch
     */
    function injectBonus(uint256 epoch) external payable nonReentrant notContract onlyAdmin {
        require(epoch == currentEpoch, "inject is too early/late");
        require(rounds[epoch].startTimestamp != 0 && rounds[epoch].closeTimestamp != 0 && block.timestamp < rounds[epoch].closeTimestamp, "The Round not available");

        uint256 amount = msg.value;

        Round storage round = rounds[epoch];
        round.bonusStatistics.roundTotalAmount += amount;
        round.bonusStatistics.roundBonusAmount += amount;
        round.roundTeamsStatistics.zebraBonusAmount += amount;
        
        emit InjectBonus(epoch,msg.value);
    }

    /** 
     * @notice Pause the contract
     * @dev Callable by admin
     */
    function pause() external whenNotPaused onlyAdmin {
        _pause();
        emit Pause(currentEpoch);
    }

    /** 
     * @notice called by the admin to unpause, returns to normal state
     * Resume the contract Reset the end time according to the remaining time (compensate for the time of one round)
     * Once the contract is started, it cannot be really stopped, and the suspension is only used for system maintenance
     */
    function unpause() external whenPaused onlyAdmin {
        _unpause();
        emit Unpause(currentEpoch);
    }

    /** 
     * @notice Time validity verification, contract function requests must be made within the start time and end time
     * Round must have started and locked
     */
    function _bettable(uint256 epoch) internal view returns (bool) {
        return
            rounds[epoch].startTimestamp != 0 &&
            rounds[epoch].closeTimestamp != 0 &&
            block.timestamp > rounds[epoch].startTimestamp &&
            block.timestamp < rounds[epoch].closeTimestamp;
    }

    /** 
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        _safeTransferBNB(adminAddress, currentTreasuryAmount);

        emit TreasuryClaim(currentTreasuryAmount);
    }

    /** 
     * @notice Transfer BNB in a safe way
     * @param to: address to transfer BNB to
     * @param value: BNB amount to transfer (in wei)
     */
    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: BNB_TRANSFER_FAILED");
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperator(address operatorAddressArg) external onlyAdmin {
        require(operatorAddressArg != address(0), "Cannot be zero address");
        operatorAddress = operatorAddressArg;

        emit NewOperatorAddress(operatorAddressArg);
    }

    /**
     * @notice Set admin address
     * @dev Callable by owner
     */
    function setAdmin(address adminAddressArg) external onlyOwner {
        require(adminAddressArg != address(0), "Cannot be zero address");
        adminAddress = adminAddressArg;

        emit NewAdminAddress(adminAddressArg);
    }

    /** 
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}