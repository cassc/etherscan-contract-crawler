/**
 *Submitted for verification at BscScan.com on 2022-12-02
*/

/* GILMM (GLMM) 

Join us in GILMM now! 

Telegram: @GILMMchat
Twitter: @GilmmGL
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GLMMPresale is Ownable {

    using SafeMath for uint256;

    IERC20 public GLMM = IERC20(0x46e1e7FA1F38A1C9c0B1a3f51D666e28ef7CdfA8);
    address public Recipient = 0x19f88d04A86aDc8604E07bCF6AFF27919584724A;

    uint256 public tokenRatePerEth = 30000000;
    uint256 public minETHLimit = 0.01 ether;
    uint256 public maxETHLimit = 3 ether;

    uint256 public hardCap = 100 ether;
    uint256 public totalRaisedBNB = 0;
    uint256 public totaltokenSold = 0;

    uint256 public startTime;
    uint256 public endTime;
    bool public contractPaused;

    mapping(address => uint256) public usersInvestments;

    constructor(uint256 _startTime, uint256 _endTime) {
        require(_startTime > block.timestamp, 'past timestamp');
        startTime = _startTime;
        if(_endTime > _startTime + 7 days) {
            endTime = _endTime;
        } else {
            endTime = _startTime + 30 days;
        }
    }

    modifier checkIfPaused() {
        require(contractPaused == false, "contract is paused");
        _;
    }

    function setPresaleToken(address tokenaddress) external onlyOwner {
        require( tokenaddress != address(0) );
        GLMM = IERC20(tokenaddress);
    }

    function setRecipient(address recipient) external onlyOwner {
        Recipient = recipient;
    }

    function setTokenRatePerEth(uint256 rate) external onlyOwner {
        tokenRatePerEth = rate;
    }

    function setMinEthLimit(uint256 amount) external onlyOwner {
        minETHLimit = amount;    
    }

    function setMaxEthLimit(uint256 amount) external onlyOwner {
        maxETHLimit = amount;    
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, 'past timestamp');
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        require(_endTime > startTime + 15 days, 'too short period');
        endTime = _endTime;
    }

    function togglePause() external onlyOwner returns (bool){
        contractPaused = !contractPaused;
        return contractPaused;
    }

    receive() external payable{
        deposit();
    }

    function deposit() public payable checkIfPaused {
        require(block.timestamp > startTime, 'Sale has not started');
        require(block.timestamp < endTime, 'Sale has ended');
        require(totalRaisedBNB <= hardCap, 'HardCap exceeded');
        require(
                usersInvestments[msg.sender].add(msg.value) <= maxETHLimit
                && usersInvestments[msg.sender].add(msg.value) >= minETHLimit,
                "Installment Invalid."
        );
        
        uint256 tokenAmount = getTokensPerEth(msg.value);
        require(GLMM.transfer(msg.sender, tokenAmount), "Insufficient balance of presale contract!");

        totalRaisedBNB = totalRaisedBNB.add(msg.value);
        totaltokenSold = totaltokenSold.add(tokenAmount);
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);

        payable(Recipient).transfer(msg.value);
    }

    function getUnsoldTokens(address token, address to) external onlyOwner {
        require(block.timestamp > endTime + 7 days, "You cannot get tokens until the presale is closed.");
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)) );
        payable(to).transfer(address(this).balance);
    }

    function getUserRemainingAllocation(address account) external view returns ( uint256 ) {
        return maxETHLimit.sub(usersInvestments[account]);
    }

    function getTokensPerEth(uint256 amount) internal view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(10**(uint256(18).sub(GLMM.decimals())));
    }
}