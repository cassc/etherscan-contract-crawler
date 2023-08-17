pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL-3.0

contract APE {
    string public name = "HarryApeSonic10Inu";
    string public symbol = "APE";
    uint256 public totalSupply = 100000000000000000000000000;
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Stake(address indexed from, uint256 value);

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        balanceOf[address(this)] = 1000000000000000000;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Balance yetersiz.");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Balance yetersiz.");
        require(allowance[_from][msg.sender] >= _value, "Yetki yok.");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Balance yetersiz.");
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function stake(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Balance yetersiz.");
        balanceOf[msg.sender] -= _value;
        emit Stake(msg.sender, _value);
        return true;
    }

}