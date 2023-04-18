/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

pragma solidity ^0.8.2;

contract BNBDevoN {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 50000000000000000000000000000000000000000;
    string public name = "BNBDevoN";
    string public symbol = "BNBDEVON";
    uint public decimals = 18;
    uint public buyTax = 9;
    uint public sellTax = 10;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        uint taxedValue = applyTax(value, false);
        balances[to] += taxedValue;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, taxedValue);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        uint taxedValue = applyTax(value, false);
        balances[to] += taxedValue;
        balances[from] -= value;
        emit Transfer(from, to, taxedValue);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function applyTax(uint value, bool isBuying) internal view returns(uint) {
        uint taxRate = isBuying ? buyTax : sellTax;
        uint taxAmount = value * taxRate / 100;
        return value - taxAmount;
    }
}