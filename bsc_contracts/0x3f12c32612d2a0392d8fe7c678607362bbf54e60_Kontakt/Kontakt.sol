/**
 *Submitted for verification at BscScan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Kontakt {

    string public name = "Kontakt";
    string public symbol = "ERA";
    uint256 public totalSupply = 127440000000000000000000000;
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public burnAmount = totalSupply / 2;
    address public owner = 0x4F2171D1Db412bB932Ed0cDf89c35eF87C119cdA;
    
   

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balanceOf[owner] = totalSupply - burnAmount;
        balanceOf[address(this)] = burnAmount;
        emit Transfer(address(0), owner, totalSupply - burnAmount);
        emit Transfer(address(0), address(this), burnAmount);
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "ERC20: transfer amount must be greater than zero");
        require(balanceOf[_from] >= _value, "ERC20: insufficient balance");

    

        balanceOf[_from] -= _value;

        
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender], "ERC20: transfer amount exceeds allowance");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}