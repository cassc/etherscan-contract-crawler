/**
 *Submitted for verification at Etherscan.io on 2023-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CPICoin {
    string public name = "CPI Coin";
    string public symbol = "CPI";
    uint256 public totalSupply = 2_000_000_000 * 10**18;
    uint8 public decimals = 18;
    address public taxWallet = 0xD81895407B375389dC5e4E5d0CFEC65C1bd9dAb3;
    uint256 public buyTaxPercent = 2;
    uint256 public sellTaxPercent = 2;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balances[msg.sender], "ERC20: insufficient balance");
        uint256 taxedAmount = getTaxedAmount(_value, msg.sender == taxWallet);
        balances[msg.sender] -= _value;
        balances[_to] += taxedAmount;
        emit Transfer(msg.sender, _to, taxedAmount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balances[_from], "ERC20: insufficient balance");
        require(_value <= allowed[_from][msg.sender], "ERC20: insufficient allowance");
        uint256 taxedAmount = getTaxedAmount(_value, _from == taxWallet);
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += taxedAmount;
        emit Transfer(_from, _to, taxedAmount);
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

    function getTaxedAmount(uint256 _value, bool _isTaxWallet) internal view returns (uint256) {
        uint256 taxAmount = _isTaxWallet ? 0 : _value * buyTaxPercent / 100;
        return _value - taxAmount;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}