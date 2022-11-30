// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "../Types.sol";

/// @dev only necessary function from https://github.com/notional-finance/contracts-v2/blob/master/interfaces/notional/NotionalProxy.sol
interface NotionalProxy {
    // TODO alfredo - move to TestNotionalProxy once TradingModule is deployed on mainnet
    function owner() external view returns (address);

    function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions) external payable;

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        uint256 blockTime,
        bool riskAdjusted
    ) external view returns (int256 presentValue);

    function getMarketIndex(uint256 maturity, uint256 blockTime) external pure returns (uint8 marketIndex);

    function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (uint88 fCashAmount, uint8 marketIndex, bytes32 encodedTrade);

    function getfCashBorrowFromPrincipal(
        uint16 currencyId,
        uint256 borrowedAmountExternal,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (uint88 fCashDebt, uint8 marketIndex, bytes32 encodedTrade);

    function getDepositFromfCashLend(
        uint16 currencyId,
        uint256 fCashAmount,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime
    )
        external
        view
        returns (uint256 depositAmountUnderlying, uint256 depositAmountAsset, uint8 marketIndex, bytes32 encodedTrade);

    function getPrincipalFromfCashBorrow(
        uint16 currencyId,
        uint256 fCashBorrow,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime
    )
        external
        view
        returns (uint256 borrowAmountUnderlying, uint256 borrowAmountAsset, uint8 marketIndex, bytes32 encodedTrade);

    function getCurrency(uint16 currencyId)
        external
        view
        returns (Token memory assetToken, Token memory underlyingToken);

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    function getAccount(address account)
        external
        view
        returns (
            AccountContext memory accountContext,
            AccountBalance[] memory accountBalances,
            PortfolioAsset[] memory portfolio
        );

    function enterVault(
        address account,
        address vault,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint256 fCash,
        uint32 maxBorrowRate,
        bytes calldata vaultData
    ) external payable returns (uint256 strategyTokensAdded);

    function exitVault(
        address account,
        address vault,
        address receiver,
        uint256 vaultSharesToRedeem,
        uint256 fCashToLend,
        uint32 minLendRate,
        bytes calldata exitVaultData
    ) external payable returns (uint256 underlyingToReceiver);

    function getVaultAccount(address account, address vault) external view returns (VaultAccount memory);

    function getVaultConfig(address vault) external view returns (VaultConfig memory vaultConfig);
}