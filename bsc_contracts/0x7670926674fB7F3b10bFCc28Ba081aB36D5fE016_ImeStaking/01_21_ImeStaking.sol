//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferDeferrer} from "./abstract/TransferDeferrer.sol";
import {FlexibleInterest} from "./abstract/FlexibleInterest.sol";
import {PRBMathUD60x18Typed as Math, PRBMath} from "prb-math/contracts/PRBMathUD60x18Typed.sol";
import {Calendar} from "./lib/Calendar.sol";
import {Sorter} from "./lib/Sorter.sol";

import {IImeStakingCore} from "./IImeStakingCore.sol";
import {IImeStakingManageable} from "./IImeStakingManageable.sol";
import {ImeStakingAccessControl} from "./ImeStakingAccessControl.sol";

/**
    @title ImeStaking
    @author iMe Group

    @notice Implementation of iMe staking version 1
 */
contract ImeStaking is
    FlexibleInterest,
    TransferDeferrer,
    IImeStakingCore,
    IImeStakingManageable,
    ImeStakingAccessControl
{
    /**
        @notice Available withdrawal modes

        "Safe" strategy is used for safe withdrawals, with deferred token transfer
        Premature withdrawal is used for non-safe withdrawals before staking finish
        Immediate withdrawal is used for withdrawals after staking finish
        Also, force withdrawal using Immediate withdrawal mode.
     */
    enum WithdrawalMode {
        Safe,
        Premature,
        Immediate
    }

    uint64 private _startsAt;
    uint64 private _endsAt;
    uint64 private _incomePeriod;
    uint64 private _safeWithdrawalDuration;
    bool private _depositsAllowed = true;
    bool private _withdrawalsAllowed = true;
    string private _name;
    string private _author;
    PRBMath.UD60x18 private _percent;
    uint256 private _compoundAccrualThreshold;
    mapping(WithdrawalMode => PRBMath.UD60x18) private _fees;
    IERC20 private _token;

    constructor(
        string memory stakingName,
        string memory stakingAuthor,
        address tokenAddress,
        uint256 start,
        uint256 end,
        uint256 apy,
        uint256 accrualPeriod,
        uint256 prematureWithdrawalFeeBy1e9,
        uint256 safeWithdrawalFeeBy1e9,
        uint256 tokensToEnableCompoundAccrual,
        uint256 withdrawnTokensLockDuration
    ) FlexibleInterest(start) {
        _name = stakingName;
        _author = stakingAuthor;
        _token = IERC20(tokenAddress);

        _percent = Math.sub(
            Math.pow(
                Math.add(
                    Math.div(Math.fromUint(apy), Math.fromUint(100)),
                    Math.fromUint(1)
                ),
                Math.inv(Math.fromUint((1 days * 365) / accrualPeriod))
            ),
            Math.fromUint(1)
        );
        _incomePeriod = uint64(accrualPeriod);

        if (start > end) revert StakingLifespanInvalid();

        _startsAt = uint64(start);
        _endsAt = uint64(end);

        _fees[WithdrawalMode.Premature] = Math.div(
            Math.fromUint(prematureWithdrawalFeeBy1e9),
            Math.fromUint(1e9)
        );
        _fees[WithdrawalMode.Safe] = Math.div(
            Math.fromUint(safeWithdrawalFeeBy1e9),
            Math.fromUint(1e9)
        );

        _safeWithdrawalDuration = uint64(withdrawnTokensLockDuration);
        _compoundAccrualThreshold = tokensToEnableCompoundAccrual;
    }

    /*
        Implementation of IImeStakingV1Core
     */

    function name() external view override returns (string memory) {
        return _name;
    }

    function author() external view override returns (string memory) {
        return _author;
    }

    function version() external pure override returns (string memory) {
        return "1";
    }

    function token() external view override returns (address) {
        return address(_token);
    }

    function feeToken() external view override returns (address) {
        return address(_token);
    }

    function startsAt() external view override returns (uint256) {
        return _startsAt;
    }

    function endsAt() external view override returns (uint256) {
        return _endsAt;
    }

    function income() external view override returns (uint256) {
        return Math.toUint(Math.mul(Math.fromUint(1e9), _percent));
    }

    function incomePeriod() external view override returns (uint256) {
        return _incomePeriod;
    }

    function prematureWithdrawalFee() external view override returns (uint256) {
        PRBMath.UD60x18 memory fee = _fees[WithdrawalMode.Premature];
        return Math.toUint(Math.mul(Math.fromUint(1e9), fee));
    }

    function safeWithdrawalFee() external view override returns (uint256) {
        PRBMath.UD60x18 memory fee = _fees[WithdrawalMode.Safe];
        return Math.toUint(Math.mul(Math.fromUint(1e9), fee));
    }

    function safeWithdrawalDuration() external view override returns (uint256) {
        return _safeWithdrawalDuration;
    }

    function compoundAccrualThreshold()
        external
        view
        override
        returns (uint256)
    {
        return _compoundAccrualThreshold;
    }

    function debtOf(address account) external view override returns (uint256) {
        return _debtOf(account, _accrualNow());
    }

    function impactOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _impactOf(account);
    }

    function safelyWithdrawnTokensOf(address account)
        external
        view
        override
        returns (uint256 pending, uint256 ready)
    {
        return _deferredTokensOf(account);
    }

    function estimateSolvency(uint256 at)
        external
        view
        override
        returns (uint256 lack, uint256 excess)
    {
        uint256 balance = _token.balanceOf(address(this));
        uint256 tokensToGive = _totalDebt(Sorter.min(_endsAt, at)) +
            _overallDeferredTokens();

        if (tokensToGive > balance) {
            lack = tokensToGive - balance;
        } else if (tokensToGive < balance) {
            excess = balance - tokensToGive;
        }
    }

    function stake(uint256 amount) external override {
        if (!_depositsAllowed) revert DepositDisabled();

        if (_now() < _startsAt) revert DepositTooEarly(_now(), _startsAt);

        if (_now() > _endsAt) revert DepositTooLate(_now(), _endsAt);

        _deposit(_msgSender(), amount, _accrualNow());
        emit Deposit(_msgSender(), amount);
        _safe(_token.transferFrom(_msgSender(), address(this), amount));
    }

    function withdraw(uint256 amount, bool safe) external override {
        if (!_withdrawalsAllowed) {
            revert WithdrawalDisabled();
        }

        uint256 debt = _debtOf(_msgSender(), _accrualNow());
        if (amount > debt) {
            revert WithdrawalOverLimit(amount, debt);
        }

        WithdrawalMode mode;

        if (_now() >= _endsAt) {
            mode = WithdrawalMode.Immediate;
        } else {
            mode = safe ? WithdrawalMode.Safe : WithdrawalMode.Premature;
        }

        _withdraw(_msgSender(), amount, mode);
    }

    function claim() external override {
        _claim(_msgSender());
    }

    function manageDeposits(bool allowed)
        external
        override
        onlyRole(STAKING_MANAGER_ROLE)
    {
        _depositsAllowed = allowed;
    }

    /*
        Implementation of IImeStakingV1Manageable
     */

    function manageWithdrawals(bool allowed)
        external
        override
        onlyRole(STAKING_MANAGER_ROLE)
    {
        _withdrawalsAllowed = allowed;
    }

    function setLifespan(uint256 start, uint256 end)
        external
        override
        onlyRole(STAKING_MANAGER_ROLE)
    {
        if (start > end) revert StakingLifespanInvalid();
        if (end < _now()) revert StakingLifespanInvalid();
        if (start != _startsAt) _startsAt = uint64(start);
        if (end != _endsAt) _endsAt = uint64(end);
    }

    function setWithdrawalFee(bool safe, uint256 fee)
        external
        override
        onlyRole(STAKING_MANAGER_ROLE)
    {
        if (safe)
            _fees[WithdrawalMode.Safe] = Math.div(
                Math.fromUint(fee),
                Math.fromUint(1e9)
            );
        else
            _fees[WithdrawalMode.Premature] = Math.div(
                Math.fromUint(fee),
                Math.fromUint(1e9)
            );
    }

    function rescueFunds(uint256 amount, address to)
        external
        override
        onlyRole(STAKING_BANKER_ROLE)
    {
        _rescueFunds(amount, to);
    }

    function rescueFunds(address to)
        external
        override
        onlyRole(STAKING_BANKER_ROLE)
    {
        _rescueFunds(_freeTokens(), to);
    }

    function forceWithdrawal(address to)
        external
        override
        onlyRole(STAKING_MANAGER_ROLE)
    {
        if (_now() < _endsAt) revert ForceWithdrawalTooEarly(_endsAt);

        _withdraw(to, _debtOf(to, _accrualNow()), WithdrawalMode.Immediate);
    }

    function _accrualNow() internal view returns (uint256) {
        // After _endsAt, time stops
        return Sorter.min(_now(), _endsAt);
    }

    function _accrualPeriod() internal view override returns (uint256) {
        return _incomePeriod;
    }

    function _accrualPercent()
        internal
        view
        override
        returns (PRBMath.UD60x18 memory)
    {
        return _percent;
    }

    function _flexibleThreshold() internal view override returns (uint256) {
        return _compoundAccrualThreshold;
    }

    function _freeTokens() internal view returns (uint256) {
        return
            _token.balanceOf(address(this)) -
            _overallImpact() -
            _overallDeferredTokens();
    }

    function _fee(uint256 amount, WithdrawalMode mode)
        internal
        view
        returns (uint256)
    {
        if (_fees[mode].value == 0) return 0;
        else return Math.toUint(Math.mul(Math.fromUint(amount), _fees[mode]));
    }

    function _withdraw(
        address user,
        uint256 amount,
        WithdrawalMode mode
    ) internal {
        _withdrawal(user, amount, _accrualNow());

        uint256 fee = _fee(amount, mode);
        emit Withdrawal(user, amount, fee);

        if (mode == WithdrawalMode.Safe) {
            _deferTransfer(
                user,
                amount - fee,
                _now() + _safeWithdrawalDuration
            );
        } else {
            _safe(_token.transfer(user, amount - fee));
        }
    }

    function _claim(address to) internal {
        uint256 claimed = _finalizeDeferredTransfers(to);

        if (claimed == 0) {
            return;
        }

        emit Claim(to, claimed);

        _safe(_token.transfer(to, claimed));
    }

    function _rescueFunds(uint256 amount, address to) internal {
        uint256 available = _freeTokens();

        if (amount > available) {
            revert RescueOverFreeTokens(amount, available);
        }

        _safe(_token.transfer(to, amount));
    }

    /**
         @dev Handle a safe token transfer
     */
    function _safe(bool transfer) internal pure {
        require(transfer, "Token transfer failed");
    }
}