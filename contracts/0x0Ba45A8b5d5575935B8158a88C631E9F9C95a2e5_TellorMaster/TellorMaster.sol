/**
 *Submitted for verification at Etherscan.io on 2019-08-01
*/

pragma solidity ^0.5.0;


//Functions for retrieving min and Max in 51 length array (requestQ)
//Taken partly from: https://github.com/modular-network/ethereum-libraries-array-utils/blob/master/contracts/Array256Lib.sol

library Utilities{

    /**
    * @dev Returns the minimum value in an array.
    */
    function getMax(uint[51] memory data) internal pure returns(uint256 max,uint256 maxIndex) {
        max = data[1];
        maxIndex;
        for(uint i=1;i < data.length;i++){
            if(data[i] > max){
                max = data[i];
                maxIndex = i;
                }
        }
    }

    /**
    * @dev Returns the minimum value in an array.
    */
    function getMin(uint[51] memory data) internal pure returns(uint256 min,uint256 minIndex) {
        minIndex = data.length - 1;
        min = data[minIndex];
        for(uint i = data.length-1;i > 0;i--) {
            if(data[i] < min) {
                min = data[i];
                minIndex = i;
            }
        }
  }




  // /// @dev Returns the minimum value and position in an array.
  // //@note IT IGNORES THE 0 INDEX
  //   function getMin(uint[51] memory arr) internal pure returns (uint256 min, uint256 minIndex) {
  //     assembly {
  //         minIndex := 50
  //         min := mload(add(arr, mul(minIndex , 0x20)))
  //         for {let i := 49 } gt(i,0) { i := sub(i, 1) } {
  //             let item := mload(add(arr, mul(i, 0x20)))
  //             if lt(item,min){
  //                 min := item
  //                 minIndex := i
  //             }
  //         }
  //     }
  //   }


  
  // function getMax(uint256[51] memory arr) internal pure returns (uint256 max, uint256 maxIndex) {
  //     assembly {
  //         for { let i := 0 } lt(i,51) { i := add(i, 1) } {
  //             let item := mload(add(arr, mul(i, 0x20)))
  //             if lt(max, item) {
  //                 max := item
  //                 maxIndex := i
  //             }
  //         }
  //     }
  //   }





  }


