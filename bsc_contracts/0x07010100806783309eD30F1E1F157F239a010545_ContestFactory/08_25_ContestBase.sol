// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@artman325/releasemanager/contracts/CostManagerHelperERC2771Support.sol";

contract ContestBase is Initializable, ReentrancyGuardUpgradeable, CostManagerHelperERC2771Support, OwnableUpgradeable {
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeMathUpgradeable for uint256;

    // ** deprecated 
    // delegateFee (some constant in contract) which is percent of amount. They can delegate their entire amount of vote to the judge, or some.
    // uint256 delegateFee = 5e4; // 5% mul at 1e6
    
    uint8 internal constant OPERATION_SHIFT_BITS = 240;  // 256 - 16
    // Constants representing operations
    uint8 internal constant OPERATION_INITIALIZE = 0x0;
    uint8 internal constant OPERATION_INITIALIZE_ETH_ONLY = 0x1;
    uint8 internal constant OPERATION_CLAIM = 0x2;
    uint8 internal constant OPERATION_COMPLETE = 0x3;
    uint8 internal constant OPERATION_DELEGATE = 0x4;
    uint8 internal constant OPERATION_ENTER = 0x5;
    uint8 internal constant OPERATION_LEAVE = 0x6;
    uint8 internal constant OPERATION_VOTE = 0x7;
    uint8 internal constant OPERATION_PLEDGE = 0x8;
    uint8 internal constant OPERATION_REVOKE = 0x9;
    

    // penalty for revoke tokens
    uint256 public revokeFee; // 10% mul at 1e6
    
    EnumerableSetUpgradeable.AddressSet private _judgesWhitelist;
    EnumerableSetUpgradeable.AddressSet private _personsList;
    
    mapping (address => uint256) private _balances;
    
    Contest _contest;
    
    struct Contest {
        uint256 stage;
        uint256 stagesCount;
        mapping (uint256 => Stage) _stages;

    }
	
    struct Stage {
        uint256 winnerWeight;

        mapping (uint256 => address[]) winners;
        bool winnersLock;

        uint256 amount;     // acummulated all pledged 
        uint256 minAmount;
        
        bool active;    // stage will be active after riched minAmount
        bool completed; // true if stage already processed
        uint256 startTimestampUtc;
        uint256 contestPeriod; // in seconds
        uint256 votePeriod; // in seconds
        uint256 revokePeriod; // in seconds
        uint256 endTimestampUtc;
        EnumerableSetUpgradeable.AddressSet contestsList;
        EnumerableSetUpgradeable.AddressSet pledgesList;
        EnumerableSetUpgradeable.AddressSet judgesList;
        EnumerableSetUpgradeable.UintSet percentForWinners;
        mapping (address => Participant) participants;
    }
   
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single participant at single stage
    struct Participant {
        uint256 weight; // user weight
        uint256 balance; // user balance
        uint256 balanceAfter; // balance after calculate
        bool voted;  // if true, that person already voted
        address voteTo; // person voted to
        bool delegated;  // if true, that person delegated to some1
        address delegateTo; // person delegated to
        EnumerableSetUpgradeable.AddressSet delegatedBy; // participant who delegated own weight
        EnumerableSetUpgradeable.AddressSet votedBy; // participant who delegated own weight
        bool won;  // if true, that person won round. setup after EndOfStage
        bool claimed; // if true, that person claimed them prise if won ofc
        bool revoked; // if true, that person revoked from current stage
        //bool left; // if true, that person left from current stage and contestant list
        bool active; // always true

    }

	event ContestStart();
    event ContestComplete();
    event ContestWinnerAnnounced(address[] indexed winners);
    event StageStartAnnounced(uint256 indexed stageID);
    event StageCompleted(uint256 indexed stageID);
    
    error PersonMustHaveNotVotedOrDelegatedBefore(address account, uint256 stageID);
    error JudgeHaveBeenAlreadyDelegated(address account, uint256 stageID);
    error StageHaveStillInGatheringMode(uint256 stageID);
    error StageHaveNotCompletedYet(uint256 stageID);
    error StageIsOutOfContestPeriod(uint256 stageID);
    error StageIsOutOfVotingPeriod(uint256 stageID);
    error StageIsOutOfRevokeOrVotePeriod(uint256 stageID);
    error StageHaveNotCompletedOrSenderHasAlreadyClaimedOrRevoked(uint256 stageID);
    error MustBeInContestantList(uint256 stageID, address account);
    error MustNotBeInContestantList(uint256 stageID, address account);
    error MustBeInPledgesList(uint256 stageID, address account);
    error MustNotBeInPledgesList(uint256 stageID, address account);
    error MustBeInJudgesList(uint256 stageID, address account);
    error MustNotBeInJudgesList(uint256 stageID, address account);
    error MustBeInPledgesOrJudgesList(uint256 stageID, address account);
    error StageHaveNotEndedYet(uint256 stageID);
    error MethodDoesNotSupported();
    
	////
	// modifiers section
	////
// not (A or B) = (not A) and (not B)
// not (A and B) = (not A) or (not B)
    /**
     * @param account address
     * @param stageID Stage number
     */
    modifier onlyNotVotedNotDelegated(address account, uint256 stageID) {
        Participant storage participant = _contest._stages[stageID].participants[account];
        if (participant.voted || participant.delegated) {
            revert PersonMustHaveNotVotedOrDelegatedBefore(account, stageID);
        }
        _;
    }
    
    /**
     * @param account address
     * @param stageID Stage number
     */
    modifier judgeNotDelegatedBefore(address account, uint256 stageID) {
        Participant storage participant = _contest._stages[stageID].participants[account];
        if (participant.delegated) {
            revert JudgeHaveBeenAlreadyDelegated(account, stageID);
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier stageActive(uint256 stageID) {
        Stage storage stage = _contest._stages[stageID];
        if (stage.active) {
            revert StageHaveStillInGatheringMode(stageID);
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier stageNotCompleted(uint256 stageID) {
        Stage storage stage = _contest._stages[stageID];
        if (stage.completed) {
            revert StageHaveNotCompletedYet(stageID);
        }
        _;
    }

    /**
     * @param stageID Stage number
     */
    modifier canPledge(uint256 stageID) {
        Stage storage stage = _contest._stages[stageID];
        uint256 endContestTimestamp = (stage.startTimestampUtc).add(stage.contestPeriod);
        if ((stage.active == true) && (endContestTimestamp <= block.timestamp)) {
            revert StageIsOutOfContestPeriod(stageID);
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier canDelegateAndVote(uint256 stageID) {
        Stage storage stage = _contest._stages[stageID];
        uint256 endContestTimestamp = (stage.startTimestampUtc).add(stage.contestPeriod);
        uint256 endVoteTimestamp = endContestTimestamp.add(stage.votePeriod);
        if (
            (stage.active == false) ||
            (endVoteTimestamp <= block.timestamp) ||
            (block.timestamp < endContestTimestamp)
        ) {
            revert StageIsOutOfVotingPeriod(stageID);
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier canRevoke(uint256 stageID) {
        Stage storage stage = _contest._stages[stageID];

        uint256 endContestTimestamp = (stage.startTimestampUtc).add(stage.contestPeriod);
        uint256 endVoteTimestamp = (stage.startTimestampUtc).add(stage.contestPeriod).add(stage.votePeriod);
        uint256 endRevokeTimestamp = stage.endTimestampUtc;
        
        if (
            (stage.active == false) || 
            (endRevokeTimestamp <= block.timestamp) || 
            (block.timestamp < endContestTimestamp)
        ) {
            revert StageIsOutOfRevokeOrVotePeriod(stageID);
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier canClaim(uint256 stageID) {
        Stage storage stage = _contest._stages[stageID];
        address sender = _msgSender();
        uint256 endTimestampUtc = stage.endTimestampUtc;
        
        if (
            (stage.participants[_msgSender()].revoked) ||
            (stage.participants[_msgSender()].claimed) ||
            (stage.completed == false) && 
            (stage.active == false) && 
            (block.timestamp <= endTimestampUtc)
        ) {
            revert StageHaveNotCompletedOrSenderHasAlreadyClaimedOrRevoked(stageID);
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier inContestsList(uint256 stageID) {
        if (_contest._stages[stageID].contestsList.contains(_msgSender()) == false) {
            revert MustBeInContestantList(stageID, _msgSender());
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier notInContestsList(uint256 stageID) {
        if (_contest._stages[stageID].contestsList.contains(_msgSender())) {
            revert MustNotBeInContestantList(stageID, _msgSender());
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier inPledgesList(uint256 stageID) {
        if (_contest._stages[stageID].pledgesList.contains(_msgSender()) == false) {
            revert MustBeInPledgesList(stageID, _msgSender());
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier notInPledgesList(uint256 stageID) {
        if (_contest._stages[stageID].pledgesList.contains(_msgSender())) {
            revert MustNotBeInPledgesList(stageID, _msgSender());
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier inJudgesList(uint256 stageID) {
        if (_contest._stages[stageID].judgesList.contains(_msgSender()) == false) {
            revert MustBeInJudgesList(stageID, _msgSender());
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier notInJudgesList(uint256 stageID) {
        if (_contest._stages[stageID].judgesList.contains(_msgSender())) {
            revert MustNotBeInJudgesList(stageID, _msgSender());
        }
        _;
    }
    
    /**
     * @param stageID Stage number
     */        
    modifier inPledgesOrJudgesList(uint256 stageID) {
        Stage storage stage = _contest._stages[stageID];

        if (
            stage.pledgesList.contains(_msgSender()) == false &&
            stage.judgesList.contains(_msgSender()) == false
        ) {
            revert MustBeInPledgesOrJudgesList(stageID, _msgSender());
        }
        _;
    }  
    
    /**
     * @param stageID Stage number
     */
    modifier canCompleted(uint256 stageID) {
        Stage storage stage = _contest._stages[stageID];
        if (
            (stage.completed == true) ||
            (stage.active == false) ||
            (stage.endTimestampUtc >= block.timestamp)
        ) {
            revert StageHaveNotEndedYet(stageID);
        }
        _;
    }
    ////
	// END of modifiers section 
	////
        
    //constructor() public {}
    
	/**
     * @param stagesCount count of stages for first Contest
     * @param stagesMinAmount array of minimum amount that need to reach at each stage
     * @param contestPeriodInSeconds duration in seconds  for contest period(exclude before reach minimum amount)
     * @param votePeriodInSeconds duration in seconds  for voting period
     * @param revokePeriodInSeconds duration in seconds  for revoking period
     * @param percentForWinners array of values in percentages of overall amount that will gain winners 
     * @param judges array of judges' addresses. if empty than everyone can vote
     * @param costManager address of costManager
     
     */
    function __ContestBase__init(
        uint256 stagesCount,
        uint256[] memory stagesMinAmount,
        uint256 contestPeriodInSeconds,
        uint256 votePeriodInSeconds,
        uint256 revokePeriodInSeconds,
        uint256[] memory percentForWinners,
        address[] memory judges,
        address costManager
    ) 
        internal 
        onlyInitializing 
    {
        __CostManagerHelper_init(_msgSender());
        _setCostManager(costManager);

        __Ownable_init();
        __ReentrancyGuard_init();
    
        revokeFee = 10e4;
        
        uint256 stage = 0;
        
        _contest.stage = 0;            
        for (stage = 0; stage < stagesCount; stage++) {
            _contest._stages[stage].minAmount = stagesMinAmount[stage];
            _contest._stages[stage].winnersLock = false;
            _contest._stages[stage].active = false;
            _contest._stages[stage].contestPeriod = contestPeriodInSeconds;
            _contest._stages[stage].votePeriod = votePeriodInSeconds;
            _contest._stages[stage].revokePeriod = revokePeriodInSeconds;
            
            for (uint256 i = 0; i < judges.length; i++) {
                _contest._stages[stage].judgesList.add(judges[i]);
            }
            
            for (uint256 i = 0; i < percentForWinners.length; i++) {
                _contest._stages[stage].percentForWinners.add(percentForWinners[i]);
            }
        }
        
        emit ContestStart();
        
        
    }

    ////
	// public section
	////
	/**
	 * @dev show contest state
	 * @param stageID Stage number
	 */
    function isContestOnline(uint256 stageID) public view returns (bool res){

        if (
            (_contest._stages[stageID].winnersLock == false) &&
            (
                (_contest._stages[stageID].active == false) ||
                ((_contest._stages[stageID].active == true) && (_contest._stages[stageID].endTimestampUtc > block.timestamp))
            ) && 
            (_contest._stages[stageID].completed == false)
        ) {
            res = true;
        } else {
            res = false;
        }
    }
    
    function getStageAmount( uint256 stageID) public view returns (uint256) {
        return _contest._stages[stageID].amount;
    }
    
    function getStageNumber() public view returns (uint256) {
        return _contest.stage;
    }

    /**
     * @param amount amount to pledge
	 * @param stageID Stage number
     */
    function pledge(uint256 amount, uint256 stageID) public virtual {
        _pledge(amount, stageID);
    }
    
    /**
     * @param judge address of judge which user want to delegate own vote
	 * @param stageID Stage number
     */
    function delegate(
        address judge, 
        uint256 stageID
    ) 
        public
        notInContestsList(stageID)
        stageNotCompleted(stageID)
        onlyNotVotedNotDelegated(_msgSender(), stageID)
        judgeNotDelegatedBefore(judge, stageID)
    {
        _delegate(judge, stageID);

        _accountForOperation(
            (OPERATION_DELEGATE << OPERATION_SHIFT_BITS) | stageID,
            uint256(uint160(_msgSender())),
            uint256(uint160(judge))
        );
    }
    
    /** 
     * @param contestantAddress address of contestant which user want to vote
	 * @param stageID Stage number
     */     
    function vote(
        address contestantAddress,
        uint256 stageID
    ) 
        public 
        notInContestsList(stageID)
        onlyNotVotedNotDelegated(_msgSender(), stageID)  
        stageNotCompleted(stageID)
        canDelegateAndVote(stageID)
    {
        _vote(contestantAddress, stageID);
        
        _accountForOperation(
            (OPERATION_VOTE << OPERATION_SHIFT_BITS) | stageID,
            uint256(uint160(_msgSender())),
            uint256(uint160(contestantAddress))
        );
    }
    
    /**
     * @param stageID Stage number
     */
    function claim(
        uint256 stageID
    )
        public
        inContestsList(stageID)
        canClaim(stageID)
    {
        _contest._stages[stageID].participants[_msgSender()].claimed = true;
        uint prizeAmount = _contest._stages[stageID].participants[_msgSender()].balanceAfter;
        _claimAfter(prizeAmount);

        
        _accountForOperation(
            (OPERATION_CLAIM << OPERATION_SHIFT_BITS) | stageID,
            uint256(uint160(_msgSender())),
            0
        );
    }
    
    /**
     * @param stageID Stage number
     */
    function enter(
        uint256 stageID
    ) 
        notInContestsList(stageID) 
        notInPledgesList(stageID) 
        notInJudgesList(stageID) 

        public 
    {
        _enter(stageID);
        
        _accountForOperation(
            (OPERATION_ENTER << OPERATION_SHIFT_BITS) | stageID,
            uint256(uint160(_msgSender())),
            0
        );
    }
    
    /**
     * @param stageID Stage number
     */   
    function leave(
        uint256 stageID
    ) 
        public 
    {
        _leave(stageID);

        _accountForOperation(
            (OPERATION_LEAVE << OPERATION_SHIFT_BITS) | stageID,
            uint256(uint160(_msgSender())),
            0
        );
    }
    
    /**
     * @param stageID Stage number
     */
    function revoke(
        uint256 stageID
    ) 
        public
        notInContestsList(stageID)
        stageNotCompleted(stageID)
        canRevoke(stageID)
    {
        
        _revoke(stageID);
        
        _contest._stages[stageID].participants[_msgSender()].revoked == true;
            
        uint revokedBalance = _contest._stages[stageID].participants[_msgSender()].balance;
        _contest._stages[stageID].amount = _contest._stages[stageID].amount.sub(revokedBalance);
        revokeAfter(revokedBalance.sub(revokedBalance.mul(_calculateRevokeFee(stageID)).div(1e6)));
        
        _accountForOperation(
            (OPERATION_REVOKE << OPERATION_SHIFT_BITS) | stageID,
            uint256(uint160(_msgSender())),
            0
        );
    } 

    ////
	// internal section
	////
	
	/**
	 * calculation revokeFee penalty.  it gradually increased if revoke happens in voting period
	 * @param stageID Stage number
	 */
	function _calculateRevokeFee(
	    uint256 stageID
    )
        internal 
        view
        returns(uint256)
    {
        uint256 endContestTimestamp = (_contest._stages[stageID].startTimestampUtc).add(_contest._stages[stageID].contestPeriod);
        uint256 endVoteTimestamp = (_contest._stages[stageID].startTimestampUtc).add(_contest._stages[stageID].contestPeriod).add(_contest._stages[stageID].votePeriod);
        
        if ((endVoteTimestamp > block.timestamp) && (block.timestamp >= endContestTimestamp)) {
            uint256 revokeFeePerSecond = (revokeFee).div(endVoteTimestamp.sub(endContestTimestamp));
            return revokeFeePerSecond.mul(block.timestamp.sub(endContestTimestamp));
            
        } else {
            return revokeFee;
        }
        
    }
	
	/**
     * @param judge address of judge which user want to delegate own vote
     * @param stageID Stage number
     */
    function _delegate(
        address judge, 
        uint256 stageID
    ) 
        internal 
        canDelegateAndVote(stageID)
    {
        Stage storage stage = _contest._stages[stageID];
        // code left for possibility re-delegate
        // if (_contests[contestID]._stages[stageID].participants[_msgSender()].delegated == true) {
        //     _revoke(stageID);
        // }
        stage.participants[_msgSender()].delegated = true;
        stage.participants[_msgSender()].delegateTo = judge;
        stage.participants[judge].delegatedBy.add(_msgSender());
    }
    
    /** 
     * @param contestantAddress address of contestant which user want to vote
	 * @param stageID Stage number
     */ 
    function _vote(
        address contestantAddress,
        uint256 stageID
    ) 
        internal
    {
        Stage storage stage = _contest._stages[stageID];
        if (stage.contestsList.contains(contestantAddress) == false) {
            revert MustBeInContestantList(stageID, contestantAddress);
        }
     
        // code left for possibility re-vote
        // if (_contests[contestID]._stages[stageID].participants[_msgSender()].voted == true) {
        //     _revoke(stageID);
        // }
        //----
        
        stage.participants[_msgSender()].voted = true;
        stage.participants[_msgSender()].voteTo = contestantAddress;
        stage.participants[contestantAddress].votedBy.add(_msgSender());
    }
    
    /**
     * @param amount amount 
     */
    function _claimAfter(uint256 amount) internal virtual { }
    
    /**
     * @param amount amount 
     */
    function revokeAfter(uint256 amount) internal virtual {}
    
    /** 
	 * @param stageID Stage number
     */ 
    function _revoke(
        uint256 stageID
    ) 
        private
    {
        address addr;
        if (_contest._stages[stageID].participants[_msgSender()].voted == true) {
            addr = _contest._stages[stageID].participants[_msgSender()].voteTo;
            _contest._stages[stageID].participants[addr].votedBy.remove(_msgSender());
        } else if (_contest._stages[stageID].participants[_msgSender()].delegated == true) {
            addr = _contest._stages[stageID].participants[_msgSender()].delegateTo;
            _contest._stages[stageID].participants[addr].delegatedBy.remove(_msgSender());
        } else {
            
        }
    }
    
    /**
     * @dev This method triggers the complete(stage), if it hasn't successfully been triggered yet in the contract. 
     * The complete(stage) method works like this: if stageBlockNumber[N] has not passed yet then reject. Otherwise it wraps up the stage as follows, and then increments 'stage':
     * @param stageID Stage number
     */
    function complete(uint256 stageID) public onlyOwner canCompleted(stageID) {
       _complete(stageID);
    }
  
	/**
	 * @dev need to be used after each pledge/enter
     * @param stageID Stage number
	 */
	function _turnStageToActive(uint256 stageID) internal {
	    
        if (
            (_contest._stages[stageID].active == false) && 
            (_contest._stages[stageID].amount >= _contest._stages[stageID].minAmount)
        ) {
            _contest._stages[stageID].active = true;
            // fill time
            _contest._stages[stageID].startTimestampUtc = block.timestamp;
            _contest._stages[stageID].endTimestampUtc = (block.timestamp)
                .add(_contest._stages[stageID].contestPeriod)
                .add(_contest._stages[stageID].votePeriod)
                .add(_contest._stages[stageID].revokePeriod);
            emit StageStartAnnounced(stageID);
        } else if (
            (_contest._stages[stageID].active == true) && 
            (_contest._stages[stageID].endTimestampUtc < block.timestamp)
        ) {
            // run complete
	        _complete(stageID);
	    } else {
            
        }
        
	}
	
	/**
	 * @dev logic for ending stage (calculate weights, pick winners, reward losers, turn to next stage)
     * @param stageID Stage number
	 */
	function _complete(uint256 stageID) internal  {
	    emit StageCompleted(stageID);

	    _calculateWeights(stageID);
	    uint256 percentWinnersLeft = _rewardWinners(stageID);
	    _rewardLosers(stageID, percentWinnersLeft);
	 
	    //mark stage completed
	    _contest._stages[stageID].completed = true;
	    
	    // switch to next stage
	    if (_contest.stagesCount == stageID.add(1)) {
            // just complete if last stage 
            
            emit ContestComplete();
        } else {
            // increment stage
            _contest.stage = (_contest.stage).add(1);
        }
        _accountForOperation(
            (OPERATION_COMPLETE << OPERATION_SHIFT_BITS) | stageID,
            uint256(uint160(_msgSender())),
            0
        );
	}
	
	/**
	 * @param amount amount
     * @param stageID Stage number
	 */
    function _pledge(
        uint256 amount, 
        uint256 stageID
    ) 
        internal 
        canPledge(stageID) 
        notInContestsList(stageID) 
    {
        _createParticipant(stageID);
        
        _contest._stages[stageID].pledgesList.add(_msgSender());
        
        // accumalate balance in current stage
        _contest._stages[stageID].participants[_msgSender()].balance = (
            _contest._stages[stageID].participants[_msgSender()].balance
            ).add(amount);
            
        // accumalate overall stage balance
        _contest._stages[stageID].amount = (
            _contest._stages[stageID].amount
            ).add(amount);
        
        _turnStageToActive(stageID);

        _accountForOperation(
            (OPERATION_PLEDGE << OPERATION_SHIFT_BITS) | stageID,
            uint256(uint160(_msgSender())),
            0
        );
    }
    
    /**
     * @param stageID Stage number
	 */
    function _enter(
        uint256 stageID
    ) 
        internal 
        notInContestsList(stageID) 
        notInPledgesList(stageID) 
        notInJudgesList(stageID) 
    {
        _turnStageToActive(stageID);
        _createParticipant(stageID);
        _contest._stages[stageID].contestsList.add(_msgSender());

        _accountForOperation(
            (OPERATION_ENTER << OPERATION_SHIFT_BITS) | stageID,
            uint256(uint160(_msgSender())),
            0
        );
    }
    
    /**
     * @param stageID Stage number
	 */
    function _leave(
        uint256 stageID
    ) 
        internal 
        inContestsList(stageID) 
    {
        _contest._stages[stageID].contestsList.remove(_msgSender());
        _contest._stages[stageID].participants[msg.sender].active = false;

        _accountForOperation(
            (OPERATION_LEAVE << OPERATION_SHIFT_BITS) | stageID,
            uint256(uint160(_msgSender())),
            0
        );
    }
    
    /**
     * @param stageID Stage number
	 */     
    function _createParticipant(uint256 stageID) internal {
        if (_contest._stages[stageID].participants[_msgSender()].active) {
             // ---
        } else {
            //Participant memory p;
            //_contest._stages[stageID].participants[_msgSender()] = p;
            _contest._stages[stageID].participants[_msgSender()].active = true;
        }
    }

    function _msgSender(
    ) 
        internal 
        view 
        virtual
        override(TrustedForwarder, ContextUpgradeable)
        returns (address signer) 
    {
        return TrustedForwarder._msgSender();
        
    }
error ForwarderCanNotBeOwner();
error DeniedForForwarder();
    function setTrustedForwarder(
        address forwarder
    ) 
        public 
        virtual
        override
        onlyOwner 
    {
        if (owner() == forwarder) {
            revert ForwarderCanNotBeOwner();
        }
        _setTrustedForwarder(forwarder);
    }

    function transferOwnership(
        address newOwner
    ) public 
        virtual 
        override 
        onlyOwner 
    {
        if (_isTrustedForwarder(msg.sender)) {
            revert DeniedForForwarder();
        }
        if (_isTrustedForwarder(newOwner)) {
            _setTrustedForwarder(address(0));
        }
        super.transferOwnership(newOwner);
        
    }

    
	////
	// private section
	////
	
	/**
     * @param stageID Stage number
	 */
	function _calculateWeights(uint256 stageID) private {
	       
        // loop via contestsList 
        // find it in participant 
        //     loop via votedBy
        //         in each calculate weight
        //             if delegatedBy empty  -- sum him balance only
        //             if delegatedBy not empty -- sum weight inside all who delegated
        // make array of winners
        // set balanceAfter
	    
	    address addrContestant;
	    address addrVotestant;
	    address addrWhoDelegated;
	    
	    for (uint256 i = 0; i < _contest._stages[stageID].contestsList.length(); i++) {
	        addrContestant = _contest._stages[stageID].contestsList.at(i);
	        for (uint256 j = 0; j < _contest._stages[stageID].participants[addrContestant].votedBy.length(); j++) {
	            addrVotestant = _contest._stages[stageID].participants[addrContestant].votedBy.at(j);
	            
                // sum votes
                _contest._stages[stageID].participants[addrContestant].weight = 
                _contest._stages[stageID].participants[addrContestant].weight.add(
                    _contest._stages[stageID].participants[addrVotestant].balance
                );
                
                // sum all delegated if exists
                for (uint256 k = 0; k < _contest._stages[stageID].participants[addrVotestant].delegatedBy.length(); k++) {
                    addrWhoDelegated = _contest._stages[stageID].participants[addrVotestant].delegatedBy.at(k);
                    _contest._stages[stageID].participants[addrContestant].weight = 
	                _contest._stages[stageID].participants[addrContestant].weight.add(
	                    _contest._stages[stageID].participants[addrWhoDelegated].balance
	                );
                }
	             
	        }
	        
	    }
	}
	
	/**
     * @param stageID Stage number
	 * @return percentLeft percents left if count of winners more that prizes. in that cases left percent distributed to losers
	 */
	function _rewardWinners(uint256 stageID) private returns(uint256 percentLeft)  {
	    
        uint256 indexPrize = 0;
	    address addrContestant;
	    
	    uint256 lenContestList = _contest._stages[stageID].contestsList.length();
	    if (lenContestList>0)  {
	    
    	    uint256[] memory weight = new uint256[](lenContestList);
    
    	    for (uint256 i = 0; i < lenContestList; i++) {
    	        addrContestant = _contest._stages[stageID].contestsList.at(i);
                weight[i] = _contest._stages[stageID].participants[addrContestant].weight;
    	    }
    	    weight = sortAsc(weight);
    
            // dev Note: 
            // the original implementation is an infinite loop. When. i is 0 the loop decrements it again, 
            // but since it's an unsigned integer it undeflows and loops back to the maximum uint 
            // so use  "for (uint i = a.length; i > 0; i--)" and in code "a[i-1]" 
    	    for (uint256 i = weight.length; i > 0; i--) {
    	       for (uint256 j = 0; j < lenContestList; j++) {
    	            addrContestant = _contest._stages[stageID].contestsList.at(j);
    	            if (
    	                (weight[i-1] > 0) &&
    	                (_contest._stages[stageID].participants[addrContestant].weight == weight[i-1]) &&
    	                (_contest._stages[stageID].participants[addrContestant].won == false) &&
    	                (_contest._stages[stageID].participants[addrContestant].active == true) &&
    	                (_contest._stages[stageID].participants[addrContestant].revoked == false)
    	            ) {
    	                 
    	                _contest._stages[stageID].participants[addrContestant].balanceAfter = (_contest._stages[stageID].amount)
    	                    .mul(_contest._stages[stageID].percentForWinners.at(indexPrize))
    	                    .div(100);
                    
                        _contest._stages[stageID].participants[addrContestant].won = true;
                        
                        indexPrize++;
                        break;
    	            }
    	        }
    	        if (indexPrize >= _contest._stages[stageID].percentForWinners.length()) {
    	            break;
    	        }
    	    }
	    }
	    
	    percentLeft = 0;
	    if (indexPrize < _contest._stages[stageID].percentForWinners.length()) {
	       for (uint256 i = indexPrize; i < _contest._stages[stageID].percentForWinners.length(); i++) {
	           percentLeft = percentLeft.add(_contest._stages[stageID].percentForWinners.at(i));
	       }
	    }
	    return percentLeft;
	}
	
    /**
     * @param stageID Stage number
	 * @param prizeWinLeftPercent percents left if count of winners more that prizes. in that cases left percent distributed to losers
	 */
	function _rewardLosers(uint256 stageID, uint256 prizeWinLeftPercent) private {
	    // calculate left percent
	    // calculate howmuch participant loose
	    // calculate and apply left weight
	    address addrContestant;
	    uint256 leftPercent = 100;
	    
	    uint256 prizecount = _contest._stages[stageID].percentForWinners.length();
	    for (uint256 i = 0; i < prizecount; i++) {
	        leftPercent = leftPercent.sub(_contest._stages[stageID].percentForWinners.at(i));
	    }

	    leftPercent = leftPercent.add(prizeWinLeftPercent); 
	    
	    uint256 loserParticipants = 0;
	    if (leftPercent > 0) {
	        for (uint256 j = 0; j < _contest._stages[stageID].contestsList.length(); j++) {
	            addrContestant = _contest._stages[stageID].contestsList.at(j);
	            
	            if (
	                (_contest._stages[stageID].participants[addrContestant].won == false) &&
	                (_contest._stages[stageID].participants[addrContestant].active == true) &&
	                (_contest._stages[stageID].participants[addrContestant].revoked == false)
	            ) {
	                loserParticipants++;
	            }
	        }

	        if (loserParticipants > 0) {
	            uint256 rewardLoser = (_contest._stages[stageID].amount).mul(leftPercent).div(100).div(loserParticipants);
	            
	            for (uint256 j = 0; j < _contest._stages[stageID].contestsList.length(); j++) {
    	            addrContestant = _contest._stages[stageID].contestsList.at(j);
    	            
    	            if (
    	                (_contest._stages[stageID].participants[addrContestant].won == false) &&
    	                (_contest._stages[stageID].participants[addrContestant].active == true) &&
    	                (_contest._stages[stageID].participants[addrContestant].revoked == false)
    	            ) {
    	                _contest._stages[stageID].participants[addrContestant].balanceAfter = rewardLoser;
    	            }
    	        }
	        }
	    }
	}
    
    // useful method to sort native memory array 
    function sortAsc(uint256[] memory data) private returns(uint[] memory) {
       quickSortAsc(data, int(0), int(data.length - 1));
       return data;
    }
    
    function quickSortAsc(uint[] memory arr, int left, int right) private {
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortAsc(arr, left, j);
        if (i < right)
            quickSortAsc(arr, i, right);
    }

}