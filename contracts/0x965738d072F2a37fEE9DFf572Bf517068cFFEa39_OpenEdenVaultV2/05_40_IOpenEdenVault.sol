// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOpenEdenVault {
    function fulfill(bytes32 requestId, uint256 totalOffChainAssets) external;

    event UpdateExchangeRateDecimal(uint256 exchangeRateDecimal);
    event SetOplServiceProvider(address oplServiceProvider);
    event UpdateTreasury(address newAddress);
    event SetBaseVault(address baseVault);
    event SetKycManager(address kycManager);

    event UpdateMinTxsFee(uint256 newValue);
    event ClaimOnchainServiceFee(
        address caller,
        address receiver,
        uint256 amount
    );
    event ClaimOffchainServiceFee(
        address caller,
        address receiver,
        uint256 amount
    );
    event UpdateEpochData(
        uint256 onchainFeeClaimable,
        uint256 offchainFeeClaimable,
        uint256 epoch,
        bytes32 requestId
    );
    event UpdateQueueWithdrawal(
        address investor,
        uint256 shares,
        bytes32 requestId
    );
    event ProcessWithdrawalQueue(
        address investor,
        uint256 assets,
        uint256 shares,
        bytes32 requestId
    );
    event FundTBillPurchase(address treasury, uint256 assets);
    event ProcessWithdraw(
        address receiver,
        uint256 assets,
        uint256 shares,
        bytes32 requestId,
        uint256 subAssets,
        uint256 subShare
    );
    event RedeemVault(address receiver, uint256 assets, uint256 shares);
    event ProcessDeposit(
        address receiver,
        uint256 assets,
        uint256 shares,
        bytes32 requestId,
        uint256 txsFee,
        address oplServiceProvider
    );
    event RequestUpdateEpoch(address caller, bytes32 requestId);
    event RequestWithdrawalQueue(address caller, bytes32 requestId);
    event RequestDeposit(address receiver, uint256 assets, bytes32 requestId);
    event RequestWithdraw(address receiver, uint256 shares, bytes32 requestId);
    event Fulfill(
        address investor,
        bytes32 requestId,
        uint256 totalOffChainAssets,
        // uint256 exchangeRate,
        uint256 amount,
        uint8 action //ACTION
    );
    event WithdrawVault(
        address receiver,
        uint256 assets,
        uint256 shares,
        uint256 exchangeRate,
        bytes32 requestId
    );
}