/**
* @title Tellor Getters Library
* @dev This is the getter library for all variables in the Tellor Tributes system. TellorGetters references this 
* libary for the getters logic
*/
library TellorGettersLibrary{
    using SafeMath for uint256;

    event NewTellorAddress(address _newTellor); //emmited when a proposed fork is voted true

    /*Functions*/

    //The next two functions are onlyOwner functions.  For Tellor to be truly decentralized, we will need to transfer the Deity to the 0 address.
    //Only needs to be in library
    /**
    * @dev This function allows us to set a new Deity (or remove it) 
    * @param _newDeity address of the new Deity of the tellor system 
    */
    function changeDeity(TellorStorage.TellorStorageStruct storage self, address _newDeity) internal{
        require(self.addressVars[keccak256("_deity")] == msg.sender);
        self.addressVars[keccak256("_deity")] =_newDeity;
    }


    //Only needs to be in library
    /**
    * @dev This function allows the deity to upgrade the Tellor System
    * @param _tellorContract address of new updated TellorCore contract
    */
    function changeTellorContract(TellorStorage.TellorStorageStruct storage self,address _tellorContract) internal{
        require(self.addressVars[keccak256("_deity")] == msg.sender);
        self.addressVars[keccak256("tellorContract")]= _tellorContract;
        emit NewTellorAddress(_tellorContract);
    }


    /*Tellor Getters*/

    /**
    * @dev This function tells you if a given challenge has been completed by a given miner
    * @param _challenge the challenge to search for
    * @param _miner address that you want to know if they solved the challenge
    * @return true if the _miner address provided solved the 
    */
    function didMine(TellorStorage.TellorStorageStruct storage self, bytes32 _challenge,address _miner) internal view returns(bool){
        return self.minersByChallenge[_challenge][_miner];
    }
    

    /**
    * @dev Checks if an address voted in a dispute
    * @param _disputeId to look up
    * @param _address of voting party to look up
    * @return bool of whether or not party voted
    */
    function didVote(TellorStorage.TellorStorageStruct storage self,uint _disputeId, address _address) internal view returns(bool){
        return self.disputesById[_disputeId].voted[_address];
    }


    /**
    * @dev allows Tellor to read data from the addressVars mapping
    * @param _data is the keccak256("variable_name") of the variable that is being accessed. 
    * These are examples of how the variables are saved within other functions:
    * addressVars[keccak256("_owner")]
    * addressVars[keccak256("tellorContract")]
    */
    function getAddressVars(TellorStorage.TellorStorageStruct storage self, bytes32 _data) view internal returns(address){
        return self.addressVars[_data];
    }


    /**
    * @dev Gets all dispute variables
    * @param _disputeId to look up
    * @return bytes32 hash of dispute 
    * @return bool executed where true if it has been voted on
    * @return bool disputeVotePassed
    * @return bool isPropFork true if the dispute is a proposed fork
    * @return address of reportedMiner
    * @return address of reportingParty
    * @return address of proposedForkAddress
    * @return uint of requestId
    * @return uint of timestamp
    * @return uint of value
    * @return uint of minExecutionDate
    * @return uint of numberOfVotes
    * @return uint of blocknumber
    * @return uint of minerSlot
    * @return uint of quorum
    * @return uint of fee
    * @return int count of the current tally
    */
    function getAllDisputeVars(TellorStorage.TellorStorageStruct storage self,uint _disputeId) internal view returns(bytes32, bool, bool, bool, address, address, address,uint[9] memory, int){
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];
        return(disp.hash,disp.executed, disp.disputeVotePassed, disp.isPropFork, disp.reportedMiner, disp.reportingParty,disp.proposedForkAddress,[disp.disputeUintVars[keccak256("requestId")], disp.disputeUintVars[keccak256("timestamp")], disp.disputeUintVars[keccak256("value")], disp.disputeUintVars[keccak256("minExecutionDate")], disp.disputeUintVars[keccak256("numberOfVotes")], disp.disputeUintVars[keccak256("blockNumber")], disp.disputeUintVars[keccak256("minerSlot")], disp.disputeUintVars[keccak256("quorum")],disp.disputeUintVars[keccak256("fee")]],disp.tally);
    }


    /**
    * @dev Getter function for variables for the requestId being currently mined(currentRequestId)
    * @return current challenge, curretnRequestId, level of difficulty, api/query string, and granularity(number of decimals requested), total tip for the request 
    */
    function getCurrentVariables(TellorStorage.TellorStorageStruct storage self) internal view returns(bytes32, uint, uint,string memory,uint,uint){    
        return (self.currentChallenge,self.uintVars[keccak256("currentRequestId")],self.uintVars[keccak256("difficulty")],self.requestDetails[self.uintVars[keccak256("currentRequestId")]].queryString,self.requestDetails[self.uintVars[keccak256("currentRequestId")]].apiUintVars[keccak256("granularity")],self.requestDetails[self.uintVars[keccak256("currentRequestId")]].apiUintVars[keccak256("totalTip")]);
    }


    /**
    * @dev Checks if a given hash of miner,requestId has been disputed
    * @param _hash is the sha256(abi.encodePacked(_miners[2],_requestId));
    * @return uint disputeId
    */
    function getDisputeIdByDisputeHash(TellorStorage.TellorStorageStruct storage self,bytes32 _hash) internal view returns(uint){
        return  self.disputeIdByDisputeHash[_hash];
    }


    /**
    * @dev Checks for uint variables in the disputeUintVars mapping based on the disuputeId
    * @param _disputeId is the dispute id;
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is 
    * the variables/strings used to save the data in the mapping. The variables names are  
    * commented out under the disputeUintVars under the Dispute struct
    * @return uint value for the bytes32 data submitted
    */
    function getDisputeUintVars(TellorStorage.TellorStorageStruct storage self,uint _disputeId,bytes32 _data) internal view returns(uint){
        return self.disputesById[_disputeId].disputeUintVars[_data];
    }

    
    /**
    * @dev Gets the a value for the latest timestamp available
    * @return value for timestamp of last proof of work submited
    * @return true if the is a timestamp for the lastNewValue
    */
    function getLastNewValue(TellorStorage.TellorStorageStruct storage self) internal view returns(uint,bool){
        return (retrieveData(self,self.requestIdByTimestamp[self.uintVars[keccak256("timeOfLastNewValue")]], self.uintVars[keccak256("timeOfLastNewValue")]),true);
    }


    /**
    * @dev Gets the a value for the latest timestamp available
    * @param _requestId being requested
    * @return value for timestamp of last proof of work submited and if true if it exist or 0 and false if it doesn't
    */
    function getLastNewValueById(TellorStorage.TellorStorageStruct storage self,uint _requestId) internal view returns(uint,bool){
        TellorStorage.Request storage _request = self.requestDetails[_requestId]; 
        if(_request.requestTimestamps.length > 0){
            return (retrieveData(self,_requestId,_request.requestTimestamps[_request.requestTimestamps.length - 1]),true);
        }
        else{
            return (0,false);
        }
    }


    /**
    * @dev Gets blocknumber for mined timestamp 
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up blocknumber
    * @return uint of the blocknumber which the dispute was mined
    */
    function getMinedBlockNum(TellorStorage.TellorStorageStruct storage self,uint _requestId, uint _timestamp) internal view returns(uint){
        return self.requestDetails[_requestId].minedBlockNum[_timestamp];
    }


    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp 
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up miners for
    * @return the 5 miners' addresses
    */
    function getMinersByRequestIdAndTimestamp(TellorStorage.TellorStorageStruct storage self, uint _requestId, uint _timestamp) internal view returns(address[5] memory){
        return self.requestDetails[_requestId].minersByValue[_timestamp];
    }


    /**
    * @dev Get the name of the token
    * @return string of the token name
    */
    function getName(TellorStorage.TellorStorageStruct storage self) internal pure returns(string memory){
        return "Tellor Tributes";
    }


    /**
    * @dev Counts the number of values that have been submited for the request 
    * if called for the currentRequest being mined it can tell you how many miners have submitted a value for that
    * request so far
    * @param _requestId the requestId to look up
    * @return uint count of the number of values received for the requestId
    */
    function getNewValueCountbyRequestId(TellorStorage.TellorStorageStruct storage self, uint _requestId) internal view returns(uint){
        return self.requestDetails[_requestId].requestTimestamps.length;
    }


    /**
    * @dev Getter function for the specified requestQ index
    * @param _index to look up in the requestQ array
    * @return uint of reqeuestId
    */
    function getRequestIdByRequestQIndex(TellorStorage.TellorStorageStruct storage self, uint _index) internal view returns(uint){
        require(_index <= 50);
        return self.requestIdByRequestQIndex[_index];
    }


    /**
    * @dev Getter function for requestId based on timestamp 
    * @param _timestamp to check requestId
    * @return uint of reqeuestId
    */
    function getRequestIdByTimestamp(TellorStorage.TellorStorageStruct storage self, uint _timestamp) internal view returns(uint){    
        return self.requestIdByTimestamp[_timestamp];
    }


    /**
    * @dev Getter function for requestId based on the qeuaryHash
    * @param _queryHash hash(of string api and granularity) to check if a request already exists
    * @return uint requestId
    */
    function getRequestIdByQueryHash(TellorStorage.TellorStorageStruct storage self, bytes32 _queryHash) internal view returns(uint){    
        return self.requestIdByQueryHash[_queryHash];
    }


    /**
    * @dev Getter function for the requestQ array
    * @return the requestQ arrray
    */
    function getRequestQ(TellorStorage.TellorStorageStruct storage self) view internal returns(uint[51] memory){
        return self.requestQ;
    }


    /**
    * @dev Allowes access to the uint variables saved in the apiUintVars under the requestDetails struct
    * for the requestId specified
    * @param _requestId to look up
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is 
    * the variables/strings used to save the data in the mapping. The variables names are  
    * commented out under the apiUintVars under the requestDetails struct
    * @return uint value of the apiUintVars specified in _data for the requestId specified
    */
    function getRequestUintVars(TellorStorage.TellorStorageStruct storage self,uint _requestId,bytes32 _data) internal view returns(uint){
        return self.requestDetails[_requestId].apiUintVars[_data];
    }


    /**
    * @dev Gets the API struct variables that are not mappings
    * @param _requestId to look up
    * @return string of api to query
    * @return string of symbol of api to query
    * @return bytes32 hash of string
    * @return bytes32 of the granularity(decimal places) requested
    * @return uint of index in requestQ array
    * @return uint of current payout/tip for this requestId
    */
    function getRequestVars(TellorStorage.TellorStorageStruct storage self,uint _requestId) internal view returns(string memory,string memory, bytes32,uint, uint, uint) {
        TellorStorage.Request storage _request = self.requestDetails[_requestId]; 
        return (_request.queryString,_request.dataSymbol,_request.queryHash, _request.apiUintVars[keccak256("granularity")],_request.apiUintVars[keccak256("requestQPosition")],_request.apiUintVars[keccak256("totalTip")]);
    }


    /**
    * @dev This function allows users to retireve all information about a staker
    * @param _staker address of staker inquiring about
    * @return uint current state of staker
    * @return uint startDate of staking
    */
    function getStakerInfo(TellorStorage.TellorStorageStruct storage self,address _staker) internal view returns(uint,uint){
        return (self.stakerDetails[_staker].currentStatus,self.stakerDetails[_staker].startDate);
    }


    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp 
    * @param _requestId to look up
    * @param _timestamp is the timestampt to look up miners for
    * @return address[5] array of 5 addresses ofminers that mined the requestId
    */
    function getSubmissionsByTimestamp(TellorStorage.TellorStorageStruct storage self, uint _requestId, uint _timestamp) internal view returns(uint[5] memory){
        return self.requestDetails[_requestId].valuesByTimestamp[_timestamp];
    }

    /**
    * @dev Get the symbol of the token
    * @return string of the token symbol
    */
    function getSymbol(TellorStorage.TellorStorageStruct storage self) internal pure returns(string memory){
        return "TT";
    } 


    /**
    * @dev Gets the timestamp for the value based on their index
    * @param _requestID is the requestId to look up
    * @param _index is the value index to look up
    * @return uint timestamp
    */
    function getTimestampbyRequestIDandIndex(TellorStorage.TellorStorageStruct storage self,uint _requestID, uint _index) internal view returns(uint){
        return self.requestDetails[_requestID].requestTimestamps[_index];
    }


    /**
    * @dev Getter for the variables saved under the TellorStorageStruct uintVars variable
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is 
    * the variables/strings used to save the data in the mapping. The variables names are  
    * commented out under the uintVars under the TellorStorageStruct struct
    * This is an example of how data is saved into the mapping within other functions: 
    * self.uintVars[keccak256("stakerCount")]
    * @return uint of specified variable  
    */ 
    function getUintVar(TellorStorage.TellorStorageStruct storage self,bytes32 _data) view internal returns(uint){
        return self.uintVars[_data];
    }


    /**
    * @dev Getter function for next requestId on queue/request with highest payout at time the function is called
    * @return onDeck/info on request with highest payout-- RequestId, Totaltips, and API query string
    */
    function getVariablesOnDeck(TellorStorage.TellorStorageStruct storage self) internal view returns(uint, uint,string memory){ 
        uint newRequestId = getTopRequestID(self);
        return (newRequestId,self.requestDetails[newRequestId].apiUintVars[keccak256("totalTip")],self.requestDetails[newRequestId].queryString);
    }


    /**
    * @dev Getter function for the request with highest payout. This function is used within the getVariablesOnDeck function
    * @return uint _requestId of request with highest payout at the time the function is called
    */
    function getTopRequestID(TellorStorage.TellorStorageStruct storage self) internal view returns(uint _requestId){
            uint _max;
            uint _index;
            (_max,_index) = Utilities.getMax(self.requestQ);
             _requestId = self.requestIdByRequestQIndex[_index];
    }


    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp 
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up miners for
    * @return bool true if requestId/timestamp is under dispute
    */
    function isInDispute(TellorStorage.TellorStorageStruct storage self, uint _requestId, uint _timestamp) internal view returns(bool){
        return self.requestDetails[_requestId].inDispute[_timestamp];
    }


    /**
    * @dev Retreive value from oracle based on requestId/timestamp
    * @param _requestId being requested
    * @param _timestamp to retreive data/value from
    * @return uint value for requestId/timestamp submitted
    */
    function retrieveData(TellorStorage.TellorStorageStruct storage self, uint _requestId, uint _timestamp) internal view returns (uint) {
        return self.requestDetails[_requestId].finalValues[_timestamp];
    }


    /**
    * @dev Getter for the total_supply of oracle tokens
    * @return uint total supply
    */
    function totalSupply(TellorStorage.TellorStorageStruct storage self) internal view returns (uint) {
       return self.uintVars[keccak256("total_supply")];
    }

}







