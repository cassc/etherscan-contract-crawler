// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./StratManager.sol";

abstract contract FeeManager is StratManager {
    uint constant public MAX_FEE = 1000;
    uint constant public MAX_CALL_FEE = 117;

    uint constant public WITHDRAWAL_FEE_CAP = 50;
    uint constant public WITHDRAWAL_MAX = 10000;

    uint public withdrawalFee = 10;

    uint public callFee = 58;
    uint public bloomifyFee = MAX_FEE - callFee;

    function setCallFee(uint256 _fee) public onlyManager {
        require(_fee <= MAX_CALL_FEE, "!cap");
        
        callFee = _fee;
        bloomifyFee = MAX_FEE - callFee;
    }

    function setWithdrawalFee(uint256 _fee) public onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "!cap");

        withdrawalFee = _fee;
    }
}