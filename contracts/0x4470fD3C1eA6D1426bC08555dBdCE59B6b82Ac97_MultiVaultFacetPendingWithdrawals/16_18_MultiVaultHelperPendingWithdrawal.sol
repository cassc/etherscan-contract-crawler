// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawalsEvents.sol";

import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperPendingWithdrawal is IMultiVaultFacetPendingWithdrawalsEvents {
    modifier pendingWithdrawalOpened(
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId
    ) {
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        require(pendingWithdrawal.amount > 0);

        _;
    }

    function _pendingWithdrawal(
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId
    ) internal view returns (IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id];
    }

    function _pendingWithdrawal(
        address recipient,
        uint256 id
    ) internal view returns (IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams memory) {
        return _pendingWithdrawal(IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId(recipient, id));
    }

    function _pendingWithdrawalApproveStatusUpdate(
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId,
        IMultiVaultFacetPendingWithdrawals.ApproveStatus approveStatus
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].approveStatus = approveStatus;

        emit PendingWithdrawalUpdateApproveStatus(
            pendingWithdrawalId.recipient,
            pendingWithdrawalId.id,
            approveStatus
        );
    }

    function _pendingWithdrawalAmountReduce(
        address token,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId,
        uint amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].amount -= amount;
        s.pendingWithdrawalsTotal[token] -= amount;
    }

    function _withdrawalPeriod(
        address token,
        uint256 timestamp
    ) internal view returns (IMultiVaultFacetPendingWithdrawals.WithdrawalPeriodParams memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.withdrawalPeriods_[token][_withdrawalPeriodDeriveId(timestamp)];
    }

    function _withdrawalPeriodDeriveId(
        uint256 timestamp
    ) internal pure returns (uint256) {
        return timestamp / MultiVaultStorage.WITHDRAW_PERIOD_DURATION_IN_SECONDS;
    }

    function _withdrawalPeriodIncreaseTotalByTimestamp(
        address token,
        uint256 timestamp,
        uint256 amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        uint withdrawalPeriodId = _withdrawalPeriodDeriveId(timestamp);

        s.withdrawalPeriods_[token][withdrawalPeriodId].total += amount;
    }

    function _withdrawalPeriodCheckLimitsPassed(
        address token,
        uint amount,
        IMultiVaultFacetPendingWithdrawals.WithdrawalPeriodParams memory withdrawalPeriod
    ) internal view returns (bool) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IMultiVaultFacetPendingWithdrawals.WithdrawalLimits memory withdrawalLimit = s.withdrawalLimits_[token];

        if (!withdrawalLimit.enabled) return true;

        return (amount < withdrawalLimit.undeclared) &&
        (amount + withdrawalPeriod.total - withdrawalPeriod.considered < withdrawalLimit.daily);
    }
}