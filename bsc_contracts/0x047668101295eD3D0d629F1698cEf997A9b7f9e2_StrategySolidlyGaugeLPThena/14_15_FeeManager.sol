// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import './StratManager.sol';

abstract contract FeeManager is StratManager {
    uint constant public PERCENTAGE = 10000;        // 100.00%
    uint constant public MAX_PERFORMANCE_FEE = 400; //   4.00%

    uint constant public MAX_FEE = 1000;            // 100.0% of totalPerformanceFee
    uint constant public MAX_CALL_FEE = 125;        //  12.5% of MAX_FEE
    uint constant public MAX_STRATEGIST_FEE = 125;  //  12.5% of MAX_FEE

    uint public totalPerformanceFee = 400;          //  4.00%
    uint public callFee = 125;                      //  12.5% of MAX_FEE
    uint public strategistFee = 125;                //  12.5% of MAX_FEE
    uint public coFee = MAX_FEE - (strategistFee + callFee);

    function setFees(uint _callFee, uint _strategistFee) public onlyManager {
        require(_callFee <= MAX_CALL_FEE, "FeeManager: MAX_CALL_FEE");
        require(_strategistFee <= MAX_STRATEGIST_FEE, "FeeManager: MAX_STRATEGIST_FEE");
        callFee = _callFee;
        strategistFee = _strategistFee;
        coFee = MAX_FEE - (_strategistFee + _callFee);
    }

    function setTotalPerformanceFee(uint _fee) public onlyManager {
        require(_fee <= MAX_PERFORMANCE_FEE, "FeeManager: MAX_PERFORMANCE_FEE");
        totalPerformanceFee = _fee;
    }
}