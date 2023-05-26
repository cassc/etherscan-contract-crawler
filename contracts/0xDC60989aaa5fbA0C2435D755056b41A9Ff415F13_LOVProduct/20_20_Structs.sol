// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum OptionBarrierType {
    None,
    KnockIn
}

struct Deposit {
    uint256 amount;
    address receiver;
}

struct Withdrawal {
    uint256 amountShares;
    address receiver;
}

enum VaultStatus {
    DepositsClosed,
    DepositsOpen,
    NotTraded,
    Traded,
    TradeExpired,
    PayoffCalculated,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

struct OptionBarrier {
    uint256 barrierBps;
    uint256 barrierAbsoluteValue;
    uint256 strikeBps;
    uint256 strikeAbsoluteValue;
    string asset;
    string oracleName;
    OptionBarrierType barrierType;
}

struct FCNVaultMetadata {
    uint256 vaultStart;
    uint256 tradeDate;
    uint256 tradeExpiry;
    uint256 aprBps;
    uint256 tenorInDays;
    uint256 underlyingAmount; // This is how many assets were ever deposited into the vault
    uint256 currentAssetAmount; // This is how many assets are currently allocated for the vault (not sent for trade)
    uint256 totalCouponPayoff;
    uint256 vaultFinalPayoff;
    uint256 queuedWithdrawalsSharesAmount;
    uint256 queuedWithdrawalsCount;
    uint256 optionBarriersCount;
    uint256 leverage;
    address vaultAddress;
    VaultStatus vaultStatus;
    bool isKnockedIn;
    OptionBarrier[] optionBarriers;
}

struct RoundData {
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
}

struct LeverageMetadata {
    bool isAllowed;
    bool isDepositQueueOpen;
    uint256 maxDepositAmountLimit;
    uint256 sumVaultUnderlyingAmounts;
    uint256 queuedDepositsTotalAmount;
    address[] vaultAddresses;
}

struct FCNVaultAssetInfo {
    address vaultAddress;
    uint256 totalAssets;
    uint256 totalSupply;
    uint256 inputAssets;
    uint256 outputShares;
    uint256 inputShares;
    uint256 outputAssets;
}