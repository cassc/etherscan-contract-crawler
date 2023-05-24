// SPDX-License-Identifier: MIT
/**
    8 8                                                                            
 ad88888ba   88888888ba,    88  88888888888  ad88888ba   88888888888  88           
d8" 8 8 "8b  88      `"8b   88  88          d8"     "8b  88           88           
Y8, 8 8      88        `8b  88  88          Y8,          88           88           
`Y8a8a8a,    88         88  88  88aaaaa     `Y8aaaaa,    88aaaaa      88           
  `"8"8"8b,  88         88  88  88"""""       `"""""8b,  88"""""      88           
    8 8 `8b  88         8P  88  88                  `8b  88           88           
Y8a 8 8 a8P  88      .a8P   88  88          Y8a     a8P  88           88           
 "Y88888P"   88888888Y"'    88  88888888888  "Y88888P"   88888888888  88888888888  
    8 8                                                                            
                                                                                       
   web:https://vindis.pro/
   tg: https://t.me/Diesel_ETH_Tok
   Living a quarter mile at a time..                                                                                
                                                                                   */

pragma solidity ^0.8.0;


contract DIESEL {
    string public name = "DIESEL";
    string public symbol = "DIESEL";
    uint256 public totalSupply = 5_000_000* 10**18; 
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

    function renounce() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
}