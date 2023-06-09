/**
 *Submitted for verification at Etherscan.io on 2020-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

contract ERC20Token {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    constructor(string memory initName, string memory initSymbol, uint8 initDecimal, uint256 initialSupply) public{

        name = initName;
        symbol = initSymbol;
        decimals = initDecimal;
        
        totalSupply = initialSupply * 10 ** uint256(decimals);
	    balances[msg.sender] = totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender], "Not Enough Tokens");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner], "Not Enough Tokens");
        require(numTokens <= allowed[owner][msg.sender], "Not Enough Tokens");

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}