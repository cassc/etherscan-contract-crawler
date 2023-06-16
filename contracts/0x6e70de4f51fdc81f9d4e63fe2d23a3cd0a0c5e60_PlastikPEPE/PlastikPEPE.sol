/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT

// Offical Website: https://plastikpepe.com
// Offical Telegram: https://t.me/plastikpepe

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

contract PlastikPEPE is IERC20 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _taxRate;
    address private _owner;
    uint8 private _decimals;
    uint256 private _maxWalletSize;

    event TaxRateChanged(address indexed owner, uint256 newTaxRate);
    event MaxWalletSizeChanged(address indexed owner, uint256 newMaxWalletSize);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        _name = "PlastikPEPE";
        _symbol = "E2PEPE";
        _totalSupply = 1000000000 * (10 ** 18);
        _balances[msg.sender] = _totalSupply;
        _taxRate = 0;
        _owner = msg.sender;
        _decimals = 18;
        _maxWalletSize = 1000000 * (10 ** 18);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[recipient] + amount <= _maxWalletSize, "Exceeds maximum wallet size");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function allowance(address ownerAddress, address spenderAddress) public view override returns (uint256) {
    return _allowances[ownerAddress][spenderAddress];
    }


    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Allowance exceeded");
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[recipient] + amount <= _maxWalletSize, "Exceeds maximum wallet size");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] = currentAllowance - amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function transferBatch(address[] memory recipients, uint256[] memory amounts) public returns (bool) {
        require(recipients.length == amounts.length, "Recipient and amount arrays must have the same length");

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            require(amounts[i] > 0, "Amount must be greater than zero");
            totalAmount += amounts[i];
            require(_balances[recipients[i]] + amounts[i] <= _maxWalletSize, "Exceeds maximum wallet size");
            _balances[msg.sender] -= amounts[i];
            _balances[recipients[i]] += amounts[i];
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }

        require(_balances[msg.sender] >= totalAmount, "Insufficient balance");

        return true;
    }

    function getTaxRate() public view returns (uint256) {
        return _taxRate;
    }

    function setTaxRate(uint256 taxRate) public onlyOwner {
        _taxRate = taxRate;

        emit TaxRateChanged(msg.sender, taxRate);
    }

    function getMaxWalletSize() public view returns (uint256) {
        return _maxWalletSize;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;

        emit MaxWalletSizeChanged(msg.sender, maxWalletSize);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function getWalletWorth(address walletAddress) public view returns (uint256) {
        require(walletAddress != address(0), "Invalid wallet address");
        uint256 tokenBalance = _balances[walletAddress];
        return tokenBalance;
    }
}