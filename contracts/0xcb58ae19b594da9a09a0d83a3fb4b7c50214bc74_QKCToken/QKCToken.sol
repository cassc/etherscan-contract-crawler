/**
 *Submitted for verification at Etherscan.io on 2022-10-26
*/

/*

   $$\    $$$$$$$\                          $$\                 
 $$$$$$\  $$  __$$\                         $$ |                
$$  __$$\ $$ |  $$ | $$$$$$\  $$$$$$\$$$$\  $$$$$$$\   $$$$$$$\ 
$$ /  \__|$$$$$$$\ |$$  __$$\ $$  _$$  _$$\ $$  __$$\ $$  _____|
\$$$$$$\  $$  __$$\ $$ /  $$ |$$ / $$ / $$ |$$ |  $$ |\$$$$$$\  
 \___ $$\ $$ |  $$ |$$ |  $$ |$$ | $$ | $$ |$$ |  $$ | \____$$\ 
$$\  \$$ |$$$$$$$  |\$$$$$$  |$$ | $$ | $$ |$$$$$$$  |$$$$$$$  |
\$$$$$$  |\_______/  \______/ \__| \__| \__|\_______/ \_______/ 
 \_$$  _/                                                       
   \ _/                                                         

Tokens made for the Degen Space Bombs project to generate passive income!                  

*/

pragma solidity ^0.4.24;
 
//Safe Math Interface
 
contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
 
//ERC Token Standard #20 Interface
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
 
//Contract function to receive approval and execute function in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//Actual token contract
 
contract QKCToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        symbol = "$bombs";
        name = "Degen Space $Bombs Coin";
        decimals = 2;
        _totalSupply = 444400000000;
        balances[0xDDDf6F4c4cfD6319e60F09ceECf4E6D46CC042E2] = _totalSupply;
        emit Transfer(address(0), 0xDDDf6F4c4cfD6319e60F09ceECf4E6D46CC042E2, _totalSupply);
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
 
    function () public payable {
        revert();
    }
}