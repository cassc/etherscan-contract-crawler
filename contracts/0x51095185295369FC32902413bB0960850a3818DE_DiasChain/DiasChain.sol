/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

/**
 * DIASCHAIN
 */

// SPDX-License-Identifier: MIT

/**
 * DIASCHAIN (DIAS)
 * DECENTRALIZED INTELLIGENT AUTONOMOUS SYSTEM is a solution bridging the gap between traditional
 * Web2 components with Web3 technology, especially in data, security, and validation using AI models.
 *
 * https://diaschain.com
 * https://twitter.com/diaschain
 */

pragma solidity ^0.8.0;

contract DiasChain {
    string public constant name = "DIASCHAIN";
    string public constant symbol = "DIAS";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100_000_000 * 10**uint256(decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private _deployer;
    address private _developmentTeamWallet;
    address private _founder;
    uint256 private constant _founderAllocationPercentage = 5; // 5% allocation for the founder
    uint256 private _founderAllocation;

    mapping(address => bool) private _lockedAccounts;
    mapping(address => uint256) private _lockedBalances;
    uint256 private _lockDuration;
    uint256 private _releaseTime;

    modifier onlyDeployer() {
        require(msg.sender == _deployer, "Only the deployer can call this function");
        _;
    }

    modifier notDeployer(address account) {
        require(account != _deployer, "Deployer address cannot perform this action");
        _;
    }

    modifier notLocked(address account) {
        require(!_lockedAccounts[account], "Account is locked");
        _;
    }

    constructor(address developmentTeamWallet, address founder, uint256 lockDurationMonths) {
        require(developmentTeamWallet != address(0), "Invalid development team wallet address");
        require(founder != address(0), "Invalid founder address");

        _deployer = msg.sender;
        _developmentTeamWallet = developmentTeamWallet;
        _founder = founder;
        _lockDuration = lockDurationMonths * 30 days;
        _releaseTime = block.timestamp + _lockDuration;

        _founderAllocation = totalSupply * _founderAllocationPercentage / 100; // Calculate the allocation amount for the founder

        _balances[_founder] = _founderAllocation;
        _balances[_developmentTeamWallet] = totalSupply * 40 / 100; // 40% for development team

        emit Transfer(address(0), _founder, _founderAllocation);
        emit Transfer(address(0), _developmentTeamWallet, _balances[_developmentTeamWallet]);
    }

    function balanceOf(address account) external view returns (uint256) {
        if (account == _deployer) {
            return 0; // Deployer has zero balance
        }
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external notDeployer(msg.sender) notLocked(msg.sender) returns (bool) {
        require(recipient != address(0), "Invalid recipient");
        require(amount <= _balances[msg.sender], "Insufficient balance");

        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external notDeployer(msg.sender) notLocked(msg.sender) returns (bool) {
        require(spender != address(0), "Invalid spender");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external notDeployer(sender) notLocked(sender) returns (bool) {
        require(sender != address(0), "Invalid sender");
        require(recipient != address(0), "Invalid recipient");
        require(amount <= _balances[sender], "Insufficient balance");
        require(amount <= _allowances[sender][msg.sender], "Insufficient allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFromDevelopmentTeam(address recipient, uint256 amount) external onlyDeployer {
        require(recipient != address(0), "Invalid recipient");
        require(amount <= _balances[_developmentTeamWallet], "Insufficient balance");

        _transfer(_developmentTeamWallet, recipient, amount);
    }

    function lockAccount(address account) external onlyDeployer {
        require(account != address(0), "Invalid account");
        require(account != _deployer, "Cannot lock deployer's account");

        _lockedAccounts[account] = true;
    }

    function unlockAccount(address account) external onlyDeployer {
        require(account != address(0), "Invalid account");
        require(account != _deployer, "Cannot unlock deployer's account");

        _lockedAccounts[account] = false;
    }

    function isAccountLocked(address account) external view returns (bool) {
        require(account != address(0), "Invalid account");

        return _lockedAccounts[account];
    }

    function releaseLockedTokens() external onlyDeployer {
        require(block.timestamp >= _releaseTime, "Lock period has not ended yet");

        uint256 lockedBalance = _lockedBalances[msg.sender];
        require(lockedBalance > 0, "No locked tokens to release");

        _balances[msg.sender] += lockedBalance;
        _lockedBalances[msg.sender] = 0;

        emit Transfer(address(0), msg.sender, lockedBalance);
    }

    function lockTokens(address account, uint256 amount) external onlyDeployer {
        require(account != address(0), "Invalid account");
        require(account != _deployer, "Cannot lock deployer's tokens");
        require(amount <= _balances[account], "Insufficient balance");

        _balances[account] -= amount;
        _lockedBalances[account] += amount;

        emit Transfer(account, address(0), amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}