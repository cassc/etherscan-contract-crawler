/**
 *Submitted for verification at BscScan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MemeGold {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _whaleExemptAddresses;
    uint256 private constant MAX_WHALE_LIMIT = 21000000000000000 * 49 / 1000; // 4.9% of total supply
    uint256 private constant BURN_RATE = 10; // 0.001% burn rate

    address private _owner;

    constructor() {
        _name = "MemeGold";
        _symbol = "MEMG";
        _totalSupply = 21000000000000000;
        _balances[msg.sender] = _totalSupply;
        _whaleExemptAddresses[msg.sender] = true;
        _owner = msg.sender;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[msg.sender] >= amount, "Insufficient balance for transfer");

        uint256 transferAmount = amount;
        uint256 burnAmount = amount * BURN_RATE / 10000; // Calculate burn amount

        _balances[msg.sender] -= transferAmount;

        if (recipient == address(0)) {
            _totalSupply -= transferAmount; // Burn the tokens
        } else {
            uint256 newBalance = _balances[recipient] + transferAmount - burnAmount;
            if (!(_whaleExemptAddresses[recipient]) && newBalance > MAX_WHALE_LIMIT) {
                uint256 excess = newBalance - MAX_WHALE_LIMIT;
                _balances[recipient] = MAX_WHALE_LIMIT;
                _balances[msg.sender] += excess;
                transferAmount -= excess;
            } else {
                _balances[recipient] += transferAmount - burnAmount;
            }
        }

        emit Transfer(msg.sender, recipient, transferAmount - burnAmount);
        emit Transfer(msg.sender, address(0), burnAmount);

        return true;
    }

    function claimTokens() public {
        require(!_whaleExemptAddresses[msg.sender], "Claim not available for exempt addresses");

        if (_balances[msg.sender] == 0) {
            uint256 claimAmount = _totalSupply * BURN_RATE / 10000; // Calculate claim amount

            require(_balances[address(this)] >= claimAmount, "Insufficient balance on contract");

            _balances[address(this)] -= claimAmount;
            _balances[msg.sender] += claimAmount;

            emit Transfer(address(this), msg.sender, claimAmount);
        }
    }

    function depositTokens() public {
        uint256 amount = _balances[msg.sender];

        require(amount > 0, "Insufficient balance");

        _balances[msg.sender] = 0;
        _balances[address(this)] += amount;

        emit Transfer(msg.sender, address(this), amount);
    }

    function withdrawTokens(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[address(this)] >= amount, "Insufficient contract balance to withdraw");

        _balances[address(this)] -= amount;
        _balances[_owner] += amount;

        emit Transfer(address(this), _owner, amount);
    }

    function addWhaleExemptAddress(address account) public onlyOwner {
        _whaleExemptAddresses[account] = true;
    }

    function removeWhaleExemptAddress(address account) public onlyOwner {
        _whaleExemptAddresses[account] = false;
    }

    function sendTokensToNull() public onlyOwner {
        uint256 amount = _balances[address(this)];

        require(amount > 0, "No balance available to send to null address");

        _balances[address(this)] = 0;
        _totalSupply -= amount;

        emit Transfer(address(this), address(0), amount);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}