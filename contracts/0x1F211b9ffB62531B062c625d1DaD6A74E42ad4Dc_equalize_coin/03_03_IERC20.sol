//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public virtual returns (uint);
    function balanceOf(address who) public virtual returns (uint);
    function transfer(address to, uint value) public virtual;
    event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract IERC20 is ERC20Basic {
    function allowance(address owner, address spender) public virtual returns (uint);
    function transferFrom(address from, address to, uint value) public virtual;
    function approve(address spender, uint value) public virtual;
    uint public decimals;
    event Approval(address indexed owner, address indexed spender, uint value);
}