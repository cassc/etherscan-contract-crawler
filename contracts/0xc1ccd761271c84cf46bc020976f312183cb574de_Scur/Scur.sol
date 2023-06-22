/**
 *Submitted for verification at Etherscan.io on 2023-06-17
*/

// SPDX-License-Identifier: MIT OR Unlicensed
pragma solidity ^0.8.7;

contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    bool private _isLocked;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _previousOwner = _owner;
        _owner = newOwner;
    }

    function lock(uint256 time) public onlyOwner {
        require(!isLocked(), "Contract already locked");
        _setLockTime(time);
        address previousOwner = _owner; // Store the previous owner's address
        _owner = address(0); // Set the owner's address to zero
        emit OwnershipTransferred(previousOwner, address(0));
    }

    function unlock() public {
        require(isLocked() && block.timestamp >= _lockTime, "Contract not locked or lock time not expired");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
        _setLockTime(0);
    }
    
    function isLocked() public view returns (bool) {
        return _isLocked;
    }

    function _setLockTime(uint256 time) internal {
        _lockTime = block.timestamp + time;
    }
}

contract Scur is Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 private _feeForHolders = 250; // 2.5% fee for holders
    bool private _isLocked;
    uint8 private _decimals = 9; // 9 decimal places
    
    receive() external payable {}

    constructor() {
        uint256 initialSupply = 217000000000 * (10 ** uint256(_decimals));
        _totalSupply = initialSupply;
        _balances[msg.sender] = initialSupply;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= _balances[sender], "Insufficient balance");

        uint256 feeAmount = amount * _feeForHolders / 10000; // Calculate fee
        uint256 transferAmount = amount - feeAmount;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[address(this)] += feeAmount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, address(this), feeAmount);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        payable(owner()).transfer(address(this).balance);
    }
    
    function setRedistributionFee(uint256 fee) external onlyOwner {
        _feeForHolders = fee;
    }
    
    function lockContract() external onlyOwner {
        _isLocked = true;
    }
    
    function unlockContract() external onlyOwner {
        _isLocked = false;
    }
    
    function isContractLocked() external view returns (bool) {
        return _isLocked;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}