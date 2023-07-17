/**
 *Submitted for verification at Etherscan.io on 2023-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2023-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract WPEPEDOGESHIB is IERC20, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _blacklist;

    uint256 private _taxRate = 30; 
    address private _taxAddress;

    modifier onlyTokenOwner() {
        require(msg.sender == owner(), "WPEPEDOGESHIB: caller is not the token owner");
        _;
    }

    constructor() {
        name = 'WPEPEDOGESHIB';
        symbol = 'WPDS';
        _totalSupply = 10000000000 * 10**uint256(decimals);
        _balances[msg.sender] = _totalSupply;
        _taxAddress = 0x2bc2553481AbDEc1eA89DCb4b6Fd81274B169cB2;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    
    function blacklist(address account) external onlyTokenOwner {
        require(account != address(0), "WPEPEDOGESHIB: Blacklist address cannot be zero address");
        _blacklist[account] = true;
    }

    function removeFromBlacklist(address account) external onlyTokenOwner {
        _blacklist[account] = false;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }

    
    function setTaxRate(uint256 rate) external onlyTokenOwner {
        require(rate <= 100, "WPEPEDOGESHIB: Tax rate must be less than or equal to 100");
        _taxRate = rate;
    }

    function setTaxAddress(address taxAddress) external onlyTokenOwner {
        require(taxAddress != address(0), "WPEPEDOGESHIB: Tax address cannot be zero address");
        _taxAddress = taxAddress;
    }

    function getTaxRate() public view returns (uint256) {
        return _taxRate;
    }

    function getTaxAmount(uint256 amount) public view returns (uint256) {
        return amount * _taxRate / 100;
    }

    function getTaxAddress() public view returns (address) {
        return _taxAddress;
    }

    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!_blacklist[msg.sender], "WPEPEDOGESHIB: Sender is blacklisted");
        require(!_blacklist[recipient], "WPEPEDOGESHIB: Recipient is blacklisted");
        require(amount <= _balances[msg.sender], "WPEPEDOGESHIB: Insufficient balance");
        uint256 taxAmount = getTaxAmount(amount);
        uint256 transferAmount = amount - taxAmount;
        _balances[msg.sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[_taxAddress] += taxAmount;
        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, _taxAddress, taxAmount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(!_blacklist[sender], "WPEPEDOGESHIB: Sender is blacklisted");
        require(!_blacklist[recipient], "WPEPEDOGESHIB: Recipient is blacklisted");
        require(amount <= _balances[sender], "WPEPEDOGESHIB: Insufficient balance");
        require(amount <= _allowances[sender][msg.sender], "WPEPEDOGESHIB: Insufficient allowance");
        uint256 taxAmount = getTaxAmount(amount);
        uint256 transferAmount = amount - taxAmount;
        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[_taxAddress] += taxAmount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _taxAddress, taxAmount);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}