pragma solidity ^0.5.0;

//Slightly modified SafeMath library - includes a min and max function, removes useless div function
library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function add(int256 a, int256 b) internal pure returns (int256 c) {
    if(b > 0){
      c = a + b;
      assert(c >= a);
    }
    else{
      c = a + b;
      assert(c <= a);
    }

  }

  function max(uint a, uint b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  function max(int256 a, int256 b) internal pure returns (uint256) {
    return a > b ? uint(a) : uint(b);
  }

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256 c) {
    if(b > 0){
      c = a - b;
      assert(c <= a);
    }
    else{
      c = a - b;
      assert(c >= a);
    }

  }

}



/**
 * @title Tellor Oracle Storage Library
 * @dev Contains all the variables/structs used by Tellor
 */

library TellorStorage {
    //Internal struct for use in proof-of-work submission
    struct Details {
        uint value;
        address miner;
    }

    struct Dispute {
        bytes32 hash;//unique hash of dispute: keccak256(_miner,_requestId,_timestamp)
        int tally;//current tally of votes for - against measure
        bool executed;//is the dispute settled
        bool disputeVotePassed;//did the vote pass?
        bool isPropFork; //true for fork proposal NEW
        address reportedMiner; //miner who alledgedly submitted the 'bad value' will get disputeFee if dispute vote fails
        address reportingParty;//miner reporting the 'bad value'-pay disputeFee will get reportedMiner's stake if dispute vote passes
        address proposedForkAddress;//new fork address (if fork proposal)
        mapping(bytes32 => uint) disputeUintVars;
        //Each of the variables below is saved in the mapping disputeUintVars for each disputeID
        //e.g. TellorStorageStruct.DisputeById[disputeID].disputeUintVars[keccak256("requestId")]
        //These are the variables saved in this mapping:
            // uint keccak256("requestId");//apiID of disputed value
            // uint keccak256("timestamp");//timestamp of distputed value
            // uint keccak256("value"); //the value being disputed
            // uint keccak256("minExecutionDate");//7 days from when dispute initialized
            // uint keccak256("numberOfVotes");//the number of parties who have voted on the measure
            // uint keccak256("blockNumber");// the blocknumber for which votes will be calculated from
            // uint keccak256("minerSlot"); //index in dispute array
            // uint keccak256("quorum"); //quorum for dispute vote NEW
            // uint keccak256("fee"); //fee paid corresponding to dispute
        mapping (address => bool) voted; //mapping of address to whether or not they voted
    }

    struct StakeInfo {
        uint currentStatus;//0-not Staked, 1=Staked, 2=LockedForWithdraw 3= OnDispute
        uint startDate; //stake start date
    }

    //Internal struct to allow balances to be queried by blocknumber for voting purposes
    struct  Checkpoint {
        uint128 fromBlock;// fromBlock is the block number that the value was generated from
        uint128 value;// value is the amount of tokens at a specific block number
    }

    struct Request {
        string queryString;//id to string api
        string dataSymbol;//short name for api request
        bytes32 queryHash;//hash of api string and granularity e.g. keccak256(abi.encodePacked(_sapi,_granularity))
        uint[]  requestTimestamps; //array of all newValueTimestamps requested
        mapping(bytes32 => uint) apiUintVars;
        //Each of the variables below is saved in the mapping apiUintVars for each api request
        //e.g. requestDetails[_requestId].apiUintVars[keccak256("totalTip")]
        //These are the variables saved in this mapping:
            // uint keccak256("granularity"); //multiplier for miners
            // uint keccak256("requestQPosition"); //index in requestQ
            // uint keccak256("totalTip");//bonus portion of payout
        mapping(uint => uint) minedBlockNum;//[apiId][minedTimestamp]=>block.number
        mapping(uint => uint) finalValues;//This the time series of finalValues stored by the contract where uint UNIX timestamp is mapped to value
        mapping(uint => bool) inDispute;//checks if API id is in dispute or finalized.
        mapping(uint => address[5]) minersByValue;
        mapping(uint => uint[5])valuesByTimestamp;
    }

    struct TellorStorageStruct {
        bytes32 currentChallenge; //current challenge to be solved
        uint[51]  requestQ; //uint50 array of the top50 requests by payment amount
        uint[]  newValueTimestamps; //array of all timestamps requested
        Details[5]  currentMiners; //This struct is for organizing the five mined values to find the median
        mapping(bytes32 => address) addressVars;
        //Address fields in the Tellor contract are saved the addressVars mapping
        //e.g. addressVars[keccak256("tellorContract")] = address
        //These are the variables saved in this mapping:
            // address keccak256("tellorContract");//Tellor address
            // address  keccak256("_owner");//Tellor Owner address
            // address  keccak256("_deity");//Tellor Owner that can do things at will
        mapping(bytes32 => uint) uintVars; 
        //uint fields in the Tellor contract are saved the uintVars mapping
        //e.g. uintVars[keccak256("decimals")] = uint
        //These are the variables saved in this mapping:
            // keccak256("decimals");    //18 decimal standard ERC20
            // keccak256("disputeFee");//cost to dispute a mined value
            // keccak256("disputeCount");//totalHistoricalDisputes
            // keccak256("total_supply"); //total_supply of the token in circulation
            // keccak256("stakeAmount");//stakeAmount for miners (we can cut gas if we just hardcode it in...or should it be variable?)
            // keccak256("stakerCount"); //number of parties currently staked
            // keccak256("timeOfLastNewValue"); // time of last challenge solved
            // keccak256("difficulty"); // Difficulty of current block
            // keccak256("currentTotalTips"); //value of highest api/timestamp PayoutPool
            // keccak256("currentRequestId"); //API being mined--updates with the ApiOnQ Id
            // keccak256("requestCount"); // total number of requests through the system
            // keccak256("slotProgress");//Number of miners who have mined this value so far
            // keccak256("miningReward");//Mining Reward in PoWo tokens given to all miners per value
            // keccak256("timeTarget"); //The time between blocks (mined Oracle values)
        mapping(bytes32 => mapping(address=>bool)) minersByChallenge;//This is a boolean that tells you if a given challenge has been completed by a given miner
        mapping(uint => uint) requestIdByTimestamp;//minedTimestamp to apiId
        mapping(uint => uint) requestIdByRequestQIndex; //link from payoutPoolIndex (position in payout pool array) to apiId
        mapping(uint => Dispute) disputesById;//disputeId=> Dispute details
        mapping (address => Checkpoint[]) balances; //balances of a party given blocks
        mapping(address => mapping (address => uint)) allowed; //allowance for a given party and approver
        mapping(address => StakeInfo)  stakerDetails;//mapping from a persons address to their staking info
        mapping(uint => Request) requestDetails;//mapping of apiID to details
        mapping(bytes32 => uint) requestIdByQueryHash;// api bytes32 gets an id = to count of requests array
        mapping(bytes32 => uint) disputeIdByDisputeHash;//maps a hash to an ID for each dispute
    }
}


