//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferDelayer} from "./abstract/TransferDelayer.sol";
import {FlexibleInterest} from "./abstract/FlexibleInterest.sol";
import {CommonInterest} from "./abstract/CommonInterest.sol";
import {CompoundInterest} from "./abstract/CompoundInterest.sol";
import {SimpleInterest} from "./abstract/SimpleInterest.sol";
import {LimeRank} from "./lib/LimeRank.sol";
import {Math} from "./lib/Math.sol";
import {TimeContext} from "./abstract/TimeContext.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IStakingCore} from "./IStakingCore.sol";
import {IStakingInfo} from "./IStakingInfo.sol";
import {IStakingPredictable} from "./IStakingPredictable.sol";
import {IStakingStatistics} from "./IStakingStatistics.sol";
import {IStakingPausable} from "./IStakingPausable.sol";

/**
    @title Staking
    @author iMe Lab

    @notice Implementation of iMe staking version 2
 */
contract Staking is
    IStakingCore,
    IStakingInfo,
    IStakingPredictable,
    IStakingStatistics,
    IStakingPausable,
    FlexibleInterest,
    TransferDelayer,
    TimeContext,
    AccessControl
{
    constructor(
        StakingInfo memory blueprint
    )
        FlexibleInterest(blueprint.compoundAccrualThreshold)
        SimpleInterest(blueprint.startsAt - blueprint.accrualPeriod * 2)
        CompoundInterest((blueprint.startsAt + blueprint.endsAt) / 2)
        CommonInterest(blueprint.interestRate, blueprint.accrualPeriod)
    {
        require(blueprint.startsAt < blueprint.endsAt);
        require(blueprint.prematureWithdrawalFee < 1e18);
        require(blueprint.delayedWithdrawalFee < 1e18);

        _name = blueprint.name;
        _author = blueprint.author;
        _website = blueprint.website;
        _token = IERC20(blueprint.token);
        _minimalRank = blueprint.minimalRank;
        _delayedWithdrawalDuration = blueprint.delayedWithdrawalDuration;
        _startsAt = blueprint.startsAt;
        _endsAt = blueprint.endsAt;
        _delayedWithdrawalFee = blueprint.delayedWithdrawalFee;
        _prematureWithdrawalFee = blueprint.prematureWithdrawalFee;
        _isPaused = false;

        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(PARTNER_ROLE, _msgSender());

        _setRoleAdmin(MANAGER_ROLE, MANAGER_ROLE);
        _setRoleAdmin(ARBITER_ROLE, MANAGER_ROLE);
        _setRoleAdmin(PARTNER_ROLE, PARTNER_ROLE);
    }

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PARTNER_ROLE = keccak256("PARTNER_ROLE");
    bytes32 public constant ARBITER_ROLE = keccak256("ARBITER_ROLE");

    string private _name;
    string private _author;
    string private _website;
    IERC20 private immutable _token;
    uint8 private immutable _minimalRank;
    uint32 private immutable _delayedWithdrawalDuration;
    uint64 private immutable _startsAt;
    uint64 private _endsAt;
    uint64 private immutable _delayedWithdrawalFee;
    uint64 private immutable _prematureWithdrawalFee;

    bool private _isPaused;

    function version() external pure override returns (string memory) {
        return "3";
    }

    function info() external view override returns (StakingInfo memory) {
        return
            StakingInfo(
                _name,
                _author,
                _website,
                address(_token),
                _interestRate,
                _accrualPeriod,
                _delayedWithdrawalDuration,
                _compoundThreshold,
                _delayedWithdrawalFee,
                _prematureWithdrawalFee,
                _minimalRank,
                _startsAt,
                _endsAt
            );
    }

    function summary() external view override returns (StakingSummary memory) {
        return
            StakingSummary(
                _totalImpact(),
                _totalDebt(_accrualNow()),
                _totalDelayed(),
                _token.balanceOf(address(this))
            );
    }

    function totalDebt(uint64 at) external view override returns (uint256) {
        if (at > _endsAt) at = _endsAt;
        else if (at < _now()) at = _now();
        return _totalDebt(at);
    }

    function statsOf(
        address investor
    ) external view override returns (StakingStatistics memory) {
        (uint256 pending, uint256 ready) = _delayedTokensFor(investor, _now());

        return
            StakingStatistics(
                _impactOf(investor),
                _debt(investor, _accrualNow()),
                pending,
                ready
            );
    }

    function deposit(
        uint256 amount,
        uint8 rank,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(amount > 0);
        if (_now() >= deadline) revert DepositDeadlineIsReached();
        if (_isPaused) revert StakingIsPaused();
        if (_now() < _startsAt) revert DepositIsTooEarly();
        if (_now() >= _endsAt) revert DepositIsTooLate();
        if (_minimalRank != 0) {
            address subject = address(this);
            address sender = _msgSender();
            bytes32 proof = LimeRank.proof(subject, sender, deadline, rank);
            address signer = ecrecover(proof, v, r, s);
            if (!this.hasRole(ARBITER_ROLE, signer))
                revert DepositRankIsUntrusted();
            if (rank < _minimalRank) revert DepositRankIsTooLow();
        }
        _deposit(_msgSender(), amount, _now());
        emit Deposit(_msgSender(), amount);
        _safe(_token.transferFrom(_msgSender(), address(this), amount));
    }

    function withdraw(uint256 amount, bool delayed) external override {
        require(amount > 0);
        if (_now() < _endsAt && _isPaused) revert StakingIsPaused();

        _withdrawal(_msgSender(), amount, _accrualNow());

        if (delayed) {
            if (_now() >= _endsAt) revert WithdrawalDelayIsUnwanted();
            uint256 fee = Math.fromX18(amount * _delayedWithdrawalFee);
            uint64 unlockAt = _now() + _delayedWithdrawalDuration;
            _delayTransfer(_msgSender(), amount - fee, unlockAt);
            emit DelayedWithdrawal(_msgSender(), amount, fee, unlockAt);
        } else {
            uint256 fee;
            if (_now() < _endsAt)
                fee = Math.fromX18(amount * _prematureWithdrawalFee);

            _safe(_token.transfer(_msgSender(), amount - fee));
            emit Withdrawal(_msgSender(), amount, fee);
        }

        if (!_hasEnoughFunds()) revert WithdrawalIsOffensive();
    }

    function reward(address to) external override onlyRole(MANAGER_ROLE) {
        if (_now() < _endsAt) revert RewardIsTooEarly();
        uint256 prize = _debt(to, _accrualNow());
        _withdrawal(to);
        emit Withdrawal(to, prize, 0);
        _safe(_token.transfer(to, prize));
        if (!_hasEnoughFunds()) revert WithdrawalIsOffensive();
    }

    function refund(uint256 amount) external override onlyRole(PARTNER_ROLE) {
        if (_now() < _endsAt) revert RefundIsTooEarly();
        uint256 tokensToGive = _totalDelayed() + _totalDebt(_accrualNow());
        uint256 balance = _token.balanceOf(address(this));
        if (balance < tokensToGive) revert WithdrawalIsOffensive();

        uint256 freeTokens = balance - tokensToGive;
        if (amount == 0) amount = freeTokens;
        else if (amount > freeTokens) revert WithdrawalIsOffensive();

        _safe(_token.transfer(_msgSender(), amount));
    }

    function claim(address recipient) external override {
        uint256 amount = _finalizeDelayedTransfers(recipient, _now());
        if (amount == 0) revert NoTokensReadyForClaim();
        emit Claim(recipient, amount);
        _safe(_token.transfer(recipient, amount));
    }

    function pause() external override onlyRole(MANAGER_ROLE) {
        require(!_isPaused);
        _isPaused = true;
    }

    function resume() external override onlyRole(MANAGER_ROLE) {
        require(_isPaused);
        _isPaused = false;
    }

    function stop() external onlyRole(MANAGER_ROLE) {
        require(_now() >= _startsAt);
        require(_now() < _endsAt);
        _endsAt = _now();
        emit StakingInfoChanged();
    }

    function setRequisites(
        string calldata name,
        string calldata author,
        string calldata website
    ) external onlyRole(MANAGER_ROLE) {
        require(
            keccak256(abi.encode(_name, _author, _website)) !=
                keccak256(abi.encode(name, author, website))
        );
        (_name, _author, _website) = (name, author, website);
        emit StakingInfoChanged();
    }

    function _hasEnoughFunds() private view returns (bool) {
        return
            _token.balanceOf(address(this)) >= _totalImpact() + _totalDelayed();
    }

    function _safe(bool transfer) private pure {
        if (!transfer) revert TokenTransferFailed();
    }

    function _accrualNow() internal view returns (uint64) {
        uint64 time = _now();
        return time < _endsAt ? time : _endsAt;
    }

    receive() external payable {
        revert();
    }
}