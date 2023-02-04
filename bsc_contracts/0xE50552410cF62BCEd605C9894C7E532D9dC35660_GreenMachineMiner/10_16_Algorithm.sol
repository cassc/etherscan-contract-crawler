// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../BasicLibraries/SafeMath.sol";

abstract contract Algorithm {
    using SafeMath for uint256;
    using SafeMath for uint64;

    //ALGORITHM
    mapping(uint256 => uint256) internal dayInvestmentsAcum; //Total investment in miner registered at certain day
    mapping(uint256 => uint256) internal dayWithdrawalsAcum; //Total withdrawals in miner registered by certain day
    mapping(uint256 => uint256) internal dayHourSells;
    bool public nMaxSellsRestriction = false; //Max sell restriction in order to avoid TLV dumps, can produce delays on sells
    uint8 public minDaysSell = 7;
    uint8 public maxDaysSell = 14;

    //Min and Max days for selling, your sell date will vary between this limits
    function setAlgorithmLimits(uint8 _minDaysSell, uint8 _maxDaysSell) public virtual;

    function enablenMaxSellsRestriction(bool _enable) public virtual;

    function getCurrDayTimestamp(uint256 timestamp) public pure returns (uint256) {
        uint256 _hour = getCurrDayHours(timestamp);
        uint256 _minute = getCurrDayMinutes(timestamp);
        uint256 _second = getCurrDaySeconds(timestamp);
        return timestamp.sub(_hour.mul(3600).add(_minute.mul(60)).add(_second));
    }

    function getCurrHourTimestamp(uint256 timestamp) public pure returns (uint256) {
        uint256 _minute = (timestamp / 60) % 60;
        uint256 _second = timestamp % 60;
        return timestamp.sub(_minute.mul(60).add(_second));
    }

    function getCurrDayHours(uint256 timestamp) public pure returns (uint256) {
        return (timestamp / 60 / 60) % 24;
    }

    function getCurrDayMinutes(uint256 timestamp) public pure returns (uint256) {
        return (timestamp / 60) % 60;
    }

    function getCurrDaySeconds(uint256 timestamp) public pure returns (uint256) {
        return timestamp % 60;
    }

    function acumInvestment(uint256 timestamp, uint256 amount) internal { dayInvestmentsAcum[getCurrDayTimestamp(timestamp)] += amount; }

    function acumWithdrawal(uint256 timestamp, uint256 amount) internal { dayWithdrawalsAcum[getCurrDayTimestamp(timestamp)] += amount; }

    function lastDaysInvestments(uint256 timestamp) public view returns (uint256 [7] memory) {
        uint256 currDayTimestamp = getCurrDayTimestamp(timestamp);
        uint256 [7] memory _investments;
        for(uint64 i = 1; i <= 7; i++){            
            _investments[i-1] = dayInvestmentsAcum[currDayTimestamp-i.mul(86400)];
        }
        return _investments;
    }

    function lastDaysWithdrawals(uint256 timestamp) public view returns (uint256 [7] memory) {
        uint256 currDayTimestamp = getCurrDayTimestamp(timestamp);
        uint256 [7] memory _withdrawals;
        for(uint64 i = 1; i <= 7; i++){            
            _withdrawals[i-1] = dayWithdrawalsAcum[currDayTimestamp-i.mul(86400)];
        }
        return _withdrawals;
    }

    //Days for selling taking into account bnb entering/leaving the TLV last days
    function daysForSelling(uint256 timestamp) public view returns (uint256) {

        uint256 posRatio = 0;
        uint256 negRatio = 0;      
        uint256 daysSell = SafeMath.add(minDaysSell, SafeMath.sub(maxDaysSell, minDaysSell).div(2)); //We begin in the middle
        uint256 globalDiff = 0;

        //We storage the snapshots BNB diff to storage how much BNB was withdraw/invest on the miner each dat
        uint256 [7] memory _withdrawals = lastDaysWithdrawals(timestamp);
        uint256 [7] memory _investments = lastDaysInvestments(timestamp);

        //BNB investing diff along the days vs withdraws
        (posRatio, negRatio) = getRatiosFromInvWitDiff(_investments, _withdrawals);

        //We take the ratio diff, and get the amount of days to add/substract to daysSell
        if(negRatio > posRatio){
            globalDiff = (negRatio.sub(posRatio)).div(100);
        }
        else{
            globalDiff = (posRatio.sub(negRatio)).div(100);
        }

        //We adjust daysSell taking into acount the limits
        if(negRatio > posRatio){
            daysSell = daysSell.add(globalDiff);
            if(daysSell > maxDaysSell){
                daysSell = maxDaysSell;
            }
        }else{
            if(globalDiff < daysSell && daysSell.sub(globalDiff) > minDaysSell){
                daysSell = daysSell.sub(globalDiff);
            }
            else{
                daysSell = minDaysSell;
            }
        }

        return daysSell;        
    }

    //Returns pos and neg ratios used for daysForSelling, are calculated using differences between the snapshots take
    function getRatiosFromInvWitDiff(uint256 [7] memory investmentsDiff, uint256 [7] memory withdrawalsDiff) internal pure returns (uint256, uint256){
        uint256 posRatio = 0;
        uint256 negRatio = 0;
        uint256 ratioPosAdd = 0;
        uint256 ratioNegAdd = 0;

        //We storage the ratio, how much times BNB was invested respect the withdraws and vice versa
        for(uint256 i = 0; i < investmentsDiff.length; i++){
            if(investmentsDiff[i] != 0 || withdrawalsDiff[i] != 0){
                if(investmentsDiff[i] > withdrawalsDiff[i]){
                    if(withdrawalsDiff[i] > 0){
                        ratioPosAdd = investmentsDiff[i].mul(100).div(withdrawalsDiff[i]);
                        if(ratioPosAdd > 200){
                            posRatio += 200;
                        }
                        else{
                            posRatio += ratioPosAdd;
                        }
                    }else{
                        posRatio += 100;
                    }
                }
                else{
                    if(investmentsDiff[i] > 0){
                        ratioNegAdd = withdrawalsDiff[i].mul(100).div(investmentsDiff[i]);
                        if(ratioNegAdd > 200){
                            negRatio += 200;
                        }
                        else{
                            negRatio += ratioNegAdd;
                        }
                    }else{
                        negRatio += 100;
                    }
                }
            }
        }

        return (posRatio, negRatio);
    }

    constructor() {}
}