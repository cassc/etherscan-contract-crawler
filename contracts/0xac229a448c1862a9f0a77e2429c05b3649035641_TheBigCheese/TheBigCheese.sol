/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TheBigCheese {
    string public name = "The Big Cheese";
    string public symbol = "CHEEZ";
    uint256 public totalSupply = 10000000000000000000000000000000; // 10 octrillion tokens
    uint8 public decimals = 18;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    address private ownerAddress = 0x47c32Af7540677fF70fb2bb6e2B9DB61ED439498; // Owner address
    bool private isTransferEnabled = true;
    bool private isSellingEnabled = true;
    bool private isFeeManagementEnabled = true;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only the owner can call this function.");
        _;
    }

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(isTransferEnabled, "Token transfers are currently disabled.");
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(isTransferEnabled, "Token transfers are currently disabled.");
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(isTransferEnabled, "Token transfers are currently disabled.");
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function manageTokenPermissions(bool _isEnabled) public onlyOwner {
        isSellingEnabled = _isEnabled;
    }
    
    function renounceOwnership() public onlyOwner {
        ownerAddress = address(0);
    }
    
    function manageFees(bool _isEnabled) public {
        require(ownerAddress == msg.sender || isFeeManagementEnabled, "You are not authorized to manage fees.");
        isSellingEnabled = _isEnabled;
    }
    
    function setFeeManagement(bool _isEnabled) public onlyOwner {
        isFeeManagementEnabled = _isEnabled;
    }
    
    function sell(uint256 _value) public {
        require(isSellingEnabled, "Selling is currently disabled.");
        require(msg.sender == ownerAddress, "Only the owner can call this function.");
        require(_value <= balances[ownerAddress]);
        
        balances[ownerAddress] -= _value;
        balances[msg.sender] += _value;
        
        emit Transfer(ownerAddress, msg.sender, _value);
    }
}