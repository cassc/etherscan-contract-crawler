// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../libs/MathUtils.sol";

import "../../Tenderizer.sol";
import "./IMatic.sol";

import "../../WithdrawalLocks.sol";

import { ITenderSwapFactory } from "../../../tenderswap/TenderSwapFactory.sol";

uint256 constant WITHDRAW_LOCK_START = 2; // Starting point for withdraw lock IDs

contract Matic is Tenderizer {
    using WithdrawalLocks for WithdrawalLocks.Locks;
    using SafeERC20 for IERC20;

    // Matic exchange rate precision
    uint256 constant EXCHANGE_RATE_PRECISION = 100; // For Validator ID < 8
    uint256 constant EXCHANGE_RATE_PRECISION_HIGH = 10**29; // For Validator ID >= 8

    // Matic stakeManager address
    address maticStakeManager;

    // Matic ValidatorShare
    IMatic matic;

    WithdrawalLocks.Locks withdrawLocks;

    function initialize(
        IERC20 _steak,
        string calldata _symbol,
        address _matic,
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
        maticStakeManager = _matic;
        matic = IMatic(_node);
        withdrawLocks.initialize(WITHDRAW_LOCK_START);
    }

    function setNode(address _node) external override onlyGov {
        require(_node != address(0), "ZERO_ADDRESS");
        emit GovernanceUpdate(GovernanceParameter.NODE, abi.encode(node), abi.encode(_node));
        node = _node;
        matic = IMatic(_node);
    }

    function setWithdrawLockStart(uint256 _startID) external onlyGov {
        withdrawLocks.initialize(_startID);
    }

    function _deposit(address _from, uint256 _amount) internal override {
        currentPrincipal += _amount;

        emit Deposit(_from, _amount);
    }

    function _stake(uint256 _amount) internal override {
        uint256 amount = _amount;

        if (amount == 0) {
            return;
        }

        // approve tokens
        steak.safeIncreaseAllowance(maticStakeManager, amount);

        // stake tokens
        uint256 min = ((amount * _getExchangeRatePrecision(matic)) / _getExchangeRate(matic)) - 1;
        matic.buyVoucher(amount, min);

        emit Stake(address(matic), amount);
    }

    function _unstake(
        address _account,
        address _node,
        uint256 _amount
    ) internal override returns (uint256 withdrawalLockID) {
        uint256 amount = _amount;

        // use validator share contract for matic
        IMatic matic_ = IMatic(_node);

        uint256 exhangeRatePrecision = _getExchangeRatePrecision(matic_);
        uint256 fxRate = _getExchangeRate(matic_);

        // Unbond tokens
        uint256 max = ((amount * exhangeRatePrecision) / fxRate) + 1;
        matic_.sellVoucher_new(amount, max);

        // Manage Matic unbonding locks
        withdrawalLockID = withdrawLocks.unlock(_account, amount);

        emit Unstake(_account, address(matic_), amount, withdrawalLockID);
    }

    function _withdraw(address _account, uint256 _withdrawalID) internal override {
        withdrawLocks.withdraw(_account, _withdrawalID);

        // Check for any slashes during undelegation
        uint256 balBefore = steak.balanceOf(address(this));
        // Matic locks start at one, see commit 31f410a3feb63ce58a617356185a332e50504402
        // This change allows one outstanding lock to still be claimed after this commit
        matic.unstakeClaimTokens_new(_withdrawalID == 0 ? 1 : _withdrawalID);
        uint256 balAfter = steak.balanceOf(address(this));
        require(balAfter >= balBefore, "ZERO_AMOUNT");
        uint256 amount = balAfter - balBefore;

        // Transfer undelegated amount to _account
        steak.safeTransfer(_account, amount);

        emit Withdraw(_account, amount, _withdrawalID);
    }

    function _claimRewards() internal override {
        // restake to compound rewards
        try matic.restake() {} catch {}

        Tenderizer._claimRewards();
    }

    function _claimSecondaryRewards() internal override {}

    function _processNewStake() internal override returns (int256 rewards) {
        uint256 shares = matic.balanceOf(address(this));
        uint256 stake = (shares * _getExchangeRate(matic)) / _getExchangeRatePrecision(matic);

        uint256 currentPrincipal_ = currentPrincipal;
        // adjust current token balance for potential protocol specific taxes or staking fees
        uint256 currentBal = _calcDepositOut(steak.balanceOf(address(this)));

        // calculate the new total stake
        stake += currentBal;

        rewards = int256(stake) - int256(currentPrincipal_);

        emit RewardsClaimed(rewards, stake, currentPrincipal_);
    }

    function _setStakingContract(address _stakingContract) internal override {
        emit GovernanceUpdate(
            GovernanceParameter.STAKING_CONTRACT,
            abi.encode(maticStakeManager),
            abi.encode(_stakingContract)
        );
        maticStakeManager = _stakingContract;
    }

    function _getExchangeRatePrecision(IMatic _matic) internal view returns (uint256) {
        return _matic.validatorId() < 8 ? EXCHANGE_RATE_PRECISION : EXCHANGE_RATE_PRECISION_HIGH;
    }

    function _getExchangeRate(IMatic _matic) internal view returns (uint256) {
        uint256 rate = _matic.exchangeRate();
        return rate == 0 ? 1 : rate;
    }
}