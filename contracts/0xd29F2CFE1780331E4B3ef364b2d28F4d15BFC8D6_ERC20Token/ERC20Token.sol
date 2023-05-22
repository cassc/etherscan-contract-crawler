/**
 *Submitted for verification at Etherscan.io on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    bool public taxEnabled;
    uint256 public taxRate;
    string public officialTwitter;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply, string memory _officialTwitter) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
        taxEnabled = true;
        taxRate = 1;
        officialTwitter = _officialTwitter;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        require(_amount <= balances[msg.sender], "Insufficient balance");
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        require(_amount <= balances[_sender], "Insufficient balance");
        require(_amount <= allowances[_sender][msg.sender], "Insufficient allowance");
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, allowances[_sender][msg.sender] - _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function enableTax() external {
        require(!taxEnabled, "Tax is already enabled");
        taxEnabled = true;
    }

    function disableTax() external {
        require(taxEnabled, "Tax is already disabled");
        taxEnabled = false;
    }

    function setTaxRate(uint256 _rate) external {
        require(_rate <= 100, "Invalid tax rate");
        taxRate = _rate;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        uint256 taxAmount = 0;
        if (taxEnabled && _sender != address(0) && _recipient != address(0)) {
            taxAmount = (_amount * taxRate) / 100;
        }
        uint256 transferAmount = _amount - taxAmount;

        balances[_sender] -= _amount;
        balances[_recipient] += transferAmount;
        balances[address(this)] += taxAmount;

        emit Transfer(_sender, _recipient, transferAmount);
        if (taxAmount > 0) {
            emit Transfer(_sender, address(this), taxAmount);
        }
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}