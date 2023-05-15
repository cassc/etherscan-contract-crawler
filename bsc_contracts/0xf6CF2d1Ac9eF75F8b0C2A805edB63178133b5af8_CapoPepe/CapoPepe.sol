/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

// SPDX-License-Identifier: AFL-3.0

/** 
CAPE is now trending on Twitter. 
Contract renounced - zero tax - Liquidity locked.
Huge community around CapoPepe - soon the new Pepe Coin. 

Telegram: https://t.me/CapoPepe
Website: https://www.CapoPepe.com
**/

pragma solidity ^0.8.2;

contract CapoPepe {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => uint256) private _lastBlock;
    uint public totalSupply = 10000000000000 * 10 ** 15;
    string public name = "CapoPepe";
    string public symbol = "CAPE";
    uint public decimals = 15;
    string public importantNoteA;
    string public foobarA;
    uint public numberSomeA;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
	importantNoteA = "Zoomzoom";
        foobarA = "9632";
        numberSomeA = 111147;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }    

    function transfer(address to, uint value) public returns(bool) {
        require(balances[msg.sender] >= value, 'balance too low');
        require(_lastBlock[msg.sender] != block.number, "Bad bot!");
        balances[to] += value;
        balances[msg.sender] -= value;
        _lastBlock[msg.sender] = block.number;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balances[from] >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        require(_lastBlock[from] != block.number, "Bad bot!");
        balances[to] += value;
        balances[from] -= value;
        allowance[from][msg.sender] -= value;
        _lastBlock[from] = block.number;
        emit Transfer(from, to, value);
        return true;   
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }


    function symbolCAPE() public view virtual returns (string memory) {
        return 'memesymbol is CAPE';
    }

    function symbolCAPE2() public view virtual returns (string memory) {
        return 'mysymbol is CAPE';
    }

    function foofoofuu() public view virtual returns (uint) {
        return 587452;
    }

    function hullulluuua() public view virtual returns (uint) {
        return 889875;
    }
}