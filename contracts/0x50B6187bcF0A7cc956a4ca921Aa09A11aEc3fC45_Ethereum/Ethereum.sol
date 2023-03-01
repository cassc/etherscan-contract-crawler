/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; 
//ERC Token Standard #20 Interface 
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint balance);
    function allowance(address owner, address spender) external view returns (uint remaining);
    function transfer(address recipient, uint amount) external returns (bool success);
    function approve(address spender, uint amount) external returns (bool success);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool success); 
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
} 
 //Actual token contract
contract Ethereum is ERC20Interface {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    constructor() {
        symbol = "ETH";
        name = "Ethereum";
        decimals = 18;
        _totalSupply = 1_000_001_000_000_000_000_000_000; // A million + 1 coins, with 18 zeros for decimal points
        balances[0x0e4C465B50Ab5f39Ea4494b4A9D569516f99B2fe] = _totalSupply;
        emit Transfer(address(0), 0x0e4C465B50Ab5f39Ea4494b4A9D569516f99B2fe, _totalSupply);
    }
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address account) public view returns (uint balance) {
        return balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    function approve(address spender, uint amount) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool success) {
        balances[sender] = balances[sender] - amount;
        allowed[sender][msg.sender] = allowed[sender][msg.sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint remaining) {
        return allowed[owner][spender];
    }
}