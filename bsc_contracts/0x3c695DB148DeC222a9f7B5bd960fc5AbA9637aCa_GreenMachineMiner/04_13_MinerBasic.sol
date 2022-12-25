// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../BasicLibraries/SafeMath.sol";

abstract contract MinerBasic {

    event Hire(address indexed adr, uint256 greens, uint256 amount);
    event Sell(address indexed adr, uint256 greens, uint256 amount, uint256 penalty);
    event RehireMachines(address _investor, uint256 _newMachines, uint256 _hiredMachines, uint256 _nInvestors, uint256 _referralGreens, uint256 _marketGreens, uint256 _GreensUsed);

    bool internal renounce_unstuck = false; //Testing/security meassure, owner should renounce after checking everything is working fine
    uint32 internal rewardsPercentage = 15; //Rewards increase to apply (hire/sell)
    uint32 internal GREENS_TO_HATCH_1MACHINE = 576000; //576000/24*60*60 = 6.666 days to recover your investment (6.666*15 = 100%)
    uint16 internal PSN = 10000;
    uint16 internal PSNH = 5000;
    bool internal initialized = false;
    uint256 internal marketGreens; //This variable is responsible for inflation.
                                   //Number of greens on market (sold) rehire adds 20% of greens rehired

    address payable internal recAdd;
    uint8 internal devFeeVal = 1; //Dev fee
    uint8 internal marketingFeeVal = 4; //Tax used to cost the auto executions
    address payable public marketingAdd; //Wallet used for auto executions
    uint256 public maxBuy = (0.7 ether);

    uint256 public maxSellNum = 10; //Max sell TVL num
    uint256 public maxSellDiv = 1000; //Max sell TVL div //For example: 10 and 1000 -> 10/1000 = 1/100 = 1% of TVL max sell

    // This function is called by anyone who want to contribute to TVL
    function ContributeToTVL() public payable { }

    //Open/close miner
    bool public openPublic = false;
    function openToPublic(bool _openPublic) public virtual;

    function calculateMarketingTax(uint256 amount) internal view returns(uint256) { return SafeMath.div(SafeMath.mul(amount, marketingFeeVal), 100); }
    function calculateDevTax(uint256 amount) internal view returns(uint256) { return SafeMath.div(SafeMath.mul(amount, devFeeVal), 100); }
    function calculateFullTax(uint256 amount) internal view returns(uint256) { return SafeMath.div(SafeMath.mul(amount, devFeeVal + marketingFeeVal), 100); }

    constructor () {}
}