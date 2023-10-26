/**
 *Submitted for verification at Etherscan.io on 2023-09-23
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
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MaterToken is IERC20, Ownable {
    string public name = "Mater";
    string public symbol = "MATER";
    uint8 public decimals = 18;
    uint256 private _totalSupply;
    address public feeAddress;
    uint256 public maxTransferFeeRate = 2;
    uint256 public maxBurnFeeRate = 2;
    uint256 public maxTransferAmount = 10000000000 * 10**uint256(decimals);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromFees;
    uint256 public transferFeeRate = 2;
    uint256 public burnFeeRate = 1;
    uint256 public globalMaxBalance; // Global maximum balance limit for all addresses
    mapping(address => bool) public isExcludedFromMaxBalance; // Addresses excluded from global maximum balance limit

    constructor(uint256 initialSupply, address _feeAddress) {
        _totalSupply = initialSupply * 10**uint256(decimals);
        _balances[msg.sender] = _totalSupply;
        feeAddress = _feeAddress;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount <= maxTransferAmount, "Amount exceeds maximum transfer amount");
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        uint256 fee = (amount * transferFeeRate) / 100;
        uint256 burnAmount = (amount * burnFeeRate) / 100;
        uint256 transferAmount = amount - fee;
        
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(fee <= (amount * maxTransferFeeRate) / 100, "Transfer fee exceeds maximum");
        require(burnAmount <= (amount * maxBurnFeeRate) / 100, "Burn fee exceeds maximum");

        // Check if recipient's balance plus transferAmount exceeds the global maximum balance limit
        require(_balances[recipient] + transferAmount <= globalMaxBalance, "Recipient's balance would exceed the maximum allowed");

        _balances[msg.sender] -= amount;
        _balances[recipient] += transferAmount;
        _burn(msg.sender, burnAmount);
        _transferFee(fee);
        emit Transfer(msg.sender, recipient, transferAmount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount <= maxTransferAmount, "Amount exceeds maximum transfer amount");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        uint256 fee = (amount * transferFeeRate) / 100;
        uint256 burnAmount = (amount * burnFeeRate) / 100;
        uint256 transferAmount = amount - fee;

        require(fee <= (amount * maxTransferFeeRate) / 100, "Transfer fee exceeds maximum");
        require(burnAmount <= (amount * maxBurnFeeRate) / 100, "Burn fee exceeds maximum");

        // Check if recipient's balance plus transferAmount exceeds the global maximum balance limit
        require(_balances[recipient] + transferAmount <= globalMaxBalance, "Recipient's balance would exceed the maximum allowed");

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _burn(sender, burnAmount);
        _transferFee(fee);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        emit Transfer(sender, recipient, transferAmount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _transferFee(uint256 fee) internal {
        require(feeAddress != address(0), "Fee address not set");
        _balances[feeAddress] += fee;
        emit Transfer(msg.sender, feeAddress, fee);
    }

    function setTransferFeeRate(uint256 newFeeRate) public onlyOwner {
        require(newFeeRate <= 2, "Fee rate cannot exceed 2%");
        transferFeeRate = newFeeRate;
    }

    function setBurnFeeRate(uint256 newBurnFeeRate) public onlyOwner {
        require(newBurnFeeRate <= 2, "Burn fee rate cannot exceed 2%");
        burnFeeRate = newBurnFeeRate;
    }

    function setFeeAddress(address newFeeAddress) public onlyOwner {
        require(newFeeAddress != address(0), "Fee address cannot be the zero address");
        feeAddress = newFeeAddress;
    }

    function excludeFromFees(address account) public onlyOwner {
        isExcludedFromFees[account] = true;
    }

    function includeInFees(address account) public onlyOwner {
        isExcludedFromFees[account] = false;
    }

    function setMaxTransferAmount(uint256 newMaxTransferAmount) public onlyOwner {
        maxTransferAmount = newMaxTransferAmount;
    }

    function setGlobalMaxBalance(uint256 newGlobalMaxBalance) public onlyOwner {
        globalMaxBalance = newGlobalMaxBalance;
    }

    function excludeFromMaxBalance(address account) public onlyOwner {
        isExcludedFromMaxBalance[account] = true;
    }

    function includeInMaxBalance(address account) public onlyOwner {
        isExcludedFromMaxBalance[account] = false;
    }
}