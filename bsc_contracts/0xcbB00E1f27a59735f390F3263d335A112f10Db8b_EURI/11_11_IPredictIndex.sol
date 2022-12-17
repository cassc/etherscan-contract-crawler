// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPredictIndex {

    // +++++++++++++++++++  PUBLIC STATE VARIABLES  +++++++++++++++++++++++++
    function isInitialized() external view returns(bool);
    
    function baseValue() external view returns(uint32);
    function baseYear() external view returns(uint16);
    function baseMonth() external view returns(uint8);

    function releaseHour() external view returns(uint8);
    function releaseMinute() external view returns(uint8);

    function targetValue() external view returns(uint64);
    function backupValue() external view returns(uint64);
    function targetTimestamp() external view returns(uint64);
    function backupTimestamp() external view returns(uint64);

    function backupProvider() external view returns(address);

    function CPIValues(uint) external view returns(uint32);
    function CPIObservations(uint16, uint8) external returns(uint32);


    // ++++++++++++++++++++++++++  PARAMETERS  +++++++++++++++++++++++++++++
    function addDataProvider(address newProvider) external;
    function removeDataProvider() external;
    function setAPIConnectors(address _releaseAPI, address _observationAPI) external;
    function setNewReleaseTime(uint8 hour, uint8 minute) external;


    // ++++++++++++++++++++++++  USER FUNCTIONS  ++++++++++++++++++++++++++++
    function requestData(string memory apk) external;
    function fetchData() external;
    function provideData(
        uint16 yearRel, 
        uint8 monthRel, 
        uint8 dayRel, 
        uint16 yearObs, 
        uint8 monthObs, 
        uint32 observation
    ) external;

    
    // ++++++++++++++++++++  INFORMATIVE FUNCTIONS  +++++++++++++++++++++++++
    function isUpdated() external view returns(bool);
    function getTargetValue() external view returns(uint64);
    function getTargetTimestamp() external view returns(uint64);
    function getRelativeTrend() external view returns(uint32);
}