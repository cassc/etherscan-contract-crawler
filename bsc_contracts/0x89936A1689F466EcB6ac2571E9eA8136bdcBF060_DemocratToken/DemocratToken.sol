/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract DemocratToken {
    string public constant name = "Democrat Token";
    string public constant symbol = "DPT";
    uint8 public constant decimals = 18;
    uint256 public constant initialSupply = 450000000000 * 10**uint256(decimals);
    uint256 public totalSupply;
    uint256 public burnPercent = 1; // 1% burn rate
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    constructor() {
        totalSupply = initialSupply;
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value <= totalSupply / 10); // Limit transfer to 10% of total supply
        
        uint256 burnAmount = _value * burnPercent / 100;
        uint256 transferAmount = _value - burnAmount;
        
        balances[msg.sender] -= _value;
        balances[_to] += transferAmount;
        totalSupply -= burnAmount;
        
        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, address(0), burnAmount);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_value <= totalSupply / 10); // Limit transfer to 10% of total supply
        
        uint256 burnAmount = _value * burnPercent / 100;
        uint256 transferAmount = _value - burnAmount;
        
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += transferAmount;
        totalSupply -= burnAmount;
        
        emit Transfer(_from, _to, transferAmount);
        emit Transfer(_from, address(0), burnAmount);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}