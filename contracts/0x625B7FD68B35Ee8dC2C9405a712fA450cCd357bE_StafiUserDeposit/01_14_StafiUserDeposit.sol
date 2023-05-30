pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/IStafiEther.sol";
import "../interfaces/IStafiEtherWithdrawer.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/pool/IStafiStakingPool.sol";
import "../interfaces/pool/IStafiStakingPoolQueue.sol";
import "../interfaces/token/IRETHToken.sol";
import "../interfaces/node/IStafiSuperNode.sol";
import "../interfaces/node/IStafiLightNode.sol";

// Accepts user deposits and mints rETH; handles assignment of deposited ETH to pools
contract StafiUserDeposit is StafiBase, IStafiUserDeposit, IStafiEtherWithdrawer {

    // Libs
    using SafeMath for uint256;

    // Events
    event DepositReceived(address indexed from, uint256 amount, uint256 time);
    event DepositRecycled(address indexed from, uint256 amount, uint256 time);
    event DepositAssigned(address indexed stakingPool, uint256 amount, uint256 time);
    event ExcessWithdrawn(address indexed to, uint256 amount, uint256 time);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
        // Initialize settings on deployment
        if (!getBoolS("settings.user.deposit.init")) {
            // Apply settings
            setDepositEnabled(true);
            setAssignDepositsEnabled(true);
            setMinimumDeposit(0.01 ether);
            // setMaximumDepositPoolSize(100000 ether);
            setMaximumDepositAssignments(2);
            // Settings initialized
            setBoolS("settings.user.deposit.init", true);
        }
    }

    // Current deposit pool balance
    function getBalance() override public view returns (uint256) {
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        return stafiEther.balanceOf(address(this));
    }

    // Excess deposit pool balance (in excess of stakingPool queue capacity)
    function getExcessBalance() override public view returns (uint256) {
        // Get stakingPool queue capacity
        IStafiStakingPoolQueue stafiStakingPoolQueue = IStafiStakingPoolQueue(getContractAddress("stafiStakingPoolQueue"));
        uint256 stakingPoolCapacity = stafiStakingPoolQueue.getEffectiveCapacity();
        // Calculate and return
        uint256 balance = getBalance();
        if (stakingPoolCapacity >= balance) { return 0; }
        else { return balance.sub(stakingPoolCapacity); }
    }

    // Receive a ether withdrawal
    // Only accepts calls from the StafiEther contract
    function receiveEtherWithdrawal() override external payable onlyLatestContract("stafiUserDeposit", address(this)) onlyLatestContract("stafiEther", msg.sender) {}

    // Accept a deposit from a user
    function deposit() override external payable onlyLatestContract("stafiUserDeposit", address(this)) {
        // Check deposit settings
        require(getDepositEnabled(), "Deposits into Stafi are currently disabled");
        require(msg.value >= getMinimumDeposit(), "The deposited amount is less than the minimum deposit size");
        // require(getBalance().add(msg.value) <= getMaximumDepositPoolSize(), "The deposit pool size after depositing exceeds the maximum size");
        // Load contracts
        IRETHToken rETHToken = IRETHToken(getContractAddress("rETHToken"));
        // Mint rETH to user account
        rETHToken.userMint(msg.value, msg.sender);
        // Emit deposit received event
        emit DepositReceived(msg.sender, msg.value, block.timestamp);
        // Process deposit
        processDeposit();
    }

    // Recycle a deposit from a dissolved stakingPool
    // Only accepts calls from registered stakingPools
    function recycleDissolvedDeposit() override external payable onlyLatestContract("stafiUserDeposit", address(this)) onlyRegisteredStakingPool(msg.sender) {
        // Emit deposit recycled event
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
        // Process deposit
        processDeposit();
    }

    // Recycle a deposit from a withdrawn stakingPool
    function recycleWithdrawnDeposit() override external payable onlyLatestContract("stafiUserDeposit", address(this)) onlyLatestContract("stafiNetworkWithdrawal", msg.sender) {
        // Emit deposit recycled event
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
        // Process deposit
        processDeposit();
    }
    // Recycle a deposit from fee collector
    function recycleDistributorDeposit() override external payable onlyLatestContract("stafiUserDeposit", address(this)) onlyLatestContract("stafiDistributor", msg.sender) {
        // Emit deposit recycled event
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
        // Process deposit
        processDeposit();
    }

    // Process a deposit
    function processDeposit() private {
        // Load contracts
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        // Transfer ETH to stafiEther
        stafiEther.depositEther{value: msg.value}();
        // Assign deposits if enabled
        assignDeposits();
    }

    // Assign deposits to available stakingPools
    function assignDeposits() override public onlyLatestContract("stafiUserDeposit", address(this)) {
        // Check deposit settings
        require(getAssignDepositsEnabled(), "Deposit assignments are currently disabled");
        // Load contracts
        IStafiStakingPoolQueue stafiStakingPoolQueue = IStafiStakingPoolQueue(getContractAddress("stafiStakingPoolQueue"));
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        // Assign deposits
        uint256 maximumDepositAssignments = getMaximumDepositAssignments();
        for (uint256 i = 0; i < maximumDepositAssignments; ++i) {
            // Get & check next available staking pool capacity
            uint256 stakingPoolCapacity = stafiStakingPoolQueue.getNextCapacity();
            if (stakingPoolCapacity == 0 || getBalance() < stakingPoolCapacity) { break; }
            // Dequeue next available staking pool
            address stakingPoolAddress = stafiStakingPoolQueue.dequeueStakingPool();
            IStafiStakingPool stakingPool = IStafiStakingPool(stakingPoolAddress);
            // Withdraw ETH from stafiEther
            stafiEther.withdrawEther(stakingPoolCapacity);
            // Assign deposit to staking pool
            stakingPool.userDeposit{value: stakingPoolCapacity}();
            // Emit deposit assigned event
            emit DepositAssigned(stakingPoolAddress, stakingPoolCapacity, block.timestamp);
        }
    }

    // Withdraw excess deposit pool balance for rETH collateral
    function withdrawExcessBalance(uint256 _amount) override external onlyLatestContract("stafiUserDeposit", address(this)) onlyLatestContract("rETHToken", msg.sender) {
        // Load contracts
        IRETHToken rETHToken = IRETHToken(getContractAddress("rETHToken"));
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        // Check amount
        require(_amount <= getExcessBalance(), "Insufficient excess balance for withdrawal");
        // Withdraw ETH from vault
        stafiEther.withdrawEther(_amount);
        // Transfer to rETH contract
        rETHToken.depositExcess{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // Withdraw excess deposit pool balance for super node
    function withdrawExcessBalanceForSuperNode(uint256 _amount) override external onlyLatestContract("stafiUserDeposit", address(this)) onlyLatestContract("stafiSuperNode", msg.sender) {
        // Load contracts
        IStafiSuperNode superNode = IStafiSuperNode(getContractAddress("stafiSuperNode"));
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        // Check amount
        require(_amount <= getExcessBalance(), "Insufficient balance for withdrawal");
        // Withdraw ETH from vault
        stafiEther.withdrawEther(_amount);
        // Transfer to superNode contract
        superNode.depositEth{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }
    
    // Withdraw excess deposit pool balance for light node
    function withdrawExcessBalanceForLightNode(uint256 _amount) override external onlyLatestContract("stafiUserDeposit", address(this)) onlyLatestContract("stafiLightNode", msg.sender) {
        // Load contracts
        IStafiLightNode lightNode = IStafiLightNode(getContractAddress("stafiLightNode"));
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        // Check amount
        require(_amount <= getExcessBalance(), "Insufficient balance for withdrawal");
        // Withdraw ETH from vault
        stafiEther.withdrawEther(_amount);
        // Transfer to superNode contract
        lightNode.depositEth{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // Deposits currently enabled
    function getDepositEnabled() public view returns (bool) {
        return getBoolS("settings.deposit.enabled");
    }
    function setDepositEnabled(bool _value) public onlySuperUser {
        setBoolS("settings.deposit.enabled", _value);
    }

    // Deposit assignments currently enabled
    function getAssignDepositsEnabled() public view returns (bool) {
        return getBoolS("settings.deposit.assign.enabled");
    }
    function setAssignDepositsEnabled(bool _value) public onlySuperUser {
        setBoolS("settings.deposit.assign.enabled", _value);
    }

    // Minimum deposit size
    function getMinimumDeposit() public view returns (uint256) {
        return getUintS("settings.deposit.minimum");
    }
    function setMinimumDeposit(uint256 _value) public onlySuperUser {
        setUintS("settings.deposit.minimum", _value);
    }

    // The maximum size of the deposit pool
    // function getMaximumDepositPoolSize() public view returns (uint256) {
    //     return getUintS("settings.deposit.pool.maximum");
    // }
    // function setMaximumDepositPoolSize(uint256 _value) public onlySuperUser {
    //     setUintS("settings.deposit.pool.maximum", _value);
    // }

    // The maximum number of deposit assignments to perform at once
    function getMaximumDepositAssignments() public view returns (uint256) {
        return getUintS("settings.deposit.assign.maximum");
    }
    function setMaximumDepositAssignments(uint256 _value) public onlySuperUser {
        setUintS("settings.deposit.assign.maximum", _value);
    }

}