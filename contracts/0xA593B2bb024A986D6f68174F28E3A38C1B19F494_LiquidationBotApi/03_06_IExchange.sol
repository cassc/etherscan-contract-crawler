//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../../external/IERC677Receiver.sol";

/// @title A Futureswap V4 exchange for a single pair of tokens.
///
/// @notice An API for an exchange that manages leveraged trades for one pair of tokens.  One token
/// is called "asset" and it's address is returned by `assetToken()`. The other token is called
/// "stable" and it's address is returned by `stableToken()`.  Exchange is mostly symmetrical with
/// regard to how "asset" and "stable" are treated.
///
/// The API is designed for 3 roles:
///
///  - Traders
///      Use `changePosition()`.
///      Alternatively a position can be opened by doing an ERC677 token transfer of the stable token
///      to the exchange. `data` should the encoded bytes of the `ChangePositionData` struct.
///
///  - Liquidity providers
///      Liquidity provider can provide asset and stable tokens. Providing
///      tokens is done though calling `addLiquidity`, which requires the caller to be a smart contract
///      End users will use `LiquidityRouter`.  `LiquidityRouter` will use `addLiquidity()` provided by this interface.
///      Removing liquidity can either be done by calling `removeLiquidity` on the exchange
///      or doing an ERC677 token transfer of the liquidity token to the exchange. `data` should
///      contain the bytes of the `RemoveLiquidityData` struct.
///
///  - Liquidation bot(s)
///      Use `liquidate()`.
///
/// Liquidity providers receive `liquidityToken()` for providing liquidity.  They represents the
/// share of the liquidity pool a provider owns. The token is automatically staked into
/// the liquidity provider incentives contract.
/// Liquidity providers receive FST from the staking contract.
///
/// Traders receive FST tokens for trading.  Exchange automatically updates the `incentives()`
/// contract with the current position for every trader.
interface IExchange is IERC677Receiver {
    /// @notice Address of the asset token of the exchange.
    function assetToken() external view returns (address);

    /// @notice Address of the stable token of the exchange.
    ///
    ///         Must confirm to `IERC20`.
    ///
    ///         Traders have to provide the asset token as collateral for their positions while
    ///         getting exposure to the difference between the asset token and the stable token
    function stableToken() external view returns (address);

    /// @notice Address of the liquidity token of the exchange.
    ///
    ///         Must confirm to `IERC20`
    ///
    ///         Liquidity providers are minted liquidity tokens by the exchange for providing
    ///         liquidity.  These tokens represent share of the liquidity pool that a particular
    ///         provider owns.
    ///
    ///         Liquidity tokens represent shares of this total value.  With one token been worth 1
    ///         / total number of minted liquidity tokens.
    function liquidityToken() external view returns (address);

    /// @notice Address of the trading incentives contract for this exchange.  Can be 0, in case the
    ///         exchange is not incentivised.
    ///
    ///         If provided, implements `IExternalBalanceIncentives`.
    ///
    ///         Exchange will automatically inform this incentives contract about all the open
    ///         position for traders.
    function tradingIncentives() external view returns (address);

    /// @notice Returns the address of the tradingFeeIncentives, can be zero if it isn't present.
    function tradingFeeIncentives() external view returns (address);

    /// @notice Address of the incentives contract for this exchange.
    ///
    ///         Provided address, implements `IStakingIncentives`.
    ///
    ///         Liquidity tokens are automatically staked in the IStakingIncentives contract
    function liquidityIncentives() external view returns (address);

    /// @notice Address of the price oracle contract for this exchange.
    ///
    ///         Price provided by this priceOracle is used to calculate value of the assets in the
    ///         liquidity pool. When swapping assets via `swapPool()` the conversion price might be
    ///         different.
    function priceOracle() external view returns (address);

    /// @notice Address of the underlying pool that is used to perform swaps.
    ///
    ///         Expected to conform to `ISwapPool`.
    function swapPool() external view returns (address);