/**
* @title Tellor Transfer
* @dev Contais the methods related to transfers and ERC20. Tellor.sol and TellorGetters.sol
* reference this library for function's logic.
*/
library TellorTransfer {
    using SafeMath for uint256;

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);//ERC20 Approval event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);//ERC20 Transfer Event

    /*Functions*/
    
    /**
    * @dev Allows for a transfer of tokens to _to
    * @param _to The address to send tokens to
    * @param _amount The amount of tokens to send
    * @return true if transfer is successful
    */
    function transfer(TellorStorage.TellorStorageStruct storage self, address _to, uint256 _amount) public returns (bool success) {
        doTransfer(self,msg.sender, _to, _amount);
        return true;
    }


    /**
    * @notice Send _amount tokens to _to from _from on the condition it
    * is approved by _from
    * @param _from The address holding the tokens being transferred
    * @param _to The address of the recipient
    * @param _amount The amount of tokens to be transferred
    * @return True if the transfer was successful
    */
    function transferFrom(TellorStorage.TellorStorageStruct storage self, address _from, address _to, uint256 _amount) public returns (bool success) {
        require(self.allowed[_from][msg.sender] >= _amount);
        self.allowed[_from][msg.sender] -= _amount;
        doTransfer(self,_from, _to, _amount);
        return true;
    }


    /**
    * @dev This function approves a _spender an _amount of tokens to use
    * @param _spender address
    * @param _amount amount the spender is being approved for
    * @return true if spender appproved successfully
    */
    function approve(TellorStorage.TellorStorageStruct storage self, address _spender, uint _amount) public returns (bool) {
        require(allowedToTrade(self,msg.sender,_amount));
        require(_spender != address(0));
        self.allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }


    /**
    * @param _user address of party with the balance
    * @param _spender address of spender of parties said balance
    * @return Returns the remaining allowance of tokens granted to the _spender from the _user
    */
    function allowance(TellorStorage.TellorStorageStruct storage self,address _user, address _spender) public view returns (uint) {
       return self.allowed[_user][_spender]; 
    }


    /**
    * @dev Completes POWO transfers by updating the balances on the current block number
    * @param _from address to transfer from
    * @param _to addres to transfer to
    * @param _amount to transfer
    */
    function doTransfer(TellorStorage.TellorStorageStruct storage self, address _from, address _to, uint _amount) public {
        require(_amount > 0);
        require(_to != address(0));
        require(allowedToTrade(self,_from,_amount)); //allowedToTrade checks the stakeAmount is removed from balance if the _user is staked
        uint previousBalance = balanceOfAt(self,_from, block.number);
        updateBalanceAtNow(self.balances[_from], previousBalance - _amount);
        previousBalance = balanceOfAt(self,_to, block.number);
        require(previousBalance + _amount >= previousBalance); // Check for overflow
        updateBalanceAtNow(self.balances[_to], previousBalance + _amount);
        emit Transfer(_from, _to, _amount);
    }


    /**
    * @dev Gets balance of owner specified
    * @param _user is the owner address used to look up the balance
    * @return Returns the balance associated with the passed in _user
    */
    function balanceOf(TellorStorage.TellorStorageStruct storage self,address _user) public view returns (uint) {
        return balanceOfAt(self,_user, block.number);
    }


    /**
    * @dev Queries the balance of _user at a specific _blockNumber
    * @param _user The address from which the balance will be retrieved
    * @param _blockNumber The block number when the balance is queried
    * @return The balance at _blockNumber specified
    */
    function balanceOfAt(TellorStorage.TellorStorageStruct storage self,address _user, uint _blockNumber) public view returns (uint) {
        if ((self.balances[_user].length == 0) || (self.balances[_user][0].fromBlock > _blockNumber)) {
                return 0;
        }
     else {
        return getBalanceAt(self.balances[_user], _blockNumber);
     }
    }


    /**
    * @dev Getter for balance for owner on the specified _block number
    * @param checkpoints gets the mapping for the balances[owner]
    * @param _block is the block number to search the balance on
    * @return the balance at the checkpoint
    */
    function getBalanceAt(TellorStorage.Checkpoint[] storage checkpoints, uint _block) view public returns (uint) {
        if (checkpoints.length == 0) return 0;
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;
        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }


    /**
    * @dev This function returns whether or not a given user is allowed to trade a given amount 
    * and removing the staked amount from their balance if they are staked
    * @param _user address of user
    * @param _amount to check if the user can spend
    * @return true if they are allowed to spend the amount being checked
    */
    function allowedToTrade(TellorStorage.TellorStorageStruct storage self,address _user,uint _amount) public view returns(bool) {
        if(self.stakerDetails[_user].currentStatus >0){
            //Removes the stakeAmount from balance if the _user is staked
            if(balanceOf(self,_user).sub(self.uintVars[keccak256("stakeAmount")]).sub(_amount) >= 0){
                return true;
            }
        }
        else if(balanceOf(self,_user).sub(_amount) >= 0){
                return true;
        }
        return false;
    }
    

    /**
    * @dev Updates balance for from and to on the current block number via doTransfer
    * @param checkpoints gets the mapping for the balances[owner]
    * @param _value is the new balance
    */
    function updateBalanceAtNow(TellorStorage.Checkpoint[] storage checkpoints, uint _value) public {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               TellorStorage.Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
        } else {
               TellorStorage.Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
        }
    }
}




//import "./SafeMath.sol";

/**
* @title Tellor Dispute
* @dev Contais the methods related to disputes. Tellor.sol references this library for function's logic.
*/


