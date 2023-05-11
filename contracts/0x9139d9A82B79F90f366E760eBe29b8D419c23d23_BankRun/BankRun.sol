/**
 *Submitted for verification at Etherscan.io on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BankRun is IERC20 {
    string public constant name = "Bank Run";
    string public constant symbol = "BANKRUN";
    uint8 public constant decimals = 18;
    uint256 private constant MAX_SUPPLY = 210345000000000 * 10 ** decimals;
    uint256 private constant MAX_WALLET = (MAX_SUPPLY * 3) / 100;
    uint256 private constant MAX_TRANSACTION = (MAX_SUPPLY * 3) / 100;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    bool private _tradingEnabled = false;
    mapping(address => uint256) private _lastTransactionTimestamp;

    address private owner;

constructor() {
    _totalSupply = MAX_SUPPLY;
    _balances[msg.sender] = MAX_SUPPLY;
    owner = msg.sender;
    emit Transfer(address(0), msg.sender, MAX_SUPPLY);
}
function buy() public payable tradingEnabled returns (bool) {
    uint256 amount = msg.value * 10 ** decimals; // Calculate the amount of tokens to buy
    require(amount <= MAX_TRANSACTION, "Buy amount exceeds the maximum transaction limit.");
    require(_totalSupply - amount >= 0, "Not enough tokens available for sale.");

    _balances[msg.sender] += amount;
    _totalSupply -= amount;
    emit Transfer(address(0), msg.sender, amount);
    return true;
}

function sell(uint256 amount) public tradingEnabled returns (bool) {
    require(amount <= MAX_TRANSACTION, "Sell amount exceeds the maximum transaction limit.");
    require(amount <= _balances[msg.sender], "Not enough balance.");

    uint256 saleValue = amount / 10 ** decimals; // Calculate the sale value in ether
    _balances[msg.sender] -= amount;
    _totalSupply += amount;
    payable(msg.sender).transfer(saleValue);
    emit Transfer(msg.sender, address(0), amount);
    return true;
}
    modifier tradingEnabled() {
        require(_tradingEnabled, "Trading is not enabled yet.");
        _;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function setTradingEnabled(bool enabled) public {
    require(msg.sender == owner, "Only the contract owner can enable trading.");
    _tradingEnabled = enabled;
}

    function transfer(address recipient, uint256 amount) public override tradingEnabled returns (bool) {
        require(amount <= MAX_TRANSACTION, "Transfer amount exceeds the maximum transaction limit.");
        require(amount <= _balances[msg.sender], "Not enough balance.");
        require(_balances[recipient] + amount <= MAX_WALLET, "Recipient balance exceeds the maximum wallet limit.");
        require(block.timestamp - _lastTransactionTimestamp[msg.sender] >= 60, "You can not buy and then sell within one minute.");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        _lastTransactionTimestamp[msg.sender] = block.timestamp;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address ownerAddr, address spender) public view override returns (uint256) {
        return _allowances[ownerAddr][spender];
    }

    function approve(address spender, uint256 amount) public override tradingEnabled returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override tradingEnabled returns (bool) {
        require(amount <= MAX_TRANSACTION, "Transfer amount exceeds the maximum transaction limit.");
        require(amount <= _balances[sender], "Not enough balance.");
        require(_balances[recipient] + amount <= MAX_WALLET, "Recipient balance exceeds the maximum wallet limit.");
        require(_allowances[sender][msg.sender] >= amount, "Transfer amount exceeds allowance.");
        require(block.timestamp - _lastTransactionTimestamp[sender] >= 60, "You can not buy and then sell within one minute.");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        _lastTransactionTimestamp[sender] = block.timestamp;
        emit Transfer(sender, recipient, amount);
        return true;
    }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
modifier onlyOwner() {
    require(msg.sender == owner, "Only the contract owner can call this function.");
    _;

    
}
    function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
}

}