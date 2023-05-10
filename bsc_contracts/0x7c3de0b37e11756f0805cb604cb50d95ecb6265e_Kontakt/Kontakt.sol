/**
 *Submitted for verification at BscScan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Kontakt is IBEP20 {

    string public name = "Kontakt";
    string public symbol = "ERA";
    uint8 public decimals = 18;

    uint256 public totalSupply = 127440000 * 10**uint(decimals);
    uint256 public burnAmount = totalSupply / 2;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner = 0x4F2171D1Db412bB932Ed0cDf89c35eF87C119cdA;



    constructor() {
        balanceOf[owner] = totalSupply - burnAmount;
        balanceOf[address(this)] = burnAmount;
        emit Transfer(address(0), owner, totalSupply - burnAmount);
        emit Transfer(address(0), address(this), burnAmount);
    }

  


  



    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

   


    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(amount <= balanceOf[sender], "Kontakt: transfer amount exceeds balance");
        require(amount <= allowance[sender][msg.sender], "Kontakt: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        allowance[sender][msg.sender] -= amount;
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Kontakt: transfer from the zero address");
        require(recipient != address(0), "Kontakt: transfer to the zero address");
        require(amount > 0, "Kontakt: transfer amount must be greater than zero");
        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "Kontakt: transfer amount exceeds balance");
        balanceOf[sender] = senderBalance - amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
}