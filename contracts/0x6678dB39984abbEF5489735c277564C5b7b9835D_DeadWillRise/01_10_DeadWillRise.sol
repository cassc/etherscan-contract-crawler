// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "../delegatecash/IDelegationRegistry.sol";
import "../weth/IWETH.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";


/** Dead Will Rise presented by Gutter Punks
  * Contract by 0xth0mas (0xjustadev)
  * Gas optimization credit 0xDelco
*/

contract DeadWillRise is ERC721A, Ownable {

    event IndividualDailyActivity(uint256 tokenId, uint256 currentDay, uint256 riskChoice, uint256 activityOutcome);
    event IndividualCured(uint256 tokenId);
    event GroupDailyActivity(uint256 groupNum, uint256 currentDay, uint256 riskChoice, uint256 activityOutcome);
    event InfectionSpreading(uint256 currentProgress, uint256 infectionRate);
    event GroupRegistered(uint256 groupNum, address collectionAddress, address groupManager);
    event GroupTransferred(uint256 groupNum, address collectionAddress, address groupManager);

    struct IndividualData {
        uint32 lastBlock;
        uint32 lastScore;
        uint32 individualSeed;
        uint32 groupNumber;
        bool bitten; // potential outcome from an activity, when bitten individual score rate decreases substantially
    }

    struct GroupData {
        uint32 lastBlock;
        uint32 lastScore;
        uint32 groupSeed;
        uint32 totalMembers;
    }

    struct InfectionData {
        uint32 lastBlock;
        uint32 lastProgress;
        uint32 infectionRate; // rate that the infection progress will increase per block
    }

    struct ActivityRecord {
        uint32 riskChoice; // 1 = low risk, 2 = medium risk, 3 = high risk
        uint32 activityOutcome; // 1 = small reward, 2 = medium reward, 3 = large reward, 4 = devastation
    }

    uint256 public constant INDIVIDUAL_DAILY_ACTIVITY_COST = 0.001 ether;
    uint256 public constant GROUP_DAILY_ACTIVITY_COST = 0.01 ether;
    uint256 public constant GROUP_REGISTRATION_COST = 0.1 ether;
    uint256 public constant FINAL_CURE_COST = 10 ether;
    uint32 constant CURE_PROGRESS_INCREMENT = 72000;

    uint8 constant RISK_LEVEL_LOW = 1;
    uint8 constant RISK_LEVEL_MEDIUM = 2;
    uint8 constant RISK_LEVEL_HIGH = 3;
    uint8 constant ACTIVITY_OUTCOME_SMALL = 1;
    uint8 constant ACTIVITY_OUTCOME_MEDIUM = 2;
    uint8 constant ACTIVITY_OUTCOME_LARGE = 3;
    uint8 constant ACTIVITY_OUTCOME_DEVASTATED = 4;
    uint8 constant ACTIVITY_OUTCOME_CURED = 5;
    uint8 constant ACTIVITY_OUTCOME_STILL_A_ZOMBIE = 6;

    uint8 public constant MAX_DAY = 19;

    // Individuals will have a rate between 100-150 if unbitten, 25-37 if bitten
    uint32 constant INDIVIDUAL_BASE_RATE = 100;
    uint32 constant INDIVIDUAL_VARIABLE_RATE = 50;
    uint32 constant INDIVIDUAL_MAXIMUM_LUCK = 1000; // luck used to determine outcome of activities
    uint32 constant TOTAL_MAXIMUM_LUCK = 10000; // luck used to determine outcome of activities
    uint32 constant RISK_LOW_OUTCOME_LARGE = 9900;
    uint32 constant RISK_LOW_OUTCOME_MEDIUM = 9500;
    uint32 constant RISK_LOW_OUTCOME_SMALL = 100;
    uint32 constant RISK_MEDIUM_OUTCOME_LARGE = 9000;
    uint32 constant RISK_MEDIUM_OUTCOME_MEDIUM = 7500;
    uint32 constant RISK_MEDIUM_OUTCOME_SMALL = 1000;
    uint32 constant RISK_HIGH_OUTCOME_LARGE = 7500;
    uint32 constant RISK_HIGH_OUTCOME_MEDIUM = 5000;
    uint32 constant RISK_HIGH_OUTCOME_SMALL = 3300;
    uint32 constant RANDOM_CURE_CHANCE = 9500;
    uint32 constant INDIVIDUAL_REWARD_OUTCOME_LARGE = 360000;
    uint32 constant INDIVIDUAL_REWARD_OUTCOME_MEDIUM = 180000;
    uint32 constant INDIVIDUAL_REWARD_OUTCOME_SMALL = 72000;
    uint32 constant GROUP_REWARD_OUTCOME_LARGE = 36000;
    uint32 constant GROUP_REWARD_OUTCOME_MEDIUM = 18000;
    uint32 constant GROUP_REWARD_OUTCOME_SMALL = 3600;

    // Group scoring rate will increase by 1 for every 10th member that joins, 1 member = 1, 9 members = 1, 10 members = 2, 95 members = 10
    uint32 constant GROUP_BASE_RATE = 1;
    uint32 constant GROUP_VARIABLE_RATE = 10;
    uint32 constant GROUP_RATE_MULTIPLIER = 1;

    uint256 public constant MAX_SUPPLY = 5000;

    bool public eventOver;
    uint64 public eventStartTime;
    uint32 public eventStartBlock;

    uint32 public collectionSeed; // random seed set at start of game, collection seed == 0 means event not started
    uint32 public groupsRegistered; // current count of groups registered for Dead Will Rise

    bool public groupRegistrationOpen;
    bool public publicMintOpen;

    uint32 public maxPerWalletPerGroup = 1;
    uint32 public maxPerGroup = 500;
    uint32 public cureSupply = 500;

    uint32 public lastSurvivorTokenID; // declared at end of game
    uint32 public winningGroupNumber; // declared at end of game
    uint32 constant BLOCKS_PER_DAY = 7200;
    uint32 constant WITHDRAWAL_DELAY = 3600; // blocks to wait after winners declared for withdrawal
    uint32 constant LATE_JOINER_PROGRESS = 21600;

    InfectionData public infectionProgress; // current infection data - currentProgress = lastProgress + (block.number - lastBlock) * infectionRate
    mapping(address => uint256) public groupNumbers; // key = ERC-721 collection address, value = group number
    mapping(uint256 => address) public groupNumberToCollection; // key = group number, value = ERC-721 collection address
    mapping(uint256 => GroupData) public groupRecord; // key = group number, value = group data
    mapping(uint256 => address) public groupManager; // key = group number, value = current manager of group, will receive payout if group wins
    mapping(uint256 => ActivityRecord) public groupActivity; // key = groupNumber<<32 + day, value = activity results
    mapping(uint256 => IndividualData) public individualRecord; // key = tokenId, value = individual data
    mapping(uint256 => ActivityRecord) public individualActivity; // key = tokenId<<32 + day, value = activity results

    mapping(uint256 => uint256) public mintCount; // key = account<<32 + groupNumber, value = # minted

    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IDelegationRegistry delegateCash = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    string internal _baseTokenURI;
    string internal _placeholderURI;
    string internal _contractURI;

    string public constant TOKEN_URI_SEPARATOR = "/";
    bool public includeStatsInURI = true;

    modifier eventInProgress() {
        require(collectionSeed > 0 && !eventOver);
        _;
    }

    modifier eventEnded() {
        require(eventOver);
        _;
    }

    modifier canWithdraw() {
        require(uint32(block.number) > (infectionProgress.lastBlock + WITHDRAWAL_DELAY));
        _;
    }

    constructor(string memory mContractURI, string memory mPlaceholderURI) ERC721A("Dead Will Rise", "DWR") {
        _contractURI = mContractURI;
        _placeholderURI = mPlaceholderURI;
    }

    // to receive royalties and/or donations
    receive() external payable { }
    fallback() external payable { }
    //unwrap WETH from any royalties paid in WETH
    function unwrapWETH() external onlyOwner {
        uint256 wethBalance = weth.balanceOf(address(this));
        weth.withdraw(wethBalance);
    }

    /** GAME MANAGEMENT FUNCTIONS
    */ 
    function startEvent(uint32 _infectionRate) external onlyOwner {
        require(collectionSeed == 0);
        eventStartTime = uint64(block.timestamp);
        collectionSeed = uint32(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))));
        infectionProgress.lastBlock = uint32(block.number);
        infectionProgress.infectionRate = _infectionRate;
        emit InfectionSpreading(infectionProgress.lastProgress, infectionProgress.infectionRate);
        eventStartBlock = uint32(block.number);
    }

    function endEvent() external onlyOwner eventInProgress {
        require(!eventOver);
        infectionProgress.lastProgress = this.currentInfectionProgress();
        infectionProgress.lastBlock = uint32(block.number);
        infectionProgress.infectionRate = 0;
        emit InfectionSpreading(infectionProgress.lastProgress, infectionProgress.infectionRate);
        eventOver = true;
    }

    function resumeEvent(uint32 _infectionRate) external onlyOwner eventEnded {
        require(eventOver);
        infectionProgress.lastProgress = this.currentInfectionProgress();
        infectionProgress.lastBlock = uint32(block.number);
        infectionProgress.infectionRate = _infectionRate;
        emit InfectionSpreading(infectionProgress.lastProgress, infectionProgress.infectionRate);
        eventOver = false;
    }

    function setInfectionRate(uint32 _infectionRate, uint32 _progressAdder) external onlyOwner eventInProgress {
        infectionProgress.lastProgress = this.currentInfectionProgress() + _progressAdder;
        infectionProgress.lastBlock = uint32(block.number);
        infectionProgress.infectionRate = _infectionRate;
        emit InfectionSpreading(infectionProgress.lastProgress, infectionProgress.infectionRate);
    }

    function setInfectionProgress(uint32 _infectionProgress) external onlyOwner {
        infectionProgress.lastProgress = _infectionProgress;
        emit InfectionSpreading(infectionProgress.lastProgress, infectionProgress.infectionRate);
    }

    /** Save gas vs iterating collection for winner by declaring winner and allow anyone to challenge that another token has a higher score
        Winner can be declared after event has ended but withdrawals are delayed until 12 hours after event ends to allow for challenges
        In the event of a tie, first to declare wins... because this is an apocalypse and you have to be ready.
    */
    function declareLastSurvivor(uint256 tokenId) external eventEnded {
        uint256 _currentTokenID = lastSurvivorTokenID;
        if(_currentTokenID == 0 || this.getIndividualScore(tokenId) > this.getIndividualScore(_currentTokenID)) {
            lastSurvivorTokenID = uint32(tokenId);
        } else {
            revert();
        }
    }

    /** Save gas vs iterating groups for winner by declaring winner and allow anyone to challenge that another group has a higher score
        Winner can be declared after event has ended but withdrawals are delayed until 12 hours after event ends to allow for challenges
        In the event of a tie, first to declare wins... because this is an apocalypse and you have to be ready.
    */ 
    function declareWinningGroup(uint32 groupNumber) external eventEnded {
        uint32 _currentGroupNumber = winningGroupNumber;
        if(_currentGroupNumber == 0 || this.getGroupScore(groupNumber) > this.getGroupScore(_currentGroupNumber)) {
            winningGroupNumber = groupNumber;
        } else {
            revert();
        }
    }

    uint256 public totalWithdrawn;
    uint256 public totalSwept;
    uint256 public hostBalance;
    uint256 public groupBalance;
    uint256 public survivorBalance;

    /** Sweep rewards into a balance mapping first to avoid survivor/group owner set to contract with revert
    */
    function sweepRewards() external onlyOwner canWithdraw {
        uint256 currentPool = totalWithdrawn + address(this).balance - totalSwept;
        totalSwept = totalSwept + currentPool;

        uint256 survivorShare = currentPool * 30 / 100;
        uint256 groupShare = currentPool * 20 / 100;
        uint256 hostShare = (currentPool - survivorShare - groupShare);

        hostBalance += hostShare;
        groupBalance += groupShare;
        survivorBalance += survivorShare;
    }

    function withdraw(uint256 share) external onlyOwner {
        address recipient;
        uint256 recipientBalance;
        if(share == 1) {
            recipient = owner();
            recipientBalance = hostBalance;
            hostBalance = 0;
        } else if(share == 2) {
            recipient = groupManager[winningGroupNumber];
            recipientBalance = groupBalance;
            groupBalance = 0;
        } else if(share == 3) {
            recipient = ownerOf(lastSurvivorTokenID);
            recipientBalance = survivorBalance;
            survivorBalance = 0;
        }
        require(recipientBalance > 0);
        (bool sent, ) = payable(recipient).call{value: recipientBalance}("");
        require(sent);
        totalWithdrawn = totalWithdrawn + recipientBalance;
    }

    /** SCORE FUNCTIONS 
    */

    function currentInfectionProgress() external view returns (uint32) {
        if(eventOver) return infectionProgress.lastProgress;
        return (infectionProgress.lastProgress + (uint32(block.number) - infectionProgress.lastBlock) * infectionProgress.infectionRate);
    }

    function getIndividualScore(uint256 tokenId) external view returns (uint32) {
        require(_exists(tokenId));
        if(eventStartTime == 0) return 0;
        uint32 _endBlock = uint32(block.number);
        if(eventOver) _endBlock = infectionProgress.lastBlock;
        IndividualData memory individual = individualRecord[tokenId];
        uint32 _lastBlock = individual.lastBlock;
        if(_lastBlock == 0) _lastBlock = eventStartBlock;
        return (individual.lastScore + (_endBlock - _lastBlock) * this.getIndividualRate(tokenId,false) + this.getGroupScore(individual.groupNumber));
    }

    function getIndividualOnlyScore(uint256 tokenId) external view returns (uint32) {
        require(_exists(tokenId));
        if(eventStartTime == 0) return 0;
        uint32 _endBlock = uint32(block.number);
        if(eventOver) _endBlock = infectionProgress.lastBlock;
        IndividualData memory individual = individualRecord[tokenId];
        uint32 _lastBlock = individual.lastBlock;
        if(_lastBlock == 0) _lastBlock = eventStartBlock;
        return (individual.lastScore + (_endBlock - _lastBlock) * this.getIndividualRate(tokenId,false));
    }

    function getIndividualRate(uint256 tokenId, bool ignoreBite) external view returns (uint32) {
        if(eventStartTime == 0) return 0;
        IndividualData memory individual = individualRecord[tokenId];
        uint32 _individualRate = uint32(uint256(keccak256(abi.encodePacked(individual.individualSeed, collectionSeed)))) % INDIVIDUAL_VARIABLE_RATE + INDIVIDUAL_BASE_RATE;
        if(individual.bitten && !ignoreBite) { _individualRate = _individualRate / 4; }
        return _individualRate;
    }

    function getIndividualLuck(uint256 tokenId) external view returns (uint32) {
        if(eventStartTime == 0) return 0;
        IndividualData memory individual = individualRecord[tokenId];
        uint32 _individualLuck = uint32(uint256(keccak256(abi.encodePacked(collectionSeed, individual.individualSeed)))) % INDIVIDUAL_MAXIMUM_LUCK;
        return _individualLuck;
    }

    function getGroupScoreByAddress(address _collectionAddress) external view returns(uint32) {
        return this.getGroupScore(uint32(groupNumbers[_collectionAddress]));
    }

    function getGroupScore(uint32 _groupNumber) external view returns (uint32) {
        if(_groupNumber == 0) return 0;
        if(eventStartTime == 0) return 0;
        uint32 _endBlock = uint32(block.number);
        if(eventOver) _endBlock = infectionProgress.lastBlock;
        GroupData memory group = groupRecord[uint256(_groupNumber)];
        uint32 _lastBlock = group.lastBlock;
        if(_lastBlock == 0) _lastBlock = eventStartBlock;
        return (group.lastScore + (_endBlock - _lastBlock) * this.getGroupRate(_groupNumber));
    }

    function getGroupRate(uint32 _groupNumber) external view returns (uint32) {
        if(eventStartTime == 0) return 0;
        if(_groupNumber == 0 || _groupNumber > groupsRegistered) return 0;
        uint32 _totalMembers = groupRecord[uint256(_groupNumber)].totalMembers;
        return (_totalMembers / GROUP_VARIABLE_RATE + GROUP_BASE_RATE) * GROUP_RATE_MULTIPLIER;
    }

    /** DAILY ACTIVITY FUNCTIONS 
    */
    function currentDay() external view returns (uint32) {
        if(eventStartTime == 0) return 0;
        uint32 _currentDay = uint32((block.timestamp - uint256(eventStartTime)) / 1 days + 1);
        if(_currentDay > MAX_DAY) { _currentDay = MAX_DAY; }
        return _currentDay;
    }

    function getIndividualDailyActivityRecords(uint256 tokenId) external view returns(ActivityRecord[] memory) {
        uint256 numRecords = this.currentDay();
        ActivityRecord[] memory records = new ActivityRecord[](numRecords);
        for(uint256 i = 1;i <= numRecords;i++) {
            records[i-1] = individualActivity[((tokenId << 32) + i)];
        }
        return records;
    }

    function getGroupDailyActivityRecords(uint32 _groupNumber) external view returns(ActivityRecord[] memory) {
        uint256 numRecords = this.currentDay();
        ActivityRecord[] memory records = new ActivityRecord[](numRecords);
        for(uint256 i = 1;i <= numRecords;i++) {
            records[i-1] = groupActivity[((uint256(_groupNumber) << 32) + i)];
        }
        return records;
    }

    function getGroupDailyActivityRecordsByAddress(address _collectionAddress) external view returns(ActivityRecord[] memory) {
        return this.getGroupDailyActivityRecords(uint32(groupNumbers[_collectionAddress]));
    }
    
    function cureIndividual(uint256 tokenId) external payable eventInProgress {
        require(ownerOf(tokenId) == msg.sender);
        require(cureSupply > 0);

        IndividualData memory individual = individualRecord[tokenId];
        if(individual.lastBlock == 0) { individual.lastBlock = eventStartBlock; }
        individual.lastScore = (individual.lastScore + (uint32(block.number) - individual.lastBlock) * this.getIndividualRate(tokenId,false));
        individual.lastBlock = uint32(block.number);
        uint32 _groupScore = this.getGroupScore(individual.groupNumber);
        uint32 _totalScore = (individual.lastScore + _groupScore);
        uint32 _currentInfectionProgress = this.currentInfectionProgress();
        uint256 cureCost = FINAL_CURE_COST / cureSupply;
        
        if(_totalScore >= _currentInfectionProgress && individual.bitten) { // half cost if bitten but not fully zombie yet
            cureCost = cureCost / 2;
        } else if(_totalScore < _currentInfectionProgress) {
            individual.lastScore = (_currentInfectionProgress + CURE_PROGRESS_INCREMENT) - _groupScore; // bump score over infection level
        } else {
            cureCost = cureCost * 5; // greedy people that don't need a cure pay 5x
        }
        individual.bitten = false;

        cureSupply = cureSupply - 1;
        individualRecord[tokenId] = individual;
        require(msg.value >= cureCost);
        emit IndividualCured(tokenId);
    }

    function dailyActivityIndividual(uint256 tokenId, uint32 _riskChoice) external payable eventInProgress {
        require(_riskChoice >= RISK_LEVEL_LOW && _riskChoice <= RISK_LEVEL_HIGH);
        require(msg.value >= INDIVIDUAL_DAILY_ACTIVITY_COST);
        require(ownerOf(tokenId) == msg.sender);

        uint256 _currentDay = uint256(this.currentDay());
        uint256 individualDayKey = (tokenId << 32) + _currentDay;
        ActivityRecord memory activity = individualActivity[individualDayKey];
        require(activity.riskChoice == 0);
        uint32 _activityOutcome = 0;
        
        IndividualData memory individual = individualRecord[tokenId];
        if(individual.lastBlock == 0) { individual.lastBlock = eventStartBlock; }
        individual.lastScore = (individual.lastScore + (uint32(block.number) - individual.lastBlock) * this.getIndividualRate(tokenId,false));
        individual.lastBlock = uint32(block.number);
        uint32 _groupScore = this.getGroupScore(individual.groupNumber);
        uint32 _currentInfectionProgress = this.currentInfectionProgress();
        uint32 _individualLuck = this.getIndividualLuck(tokenId);

        uint32 _seed = (uint32(uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,tokenId)))) % TOTAL_MAXIMUM_LUCK) + _individualLuck;

        if((individual.lastScore + _groupScore) >= _currentInfectionProgress) {
            if(_riskChoice == RISK_LEVEL_LOW) {
                if(_seed > RISK_LOW_OUTCOME_LARGE) {
                    _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_LARGE;
                } else if(_seed > RISK_LOW_OUTCOME_MEDIUM) {
                    _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_MEDIUM;
                } else if(_seed > RISK_LOW_OUTCOME_SMALL) {
                    _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_SMALL;
                } else {
                    _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                    individual.bitten = true;
                }
            } else if(_riskChoice == RISK_LEVEL_MEDIUM) {
                if(_seed > RISK_MEDIUM_OUTCOME_LARGE) {
                    _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_LARGE;
                } else if(_seed > RISK_MEDIUM_OUTCOME_MEDIUM) {
                    _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_MEDIUM;
                } else if(_seed > RISK_MEDIUM_OUTCOME_SMALL) {
                    _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_SMALL;
                } else {
                    _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                    individual.bitten = true;
                }
            } else if(_riskChoice == RISK_LEVEL_HIGH) {
                if(_seed > RISK_HIGH_OUTCOME_LARGE) {
                    _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_LARGE;
                } else if(_seed > RISK_HIGH_OUTCOME_MEDIUM) {
                    _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_MEDIUM;
                } else if(_seed > RISK_HIGH_OUTCOME_SMALL) {
                    _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_SMALL;
                } else {
                    _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                    individual.bitten = true;
                }
            }
        } else { // already a zombie, chance to recover
            if(_seed > RANDOM_CURE_CHANCE) {
                _riskChoice = 1;
                individual.lastScore = (_currentInfectionProgress + LATE_JOINER_PROGRESS) - _groupScore;
                _activityOutcome = ACTIVITY_OUTCOME_CURED;
                individual.bitten = false;
            } else {
                _riskChoice = 1;
                _activityOutcome = ACTIVITY_OUTCOME_STILL_A_ZOMBIE;
            }
        }

        activity.riskChoice = _riskChoice;
        activity.activityOutcome = _activityOutcome;

        individualActivity[individualDayKey] = activity;
        individualRecord[tokenId] = individual;

        emit IndividualDailyActivity(tokenId, _currentDay, _riskChoice, _activityOutcome);
    }

    function dailyActivityGroup(uint32 _groupNumber, uint32 _riskChoice) external payable eventInProgress {
        require(_riskChoice >= RISK_LEVEL_LOW && _riskChoice <= RISK_LEVEL_HIGH);
        require(msg.value >= GROUP_DAILY_ACTIVITY_COST);
        require(groupManager[_groupNumber] == msg.sender);

        uint256 _currentDay = uint256(this.currentDay());
        uint256 groupDayKey = (uint256(_groupNumber) << 32) + _currentDay;
        ActivityRecord memory activity = groupActivity[groupDayKey];
        require(activity.riskChoice == 0);
        uint32 _activityOutcome = 0;
        
        GroupData memory group = groupRecord[uint256(_groupNumber)];
        if(group.lastBlock == 0) { group.lastBlock = eventStartBlock; }
        group.lastScore = (group.lastScore + (uint32(block.number) - group.lastBlock) * this.getGroupRate(_groupNumber));
        group.lastBlock = uint32(block.number);

        uint32 _seed = (uint32(uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,_groupNumber)))) % TOTAL_MAXIMUM_LUCK);

        if(_riskChoice == RISK_LEVEL_LOW) {
            if(_seed > RISK_LOW_OUTCOME_LARGE) {
                _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                group.lastScore += GROUP_REWARD_OUTCOME_LARGE;
            } else if(_seed > RISK_LOW_OUTCOME_MEDIUM) {
                _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                group.lastScore += GROUP_REWARD_OUTCOME_MEDIUM;
            } else if(_seed > RISK_LOW_OUTCOME_SMALL) {
                _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                group.lastScore += GROUP_REWARD_OUTCOME_SMALL;
            } else {
                _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                group.lastScore /= 2;
            }
        } else if(_riskChoice == RISK_LEVEL_MEDIUM) {
            if(_seed > RISK_MEDIUM_OUTCOME_LARGE) {
                _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                group.lastScore += GROUP_REWARD_OUTCOME_LARGE;
            } else if(_seed > RISK_MEDIUM_OUTCOME_MEDIUM) {
                _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                group.lastScore += GROUP_REWARD_OUTCOME_MEDIUM;
            } else if(_seed > RISK_MEDIUM_OUTCOME_SMALL) {
                _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                group.lastScore += GROUP_REWARD_OUTCOME_SMALL;
            } else {
                _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                group.lastScore /= 2;
            }
        } else if(_riskChoice == RISK_LEVEL_HIGH) {
            if(_seed > RISK_HIGH_OUTCOME_LARGE) {
                _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                group.lastScore += GROUP_REWARD_OUTCOME_LARGE;
            } else if(_seed > RISK_HIGH_OUTCOME_MEDIUM) {
                _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                group.lastScore += GROUP_REWARD_OUTCOME_MEDIUM;
            } else if(_seed > RISK_HIGH_OUTCOME_SMALL) {
                _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                group.lastScore += GROUP_REWARD_OUTCOME_SMALL;
            } else {
                _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                group.lastScore /= 2;
            }
        }

        activity.riskChoice = _riskChoice;
        activity.activityOutcome = _activityOutcome;

        groupActivity[groupDayKey] = activity;
        groupRecord[uint256(_groupNumber)] = group;

        emit GroupDailyActivity(_groupNumber, _currentDay, _riskChoice, _activityOutcome);
    }

    /** GROUP MANAGEMENT FUNCTIONS
    */

    /**  Register a group to Dead Will Rise, claims ownership
    */
    function registerGroup(address _collectionAddress) external payable {
        require(groupRegistrationOpen);
        require(msg.value >= GROUP_REGISTRATION_COST);
        require(groupNumbers[_collectionAddress] == 0);
        require(IERC721(_collectionAddress).supportsInterface(type(IERC721).interfaceId));
        groupsRegistered = groupsRegistered + 1;
        uint256 newGroupNumber = groupsRegistered;
        GroupData memory newGroup;
        newGroup.groupSeed = uint32(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _collectionAddress))));
        if(eventStartBlock > 0) {
            newGroup.lastBlock = uint32(block.number);
        }

        groupNumberToCollection[newGroupNumber] = _collectionAddress;
        groupNumbers[_collectionAddress] = newGroupNumber;
        groupRecord[newGroupNumber] = newGroup;
        groupManager[newGroupNumber] = msg.sender;
        emit GroupRegistered(newGroupNumber, _collectionAddress, msg.sender);
    }

    /** Transfer management of a group to a new user
    *   Current group manager can transfer ownership anytime
    */
    function transferGroupManagement(address _collectionAddress, address _newManager) external {
        uint256 _groupNumber = groupNumbers[_collectionAddress];
        require(groupManager[_groupNumber] == msg.sender);
        groupManager[_groupNumber] = _newManager;
        emit GroupTransferred(_groupNumber, _collectionAddress, _newManager);
    }

    /** MINTING FUNCTIONS
    */
    function setMintingVariables(bool _groupOpen, bool _publicOpen, uint32 _maxPerWalletPerGroup, uint32 _maxPerGroup) external onlyOwner {
        groupRegistrationOpen = _groupOpen;
        publicMintOpen = _publicOpen;
        maxPerWalletPerGroup = _maxPerWalletPerGroup;
        maxPerGroup = _maxPerGroup;
    }

    function getCurrentRegistrationCost() external view returns (uint256) {
        if(eventStartBlock > 0) {
            uint256 _currentDay = this.currentDay();
            if(_currentDay == MAX_DAY) {
                return 5000 ether;
            } else {
                return address(this).balance * 50 / 100 / (MAX_DAY - _currentDay);
            }
        } else {
            return 0;
        }
    }

    function mintInner(address _to, address _collectionAddress, address _onBehalfOf) internal {
        uint256 tokenId = totalSupply() + 1;
        require(tokenId <= MAX_SUPPLY);

        uint32 _groupNumber = uint32(groupNumbers[_collectionAddress]);
        require((groupRegistrationOpen && _groupNumber > 0) || publicMintOpen);

        uint256 mintKey = (uint256(uint160(_onBehalfOf)) << 32) + _groupNumber;
        uint256 currentCount = mintCount[mintKey];
        require(currentCount + 1 <= maxPerWalletPerGroup);

        uint256 _eventStartBlock = eventStartBlock;
        IndividualData memory individual;
        individual.individualSeed = uint32(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, mintKey))));
        if(_eventStartBlock > 0) {
            individual.lastBlock = uint32(block.number);
            individual.lastScore = this.currentInfectionProgress() * 110 / 100;
            require(msg.value >= this.getCurrentRegistrationCost());
        }
        if(_groupNumber > 0) {
            require(IERC721(_collectionAddress).balanceOf(_onBehalfOf) > 0);
            GroupData memory group = groupRecord[_groupNumber];
            group.totalMembers = group.totalMembers + 1;
            require(group.totalMembers <= maxPerGroup);
            if(_eventStartBlock > 0) {
                group.lastScore = this.getGroupScore(_groupNumber);
                group.lastBlock = uint32(block.number);
            }
            individual.groupNumber = _groupNumber;
            groupRecord[_groupNumber] = group;
        }

        _safeMint(_to, 1);
        mintCount[mintKey] = currentCount + 1;
        individualRecord[tokenId] = individual;
    }

    function delegateMint(address _collectionAddress, address _onBehalfOf) external payable {
        require(delegateCash.checkDelegateForAll(msg.sender, _onBehalfOf) || delegateCash.checkDelegateForContract(msg.sender, _onBehalfOf, _collectionAddress));
        mintInner(msg.sender, _collectionAddress, _onBehalfOf);
    }

    function mintIndividual() external payable {
        mintInner(msg.sender, address(0x0), msg.sender);
    }

    function mintToGroup(address _collectionAddress) external payable {
        mintInner(msg.sender, _collectionAddress, msg.sender);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPlaceholderURI(string calldata placeholderURI) external onlyOwner {
        _placeholderURI = placeholderURI;
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    function setIncludeStatsInURI(bool _stats) external onlyOwner {
        includeStatsInURI = _stats;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));

        if (eventStartTime == 0) {
            return _placeholderURI;
        }

        string memory baseURI = _baseTokenURI;
        string memory infectionStatus = 'H';
        if(this.getIndividualScore(tokenId) < this.currentInfectionProgress()) { infectionStatus = 'Z'; }
        if(includeStatsInURI) {
            uint32 individualLuck = this.getIndividualLuck(tokenId);
            uint32 individualRate = this.getIndividualRate(tokenId,true);
            return bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, infectionStatus, _toString(tokenId), TOKEN_URI_SEPARATOR, _toString(individualRate), TOKEN_URI_SEPARATOR, _toString(individualLuck)))
                : "";
        } else {
            return bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, infectionStatus, _toString(tokenId)))
                : "";
        }
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                if (ownerOf(i) == owner) {
                    uint256 _individualScore = this.getIndividualScore(i);
                    tokenIds[tokenIdsIdx++] = (i<<32)+_individualScore;
                }
            }
            return tokenIds;
        }
    }
}