    /// @notice Address of the WETH token contract.
    ///
    ///         Expected to confirm to `IWETH9`.
    ///
    ///         This token is only used if exchange is using WETH for stable or asset.  That
    ///         is either `stableToken()` is equal to this address, or `assetToken()` is equal to
    ///         this address.
    ///
    ///         If `stableToken()` has the same address as wethToken the exchange will accept ETH as stable from traders.
    ///
    ///         If `assetToken()` or `stableToken()` have the same address as wethToken the exchange
    ///         will only accept WETH from liquidity providers. Conversion is done for liquidity providers
    ///         in the `LiquidityRouter` contract.
    function wethToken() external view returns (address);

    /// @notice Address of the FST protocols treasury.
    ///
    ///         The treasury collects a protocol fee from the exchange.
    function treasury() external view returns (address);

    /// @notice Position for a particular trader.
    /// @param _trader The address to use for obtaining the position
    function getPosition(address _trader)
        external
        view
        returns (
            int256 asset,
            int256 stable,
            uint8 adlTrancheId,
            uint32 adlShareClass
        );

    /// @notice Returns the amount of asset and stable token for a given liquidity token amount.
    /// @param _amount The amount of liquidity tokens.
    function getLiquidityValue(uint256 _amount)
        external
        view
        returns (uint256 assetAmount, uint256 stableAmount);

    /// @notice Returns the amount of asset required to provide a given stableAmount. Also
    ///         returns the number of liquidity tokens that currently would be minted for the
    ///         stableAmount and assetAmount.
    /// @param _stableAmount The amount of stable tokens the user wants to supply.
    function getLiquidityTokenAmount(uint256 _stableAmount)
        external
        view
        returns (uint256 assetAmount, uint256 liquidityTokenAmount);

    /// @notice Changes a traders position in the exchange
    /// @param _deltaStable The amount of stable to change the position by
    ///                     Positive values will add stable to the position (move stable token from the trader) into the exchange
    ///                     Negative values will remove stable from the position and send the trader tokens
    /// @param _deltaAsset  The amount of asset the position should be changed by
    /// @param _stableBound The maximum/minimum amount of stable that the user is willing to pay/receive for the _deltaAsset change
    ///                     If the user is buying asset (_deltaAsset > 0) the user will have to choose a maximum negative number
    ///                     that he is going to be in dept for
    ///                     If the user is selling asset (_deltaAsset < 0) the user will have to choose a minimum positiv number
    ///                     of that that he wants to be credited with
    /// @return startAsset The amount of asset the trader owned before the change position occured,
    ///         startStable The amount of stable the trader owned before the change position occured,
    ///         totalAsset The amount of asset the trader owns after the change position has occured,
    ///         totalStable The amount of stable the trader owns after the change position has occured,
    ///         tradeFee The amount of trade fee paid to Futureswap,
    ///         traderPayout The amount of stable tokens paid to the trader
    function changePosition(
        int256 _deltaStable,
        int256 _deltaAsset,
        int256 _stableBound
    )
        external
        payable
        returns (
            int256 startAsset,
            int256 startStable,
            int256 totalAsset,
            int256 totalStable,
            uint256 tradeFee,
            uint256 traderPayout
        );

    /// @dev Data tracked throughout changePosition and used in the PositionChanged event.
    struct ChangePositionEventData {
        // The positions address that is being changed
        address trader;
        // The amount of stable tokens being paid to liquidity providers as a trade fee.
        uint256 tradeFee;
        // The amount of stable tokens being paid to the trader
        uint256 traderPayout;
        // The amount of asset the position had before changing it
        int256 startAsset;
        // The amount of stable the position had before changing it
        int256 startStable;
        // The amount of asset the position had after changing it
        int256 totalAsset;
        // The amount of stable the position had after changing it
        int256 totalStable;
        // The amount of stable tokens being paid to the liquidator
        int256 liquidatorPayment;
        // The amount of asset that was swapped (either with pool or through adl)
        int256 swappedAsset;
        // The amount of stable that was swapped (either with pool or through adl)
        int256 swappedStable;
    }

