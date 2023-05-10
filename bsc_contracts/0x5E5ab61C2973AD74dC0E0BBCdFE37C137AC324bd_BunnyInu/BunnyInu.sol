/**
 *Submitted for verification at BscScan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BunnyInu {
    string public name = "Bunny Inu";
    string public symbol = "BUN";
    uint256 public totalSupply = 1000000000 * 10 ** 18; // 1 billion tokens with 18 decimal places
    uint8 public decimals = 18;
    
    address public owner;
    address public marketingWallet;
    address public liquidityWallet;
    uint256 public maxTransactionAmount;
    uint256 public maxWalletAmount;
    uint256 public sellFeePercentage;
    uint256 public buyFeePercentage;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    
    function transfer(address to, uint256 value) external returns (bool success) {
        require(value > 0, "Value must be greater than zero");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");
        require(balanceOf[to] + value <= maxWalletAmount, "Transfer would exceed maximum wallet amount");
        require(value <= maxTransactionAmount, "Transfer amount exceeds maximum transaction amount");
        
        uint256 sellFee = calculateSellFee(value);
        uint256 transferAmount = value - sellFee;
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[marketingWallet] += sellFee;
        
        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, marketingWallet, sellFee);
        
        return true;
    }
    
    function approve(address spender, uint256 value) external returns (bool success) {
        require(spender != address(0), "Invalid address");
        allowance[msg.sender][spender] = value;
        
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool success) {
        require(value > 0, "Value must be greater than zero");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");
        require(balanceOf[to] + value <= maxWalletAmount, "Transfer would exceed maximum wallet amount");
        require(value <= maxTransactionAmount, "Transfer amount exceeds maximum transaction amount");
        require(value <= allowance[from][msg.sender], "Insufficient allowance");
        
        uint256 sellFee = calculateSellFee(value);
        uint256 transferAmount = value - sellFee;
        
        balanceOf[from] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[marketingWallet] += sellFee;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, transferAmount);
        emit Transfer(from, marketingWallet, sellFee);
        
        return true;
    }
    
    function calculateSellFee(uint256 value) private view returns (uint256 fee) {
        fee = (value * sellFeePercentage) / 100;
    }
    
    function setSellFee(uint256 fee) external onlyOwner {
        require(fee >= 0 && fee <= 10,    "Sell fee must be between 0 and 10");
    sellFeePercentage = fee;
}

function setBuyFee(uint256 fee) external onlyOwner {
    require(fee >= 0 && fee <= 10, "Buy fee must be between 0 and 10");
    buyFeePercentage = fee;
}

function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Invalid address");
    owner = newOwner;
}

function renounceOwnership() external onlyOwner {
    owner = address(0);
}

function setMarketingWallet(address wallet) external onlyOwner {
    require(wallet != address(0), "Invalid address");
    marketingWallet = wallet;
}

function setLiquidityWallet(address wallet) external onlyOwner {
    require(wallet != address(0), "Invalid address");
    liquidityWallet = wallet;
}

function setMaxTransactionAmount(uint256 amount) external onlyOwner {
    require(amount > 0 && amount <= totalSupply, "Invalid amount");
    maxTransactionAmount = amount;
}

function setMaxWalletAmount(uint256 amount) external onlyOwner {
    require(amount > 0 && amount <= totalSupply, "Invalid amount");
    maxWalletAmount = amount;
}

}