library TellorDispute {
    using SafeMath for uint256;
    using SafeMath for int256;

    event NewDispute(uint indexed _disputeId, uint indexed _requestId, uint _timestamp, address _miner);//emitted when a new dispute is initialized
    event Voted(uint indexed _disputeID, bool _position, address indexed _voter);//emitted when a new vote happens
    event DisputeVoteTallied(uint indexed _disputeID, int _result,address indexed _reportedMiner,address _reportingParty, bool _active);//emitted upon dispute tally
    event NewTellorAddress(address _newTellor); //emmited when a proposed fork is voted true

    /*Functions*/
    
    /**
    * @dev Helps initialize a dispute by assigning it a disputeId
    * when a miner returns a false on the validate array(in Tellor.ProofOfWork) it sends the
    * invalidated value information to POS voting
    * @param _requestId being disputed
    * @param _timestamp being disputed
    * @param _minerIndex the index of the miner that submitted the value being disputed. Since each official value
    * requires 5 miners to submit a value.
    */
    function beginDispute(TellorStorage.TellorStorageStruct storage self,uint _requestId, uint _timestamp,uint _minerIndex) public {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        //require that no more than a day( (24 hours * 60 minutes)/10minutes=144 blocks) has gone by since the value was "mined"
        require(block.number- _request.minedBlockNum[_timestamp]<= 144);
        require(_request.minedBlockNum[_timestamp] > 0);
        require(_minerIndex < 5);
        
        //_miner is the miner being disputed. For every mined value 5 miners are saved in an array and the _minerIndex
        //provided by the party initiating the dispute
        address _miner = _request.minersByValue[_timestamp][_minerIndex];
        bytes32 _hash = keccak256(abi.encodePacked(_miner,_requestId,_timestamp));
        
        //Ensures that a dispute is not already open for the that miner, requestId and timestamp
        require(self.disputeIdByDisputeHash[_hash] == 0);
        TellorTransfer.doTransfer(self, msg.sender,address(this), self.uintVars[keccak256("disputeFee")]);
        
        //Increase the dispute count by 1
        self.uintVars[keccak256("disputeCount")] =  self.uintVars[keccak256("disputeCount")] + 1;
        
        //Sets the new disputeCount as the disputeId
        uint disputeId = self.uintVars[keccak256("disputeCount")];
        
        //maps the dispute hash to the disputeId
        self.disputeIdByDisputeHash[_hash] = disputeId;
        //maps the dispute to the Dispute struct
        self.disputesById[disputeId] = TellorStorage.Dispute({
            hash:_hash,
            isPropFork: false,
            reportedMiner: _miner,
            reportingParty: msg.sender,
            proposedForkAddress:address(0),
            executed: false,
            disputeVotePassed: false,
            tally: 0
            });
        
        //Saves all the dispute variables for the disputeId
        self.disputesById[disputeId].disputeUintVars[keccak256("requestId")] = _requestId;
        self.disputesById[disputeId].disputeUintVars[keccak256("timestamp")] = _timestamp;
        self.disputesById[disputeId].disputeUintVars[keccak256("value")] = _request.valuesByTimestamp[_timestamp][_minerIndex];
        self.disputesById[disputeId].disputeUintVars[keccak256("minExecutionDate")] = now + 7 days;
        self.disputesById[disputeId].disputeUintVars[keccak256("blockNumber")] = block.number;
        self.disputesById[disputeId].disputeUintVars[keccak256("minerSlot")] = _minerIndex;
        self.disputesById[disputeId].disputeUintVars[keccak256("fee")]  = self.uintVars[keccak256("disputeFee")];
        
        //Values are sorted as they come in and the official value is the median of the first five
        //So the "official value" miner is always minerIndex==2. If the official value is being 
        //disputed, it sets its status to inDispute(currentStatus = 3) so that users are made aware it is under dispute
        if(_minerIndex == 2){
            self.requestDetails[_requestId].inDispute[_timestamp] = true;
        }
        self.stakerDetails[_miner].currentStatus = 3;
        emit NewDispute(disputeId,_requestId,_timestamp,_miner);
    }


    /**
    * @dev Allows token holders to vote
    * @param _disputeId is the dispute id
    * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
    */
    function vote(TellorStorage.TellorStorageStruct storage self, uint _disputeId, bool _supportsDispute) public {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];
        
        //Get the voteWeight or the balance of the user at the time/blockNumber the disupte began
        uint voteWeight = TellorTransfer.balanceOfAt(self,msg.sender,disp.disputeUintVars[keccak256("blockNumber")]);
        
        //Require that the msg.sender has not voted
        require(disp.voted[msg.sender] != true);
        
        //Requre that the user had a balance >0 at time/blockNumber the disupte began
        require(voteWeight > 0);
        
        //ensures miners that are under dispute cannot vote
        require(self.stakerDetails[msg.sender].currentStatus != 3);
        
        //Update user voting status to true
        disp.voted[msg.sender] = true;
        
        //Update the number of votes for the dispute
        disp.disputeUintVars[keccak256("numberOfVotes")] += 1;
        
        //Update the quorum by adding the voteWeight
        disp.disputeUintVars[keccak256("quorum")] += voteWeight; 
        
        //If the user supports the dispute increase the tally for the dispute by the voteWeight
        //otherwise decrease it
        if (_supportsDispute) {
            disp.tally = disp.tally.add(int(voteWeight));
        } else {
            disp.tally = disp.tally.sub(int(voteWeight));
        }
        
        //Let the network know the user has voted on the dispute and their casted vote
        emit Voted(_disputeId,_supportsDispute,msg.sender);
    }


    /**
    * @dev tallies the votes.
    * @param _disputeId is the dispute id
    */
    function tallyVotes(TellorStorage.TellorStorageStruct storage self, uint _disputeId) public {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];
        TellorStorage.Request storage _request = self.requestDetails[disp.disputeUintVars[keccak256("requestId")]];

        //Ensure this has not already been executed/tallied
        require(disp.executed == false);

        //Ensure the time for voting has elapsed
        require(now > disp.disputeUintVars[keccak256("minExecutionDate")]);  

        //If the vote is not a proposed fork 
        if (disp.isPropFork== false){
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[disp.reportedMiner];  
            //If the vote for disputing a value is succesful(disp.tally >0) then unstake the reported 
            // miner and transfer the stakeAmount and dispute fee to the reporting party 
            if (disp.tally > 0 ) { 

                //Changing the currentStatus and startDate unstakes the reported miner and allows for the
                //transfer of the stakeAmount
                stakes.currentStatus = 0;
                stakes.startDate = now -(now % 86400);

                //Decreases the stakerCount since the miner's stake is being slashed
                self.uintVars[keccak256("stakerCount")]--;
                updateDisputeFee(self);

                //Transfers the StakeAmount from the reporded miner to the reporting party
                TellorTransfer.doTransfer(self, disp.reportedMiner,disp.reportingParty, self.uintVars[keccak256("stakeAmount")]);
                
                //Returns the dispute fee to the reportingParty
                TellorTransfer.doTransfer(self, address(this),disp.reportingParty,disp.disputeUintVars[keccak256("fee")]);
                
                //Set the dispute state to passed/true
                disp.disputeVotePassed = true;

                //If the dispute was succeful(miner found guilty) then update the timestamp value to zero
                //so that users don't use this datapoint
                if(_request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] == true){
                    _request.finalValues[disp.disputeUintVars[keccak256("timestamp")]] = 0;
                }

            //If the vote for disputing a value is unsuccesful then update the miner status from being on 
            //dispute(currentStatus=3) to staked(currentStatus =1) and tranfer the dispute fee to the miner
            } else {
                //Update the miner's current status to staked(currentStatus = 1)
                stakes.currentStatus = 1;              
                //tranfer the dispute fee to the miner
                TellorTransfer.doTransfer(self,address(this),disp.reportedMiner,disp.disputeUintVars[keccak256("fee")]);
                if(_request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] == true){
                    _request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] = false;
                }
            }
        //If the vote is for a proposed fork require a 20% quorum before excecuting the update to the new tellor contract address
        } else {
            if(disp.tally > 0 ){
                require(disp.disputeUintVars[keccak256("quorum")] >  (self.uintVars[keccak256("total_supply")] * 20 / 100));
                self.addressVars[keccak256("tellorContract")] = disp.proposedForkAddress;
                disp.disputeVotePassed = true;
                emit NewTellorAddress(disp.proposedForkAddress);
            }
        }
        
        //update the dispute status to executed
        disp.executed = true;
        emit DisputeVoteTallied(_disputeId,disp.tally,disp.reportedMiner,disp.reportingParty,disp.disputeVotePassed);
    }


    /**
    * @dev Allows for a fork to be proposed
    * @param _propNewTellorAddress address for new proposed Tellor
    */
    function proposeFork(TellorStorage.TellorStorageStruct storage self, address _propNewTellorAddress) public {
        bytes32 _hash = keccak256(abi.encodePacked(_propNewTellorAddress));
        require(self.disputeIdByDisputeHash[_hash] == 0);
        TellorTransfer.doTransfer(self, msg.sender,address(this), self.uintVars[keccak256("disputeFee")]);//This is the fork fee
        self.uintVars[keccak256("disputeCount")]++;
        uint disputeId = self.uintVars[keccak256("disputeCount")];
        self.disputeIdByDisputeHash[_hash] = disputeId;
        self.disputesById[disputeId] = TellorStorage.Dispute({
            hash: _hash,
            isPropFork: true,
            reportedMiner: msg.sender, 
            reportingParty: msg.sender, 
            proposedForkAddress: _propNewTellorAddress,
            executed: false,
            disputeVotePassed: false,
            tally: 0
            }); 
        self.disputesById[disputeId].disputeUintVars[keccak256("blockNumber")] = block.number;
        self.disputesById[disputeId].disputeUintVars[keccak256("fee")]  = self.uintVars[keccak256("disputeFee")];
        self.disputesById[disputeId].disputeUintVars[keccak256("minExecutionDate")] = now + 7 days;
    }
    

    /**
    * @dev this function allows the dispute fee to fluctuate based on the number of miners on the system.
    * The floor for the fee is 15e18.
    */
    function updateDisputeFee(TellorStorage.TellorStorageStruct storage self) public {
            //if the number of staked miners divided by the target count of staked miners is less than 1
            if(self.uintVars[keccak256("stakerCount")]*1000/self.uintVars[keccak256("targetMiners")] < 1000){
                //Set the dispute fee at stakeAmt * (1- stakerCount/targetMiners)
                //or at the its minimum of 15e18 
                self.uintVars[keccak256("disputeFee")] = SafeMath.max(15e18,self.uintVars[keccak256("stakeAmount")].mul(1000 - self.uintVars[keccak256("stakerCount")]*1000/self.uintVars[keccak256("targetMiners")])/1000);
            }
            else{
                //otherwise set the dispute fee at 15e18 (the floor/minimum fee allowed)
                self.uintVars[keccak256("disputeFee")] = 15e18;
            }
    }
}


