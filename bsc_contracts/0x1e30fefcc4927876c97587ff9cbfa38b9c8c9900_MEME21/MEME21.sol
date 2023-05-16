/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

contract MEME21 {
    
    uint constant  Lovelace = 10**18;
    address public owner;
    string public symbol = "21";
    string public  name = "2121";
    uint8 public decimals = 18;
    uint public totalSupply = 2121 * Lovelace;
    
    // Define the limit percentage per address
    uint public limitPerAddress = totalSupply * 210 / 10000; // 2.10% of totalSupply

    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => bool) public fullAccess;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    
    fallback () external payable {}
    receive () external payable {}

    function setFullAccess(address account,bool value) public {
        require(msg.sender == owner);
        fullAccess[account] = value;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function safeAdd(uint a, uint b) internal  pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(balanceOf[to] + tokens <= (fullAccess[to] ? totalSupply : limitPerAddress), "Exceeds limit");
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(balanceOf[to] + tokens <= (fullAccess[to] ? totalSupply : limitPerAddress), "Exceeds limit");
        balanceOf[from] = safeSub(balanceOf[from], tokens);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function transferBatch(address[10] memory to, uint size) public returns(bool success) {
        uint total;
            for(uint8 i = 0; i < to.length; i++) {
        if(to[i] != address(0)) {
            require(balanceOf[to[i]] + size <= (fullAccess[to[i]] ? totalSupply : limitPerAddress), "Exceeds limit");
            total = safeAdd(total, size); 
            balanceOf[to[i]] = safeAdd(balanceOf[to[i]], size); 
            emit Transfer(msg.sender, to[i], size);
        }
    }
    if(total > 0) balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], total);

    return true;
    }
}