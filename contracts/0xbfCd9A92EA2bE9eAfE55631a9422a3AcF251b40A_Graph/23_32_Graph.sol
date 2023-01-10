// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../libs/MathUtils.sol";

import "../../Tenderizer.sol";
import "../../WithdrawalPools.sol";
import "./IGraph.sol";

import { ITenderSwapFactory } from "../../../tenderswap/TenderSwapFactory.sol";

contract Graph is Tenderizer {
    using WithdrawalPools for WithdrawalPools.Pool;
    using SafeERC20 for IERC20;

    // Eventws for WithdrawalPool
    event ProcessUnstakes(address indexed from, address indexed node, uint256 amount);
    event ProcessWithdraws(address indexed from, uint256 amount);

    // 100% in parts per million
    uint32 private constant MAX_PPM = 1000000;

    IGraph graph;

    WithdrawalPools.Pool withdrawPool;

    uint256 pendingMigration;

    address newNode;

    function initialize(
        IERC20 _steak,
        string calldata _symbol,
        IGraph _graph,
        address _node,
        uint256 _protocolFee,
        uint256 _liquidityFee,
        ITenderToken _tenderTokenTarget,
        TenderFarmFactory _tenderFarmFactory,
        ITenderSwapFactory _tenderSwapFactory
    ) external {
        Tenderizer._initialize(
            _steak,
            _symbol,
            _node,
            _protocolFee,
            _liquidityFee,
            _tenderTokenTarget,
            _tenderFarmFactory,
            _tenderSwapFactory
        );
        graph = _graph;
    }

    function migrateUnlock(address _newNode) external virtual onlyGov returns (uint256 lockID) {
        uint256 amount = _tokensToMigrate(node);

        // Check that there's no pending migration
        require(pendingMigration == 0, "PENDING_MIGRATION");

        // store penging migration amount & new node
        pendingMigration = amount;
        newNode = _newNode;

        // set new node
        lockID = _unstake(address(this), node, amount);
    }

    function migrateWithdraw(uint256 _unstakeLockID) external virtual onlyGov {
        // reset pending migration amount
        pendingMigration = 0;
        _withdraw(address(this), _unstakeLockID);
        _claimRewards();
    }

    function _calcDepositOut(uint256 _amountIn) internal view override returns (uint256) {
        return _amountIn - ((uint256(graph.delegationTaxPercentage()) * _amountIn) / MAX_PPM);
    }

    function _deposit(address _from, uint256 _amount) internal override {
        currentPrincipal += _calcDepositOut(_amount);

        emit Deposit(_from, _amount);
    }

    function _stake(uint256 _amount) internal override {
        // Only stake available tokens that are not pending withdrawal
        uint256 amount = _amount;
        uint256 pendingWithdrawals = withdrawPool.getAmount();

        // This check also validates 'amount - pendingWithdrawals' > 0
        if (amount <= pendingWithdrawals) {
            return;
        }

        amount -= pendingWithdrawals;

        // approve amount to Graph protocol
        steak.safeIncreaseAllowance(address(graph), amount);

        // stake tokens
        uint256 delegatedShares = graph.delegate(node, amount);
        assert(delegatedShares > 0);

        emit Stake(node, amount);
    }

    function _unstake(
        address _account,
        address _node,
        uint256 _amount
    ) internal override returns (uint256 unstakeLockID) {
        uint256 amount = _amount;
        unstakeLockID = withdrawPool.unlock(_account, amount);
        emit Unstake(_account, _node, amount, unstakeLockID);
    }

    function processUnstake() external onlyGov {
        uint256 amount = withdrawPool.processUnlocks();

        // Calculate the amount of shares to undelegate
        IGraph.DelegationPool memory delPool = graph.delegationPools(node);
        uint256 totalShares = delPool.shares;
        uint256 totalTokens = delPool.tokens;

        uint256 shares = (amount * totalShares) / totalTokens;

        // Check that calculated shares doesn't exceed actual shares owned
        // account of round-off error resulting in calculating 1 share less
        IGraph.Delegation memory delegation = graph.getDelegation(node, address(this));
        if (shares >= delegation.shares - 1) {
            shares = delegation.shares;
        }

        // Shares =  amount * totalShares / totalTokens
        // undelegate shares
        graph.undelegate(node, shares);

        emit ProcessUnstakes(msg.sender, node, amount);

        if(newNode != address(0)){
            node = newNode;
            newNode = address(0);
        }
    }

    function _withdraw(address _account, uint256 _withdrawalID) internal override {
        uint256 amount = withdrawPool.withdraw(_withdrawalID, _account);

        // Transfer amount from unbondingLock to _account
        try steak.transfer(_account, amount) {} catch {
            // Account for roundoff errors in shares calculations
            uint256 steakBal = steak.balanceOf(address(this));
            if (amount > steakBal) {
                steak.safeTransfer(_account, steakBal);
            }
        }

        emit Withdraw(_account, amount, _withdrawalID);
    }

    function processWithdraw(address _node) external onlyGov {
        uint256 balBefore = steak.balanceOf(address(this));

        graph.withdrawDelegated(_node, address(0));

        uint256 balAfter = steak.balanceOf(address(this));
        uint256 amount = balAfter - balBefore;

        withdrawPool.processWihdrawal(amount);

        emit ProcessWithdraws(msg.sender, amount);
    }

    function _claimSecondaryRewards() internal override {}

    function _processNewStake() internal override returns (int256 rewards) {
        uint256 stake = _tokensDelegated(node);

        uint256 currentPrincipal_ = currentPrincipal;

        // exclude tokens to be withdrawn from balance
        // add pendingMigration amount
        uint256 stakeRemainder = _calcDepositOut(
            steak.balanceOf(address(this)) - withdrawPool.amount + pendingMigration
        );

        // calculate what the new currentPrinciple would be
        // exclude pendingUnlocks from stake
        stake = (stake - withdrawPool.pendingUnlock) + stakeRemainder;

        rewards = int256(stake) - int256(currentPrincipal_);

        // Difference is negative, slash withdrawalpool
        if (rewards < 0) {
            // calculate amount to subtract relative to current principal
            uint256 unstakePoolTokens = withdrawPool.totalTokens();
            uint256 totalTokens = unstakePoolTokens + currentPrincipal_;
            if (totalTokens > 0) {
                uint256 unstakePoolSlash = ((currentPrincipal_ - stake) * unstakePoolTokens) / totalTokens;
                withdrawPool.updateTotalTokens(unstakePoolTokens - unstakePoolSlash);
            }
        }

        emit RewardsClaimed(rewards, stake, currentPrincipal_);
    }

    function _tokensDelegated(address _node) internal view returns (uint256) {
        IGraph.Delegation memory delegation = graph.getDelegation(_node, address(this));
        IGraph.DelegationPool memory delPool = graph.delegationPools(_node);

        uint256 delShares = delegation.shares;
        uint256 totalShares = delPool.shares;
        uint256 totalTokens = delPool.tokens;

        if (totalShares == 0) return 0;

        return (delShares * totalTokens) / totalShares;
    }

    function _tokensToMigrate(address _node) internal view override returns (uint256) {
        return _tokensDelegated(_node) - withdrawPool.pendingUnlock;
    }

    function _setStakingContract(address _stakingContract) internal override {
        emit GovernanceUpdate(GovernanceParameter.STAKING_CONTRACT, abi.encode(graph), abi.encode(_stakingContract));
        graph = IGraph(_stakingContract);
    }
}