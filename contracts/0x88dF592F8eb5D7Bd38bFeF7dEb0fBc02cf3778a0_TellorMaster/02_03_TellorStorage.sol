// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

/**
 * @title Tellor Oracle Storage Library
 * @dev Contains all the variables/structs used by Tellor
 */

contract TellorStorage {
    //Internal struct for use in proof-of-work submission
    struct Details {
        uint256 value;
        address miner;
    }

    struct Dispute {
        bytes32 hash; //unique hash of dispute: keccak256(_miner,_requestId,_timestamp)
        int256 tally; //current tally of votes for - against measure
        bool executed; //is the dispute settled
        bool disputeVotePassed; //did the vote pass?
        bool isPropFork; //true for fork proposal NEW
        address reportedMiner; //miner who submitted the 'bad value' will get disputeFee if dispute vote fails
        address reportingParty; //miner reporting the 'bad value'-pay disputeFee will get reportedMiner's stake if dispute vote passes
        address proposedForkAddress; //new fork address (if fork proposal)
        mapping(bytes32 => uint256) disputeUintVars;
        //Each of the variables below is saved in the mapping disputeUintVars for each disputeID
        //e.g. TellorStorageStruct.DisputeById[disputeID].disputeUintVars[keccak256("requestId")]
        //These are the variables saved in this mapping:
        // uint keccak256("requestId");//apiID of disputed value
        // uint keccak256("timestamp");//timestamp of disputed value
        // uint keccak256("value"); //the value being disputed
        // uint keccak256("minExecutionDate");//7 days from when dispute initialized
        // uint keccak256("numberOfVotes");//the number of parties who have voted on the measure
        // uint keccak256("blockNumber");// the blocknumber for which votes will be calculated from
        // uint keccak256("minerSlot"); //index in dispute array
        // uint keccak256("fee"); //fee paid corresponding to dispute
        mapping(address => bool) voted; //mapping of address to whether or not they voted
    }

    struct StakeInfo {
        uint256 currentStatus; //0-not Staked, 1=Staked, 2=LockedForWithdraw 3= OnDispute 4=ReadyForUnlocking 5=Unlocked
        uint256 startDate; //stake start date
    }

    //Internal struct to allow balances to be queried by blocknumber for voting purposes
    struct Checkpoint {
        uint128 fromBlock; // fromBlock is the block number that the value was generated from
        uint128 value; // value is the amount of tokens at a specific block number
    }

    struct Request {
        uint256[] requestTimestamps; //array of all newValueTimestamps requested
        mapping(bytes32 => uint256) apiUintVars;
        //Each of the variables below is saved in the mapping apiUintVars for each api request
        //e.g. requestDetails[_requestId].apiUintVars[keccak256("totalTip")]
        //These are the variables saved in this mapping:
        // uint keccak256("requestQPosition"); //index in requestQ
        // uint keccak256("totalTip");//bonus portion of payout
        mapping(uint256 => uint256) minedBlockNum; //[apiId][minedTimestamp]=>block.number
        //This the time series of finalValues stored by the contract where uint UNIX timestamp is mapped to value
        mapping(uint256 => uint256) finalValues;
        mapping(uint256 => bool) inDispute; //checks if API id is in dispute or finalized.
        mapping(uint256 => address[5]) minersByValue;
        mapping(uint256 => uint256[5]) valuesByTimestamp;
    }

    uint256[51] requestQ; //uint50 array of the top50 requests by payment amount
    uint256[] public newValueTimestamps; //array of all timestamps requested
    //Address fields in the Tellor contract are saved the addressVars mapping
    //e.g. addressVars[keccak256("tellorContract")] = address
    //These are the variables saved in this mapping:
    // address keccak256("tellorContract");//Tellor address
    // address  keccak256("_owner");//Tellor Owner address
    // address  keccak256("_deity");//Tellor Owner that can do things at will
    // address  keccak256("pending_owner"); // The proposed new owner
    //uint fields in the Tellor contract are saved the uintVars mapping
    //e.g. uintVars[keccak256("decimals")] = uint
    //These are the variables saved in this mapping:
    // keccak256("decimals");    //18 decimal standard ERC20
    // keccak256("disputeFee");//cost to dispute a mined value
    // keccak256("disputeCount");//totalHistoricalDisputes
    // keccak256("total_supply"); //total_supply of the token in circulation
    // keccak256("stakeAmount");//stakeAmount for miners (we can cut gas if we just hardcoded it in...or should it be variable?)
    // keccak256("stakerCount"); //number of parties currently staked
    // keccak256("timeOfLastNewValue"); // time of last challenge solved
    // keccak256("difficulty"); // Difficulty of current block
    // keccak256("currentTotalTips"); //value of highest api/timestamp PayoutPool
    // keccak256("currentRequestId"); //API being mined--updates with the ApiOnQ Id
    // keccak256("requestCount"); // total number of requests through the system
    // keccak256("slotProgress");//Number of miners who have mined this value so far
    // keccak256("miningReward");//Mining Reward in PoWo tokens given to all miners per value
    // keccak256("timeTarget"); //The time between blocks (mined Oracle values)
    // keccak256("_tblock"); //
    // keccak256("runningTips"); // VAriable to track running tips
    // keccak256("currentReward"); // The current reward
    // keccak256("devShare"); // The amount directed towards th devShare
    // keccak256("currentTotalTips"); //

    //This is a boolean that tells you if a given challenge has been completed by a given miner
    mapping(uint256 => uint256) requestIdByTimestamp; //minedTimestamp to apiId
    mapping(uint256 => uint256) requestIdByRequestQIndex; //link from payoutPoolIndex (position in payout pool array) to apiId
    mapping(uint256 => Dispute) public disputesById; //disputeId=> Dispute details
    mapping(bytes32 => uint256) public requestIdByQueryHash; // api bytes32 gets an id = to count of requests array
    mapping(bytes32 => uint256) public disputeIdByDisputeHash; //maps a hash to an ID for each dispute
    mapping(bytes32 => mapping(address => bool)) public minersByChallenge;
    Details[5] public currentMiners; //This struct is for organizing the five mined values to find the median
    mapping(address => StakeInfo) stakerDetails; //mapping from a persons address to their staking info
    mapping(uint256 => Request) requestDetails;

    mapping(bytes32 => uint256) public uints;
    mapping(bytes32 => address) public addresses;
    mapping(bytes32 => bytes32) public bytesVars;

    //ERC20 storage
    mapping(address => Checkpoint[]) public balances;
    mapping(address => mapping(address => uint256)) public _allowances;

    //Migration storage
    mapping(address => bool) public migrated;
}