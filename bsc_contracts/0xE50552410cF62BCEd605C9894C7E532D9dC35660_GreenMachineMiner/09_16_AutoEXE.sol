// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../BasicLibraries/SafeMath.sol";

abstract contract AutoEXE {
    using SafeMath for uint256;

    //AUTO EXE//
    uint64 internal investorsNextIndex = 0; //User on consecutive auto executions to know where executions have to continue
    //uint8 public autoFeeTax = 1; //Tax used to cost the auto executions
    uint32 internal executionHour = 1200; //12:00 //Execution hour auto executions will begin
    uint32 constant internal minutesDay = 1440;
    uint64 internal maxInvestorPerExecution = type(uint64).max; //Max investors processed per execution
    bool public enabledSingleMode = false; //Enable/disable single mode
    //address payable public autoAdd; //Wallet used for auto executions
     
    event Execute(address _sender, uint256 _totalInvestors, uint256 daysForSelling, uint256 nSells, uint256 nSellsMax);
    event ExecuteSingle(address _sender, bool _rehire);

    //Automatic execution, triggered offchain, each day or each X minutes depending on config
    //Will sell or rehire depending on algorithm decision and max sells per day
    //function execute() public virtual;

    //Execute for the next n investors
    function executeN(uint256 nInvestorsExe, bool forceSell) public virtual;

    //Automatic exection, triggered offchain, for an array of investors
    //For emergencies
    function executeAddresses(address [] memory investorsRun, bool forceSell) public virtual;

    //Single executions, only can be runned by each user if enabled
    //Will sell or rehire depending on algorithm decision and max sells per day
    function executeSingle() public virtual;
 
    function setExecutionHour(uint32 exeHour) public virtual;

    function setMaxInvestorsPerExecution(uint64 maxInvPE) public virtual;

    //function setAutotax(uint8 pcTaxAuto, address _autoAdd) public virtual;

    function enableSingleMode(bool _enable) public virtual;

    function getExecutionHour() public view returns(uint256){ return executionHour; }

    function getExecutionPeriodicity() public virtual view returns(uint64);

    //function calculateAutoTax(uint256 amount) internal view returns(uint256) { return SafeMath.div(SafeMath.mul(amount, autoFeeTax), 100); }

    constructor() {}
}