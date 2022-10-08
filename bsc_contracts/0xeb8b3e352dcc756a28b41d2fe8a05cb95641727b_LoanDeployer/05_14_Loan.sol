// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

struct Accept {
    uint256 acceptIndex;
    address borrower;
    uint256 principle;
    uint256 paidPrinciple;
    uint256 paidInterest;
    uint256 paidFee;
    uint64 paidDays;
    uint256 acceptedAt;
    uint256 lastPaymentTime;
}

contract Loan {

    address public token;
    uint256 public tokenAmount;
    uint64 public duration = 365;
    uint64 public paymentPeriod = 30;
    uint8 public aPRInerestRate;
    address public owner;
    uint8 public status; // "activated - 2, canceled - 0, pending - 1"

    address public deployer;
    address public governance;

    uint256 public createdAt;
    uint256 public acceptedAt;

    address public teamWallet;

    uint256 public acceptFee = 5; // 5%
    uint256 public payBackFee = 2; // 2%

    uint256 public weekHours = 7 * 24;

    uint64 public paymentDue = 5 * 24;

    mapping(address=>Accept[]) public acceptLoanMap;
    mapping(address=>bool) public isBorrowerMap;

    event PaidBack(
        address indexed borrower, 
        uint256 paidPrinciple, 
        uint256 paidInterest, 
        uint256 paidFee, 
        bool indexed isFullPayback
    );

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not owner!");
        _;
    }

    modifier onlyGovernance() {
        require(governance == msg.sender, "Caller is not Governance!");
        _;
    }

    modifier onlyActivated() {
        require(status == 2, "Loan is not Activated");
        _;
    }

    modifier onlyPending() {
        require(status == 1, "Loan is not Pending");
        _;
    }

    modifier onlyBorrower() {
        require(isBorrowerMap[msg.sender], "Caller is not Borrower");
        _;
    }

    constructor (){
        deployer = msg.sender;
    }

    function initialize(
        address _governance, 
        address _owner, 
        address _token,
        uint256 _tokenAmount, 
        uint64 _duration, 
        uint64 _paymentPeriod, 
        uint8 _APRinterestRate,
        address _teamWallet
    ) external {
        require(msg.sender == deployer, 'Loan: FORBIDDEN'); // sufficient check
        require(_APRinterestRate >= 5 && _APRinterestRate <= 500, "APR interest Rate should be in 5% ~ 500%");
        owner = _owner;
        governance = _governance;
        token = _token;
        tokenAmount = _tokenAmount;
        duration = _duration;
        paymentPeriod = _paymentPeriod;
        aPRInerestRate = _APRinterestRate;
        status = 1; // pending
        createdAt = block.timestamp;
        teamWallet = _teamWallet;
    }

    function updateDuration(uint64 _duration) public onlyOwner onlyPending {
        duration = _duration;
    }

    function updatePaymentPeriod(uint64 _paymentPeriod) public onlyOwner onlyPending {
        paymentPeriod = _paymentPeriod;
    }

    function updateAPRInerestRate(uint8 _APRinterestRate) public onlyOwner onlyPending {
        require(_APRinterestRate >= 3 && _APRinterestRate <= 30, "APR interest Rate should be in 3% ~ 30%");
        aPRInerestRate = _APRinterestRate;
    }

    function updatePaymentDue(uint64 _paymentDue) public onlyOwner onlyPending {
        require(paymentDue != _paymentDue, "aready same value");
        paymentDue = _paymentDue;
    }

    function updateDurationPaymentPeriodAPRInerestRate(
        uint64 _duration, 
        uint64 _paymentPeriod, 
        uint8 _APRinterestRate) public onlyOwner onlyPending {
        require(_APRinterestRate >= 3 && _APRinterestRate <= 30, "APR interest Rate should be in 3% ~ 30%");
        duration = _duration;
        paymentPeriod = _paymentPeriod;
        aPRInerestRate = _APRinterestRate;
    }

    function cancel() public onlyOwner onlyPending {
        status = 0;
        uint256 paneltyAmount = 0;

        if(block.timestamp - createdAt < weekHours * 3600){
            paneltyAmount = tokenAmount * 50 / 1000;
        }else if(block.timestamp - createdAt < 2 * weekHours * 3600){
            paneltyAmount = tokenAmount * 25 / 1000;
        }

        IERC20(token).transfer(owner, tokenAmount - paneltyAmount);
        if(paneltyAmount > 0){
            IERC20(token).transfer(teamWallet, paneltyAmount);
        }
    }

    function accept(address _borrower, uint256 _borrowAmount) public onlyGovernance {
        require(IERC20(token).balanceOf(address(this)) >= _borrowAmount, "not enough amount to borrow");
        uint256 acceptFeeAmount = _borrowAmount * acceptFee / 100;
        IERC20(token).transfer(teamWallet, acceptFeeAmount);
        IERC20(token).transfer(_borrower, _borrowAmount - acceptFeeAmount);
        if(status != 2) status = 2; // activated;
        acceptedAt = block.timestamp;
        isBorrowerMap[_borrower] = true;

        Accept memory acceptLoan = Accept({
            acceptIndex: acceptLoanMap[_borrower].length, 
            borrower:_borrower, 
            principle:_borrowAmount, 
            paidPrinciple:0,
            paidInterest:0,
            paidFee:0,
            paidDays:0,
            lastPaymentTime:acceptedAt,
            acceptedAt:acceptedAt 
        });

        acceptLoanMap[_borrower].push(acceptLoan);
        
    }

    function payBack(uint256 acceptId, uint256 _payBackAmount) public onlyBorrower {

        if(acceptLoanMap[msg.sender].length == 0){
            revert("None exist!");
        }

        uint256 lastPaymentTime = acceptLoanMap[msg.sender][acceptId].lastPaymentTime;
        
        if(block.timestamp < lastPaymentTime + (paymentPeriod * 24 - paymentDue) * 3600){
            revert("Payment Due Error!");
        }

        (uint256 principleToPay, uint256 interestToPay, uint256 feeToPay) = getPaybackAmount(acceptId, msg.sender);
        uint256 totalPay = principleToPay + interestToPay + feeToPay;
        require(_payBackAmount >= totalPay, "not enough payback amount!");
        uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
        require(allowance >= totalPay, "Caller did not approve tokens for loan payback!");

        IERC20(token).transferFrom(msg.sender, owner, (principleToPay + interestToPay));
        IERC20(token).transferFrom(msg.sender, teamWallet, feeToPay);

        acceptLoanMap[msg.sender][acceptId].paidPrinciple += principleToPay;
        acceptLoanMap[msg.sender][acceptId].paidInterest += interestToPay;
        acceptLoanMap[msg.sender][acceptId].paidFee += feeToPay;
        acceptLoanMap[msg.sender][acceptId].paidDays += paymentPeriod;
        acceptLoanMap[msg.sender][acceptId].lastPaymentTime = block.timestamp;

        emit PaidBack(msg.sender, principleToPay, interestToPay, feeToPay, false);
        
    }

    function payOff(uint256 acceptId, uint256 _payBackAmount) public onlyBorrower {

        (uint256 principleToPay, uint256 interestToPay, uint256 feeToPay) = getPayOffAmount(acceptId, msg.sender);
        uint256 totalPay = principleToPay + interestToPay + feeToPay;
        require(_payBackAmount >= totalPay, "not enough payback amount!");
        uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
        require(allowance >= totalPay, "Caller did not approve tokens for loan payback!");

        IERC20(token).transferFrom(msg.sender, owner, (principleToPay + interestToPay));
        IERC20(token).transferFrom(msg.sender, teamWallet, feeToPay);

        acceptLoanMap[msg.sender][acceptId].paidPrinciple += principleToPay;
        acceptLoanMap[msg.sender][acceptId].paidInterest += interestToPay;
        acceptLoanMap[msg.sender][acceptId].paidFee += feeToPay;
        acceptLoanMap[msg.sender][acceptId].paidDays = duration;
        acceptLoanMap[msg.sender][acceptId].lastPaymentTime = block.timestamp;

        emit PaidBack(msg.sender, principleToPay, interestToPay, feeToPay, true);
        
    }

    function getOwedAmount(address _borrower) public view returns (uint256 toPayPrinciple, uint256 toPayInterest, uint256 toPayFee){

        uint256 index = 0;
        while(index < acceptLoanMap[_borrower].length){
            Accept memory acceptLoan = acceptLoanMap[_borrower][index];
            toPayPrinciple += (acceptLoan.principle - acceptLoan.paidPrinciple);
            uint256 totalIrt = acceptLoan.principle * aPRInerestRate / 100 * duration / 365;
            toPayInterest += totalIrt - acceptLoan.paidInterest;
            toPayFee = (toPayPrinciple + toPayInterest) * payBackFee / 100;
            index ++;
        }
    }

    function getPaybackAmount(uint256 acceptId, address _account) public view 
    returns (uint256 principleToPay, uint256 interestToPay, uint256 feeToPay) {

        Accept memory acceptLoan = acceptLoanMap[_account][acceptId];
        uint256 totalIrt = acceptLoan.principle * aPRInerestRate / 100 * duration / 365;

        uint64 np = duration/paymentPeriod; // number of payment
        principleToPay = acceptLoan.principle / np;
        interestToPay = totalIrt / np;
        feeToPay = (principleToPay + interestToPay) * payBackFee / 100;

    }

    function getPayOffAmount(uint256 acceptId, address _account) public view 
    returns (uint256 principleToPay, uint256 interestToPay, uint256 feeToPay) {

        Accept memory acceptLoan = acceptLoanMap[_account][acceptId];
        uint256 totalIrt = acceptLoan.principle * aPRInerestRate / 100 * duration / 365;

        principleToPay = acceptLoan.principle - acceptLoan.paidPrinciple;
        interestToPay = totalIrt - acceptLoan.paidInterest;
        feeToPay = (principleToPay + interestToPay) * payBackFee / 100;
    }

    function updateWeekHours(uint256 _weekHours) public onlyOwner onlyPending {
        weekHours = _weekHours;
    }

    function getAcceptLoanMapLengthOf(address _borrower) public view returns(uint256){
        return acceptLoanMap[_borrower].length;
    }

}