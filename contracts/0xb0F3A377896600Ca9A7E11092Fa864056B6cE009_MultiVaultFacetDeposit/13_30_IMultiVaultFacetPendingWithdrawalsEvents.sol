// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetPendingWithdrawals.sol";


interface IMultiVaultFacetPendingWithdrawalsEvents {
    event PendingWithdrawalCancel(
        address recipient,
        uint256 id,
        uint256 amount
    );

    event PendingWithdrawalUpdateBounty(
        address recipient,
        uint256 id,
        uint256 bounty
    );

    event PendingWithdrawalCreated(
        address recipient,
        uint256 id,
        address token,
        uint256 amount,
        bytes32 payloadId
    );

    event PendingWithdrawalWithdraw(
        address recipient,
        uint256 id,
        uint256 amount
    );

    event PendingWithdrawalFill(
        address recipient,
        uint256 id
    );

    event PendingWithdrawalForce(
        address recipient,
        uint256 id
    );

    event PendingWithdrawalUpdateApproveStatus(
        address recipient,
        uint256 id,
        IMultiVaultFacetPendingWithdrawals.ApproveStatus approveStatus
    );
}