    function changePositionView(
        address _trader,
        int256 _deltaStable,
        int256 _deltaAsset,
        int256 _stableBound
    ) external returns (ChangePositionEventData memory);

    /// @notice Liquidates a traders position
    ///         For a position to be liquidatable it needs to either
    ///         have less collateral (stable) left than ExchangeConfig.minCollateral
    ///         or exceed a leverage higher than ExchangeConfig.maxLeverage
    ///         If this is a case anyone can liquidate the position and receive a reward
    /// @param _trader The trader to liquidate
    /// @return The amount of stable that was paid to the liquidator
    function liquidate(address _trader) external returns (uint256);

    /// @notice Returns the maximum amount of shares that can be redeemed respecting to liquidity pool ERC20 token constrains.
    ///         Part of the LP tokens are locked in trades and cannot be redeemed immediately. This function lower bounds the
    ///         maximum number of shares that can be redeemed currently.
    function getRedeemableLiquidityTokenAmount() external view returns (uint256);

    /// @notice Add liquidity to the exchange.  `LiquidityRouter` interface.
    ///
    ///         Callers are expected to implement the `IFutureswapLiquidityPayment` interface
    ///         to facilitate payment through a callback.
    ///
    ///         When calculating the liquidity pool value, we convert value of the "asset" tokens
    ///         into the "stable" tokens, using price provided by the priceOracle.
    ///
    /// @param _provider The account to provide the liquidity for.
    /// @param _stableAmount The amount of liquidity to provide denoted in stable
    ///                The exchange will request payment for an equal amount of stable and asset tokens
    ///                value wise
    /// @param _minLiquidityTokens The minimum amount of liquidity token to receive for providing liquidity
    /// @param _data Any extra data that the caller wants to be passed along to the callback
    /// @return The amount of tokens that were minted to _provider
    function addLiquidity(
        address _provider,
        uint256 _stableAmount,
        uint256 _minLiquidityTokens,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice Remove liquidity from the exchange.  `LiquidityRouter` interface.
    ///
    ///         Callers are expected to transfer the liquidity token into the exchange.
    ///         The exchange will then attempt to burn _tokenAmount to redeem liquidity.
    ///
    ///         While anyone can call this function, exchange is not expected to hold any liquidity
    ///         tokens.  Liquidity tokens are sent by the `LiquidityRouter` and this function is
    ///         called to burn those tokens in the same transaction.
    ///
    ///         Exchange will determine the split between asset and stable that a liquidity provider
    ///         receives based on an internal state.  But the total value will always be equal to
    ///         the share of the total assets owned by the exchange, based on the share of the
    ///         provided liquidity tokens.
    ///
    ///         `_minAssetAmount` and `_minStableAmount` allow the liquidity provider to only
    ///         withdraw when the volume of asset and share, respectively, is at or above the
    ///         specified values.
    ///
    /// @param _recipient The recipient of the redeemed liquidity
    /// @param _tokenAmount The amount of liquidity tokens to burn
    /// @param _minAssetAmount The minimum amount of asset tokens to redeem in exchange for the
    ///                        provided share of liquidity.
    ///                        happen regardless of the amount of asset in the result.
    /// @param _minStableAmount The minimum amount of stable tokens to redeem in exchange for the
    ///                         provided share of liquidity.
    /// @return assetAmount The amount of asset tokens that was actually redeemed.
    /// @return stableAmount The amount of asset tokens that was actually redeemed.
    function removeLiquidity(
        address _recipient,
        uint256 _tokenAmount,
        uint256 _minAssetAmount,
        uint256 _minStableAmount
    ) external returns (uint256 assetAmount, uint256 stableAmount);

    /// @notice Can be used together with an ERC677 onTokenTransfer
    ///         See onTokenTransfer for a description of the fields
    struct ChangePositionData {
        int256 deltaAsset;
        int256 stableBound;
    }

    /// @notice Can be used together with an ERC677 onTokenTransfer
    ///         See onTokenTransfer for a description of the fields
    struct RemoveLiquidityData {
        uint256 minAssetAmount;
        uint256 minStableAmount;
    }

    /// @notice Similar to RemoveLiquidityData but with extra receiver data.
    ///
    ///         When staking tokens are redeemed for stable/asset, an instance of this type is
    ///         expected as the `data` argument in an `transferAndCall` call between the
    ///         `StakingIncentives` and the `Exchange` contracts.  The `reciever` field allows the
    ///         `StakingIncentives` to specify the receiver of the stable and asset tokens.
    struct RemoveLiquidityDataWithReceiver {
        uint256 minAssetAmount;
        uint256 minStableAmount;
        address receiver;
    }

    /// @notice Restricts exchange functionality.
    enum ExchangeState {
        /// @notice All functions are operational.
        NORMAL,
        /// @notice Only allow positions to be closed and liquidity removed.
        PAUSED,
        /// @notice No operations all allowed.
        STOPPED
    }

    /// @notice Updates the config of the exchange, can only be performed by the voting executor.
    function setExchangeConfig1(
        int256 _tradeFeeFraction,
        int256 _timeFee,
        uint256 _maxLeverage,
        uint256 _minCollateral,
        int256 _treasuryFraction,
        uint256 _removeLiquidityFee,
        int256 _tradeLiquidityReserveFactor
    ) external;

    /// @notice Returns the first part of the config parameters for this exchange
    function exchangeConfig1()
        external
        view
        returns (
            int256 tradeFeeFraction,
            int256 timeFee,
            uint256 maxLeverage,
            uint256 minCollateral,
            int256 treasuryFraction,
            uint256 removeLiquidityFee,
            int256 tradeLiquidityReserveFactor
        );

    /// @notice Updates the config of the exchange, can only be performed by the voting executor.
    function setExchangeConfig2(
        int256 _dfrRate,
        int256 _liquidatorFrac,
        int256 _maxLiquidatorFee,
        int256 _poolLiquidationFrac,
        int256 _maxPoolLiquidationFee,
        int256 _adlFeePercent
    ) external;

    /// @notice Returns the second part of the config parameters for this exchange
    function exchangeConfig2()
        external
        view
        returns (
            int256 dfrRate,
            int256 liquidatorFrac,
            int256 maxLiquidatorFee,
            int256 poolLiquidationFrac,
            int256 maxPoolLiquidationFee,
            int256 adlFeePercent
        );

    /// @notice Returns the current state of the exchange.
    ///         See description on ExchangeState above for details
    function exchangeState() external view returns (ExchangeState);

    /// @notice Returns the pause price that exchange was paused at.
    ///         If the exchange got paused, this price overides
    ///         the oracle price for liquidations and liquidity
    ///         providers redeeming their liquidity.
    function pausePrice() external view returns (int256);

    /// @notice Returns the current oracle price that is the price of the
    ///         smallest particle of the asset token in the smallest particles
    ///         of stable tokens with 18 decimals.
    ///           For example for ETH/USDC where ETH has 18 decimals and USDC
    ///         has 6 decimals that would be the price of 1 Wei in 0.000001 USDC
    ///         (1*10^-18 ETH in 1*10^-6 USDC) with 18 decimals.
    function getOraclePrice() external view returns (int256);

    /// @notice Update the exchange state.
    ///         Is used to PAUSE or STOP the exchange. When PAUSED
    ///         trades cannot open, liquidity cannot be added, and a
    ///         fixed oracle price is set. When STOPPED no user actions
    ///         can occur.
    function setExchangeState(ExchangeState _state, int256 _pausePrice) external;
}