/**
* itle Tellor Dispute
* @dev Contais the methods related to miners staking and unstaking. Tellor.sol 
* references this library for function's logic.
*/

library TellorStake {
    event NewStake(address indexed _sender);//Emits upon new staker
    event StakeWithdrawn(address indexed _sender);//Emits when a staker is now no longer staked
    event StakeWithdrawRequested(address indexed _sender);//Emits when a staker begins the 7 day withdraw period

    /*Functions*/
    
    /**
    * @dev This function stakes the five initial miners, sets the supply and all the constant variables.
    * This function is called by the constructor function on TellorMaster.sol
    */
    function init(TellorStorage.TellorStorageStruct storage self) public{
        require(self.uintVars[keccak256("decimals")] == 0);
        //Give this contract 6000 Tellor Tributes so that it can stake the initial 6 miners
        TellorTransfer.updateBalanceAtNow(self.balances[address(this)], 2**256-1 - 6000e18);

        // //the initial 5 miner addresses are specfied below
        // //changed payable[5] to 6
        address payable[6] memory _initalMiners = [address(0x4c49172A499D18eA3093D59A304eEF63F9754e25),
        address(0xbfc157b09346AC15873160710B00ec8d4d520C5a),
        address(0xa3792188E76c55b1A649fE5Df77DDd4bFD6D03dB),
        address(0xbAF31Bbbba24AF83c8a7a76e16E109d921E4182a),
        address(0x8c9841fEaE5Fc2061F2163033229cE0d9DfAbC71),
        address(0xc31Ef608aDa4003AaD4D2D1ec2Be72232A9E2A86)];
        //Stake each of the 5 miners specified above
        for(uint i=0;i<6;i++){//6th miner to allow for dispute
            //Miner balance is set at 1000e18 at the block that this function is ran
            TellorTransfer.updateBalanceAtNow(self.balances[_initalMiners[i]],1000e18);

            newStake(self, _initalMiners[i]);
        }

        //update the total suppply
        self.uintVars[keccak256("total_supply")] += 6000e18;//6th miner to allow for dispute
        //set Constants
        self.uintVars[keccak256("decimals")] = 18;
        self.uintVars[keccak256("targetMiners")] = 200;
        self.uintVars[keccak256("stakeAmount")] = 1000e18;
        self.uintVars[keccak256("disputeFee")] = 970e18;
        self.uintVars[keccak256("timeTarget")]= 600;
        self.uintVars[keccak256("timeOfLastNewValue")] = now - now  % self.uintVars[keccak256("timeTarget")];
        self.uintVars[keccak256("difficulty")] = 1;
    }


    /**
    * @dev This function allows stakers to request to withdraw their stake (no longer stake)
    * once they lock for withdraw(stakes.currentStatus = 2) they are locked for 7 days before they
    * can withdraw the deposit
    */
    function requestStakingWithdraw(TellorStorage.TellorStorageStruct storage self) public {
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
        //Require that the miner is staked
        require(stakes.currentStatus == 1);

        //Change the miner staked to locked to be withdrawStake
        stakes.currentStatus = 2;

        //Change the startDate to now since the lock up period begins now
        //and the miner can only withdraw 7 days later from now(check the withdraw function)
        stakes.startDate = now -(now % 86400);

        //Reduce the staker count
        self.uintVars[keccak256("stakerCount")] -= 1;
        TellorDispute.updateDisputeFee(self);
        emit StakeWithdrawRequested(msg.sender);
    }


    /**
    * @dev This function allows users to withdraw their stake after a 7 day waiting period from request 
    */
    function withdrawStake(TellorStorage.TellorStorageStruct storage self) public {
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
        //Require the staker has locked for withdraw(currentStatus ==2) and that 7 days have 
        //passed by since they locked for withdraw
        require(now - (now % 86400) - stakes.startDate >= 7 days);
        require(stakes.currentStatus == 2);
        stakes.currentStatus = 0;
        emit StakeWithdrawn(msg.sender);
    }


    /**
    * @dev This function allows miners to deposit their stake.
    */
    function depositStake(TellorStorage.TellorStorageStruct storage self) public {
      newStake(self, msg.sender);
      //self adjusting disputeFee
      TellorDispute.updateDisputeFee(self);
    }

    /**
    * @dev This function is used by the init function to succesfully stake the initial 5 miners.
    * The function updates their status/state and status start date so they are locked it so they can't withdraw
    * and updates the number of stakers in the system.
    */
    function newStake(TellorStorage.TellorStorageStruct storage self, address staker) internal {
        require(TellorTransfer.balanceOf(self,staker) >= self.uintVars[keccak256("stakeAmount")]);
        //Ensure they can only stake if they are not currrently staked or if their stake time frame has ended
        //and they are currently locked for witdhraw
        require(self.stakerDetails[staker].currentStatus == 0 || self.stakerDetails[staker].currentStatus == 2);
        self.uintVars[keccak256("stakerCount")] += 1;
        self.stakerDetails[staker] = TellorStorage.StakeInfo({
            currentStatus: 1,
            //this resets their stake start date to today
            startDate: now - (now % 86400)
        });
        emit NewStake(staker);
    }
}


