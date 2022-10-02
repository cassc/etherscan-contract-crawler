// SPDX-License-Identifier: MIT License
pragma solidity >=0.8.0 <0.9.0;

import "./PhunkAuctionFlywheel.sol";

contract PhunkAuctionFlywheelHelper {
    PhunkAuctionFlywheel public immutable FLY;

    uint public lastWeekStartThatCanHaveEth = 1662336000;
    
    uint weeklyAllowance = 0.001 ether;
    
    modifier adminRequired() {
        require(FLY.hasRole(0x0, msg.sender), "Must be admin");
        _;
    }
    
    modifier validDepositAmount() {
        require(
            msg.value >= weeklyAllowance &&
            msg.value % weeklyAllowance == 0,
            "Invalid deposit amount");

        _;
    }
    
    function setWeeklyAllowance(uint _weeklyAllowance) external adminRequired {
        weeklyAllowance = _weeklyAllowance;
    }
    
    constructor(address _flywheelAddress) payable {
        FLY = PhunkAuctionFlywheel(_flywheelAddress);
    }
    
    receive() external payable validDepositAmount adminRequired  {
        withdrawAllEthAndSetAllowancesToZero(26);
        depositNewEth();
    }
    
    function withdrawAllEthAndSetAllowancesToZero(uint numberOfWeeksToCheck) public adminRequired {
        uint startTime = lastWeekStartThatCanHaveEth;
        
        uint[] memory weekStarts = new uint[](numberOfWeeksToCheck);
        uint[] memory amounts = new uint[](numberOfWeeksToCheck);
        
        for (uint i; i < numberOfWeeksToCheck; ++i) {
            weekStarts[i] = startTime + i * 7 days;
            amounts[i] = FLY.startOfWeekToWeeklyAllowanceMapping(weekStarts[i]);
        }
        
        FLY.withdrawEthFromWeeklySpendingLimits(weekStarts, amounts);
        
        lastWeekStartThatCanHaveEth = FLY.getStartOfCurrentWeek();
    }
    
    function depositNewEth() public payable validDepositAmount adminRequired {
        uint startTime = FLY.getStartOfCurrentWeek();
        uint numberOfWeeks = msg.value / weeklyAllowance;
        
        uint[] memory weekStarts = new uint[](numberOfWeeks);
        uint[] memory amounts = new uint[](numberOfWeeks);
        
        for (uint i; i < numberOfWeeks; ++i) {
            weekStarts[i] = startTime + i * 7 days;
            amounts[i] = weeklyAllowance;
        }
        
        FLY.depositEthWithWeeklySpendingLimits{value: msg.value}(weekStarts, amounts);
    }
    
    function viewWeeklyAllWeeklyAllowancesUpToNWeeks(uint numberOfWeeks) public view returns (uint[] memory, uint[] memory) {
        uint startTime = 1662336000;
        
        uint[] memory weekStarts = new uint[](numberOfWeeks);
        uint[] memory amounts = new uint[](numberOfWeeks);
        
        for (uint i; i < numberOfWeeks; ++i) {
            weekStarts[i] = startTime + i * 7 days;
            amounts[i] = FLY.startOfWeekToWeeklyAllowanceMapping(weekStarts[i]);
        }
        
        return (weekStarts, amounts);
    }
    
    function failsafeWithdraw() external adminRequired {
        (address treasury,,,,,,,,) = FLY.addressRegistry();
        
        (bool success, ) = payable(treasury).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}