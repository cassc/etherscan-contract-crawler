// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

/**
 * @title TwitterLuckyNum pragma erimental ABIEncoderV2
 * @author BinanceTiger
 */
contract TwitterLuckyNum is Ownable,Pausable,ReentrancyGuard{
    
    // Genesis Round Start Logo
    bool public genesisStartOnce = false;
    
    // adminAddress
    address public adminAddress;
    // operatorAddress
    address public operatorAddress;
    // The total amount of handling fees not turned over to the treasury
    uint256 public treasuryAmount;

    // currentEpoch
    uint256 public currentEpoch;

    // Information about each round,RoundNum => Round
    mapping(uint256 => Round) public rounds;
    // Player's play information and winning information for each round
    mapping(uint256 => mapping(address => PlayInfo)) public ledger;
    // Player's corresponding round information (which rounds have been played)
    mapping(address => uint256[]) public userRounds;

    // GlobalData
    GlobalData public globalData;

    // GlobalData
    struct GlobalData{
        // Calculate ratios
        uint256 tenThousandRate;
        // The minimum unit price 
        uint256 betUnitMinPrice;
        // Treasuryfee (e.g. 300=3%)
        uint256 treasuryfee;
        // Round time (12h),60*60*12 = globalData.singleRoundSeconds
        uint256 singleRoundSeconds;
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
        // TotalAmount
        uint256 roundTotalAmount;
        // Team Statistics
        RoundTeamsStatistics roundTeamsStatistics;
        // luckyNum(complete number)
        uint256 luckyNum;
        // luckyNum(last number)
        uint256 luckyNumLast;
        // winnerTeams
        Teams winnerTeams;
    }

    // Team Statistics
    struct RoundTeamsStatistics{
        uint256 rabbitAmount;
        uint256 zebraAmount;
        uint256 dogAmount;
        uint256 roosterAmount;
        uint256 foxAmount;
    }

    // Play record of each game
    struct PlayInfo{
        // Total bnb consumed
        uint256 consumeAmount;
        // The team selected
        Teams chooseTeam;
        // isClaimed
        bool isClaimed;
        // WinningAmount
        uint256 winningAmount;
    }

    // Teams
    enum Teams {
        Rabbit,
        Zebra,
        Dog,
        Rooster,
        Fox,
        Failed,
        UnPublished
    }

    event Pause(uint256 indexed epoch);
    event Unpause(uint256 indexed epoch);
    event TreasuryClaim(uint256 amount);
    event StartRound(uint256 indexed epoch);
    event NewOperatorAddress(address operator);
    event NewAdminAddress(address admin);
    event BetAnimal(address indexed sender, uint256 indexed epoch,uint256 teams, uint256 amount);
    event InjectContractBnb(uint256 amount);
    event BetEvent(address indexed sender, uint256 indexed epoch,uint256 reward);
    event ReturnEvent(address indexed sender, uint256 indexed epoch,uint256 reward);

    // Constructor
    constructor(
        address _adminAddress,
        address _operatorAddress
    ){
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        currentEpoch = 0;

        globalData.tenThousandRate = 10000;
        globalData.betUnitMinPrice = 5000000000000000; // 0.005BNB
        globalData.treasuryfee = 300;
        globalData.singleRoundSeconds = 43200;  // 30min=1800,12h=43200
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
     * @notice Start the creation round (this operation will set the current round and the next round to be a failed round)
     * Calling method: Pause the function and set genesisStartOnce to false, and then execute this function, set genesisStartOnce to true
    *  For example, in the 3rd round, if the genesis round is suspended again, the round will be increased by one, the current round will be voided, and the player's amount corresponding to the bet will be returned to the player.
     * @dev Callable by operator
     */
    function genesisStartRound(uint256 startTimestamp) external whenNotPaused onlyOperator {
        require(!genesisStartOnce, "Can only run genesisStartRound once");
        // The time set must be greater than the block time, and the past time cannot be set
        require(startTimestamp>block.timestamp,"The set time must be greater than the block time");

        if(currentEpoch == 0){
            // Genesis round, must be no data
            if(rounds[currentEpoch].startTimestamp == 0){
                // Start the current round
                _startRound(currentEpoch,startTimestamp);
                // Start the next round
                _startRound(currentEpoch+1,startTimestamp+globalData.singleRoundSeconds);
            }else{
                _genesisStartRoundInner(startTimestamp);
            }
        }else{
            _genesisStartRoundInner(startTimestamp);
        }

        genesisStartOnce = true;
        emit StartRound(currentEpoch);
    }

    /**
     * @notice The creation round starts, and the current round and the next round will be invalidated
     * @param startTimestamp:startTimestamp
     */
    function _genesisStartRoundInner(uint256 startTimestamp) internal {
        // No need for this round to end
        require(!rounds[currentEpoch].settlemented,"The previous round needs to end");
        // Don't need to end the next round
        require(!rounds[currentEpoch+1].settlemented,"The previous round needs to end");
        // The next round must be no data and no executeRound
        require(rounds[currentEpoch+2].startTimestamp == 0,"In the next next round, there must be no data");

        // Set the current round as a loser
        rounds[currentEpoch].winnerTeams = Teams.Failed;
        // Set the next turn as a loser
        rounds[currentEpoch+1].winnerTeams = Teams.Failed;

        currentEpoch = currentEpoch + 2;

        // Start the current round
        _startRound(currentEpoch,startTimestamp);
        // Start the next round
        _startRound(currentEpoch+1,startTimestamp+globalData.singleRoundSeconds);
    }

    /**
     * @notice Round X starts
     * @param epoch:epoch
     * @param startTimestamp:startTimestamp
     */
    function _startRound(uint256 epoch,uint256 startTimestamp) internal {
        Round storage round = rounds[epoch];
        round.epoch = epoch;
        round.startTimestamp = startTimestamp;
        round.closeTimestamp = startTimestamp+globalData.singleRoundSeconds -1;
        round.settlemented = false;
        round.luckyNum = 0;
        round.luckyNumLast = 0;
        round.winnerTeams = Teams.UnPublished;

        emit StartRound(epoch);
    }

    /**
     * 
     * @notice betAnimal
     * @param epoch:epoch
     * @param team:team
     */
    function betAnimal(uint256 epoch,uint256 team) external payable whenNotPaused nonReentrant notContract {
        require(epoch == currentEpoch || epoch == currentEpoch + 1 ,"Buy is too early/late");
        require(team <=4,"The team was chosen incorrectly");
        require(genesisStartOnce,"Can only run after genesisStartRound is triggered");
        // Can only bet before the current/next round starts && unsettled
        require(_bettable(epoch), "The Round not available");
        // You can only bet once in a round
        require(ledger[epoch][msg.sender].consumeAmount == 0,"You can only bet once per turn");
        // Minimum amount judgment
        require(msg.value >= globalData.betUnitMinPrice, "Buy amount must be greater than minBetAmount");

        uint256 amount = msg.value;

        // Update round data
        Round storage round = rounds[epoch];
        round.roundTotalAmount += amount;

        // Update user's round data
        PlayInfo storage playInfo = ledger[epoch][msg.sender];
        playInfo.consumeAmount += amount;

        // Team Statistics
        if(team == 0){
            playInfo.chooseTeam = Teams.Rabbit;
            round.roundTeamsStatistics.rabbitAmount += amount;
        }else if(team == 1){
            playInfo.chooseTeam = Teams.Zebra;
            round.roundTeamsStatistics.zebraAmount += amount;
        }else if(team == 2){
            playInfo.chooseTeam = Teams.Dog;
            round.roundTeamsStatistics.dogAmount += amount;
        }else if(team == 3){
            playInfo.chooseTeam = Teams.Rooster;
            round.roundTeamsStatistics.roosterAmount += amount;
        }else if(team == 4){
            playInfo.chooseTeam = Teams.Fox;
            round.roundTeamsStatistics.foxAmount += amount;
        }

        // Update player's play record
        userRounds[msg.sender].push(epoch);
        
        emit BetAnimal(msg.sender,epoch,team,amount);
    }
    
    /**
     * @notice Receive dividends after the round is over
     * @param epoch: epoch
     */
    function drawBonus(uint256 epoch) external nonReentrant notContract{
        // The round needs to end
        if (rounds[epoch].settlemented){
            // Have a play record
            if (ledger[epoch][msg.sender].consumeAmount > 0){
                // Selected team = round winning team
                if (ledger[epoch][msg.sender].chooseTeam == rounds[epoch].winnerTeams){
                    // unaccalimed
                    if (!ledger[epoch][msg.sender].isClaimed){
                        // Team revenue multiple = sum of all team bonuses / sum of team bonuses selected by players
                        uint256 reward = 0;

                        if(rounds[epoch].winnerTeams == Teams.Rabbit){
                            reward = ledger[epoch][msg.sender].consumeAmount * rounds[epoch].roundTotalAmount 
                                * (globalData.tenThousandRate - globalData.treasuryfee) / rounds[epoch].roundTeamsStatistics.rabbitAmount / globalData.tenThousandRate;
                        }else if(rounds[epoch].winnerTeams == Teams.Zebra){
                            reward = ledger[epoch][msg.sender].consumeAmount * rounds[epoch].roundTotalAmount  
                                * (globalData.tenThousandRate - globalData.treasuryfee) / rounds[epoch].roundTeamsStatistics.zebraAmount / globalData.tenThousandRate;
                        }else if(rounds[epoch].winnerTeams == Teams.Dog){
                            reward = ledger[epoch][msg.sender].consumeAmount * rounds[epoch].roundTotalAmount
                                * (globalData.tenThousandRate - globalData.treasuryfee) / rounds[epoch].roundTeamsStatistics.dogAmount / globalData.tenThousandRate;
                        }else if(rounds[epoch].winnerTeams == Teams.Rooster){
                            reward = ledger[epoch][msg.sender].consumeAmount * rounds[epoch].roundTotalAmount
                                * (globalData.tenThousandRate - globalData.treasuryfee) / rounds[epoch].roundTeamsStatistics.roosterAmount / globalData.tenThousandRate;
                        }else if(rounds[epoch].winnerTeams == Teams.Fox){
                            reward = ledger[epoch][msg.sender].consumeAmount * rounds[epoch].roundTotalAmount
                                * (globalData.tenThousandRate - globalData.treasuryfee) / rounds[epoch].roundTeamsStatistics.foxAmount / globalData.tenThousandRate;
                        }

                        if (reward > 0) {
                            ledger[epoch][msg.sender].isClaimed = true; // Set to claimed
                            ledger[epoch][msg.sender].winningAmount = reward; // Set to winningAmount
                            
                            _safeTransferBNB(address(msg.sender), reward);
                            emit BetEvent(msg.sender,epoch,reward);
                        }
                    }
                }
            }
        }else if(rounds[epoch].winnerTeams == Teams.Failed){
            // Have a play record
            if (ledger[epoch][msg.sender].consumeAmount > 0){
                // unaccalimed
                if (!ledger[epoch][msg.sender].isClaimed){
                    // Refund of the betting amount
                    uint256 reward = ledger[epoch][msg.sender].consumeAmount;
                    ledger[epoch][msg.sender].isClaimed = true; // Set to claimed
                    _safeTransferBNB(address(msg.sender), reward);
                    emit ReturnEvent(msg.sender,epoch,reward);
                }
            }
        }
    }

    /**
     * @notice Round settlement
     */
    function _calculateEndRound(uint256 luckyNum,uint256 luckyNumLast) internal {
        Round storage round = rounds[currentEpoch];

        // Settle and end the round
        round.luckyNum = luckyNum;
        round.luckyNumLast = luckyNumLast;
        round.settlemented = true;

        bool hasPlayer = true;

        // Winning team
        if(luckyNumLast == 0 || luckyNumLast == 1){
            round.winnerTeams = Teams.Rabbit;
            if(round.roundTeamsStatistics.rabbitAmount == 0){
                hasPlayer = false;
            }
        }else if(luckyNumLast == 2 || luckyNumLast == 3){
            round.winnerTeams = Teams.Zebra;
            if(round.roundTeamsStatistics.zebraAmount == 0){
                hasPlayer = false;
            }
        }else if(luckyNumLast == 4 || luckyNumLast == 5){
            round.winnerTeams = Teams.Dog;
            if(round.roundTeamsStatistics.dogAmount == 0){
                hasPlayer = false;
            }
        }else if(luckyNumLast == 6 || luckyNumLast == 7){
            round.winnerTeams = Teams.Rooster;
            if(round.roundTeamsStatistics.roosterAmount == 0){
                hasPlayer = false;
            }
        }else if(luckyNumLast == 8 || luckyNumLast == 9){
            round.winnerTeams = Teams.Fox;
            if(round.roundTeamsStatistics.foxAmount == 0){
                hasPlayer = false;
            }
        }

        if(hasPlayer){
            // Round Statistics
            uint256 _treasuryAmount = round.roundTotalAmount * globalData.treasuryfee / globalData.tenThousandRate;
            // Add up to treasuryfee 3%
            treasuryAmount += _treasuryAmount;
        }else{
            // If there is no one involved in the corresponding round, the amount will be turned over to the treasury
            treasuryAmount += round.roundTotalAmount;
        }
    }

    /** 
     * @notice Settle and start the next round
     * @dev Callable by operator
     * @param luckyNum: luckyNum
     * @param luckyNumLast: luckyNumLast
     */
    function executeRound(uint256 luckyNum, uint256 luckyNumLast) external whenNotPaused onlyOperator {
        // Increment currentEpoch to current round (n)
        require(genesisStartOnce,"Can only run after genesisStartRound is triggered");
        // Time check (settlement will be made after the round has ended)
        require(block.timestamp > rounds[currentEpoch].closeTimestamp,"The round is not over yet");
        // The start time of the next round needs to be greater than the current time, if not, you need to re-create the creation round
        require(block.timestamp < rounds[currentEpoch+1].closeTimestamp,"The data error,requires restart");
        // Duplicate settlement check
        require(!rounds[currentEpoch].settlemented,"The round has been settled");

        // Settle the current round
        _calculateEndRound(luckyNum,luckyNumLast);

        currentEpoch = currentEpoch + 1;

        // Start the next round
        _startRound(currentEpoch+1,rounds[currentEpoch].closeTimestamp+1);
    }

    /**
     *@notice To get the real-time multiplier of 5 teams, the front-end call needs to be divided by 1000000
     *@param epoch: epoch
     */
    function getTeamsMultiply(uint256 epoch) external view returns (uint256[] memory) {
        uint256[] memory data = new uint256[](5);

        if(rounds[epoch].roundTotalAmount == 0){
            return data;
        }else{
            if(rounds[epoch].roundTeamsStatistics.rabbitAmount == 0){
                data[0] = rounds[epoch].roundTotalAmount * 1000000 / globalData.betUnitMinPrice;
            }else{
                data[0] = rounds[epoch].roundTotalAmount * 1000000 / rounds[epoch].roundTeamsStatistics.rabbitAmount;
            }

            if(rounds[epoch].roundTeamsStatistics.zebraAmount == 0){
                data[1] = rounds[epoch].roundTotalAmount * 1000000 / globalData.betUnitMinPrice;
            }else{
                data[1] = rounds[epoch].roundTotalAmount * 1000000 / rounds[epoch].roundTeamsStatistics.zebraAmount;
            }
            
            if(rounds[epoch].roundTeamsStatistics.dogAmount == 0){
                data[2] = rounds[epoch].roundTotalAmount * 1000000 / globalData.betUnitMinPrice;
            }else{
                data[2] = rounds[epoch].roundTotalAmount * 1000000 / rounds[epoch].roundTeamsStatistics.dogAmount;
            }

            if(rounds[epoch].roundTeamsStatistics.roosterAmount == 0){
                data[3] = rounds[epoch].roundTotalAmount * 1000000 / globalData.betUnitMinPrice;
            }else{
                data[3] = rounds[epoch].roundTotalAmount * 1000000 / rounds[epoch].roundTeamsStatistics.roosterAmount;
            }

            if(rounds[epoch].roundTeamsStatistics.foxAmount == 0){
                data[4] = rounds[epoch].roundTotalAmount * 1000000 / globalData.betUnitMinPrice;
            }else{
                data[4] = rounds[epoch].roundTotalAmount * 1000000 / rounds[epoch].roundTeamsStatistics.foxAmount;
            }
            return data;
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
        returns (uint256[] memory,PlayInfo[] memory,uint256[] memory)
    {
        require(size>=1,"need size >=1");
        
        uint256 length = size;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        PlayInfo[] memory playInfo = new PlayInfo[](length);
        uint256[] memory winInfo = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 reward = 0;
            uint256 _userRound = userRounds[user][cursor + i];
            PlayInfo memory _playInfo = ledger[_userRound][user];

            values[i] = _userRound;
            playInfo[i] = _playInfo;

            if(_playInfo.consumeAmount!=0 && !_playInfo.isClaimed && rounds[_userRound].settlemented){
                if (_playInfo.chooseTeam == rounds[_userRound].winnerTeams){
                    if(rounds[_userRound].winnerTeams == Teams.Rabbit){
                        reward = _playInfo.consumeAmount * rounds[_userRound].roundTotalAmount 
                            * (globalData.tenThousandRate - globalData.treasuryfee) / globalData.tenThousandRate / rounds[_userRound].roundTeamsStatistics.rabbitAmount;
                    }else if(rounds[_userRound].winnerTeams == Teams.Zebra){
                        reward = _playInfo.consumeAmount * rounds[_userRound].roundTotalAmount 
                            * (globalData.tenThousandRate - globalData.treasuryfee) / globalData.tenThousandRate / rounds[_userRound].roundTeamsStatistics.zebraAmount;
                    }else if(rounds[_userRound].winnerTeams == Teams.Dog){
                        reward = _playInfo.consumeAmount * rounds[_userRound].roundTotalAmount 
                            * (globalData.tenThousandRate - globalData.treasuryfee) / globalData.tenThousandRate / rounds[_userRound].roundTeamsStatistics.dogAmount;
                    }else if(rounds[_userRound].winnerTeams == Teams.Rooster){
                        reward = _playInfo.consumeAmount * rounds[_userRound].roundTotalAmount 
                            * (globalData.tenThousandRate - globalData.treasuryfee) / globalData.tenThousandRate / rounds[_userRound].roundTeamsStatistics.roosterAmount;
                    }else if(rounds[_userRound].winnerTeams == Teams.Fox){
                        reward = _playInfo.consumeAmount * rounds[_userRound].roundTotalAmount 
                            * (globalData.tenThousandRate - globalData.treasuryfee) / globalData.tenThousandRate / rounds[_userRound].roundTeamsStatistics.foxAmount;
                    }
                }
            }else if(rounds[_userRound].winnerTeams == Teams.Failed){
                // Have a play record
                if (_playInfo.consumeAmount > 0){
                    // unaccalimed
                    if (!_playInfo.isClaimed){
                        // Refund of the betting amount
                        reward = _playInfo.consumeAmount;
                    }
                }
            }

            winInfo[i] = reward;
        }

        // In playInfo, there are [the amount of real-time dividends received and the number of airdrops received] Round has dividends after the round ends, first prize
        return (values,playInfo,winInfo);
    }

    /**
     * @notice Admin injects contract fees (for errors such as receiving fees)
     */
    function injectContractBnb() external payable nonReentrant notContract onlyAdmin{
        emit InjectContractBnb(msg.value);
    }

    /** 
     * @notice Pause the contract
     * @dev Callable by admin or operator
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
        // If the contract is suspended, the genesis round identifier will be reset. After the contract is suspended, the genesis function needs to be manually activated.
        genesisStartOnce = false;

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
            !rounds[epoch].settlemented &&
            rounds[epoch].winnerTeams != Teams.Failed &&
            block.timestamp < rounds[epoch].startTimestamp;
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