/**
* @title Tellor Getters
* @dev Oracle contract with all tellor getter functions. The logic for the functions on this contract 
* is saved on the TellorGettersLibrary, TellorTransfer, TellorGettersLibrary, and TellorStake
*/
contract TellorGetters{
    using SafeMath for uint256;

    using TellorTransfer for TellorStorage.TellorStorageStruct;
    using TellorGettersLibrary for TellorStorage.TellorStorageStruct;
    using TellorStake for TellorStorage.TellorStorageStruct;

    TellorStorage.TellorStorageStruct tellor;
    
    /**
    * @param _user address
    * @param _spender address
    * @return Returns the remaining allowance of tokens granted to the _spender from the _user
    */
    function allowance(address _user, address _spender) external view returns (uint) {
       return tellor.allowance(_user,_spender);
    }

    /**
    * @dev This function returns whether or not a given user is allowed to trade a given amount  
    * @param _user address
    * @param _amount uint of amount
    * @return true if the user is alloed to trade the amount specified
    */
    function allowedToTrade(address _user,uint _amount) external view returns(bool){
        return tellor.allowedToTrade(_user,_amount);
    }

    /**
    * @dev Gets balance of owner specified
    * @param _user is the owner address used to look up the balance
    * @return Returns the balance associated with the passed in _user
    */
    function balanceOf(address _user) external view returns (uint) { 
        return tellor.balanceOf(_user);
    }

    /**
    * @dev Queries the balance of _user at a specific _blockNumber
    * @param _user The address from which the balance will be retrieved
    * @param _blockNumber The block number when the balance is queried
    * @return The balance at _blockNumber
    */
    function balanceOfAt(address _user, uint _blockNumber) external view returns (uint) {
        return tellor.balanceOfAt(_user,_blockNumber);
    }

    /**
    * @dev This function tells you if a given challenge has been completed by a given miner
    * @param _challenge the challenge to search for
    * @param _miner address that you want to know if they solved the challenge
    * @return true if the _miner address provided solved the 
    */
    function didMine(bytes32 _challenge, address _miner) external view returns(bool){
        return tellor.didMine(_challenge,_miner);
    }


    /**
    * @dev Checks if an address voted in a given dispute
    * @param _disputeId to look up
    * @param _address to look up
    * @return bool of whether or not party voted
    */
    function didVote(uint _disputeId, address _address) external view returns(bool){
        return tellor.didVote(_disputeId,_address);
    }


    /**
    * @dev allows Tellor to read data from the addressVars mapping
    * @param _data is the keccak256("variable_name") of the variable that is being accessed. 
    * These are examples of how the variables are saved within other functions:
    * addressVars[keccak256("_owner")]
    * addressVars[keccak256("tellorContract")]
    */
    function getAddressVars(bytes32 _data) view external returns(address){
        return tellor.getAddressVars(_data);
    }


    /**
    * @dev Gets all dispute variables
    * @param _disputeId to look up
    * @return bytes32 hash of dispute 
    * @return bool executed where true if it has been voted on
    * @return bool disputeVotePassed
    * @return bool isPropFork true if the dispute is a proposed fork
    * @return address of reportedMiner
    * @return address of reportingParty
    * @return address of proposedForkAddress
    * @return uint of requestId
    * @return uint of timestamp
    * @return uint of value
    * @return uint of minExecutionDate
    * @return uint of numberOfVotes
    * @return uint of blocknumber
    * @return uint of minerSlot
    * @return uint of quorum
    * @return uint of fee
    * @return int count of the current tally
    */
    function getAllDisputeVars(uint _disputeId) public view returns(bytes32, bool, bool, bool, address, address, address,uint[9] memory, int){
        return tellor.getAllDisputeVars(_disputeId);
    }
    

    /**
    * @dev Getter function for variables for the requestId being currently mined(currentRequestId)
    * @return current challenge, curretnRequestId, level of difficulty, api/query string, and granularity(number of decimals requested), total tip for the request 
    */
    function getCurrentVariables() external view returns(bytes32, uint, uint,string memory,uint,uint){    
        return tellor.getCurrentVariables();
    }

    /**
    * @dev Checks if a given hash of miner,requestId has been disputed
    * @param _hash is the sha256(abi.encodePacked(_miners[2],_requestId));
    * @return uint disputeId
    */
    function getDisputeIdByDisputeHash(bytes32 _hash) external view returns(uint){
        return  tellor.getDisputeIdByDisputeHash(_hash);
    }
    

    /**
    * @dev Checks for uint variables in the disputeUintVars mapping based on the disuputeId
    * @param _disputeId is the dispute id;
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is 
    * the variables/strings used to save the data in the mapping. The variables names are  
    * commented out under the disputeUintVars under the Dispute struct
    * @return uint value for the bytes32 data submitted
    */
    function getDisputeUintVars(uint _disputeId,bytes32 _data) external view returns(uint){
        return tellor.getDisputeUintVars(_disputeId,_data);
    }


    /**
    * @dev Gets the a value for the latest timestamp available
    * @return value for timestamp of last proof of work submited
    * @return true if the is a timestamp for the lastNewValue
    */
    function getLastNewValue() external view returns(uint,bool){
        return tellor.getLastNewValue();
    }


    /**
    * @dev Gets the a value for the latest timestamp available
    * @param _requestId being requested
    * @return value for timestamp of last proof of work submited and if true if it exist or 0 and false if it doesn't
    */
    function getLastNewValueById(uint _requestId) external view returns(uint,bool){
        return tellor.getLastNewValueById(_requestId);
    }
        

    /**
    * @dev Gets blocknumber for mined timestamp 
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up blocknumber
    * @return uint of the blocknumber which the dispute was mined
    */
    function getMinedBlockNum(uint _requestId, uint _timestamp) external view returns(uint){
        return tellor.getMinedBlockNum(_requestId,_timestamp);
    }


    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp 
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up miners for
    * @return the 5 miners' addresses
    */
    function getMinersByRequestIdAndTimestamp(uint _requestId, uint _timestamp) external view returns(address[5] memory){
        return tellor.getMinersByRequestIdAndTimestamp(_requestId,_timestamp);
    }


    /**
    * @dev Get the name of the token
    * return string of the token name
    */
    function getName() external view returns(string memory){
        return tellor.getName();
    }


    /**
    * @dev Counts the number of values that have been submited for the request 
    * if called for the currentRequest being mined it can tell you how many miners have submitted a value for that
    * request so far
    * @param _requestId the requestId to look up
    * @return uint count of the number of values received for the requestId
    */
    function getNewValueCountbyRequestId(uint _requestId) external view returns(uint){
        return tellor.getNewValueCountbyRequestId(_requestId);
    }


    /**
    * @dev Getter function for the specified requestQ index
    * @param _index to look up in the requestQ array
    * @return uint of reqeuestId
    */
    function getRequestIdByRequestQIndex(uint _index) external view returns(uint){
        return tellor.getRequestIdByRequestQIndex(_index);
    }


    /**
    * @dev Getter function for requestId based on timestamp 
    * @param _timestamp to check requestId
    * @return uint of reqeuestId
    */
    function getRequestIdByTimestamp(uint _timestamp) external view returns(uint){    
        return tellor.getRequestIdByTimestamp(_timestamp);
    }

    /**
    * @dev Getter function for requestId based on the queryHash
    * @param _request is the hash(of string api and granularity) to check if a request already exists
    * @return uint requestId
    */
    function getRequestIdByQueryHash(bytes32 _request) external view returns(uint){    
        return tellor.getRequestIdByQueryHash(_request);
    }


    /**
    * @dev Getter function for the requestQ array
    * @return the requestQ arrray
    */
    function getRequestQ() view public returns(uint[51] memory){
        return tellor.getRequestQ();
    }


    /**
    * @dev Allowes access to the uint variables saved in the apiUintVars under the requestDetails struct
    * for the requestId specified
    * @param _requestId to look up
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is 
    * the variables/strings used to save the data in the mapping. The variables names are  
    * commented out under the apiUintVars under the requestDetails struct
    * @return uint value of the apiUintVars specified in _data for the requestId specified
    */
    function getRequestUintVars(uint _requestId,bytes32 _data) external view returns(uint){
        return tellor.getRequestUintVars(_requestId,_data);
    }


    /**
    * @dev Gets the API struct variables that are not mappings
    * @param _requestId to look up
    * @return string of api to query
    * @return string of symbol of api to query
    * @return bytes32 hash of string
    * @return bytes32 of the granularity(decimal places) requested
    * @return uint of index in requestQ array
    * @return uint of current payout/tip for this requestId
    */
    function getRequestVars(uint _requestId) external view returns(string memory, string memory,bytes32,uint, uint, uint) {
        return tellor.getRequestVars(_requestId);
    }


    /**
    * @dev This function allows users to retireve all information about a staker
    * @param _staker address of staker inquiring about
    * @return uint current state of staker
    * @return uint startDate of staking
    */
    function getStakerInfo(address _staker) external view returns(uint,uint){
        return tellor.getStakerInfo(_staker);
    }
    
    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp 
    * @param _requestId to look up
    * @param _timestamp is the timestampt to look up miners for
    * @return address[5] array of 5 addresses ofminers that mined the requestId
    */    
    function getSubmissionsByTimestamp(uint _requestId, uint _timestamp) external view returns(uint[5] memory){
        return tellor.getSubmissionsByTimestamp(_requestId,_timestamp);
    }

    /**
    * @dev Get the symbol of the token
    * return string of the token symbol
    */
    function getSymbol() external view returns(string memory){
        return tellor.getSymbol();
    } 

    /**
    * @dev Gets the timestamp for the value based on their index
    * @param _requestID is the requestId to look up
    * @param _index is the value index to look up
    * @return uint timestamp
    */
    function getTimestampbyRequestIDandIndex(uint _requestID, uint _index) external view returns(uint){
        return tellor.getTimestampbyRequestIDandIndex(_requestID,_index);
    }


    /**
    * @dev Getter for the variables saved under the TellorStorageStruct uintVars variable
    * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is 
    * the variables/strings used to save the data in the mapping. The variables names are  
    * commented out under the uintVars under the TellorStorageStruct struct
    * This is an example of how data is saved into the mapping within other functions: 
    * self.uintVars[keccak256("stakerCount")]
    * @return uint of specified variable  
    */ 
    function getUintVar(bytes32 _data) view public returns(uint){
        return tellor.getUintVar(_data);
    }


    /**
    * @dev Getter function for next requestId on queue/request with highest payout at time the function is called
    * @return onDeck/info on request with highest payout-- RequestId, Totaltips, and API query string
    */
    function getVariablesOnDeck() external view returns(uint, uint,string memory){    
        return tellor.getVariablesOnDeck();
    }

    
    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp 
    * @param _requestId to look up
    * @param _timestamp is the timestamp to look up miners for
    * @return bool true if requestId/timestamp is under dispute
    */
    function isInDispute(uint _requestId, uint _timestamp) external view returns(bool){
        return tellor.isInDispute(_requestId,_timestamp);
    }
    

    /**
    * @dev Retreive value from oracle based on timestamp
    * @param _requestId being requested
    * @param _timestamp to retreive data/value from
    * @return value for timestamp submitted
    */
    function retrieveData(uint _requestId, uint _timestamp) external view returns (uint) {
        return tellor.retrieveData(_requestId,_timestamp);
    }


    /**
    * @dev Getter for the total_supply of oracle tokens
    * @return uint total supply
    */
    function totalSupply() external view returns (uint) {
       return tellor.totalSupply();
    }


}

