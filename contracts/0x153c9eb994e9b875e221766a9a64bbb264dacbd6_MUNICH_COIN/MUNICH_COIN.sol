/**
 *Submitted for verification at Etherscan.io on 2023-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MUNICH_COIN {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping (address =>uint256)private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address private _owner;
    constructor(){
        _name= "MUNICH_COIN";
        _symbol = "MUNICH";
        _decimals = 18;
        _totalSupply = 8000000000000000000000000000 * 10**uint256(_decimals);
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
    } 
    function getOwner () external view returns (address) {
        return _owner;
    }
    function name () external view returns (string memory) {
        return _name;
    }

    function symbol () external view returns (string memory){
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256){
        return _balances[account];
    }


    function allowance(address owner, address spender) public view returns  (uint256){
    return _allowances[owner][spender];
    }
    function _trasfer (address sender, address recipient, uint256 amount) private {
        _balances[sender]-= amount;
        _balances[recipient]+= amount;
        emit Transfer(sender,recipient, amount);
    } 
    function _approve(address owner, address spender, uint256 amount)private {
        _allowances [owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    event Transfer(address indexed from, address indexed to,uint256 value);
    event Approval(address indexed owner, address indexed spender,uint256 value);

}