pragma solidity 0.4.24;


/**
* @title Tellor Getters
* @dev Oracle contract with all tellor getter functions. The logic for the functions on this contract 
* is saved on the TellorGettersLibrary, TellorTransfer, TellorGettersLibrary, and TellorStake
*/
interface ITellorGetters {
    function getNewValueCountbyRequestId(uint _requestId) external view returns(uint);
    function getTimestampbyRequestIDandIndex(uint _requestID, uint _index) external view returns(uint);
    function retrieveData(uint _requestId, uint _timestamp) external view returns (uint);
}