/**
* @title Tellor Master
* @dev This is the Master contract with all tellor getter functions and delegate call to Tellor. 
* The logic for the functions on this contract is saved on the TellorGettersLibrary, TellorTransfer, 
* TellorGettersLibrary, and TellorStake
*/
contract TellorMaster is TellorGetters{
    
    event NewTellorAddress(address _newTellor);

    /**
    * @dev The constructor sets the original `tellorStorageOwner` of the contract to the sender
    * account, the tellor contract to the Tellor master address and owner to the Tellor master owner address 
    * @param _tellorContract is the address for the tellor contract
    */
    constructor (address _tellorContract)  public{
        tellor.init();
        tellor.addressVars[keccak256("_owner")] = msg.sender;
        tellor.addressVars[keccak256("_deity")] = msg.sender;
        tellor.addressVars[keccak256("tellorContract")]= _tellorContract;
        emit NewTellorAddress(_tellorContract);
    }
    

    /**
    * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp 
    * @dev Only needs to be in library
    * @param _newDeity the new Deity in the contract
    */

    function changeDeity(address _newDeity) external{
        tellor.changeDeity(_newDeity);
    }


    /**
    * @dev  allows for the deity to make fast upgrades.  Deity should be 0 address if decentralized
    * @param _tellorContract the address of the new Tellor Contract
    */
    function changeTellorContract(address _tellorContract) external{
        tellor.changeTellorContract(_tellorContract);
    }
  

    /**
    * @dev This is the fallback function that allows contracts to call the tellor contract at the address stored
    */
    function () external payable {
        address addr = tellor.addressVars[keccak256("tellorContract")];
        bytes memory _calldata = msg.data;
        assembly {
            let result := delegatecall(not(0), addr, add(_calldata, 0x20), mload(_calldata), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}