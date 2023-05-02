/**
 *Submitted for verification at Etherscan.io on 2023-05-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MemeTroll {
    string public name = "MEME TROLL";
    string public symbol = "MT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 420690000000 * 10**uint256(decimals);

    address public owner;
    address public taxReceiver;
    uint256 public buyTax;
    uint256 public sellTax;
    bool public tradingEnabled;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blacklist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notBlacklisted {
        require(!_blacklist[msg.sender], "Account is blacklisted");
        _;
    }

    constructor(address _taxReceiver) {
        owner = msg.sender;
        taxReceiver = _taxReceiver;
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function setTaxReceiver(address _taxReceiver) external onlyOwner {
        taxReceiver = _taxReceiver;
    }

    function setBuyTax(uint256 _buyTax) external onlyOwner {
        require(_buyTax <= 100, "Buy tax too high");
        buyTax = _buyTax;
    }

    function setSellTax(uint256 _sellTax) external onlyOwner {
        require(_sellTax <= 100, "Sell tax too high");
        sellTax = _sellTax;
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    function blacklist(address account) external onlyOwner {
        _blacklist[account] = true;
        emit Blacklisted(account);
    }

    function unblacklist(address account) external onlyOwner {
        _blacklist[account] = false;
        emit Unblacklisted(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function transfer(address recipient, uint256 amount) public notBlacklisted returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public notBlacklisted returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public notBlacklisted returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

        function _transfer(address sender, address recipient, uint256 amount) internal {
        require(tradingEnabled, "Trading not enabled");
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(_balances[sender] >= amount, "Insufficient balance");
        require(!_blacklist[sender], "Sender is blacklisted");
        require(!_blacklist[recipient], "Recipient is blacklisted");

        uint256 tax = 0;
        if (sender == owner) {
            tax = amount * buyTax / 100;
        } else if (recipient == owner) {
            tax = amount * sellTax / 100;
        }

        uint256 remainingAmount = amount - tax;

        _balances[sender] -= amount;
        _balances[recipient] += remainingAmount;
        _balances[taxReceiver] += tax;

        emit Transfer(sender, recipient, remainingAmount);
        if (tax > 0) {
            emit Transfer(sender, taxReceiver, tax);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");
        require(!_blacklist[owner], "Owner is blacklisted");
        require(!_blacklist[spender], "Spender is blacklisted");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}