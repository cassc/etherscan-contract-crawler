/**
 *Submitted for verification at BscScan.com on 2023-03-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// LEGAL DISCLAIMER
// The information provided in this smart contract does not constitute investment advice, financial advice, trading advice, or any other sort of advice and you should not treat any of the content as such. 
// The GPT4AI team does not recommend that any cryptocurrency should be bought, sold, or held by you. 
// Do conduct your own due diligence and consult your financial advisor before making any investment decisions. 
// By purchasing GPT4AI, you agree that you are not purchasing a security or investment and you agree to hold the team harmless and not liable for any losses or taxes you may incur. 
// You also agree that the team is presenting the token "as is" and is not required to provide any support or services. 
// You should have no expectation of any form from GPT4AI and its team. 
// Although GPT4AI is an EXPERIMENTAL token for social experiment and not a digital currency, the team strongly recommends that United States persons do not purchase it because the team cannot ensure compliance with United states regulations. 
// Always make sure that you are in compliance with your local laws and regulations before you make any purchase.
//
// ----------------------------------------------------------------------------




// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract GPT4AI is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "GPT4AI";
        symbol = "GPT4AI";
        decimals = 18;
        _totalSupply = 69000000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}