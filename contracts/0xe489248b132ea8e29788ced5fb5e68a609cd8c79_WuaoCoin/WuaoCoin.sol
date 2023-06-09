/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

abstract contract ERC20Interface{
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner)public virtual view returns (uint);
    function allowance(address tokenOwner, address spender)
    public virtual view returns (uint);
    function transfer(address to, uint tokens) public virtual returns (bool);
    function approve(address spender, uint tokens)  public virtual returns (bool);
    function transferFrom(address from, address to, uint tokens)virtual public returns (bool);
     
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
}

contract WuaoCoin is ERC20Interface{
    string public constant name   = "WUAOCOIN";
    string public constant symbol = "WUAO";
    uint8 public constant decimals= 18;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint private immutable totalSupp;
    address private immutable manager;
    
    constructor() {// todo change 100.000.000.000.000.000.000.000.000
        totalSupp = 100000000000000000000000000;
        balances[msg.sender] = totalSupp;
        emit Transfer(address(0), msg.sender, totalSupp);
        manager = msg.sender;
    }

    function totalSupply() public view override returns (uint){
        return totalSupp;
    }
 
    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        balance = balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) override public returns (bool success) {
        balances[msg.sender] = sub(balances[msg.sender],tokens);
        balances[to] = add(balances[to],tokens);
        emit Transfer(msg.sender, to, tokens);
        success = true;
    }
 
    function approve(address spender, uint tokens) override public returns (bool success) {
        require (balances[msg.sender] > tokens,"Sender without balance!");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        success = true;
    }
 
    function transferFrom(address from, address to, uint tokens) override public returns (bool success) {
        require(allowed[from][msg.sender]>=tokens,"Spender without balance");
        allowed[from][msg.sender] = sub(allowed[from][msg.sender],tokens);
        balances[from] = sub(balances[from],tokens);
        balances[to] = add(balances[to],tokens);
        emit Transfer(from, to, tokens);
        success = true;
    }
 
    function allowance(address tokenOwner, address spender)  public override view returns (uint remaining) {
        remaining = allowed[tokenOwner][spender];
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
}