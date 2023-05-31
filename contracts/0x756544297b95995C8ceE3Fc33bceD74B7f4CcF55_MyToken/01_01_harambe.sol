// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => uint256) private lastTradeTime;

    uint256 private tradeDelay = 24 hours;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "HARAMBE";
        symbol = "HMB";
        decimals = 18;
        totalSupply = 10000000000 * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender], "Insufficient balance");
        require(isTradeAllowed(msg.sender), "Trade not allowed before delay");

        balances[msg.sender] -= value;
        balances[to] += value;

        lastTradeTime[msg.sender] = block.timestamp;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from], "Insufficient balance");
        require(value <= allowed[from][msg.sender], "Insufficient allowance");
        require(isTradeAllowed(from), "Trade not allowed before delay");

        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;

        lastTradeTime[from] = block.timestamp;

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function isTradeAllowed(address account) internal view returns (bool) {
        return lastTradeTime[account] + tradeDelay <= block.timestamp;
    }

    // Additional functions to add and remove liquidity from Uniswap

    function addLiquidity(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        balances[msg.sender] += amount;
        totalSupply += amount;

        emit Transfer(address(0), msg.sender, amount);
    }

    function removeLiquidity(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }
}