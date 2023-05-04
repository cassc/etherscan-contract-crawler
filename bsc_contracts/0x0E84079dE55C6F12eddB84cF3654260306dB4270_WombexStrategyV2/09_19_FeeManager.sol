// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./StratManager.sol";

abstract contract FeeManager is StratManager {
    uint constant public MAX_FEE = 5000;
    uint constant public FEE_DIVISOR = 1000;
    uint public zaynFee = 200;
    uint public mgmtFeeDelay = 43200; // 12 hours
    uint public chargePerDay = 54794520000000; // 0.02 / 365
    uint public revShareFees = 50; // 0.05 or 5%

    function setZaynFee(uint256 _fee) public onlyManager {
        require(_fee <= MAX_FEE, "!cap");
        zaynFee = _fee;
    }

    function setMgmtFeeDelay(uint256 _seconds) public onlyManager {
        mgmtFeeDelay = _seconds;
    }

    function setChargePerDay(uint256 _perDay) public onlyManager {
        chargePerDay = _perDay;
    }

    function setRevShareFees(uint256 _revShareFees) public onlyManager {
        revShareFees = _revShareFees;
    }
}