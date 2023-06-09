// SPDX-License-Identifier: MIT

/*
チェリー 

完璧な花を見つけることは、完璧なトークンを見つけるようなものです。
私たちは良いトークンとは何かを定義します。
単純。税金はかかりません。隠れた機能はありません。作成。

https://t.me/cherry_b
*/


pragma solidity ^0.8.0;


contract CHERRY {
    string public name = "CHERRY BLOSSOM";
    string public symbol = "CHERRY";
    uint256 public totalSupply = 50_000_000_00* 10**18; 
    uint8 public decimals = 18;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != address(0));
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
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        require(_to != address(0));
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
}