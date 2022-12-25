/*
    GreenMachineMiner Miner config - BSC Miner
    Developed by Kraitor <TG: kraitordev>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BasicLibraries/SafeMath.sol";
import "./BasicLibraries/Auth.sol";
import "./Libraries/Testable.sol";

contract GreenMachineMinerConfig is Auth, Testable {
    using SafeMath for uint256;

    //External config of the miner

    constructor(address minerAddress, address timerAddr) Auth(msg.sender) Testable(timerAddr) {
        minerAdd = minerAddress;
    }

    address minerAdd = address(0);

    //Set miner address
    function setMinerAddress(address adr) public authorized { minerAdd = adr; }

    //CUSTOM (ROI events)//
    //One time event
    uint256 internal roiEventBoostPercentage = 0;
    uint256 internal roiEventDuration = 1 days;
    uint256 internal timestampRoiEventBegins = 0; //when roi event begins, 0 means disabled

    function getOneTimeEventBoostPercentage(uint256 _currentEventBoostPercentage) public view returns (uint256) {
        uint256 eventBoostPercentage = _currentEventBoostPercentage;

        //One time event
        if(timestampRoiEventBegins != 0 && getCurrentTime() > timestampRoiEventBegins){
            if(getCurrentTime() < timestampRoiEventBegins.add(roiEventDuration)){
                if(roiEventBoostPercentage > eventBoostPercentage){
                    eventBoostPercentage = roiEventBoostPercentage;
                }
            }
        }

        return eventBoostPercentage;
    }

    function setOneTimeEventBoost(uint256 _roiEventBoostPercentage, uint256 _roiEventDuration, uint256 _timestampRoiEventBegins) public authorized {
        roiEventBoostPercentage = _roiEventBoostPercentage;
        roiEventDuration = _roiEventDuration.mul(1 days);
        timestampRoiEventBegins = _timestampRoiEventBegins;
    }

    //Periodic event
    uint256 internal roiPeriodicEventBoostPercentage = 0;
    uint256 internal roiPeriodicEventDuration = 1 days;
    uint256 internal timestampRoiEventPeriodicityBegins = 0; //when periodic events begins, 0 means disabled
    uint256 internal roiEventPeriodicity = 7 days;

    function getPeriodicEventBoostPercentage(uint256 _currentEventBoostPercentage) public view returns (uint256) {
        uint256 eventBoostPercentage = _currentEventBoostPercentage;

        //Periodic events
        if(timestampRoiEventPeriodicityBegins != 0 && getCurrentTime() > timestampRoiEventPeriodicityBegins){
            //Formula to check if we are on event period
            //(currentTimestamp - timestampInit) % (duration + restPeriod) < duration
            if(getCurrentTime().sub(timestampRoiEventPeriodicityBegins).mod(roiEventPeriodicity.add(roiPeriodicEventDuration)) < roiPeriodicEventDuration){
                if(roiPeriodicEventBoostPercentage > eventBoostPercentage){
                    eventBoostPercentage = roiPeriodicEventBoostPercentage;
                }
            }
        }

        return eventBoostPercentage;
    }

    function setPeriodicEventBoost(uint256 _roiPeriodicEventBoostPercentage, uint256 _roiPeriodicEventDuration, uint256 _timestampRoiEventPeriodicityBegins, uint256 _roiEventPeriodicity) public authorized {
        roiPeriodicEventBoostPercentage = _roiPeriodicEventBoostPercentage;
        roiPeriodicEventDuration = _roiPeriodicEventDuration.mul(1 days);
        timestampRoiEventPeriodicityBegins = _timestampRoiEventPeriodicityBegins;
        roiEventPeriodicity = _roiEventPeriodicity.mul(1 days);
    }

    //Milestone event
    uint256 public ntvlMilestoneSteps;
    mapping(uint256 => uint256) internal tvlMilestoneSteps;
    mapping(uint256 => uint256) internal tvlMilestoneBoostPercentages;
    uint256 internal tvlMilestonesEventDuration = 1 days;
    mapping(uint256 => uint256) internal tvlMilestoneStepsTimestampBegin; //when step begins, 0 means still not started

    function getMilestoneEventBoostPercentage(uint256 _currentEventBoostPercentage) public view returns (uint256) {
        uint256 eventBoostPercentage = _currentEventBoostPercentage;

        //Milestone events 
        if(ntvlMilestoneSteps > 0){
            //We get current milestone
            uint256 _milestoneBoostPercentage = 0;
            uint256 _stepTimestampBegin = 0;
            for(uint256 i = 0; i < ntvlMilestoneSteps; i++){
                if(address(minerAdd).balance > tvlMilestoneSteps[i].mul(10 ** 18)){
                    _milestoneBoostPercentage = tvlMilestoneBoostPercentages[i];
                    _stepTimestampBegin = tvlMilestoneStepsTimestampBegin[i];
                }
            }

            if(getCurrentTime() > _stepTimestampBegin && getCurrentTime() < _stepTimestampBegin.add(tvlMilestonesEventDuration)){
                if(_milestoneBoostPercentage > eventBoostPercentage){
                    eventBoostPercentage = _milestoneBoostPercentage;
                }
            }
        }

        return eventBoostPercentage;
    }

    function setMilestoneEventBoost(uint256 [] memory _tvlMilestoneSteps, uint256 [] memory _tvlMilestoneBoostPercentages, uint256 _tvlMilestonesEventDuration, uint256 [] memory _tvlMilestoneStepsTimestampBegin) public authorized {
        require(_tvlMilestoneSteps.length == _tvlMilestoneBoostPercentages.length, 'Arrays of different size');
        require(_tvlMilestoneSteps.length == _tvlMilestoneStepsTimestampBegin.length, 'Arrays of different size');

        ntvlMilestoneSteps = _tvlMilestoneSteps.length;
        
        for(uint256 i = 0; i < ntvlMilestoneSteps; i++){
            tvlMilestoneSteps[i] = _tvlMilestoneSteps[i];
            tvlMilestoneBoostPercentages[i] = _tvlMilestoneBoostPercentages[i];
            tvlMilestonesEventDuration = _tvlMilestonesEventDuration.mul(1 days);
            tvlMilestoneStepsTimestampBegin[i] = _tvlMilestoneStepsTimestampBegin[i];
        }
    }

    function updateMilestoneEventBoostTimestamp() internal {
        for(uint256 i = 0; i < ntvlMilestoneSteps; i++){
            if(address(minerAdd).balance > tvlMilestoneSteps[i].mul(10**18)){
                if(tvlMilestoneStepsTimestampBegin[i] == 0){
                    tvlMilestoneStepsTimestampBegin[i] = getCurrentTime(); //Timestamp update
                }
            }
        }
    }

    function checkNeedUpdateMilestoneEventBoostTimestamp() internal view returns (bool) {
        bool needUpdate = false;

        for(uint256 i = 0; i < ntvlMilestoneSteps; i++){
            if(address(minerAdd).balance > tvlMilestoneSteps[i].mul(10**18)){
                if(tvlMilestoneStepsTimestampBegin[i] == 0){
                    needUpdate = true;
                }
            }
        }

        return needUpdate;
    }

    //General
    function getEventsBoostPercentage() public view returns (uint256) {

        uint256 eventBoostPercentage = getMilestoneEventBoostPercentage(getPeriodicEventBoostPercentage(getOneTimeEventBoostPercentage(0)));

        //Limited, security meassure
        if(eventBoostPercentage > 1000){
            eventBoostPercentage = 1000;
        }

        return eventBoostPercentage;
    }

    function needUpdateEventBoostTimestamps() external view returns (bool) {
        return checkNeedUpdateMilestoneEventBoostTimestamp();
    }

    function updateEventsBoostTimestamps() external {
        updateMilestoneEventBoostTimestamp();
    }

    function applyROIEventBoost(uint256 amount) external view returns (uint256) {
        return amount.add(amount.mul(getEventsBoostPercentage()).div(100));
    }    

    //ALGORITHM(?)//

    ////////////////
}