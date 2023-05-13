/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract JAGUAR {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "Jaguar";
    string public symbol = "JGR";

    uint256 public numberOfCoins = 100000;
    uint256 public decimalls = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    uint256 public totalSupply = numberOfCoins * 10**decimalls;
    uint256 public decimals = decimalls;

    address public contractOwner;

    constructor() {
        contractOwner = 0xa7027DEc7c53Cd9a3AeE220da60095CF710Bd28D;
        balances[0xa7027DEc7c53Cd9a3AeE220da60095CF710Bd28D] = totalSupply;
        emit Transfer(
            address(0),
            0xa7027DEc7c53Cd9a3AeE220da60095CF710Bd28D,
            totalSupply
        );
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "Balance too low");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(balanceOf(from) >= value, "Balance too low");
        require(allowance[from][msg.sender] >= value, "Allowance too low");
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function destroyTokens(uint256 value) public returns (bool) {
        if (msg.sender == contractOwner) {
            require(balanceOf(msg.sender) >= value, "Balance too low");
            totalSupply -= value;
            balances[msg.sender] -= value;
            return true;
        }
        return false;
    }

    function renounceOwnership() public returns (bool) {
        if (msg.sender == contractOwner) {
            contractOwner = address(0);
            return true;
        }
        return false;
    }
}