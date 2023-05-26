// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface INotionalFinance {
    function batchBalanceAction(address account, BalanceAction[] calldata actions) external payable;

    struct BalanceAction {
        // Deposit action to take (if any)
        DepositActionType actionType;
        uint16 currencyId;
        // Deposit action amount must correspond to the depositActionType, see documentation above.
        uint256 depositActionAmount;
        // Withdraw an amount of asset cash specified in Notional internal 8 decimal precision
        uint256 withdrawAmountInternalPrecision;
        // If set to true, will withdraw entire cash balance. Useful if there may be an unknown amount of asset cash
        // residual left from trading.
        bool withdrawEntireCashBalance;
        // If set to true, will redeem asset cash to the underlying token on withdraw.
        bool redeemToUnderlying;
    }

    function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions) external payable;

    /// @notice Defines a balance action with a set of trades to do as well
    struct BalanceActionWithTrades {
        DepositActionType actionType;
        uint16 currencyId;
        uint256 depositActionAmount;
        uint256 withdrawAmountInternalPrecision;
        bool withdrawEntireCashBalance;
        bool redeemToUnderlying;
        // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
        bytes32[] trades;
    }

    enum DepositActionType {
        // No deposit action
        None,
        // Deposit asset cash, depositActionAmount is specified in asset cash external precision
        DepositAsset,
        // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
        // external precision
        DepositUnderlying,
        // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
        // nTokens into the account
        DepositAssetAndMintNToken,
        // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
        DepositUnderlyingAndMintNToken,
        // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
        // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
        RedeemNToken,
        // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
        // Notional internal 8 decimal precision.
        ConvertCashToNToken
    }

    function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (uint88 fCashAmount, uint8 marketIndex, bytes32 encodedTrade);

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    /// @dev Market object as represented in memory
    struct MarketParameters {
        bytes32 storageSlot;
        uint256 maturity;
        // Total amount of fCash available for purchase in the market.
        int256 totalfCash;
        // Total amount of cash available for purchase in the market.
        int256 totalAssetCash;
        // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
        int256 totalLiquidity;
        // This is the previous annualized interest rate in RATE_PRECISION that the market traded
        // at. This is used to calculate the rate anchor to smooth interest rates over time.
        uint256 lastImpliedRate;
        // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
        // remaining resistent to flash loan attacks.
        uint256 oracleRate;
        // This is the timestamp of the previous trade
        uint256 previousTradeTime;
    }

    function withdraw(uint16 _currencyId, uint88 _amountInternalPrecision, bool _redeemToUnderlying) external returns (uint256);

    /**
     * @notice Prior to maturity, allows an account to withdraw their position from the vault. Will
     * redeem some number of vault shares to the borrow currency and close the borrow position by
     * lending `fCashToLend`. Any shortfall in cash from lending will be transferred from the account,
     * any excess profits will be transferred to the account.
     *
     * Post maturity, will net off the account's debt against vault cash balances and redeem all remaining
     * strategy tokens back to the borrowed currency and transfer the profits to the account.
     *
     * @param account the address that will exit the vault
     * @param vault the vault to enter
     * @param vaultSharesToRedeem amount of vault tokens to exit, only relevant when exiting pre-maturity
     * @param fCashToLend amount of fCash to lend
     * @param minLendRate the minimum rate to lend at
     * @param exitVaultData passed to the vault during exit
     * @return underlyingToReceiver amount of underlying tokens returned to the receiver on exit
     */
    function exitVault(
        address account,
        address vault,
        address receiver,
        uint256 vaultSharesToRedeem,
        uint256 fCashToLend,
        uint32 minLendRate,
        bytes calldata exitVaultData
    ) external payable returns (uint256 underlyingToReceiver);

    /// @notice Specifies the different trade action types in the system. Each trade action type is
    /// encoded in a tightly packed bytes32 object. Trade action type is the first big endian byte of the
    /// 32 byte trade action object. The schemas for each trade action type are defined below.
    enum TradeActionType {
        // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 minImpliedRate, uint120 unused)
        Lend,
        // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 maxImpliedRate, uint128 unused)
        Borrow,
        // (uint8 TradeActionType, uint8 MarketIndex, uint88 assetCashAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
        AddLiquidity,
        // (uint8 TradeActionType, uint8 MarketIndex, uint88 tokenAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
        RemoveLiquidity,
        // (uint8 TradeActionType, uint32 Maturity, int88 fCashResidualAmount, uint128 unused)
        PurchaseNTokenResidual,
        // (uint8 TradeActionType, address CounterpartyAddress, int88 fCashAmountToSettle)
        SettleCashDebt
    }

    function nTokenClaimIncentives() external returns (uint256);

    function nTokenGetClaimableIncentives(address account, uint256 blockTime) external view returns (uint256);

    function nTokenPresentValueUnderlyingDenominated(uint16 currencyId)
        external
        view
        returns (int256);

    function nTokenAddress(uint16 currencyId) external view returns (address);
    
    function nTokenTotalSupply(address nTokenAddress) external view returns (uint256);

    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256, int256);

    function getAccountBalance(uint16 currencyId, address account) external view returns (
        int256 cashBalance,
        int256 nTokenBalance,
        uint256 lastClaimTime
    );

    function getfCashNotional(
        address account,
        uint16 currencyId,
        uint256 maturity
    ) external view returns (int256);

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        uint256 blockTime,
        bool riskAdjusted
    ) external view returns (int256 presentValue);

    function getAccountPortfolio(address account) external view returns (PortfolioAsset[] memory);

    /// @dev A portfolio asset when loaded in memory
    struct PortfolioAsset {
        // Asset currency id
        uint256 currencyId;
        uint256 maturity;
        // Asset type, fCash or liquidity token.
        uint256 assetType;
        // fCash amount or liquidity token amount
        int256 notional;
        // Used for managing portfolio asset state
        uint256 storageSlot;
        // The state of the asset for when it is written to storage
        AssetStorageState storageState;
    }
    
    /// @notice Used internally for PortfolioHandler state
    enum AssetStorageState {
        NoChange,
        Update,
        Delete,
        RevertIfStored
    }
}