//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../amm_adapter/IAmmAdapter.sol";
import "../amm_adapter/IAmmAdapterCallback.sol";
import "../external/IERC677Receiver.sol";
import "../external/IWETH9.sol";
import "../incentives/IStakingIncentives.sol";
import "../external/IERC677Receiver.sol";
import "../external/IWETH9.sol";
import "../lib/FsMath.sol";
import "../lib/Utils.sol";
import "../token/ILiquidityToken.sol";
import "../upgrade/FsBase.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IExchangeLedger.sol";
import "./TokenVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title The implementation of an AMM that hedges its positions by trading in the spot market.
/// @notice This AMM takes the opposite position to the aggregate trader positions on the Futureswap
/// exchange (can be 0 if trader longs and shorts are perfectly balanced). This AMM hedges its position by taking an
/// opposite position on an external market and thus ideally stay market neutral. Example: aggregate trader position
/// on the Futureswap exchange is long 200 asset tokens. The AMM's position there would be short 200 asset token. But
/// it also has a 200 asset long position on the external spot market. This allows it to make the fees without being
/// exposed to market risks (relatively to LPs' original 50:50 allocation in value between stable:asset).
/// @dev This AMM should never directly hold funds and should send any tokens directly to the token vault.
contract SpotMarketAmm is FsBase, IAmm, IAmmAdapterCallback, IERC677Receiver {
    using SafeERC20 for IERC20;

    /// @dev This is immutable as it will stay fixed across the entire system.
    address public immutable wethToken;

    IAmmAdapter public ammAdapter;
    IExchangeLedger public exchangeLedger;
    TokenVault public tokenVault;
    ILiquidityToken public liquidityToken;
    address public liquidityIncentives;
    IOracle public oracle;
    address public assetToken;
    address public stableToken;
    AmmConfig public ammConfig;

    /// @notice A flag to guard against functions being illegally called outside of trading flow.
    bool private inTradingExecution;

    /// @notice The AMM's collateral includes both original stable liquidity added and its position on spot market to
    /// hedge against its position on the Futureswap exchange.
    /// The two positions (on Futureswap exchange and external spot market) should perfectly cancel each other out,
    /// excluding fees (Trade and time fees that are paid from traders to the AMM). The only exception that can cause
    /// a mismatch between the AMM's two positions is when ADL happens, which partially closes the AMM's position on
    /// the Futureswap exchange but leaves its corresponding hedge (position on Spot market) still open. When this
    /// happens, the AMM's book is not market neutral and is exposed to market risks. But this only happens in the
    /// extreme case where ADL runs out of opposite trader positions on the Futureswap exchange and should rarely, if
    /// ever, happen in real life.
    int256 public collateral;

    /// @dev Reserves storage for future upgrades. Each contract will use exactly storage slot 1000 until 2000.
    ///      When adding new fields to this contract, one must decrement this counter proportional to the
    ///      number of uint256 slots used.
    //slither-disable-next-line unused-state
    uint256[988] private _____contractGap;

    /// @notice Only for testing our contract gap mechanism, never use in prod.
    //slither-disable-next-line constable-states,unused-state
    uint256 private ___storageMarker;

    /// @notice Emitted when liquidity is added by a liquidity provider
    /// @param provider The provider's address
    /// @param assetAmount The amount of asset tokens the liquidity provider provided
    /// @param stableAmount The amount of stable tokens the liquidity provider provided
    /// @param liquidityTokenAmount The amount of liquidity tokens that were issued
    /// @param liquidityTokenSupply The new total supply of liquidity tokens
    event LiquidityAdded(
        address indexed provider,
        int256 assetAmount,
        int256 stableAmount,
        int256 liquidityTokenAmount,
        int256 liquidityTokenSupply
    );

    /// @notice Emitted when liquidity is removed by a liquidity provider
    /// @param provider The provider's address
    /// @param assetAmount The amount of asset tokens the liquidity provider received
    /// @param stableAmount The amount of stable tokens the liquidity provider received
    /// @param liquidityTokenAmount The amount of liquidity tokens that were burnt
    /// @param liquidityTokenSupply The new total supply of liquidity tokens
    event LiquidityRemoved(
        address indexed provider,
        int256 assetAmount,
        int256 stableAmount,
        int256 liquidityTokenAmount,
        int256 liquidityTokenSupply
    );

    event OracleChanged(address oldOracle, address newOracle);
    event AmmConfigChanged(AmmConfig oldConfig, AmmConfig newConfig);
    event AmmAdapterChanged(address oldAmmAdapter, address newAmmAdapter);
    event LiquidityIncentivesChanged(
        address oldLiquidityIncentives,
        address newLiquidityIncentives
    );

    struct AmmConfig {
        // A fee for removing liquidity, range: [0, 1 ether). 0 is 0% and 1 ether is 100% (it should never be 100%).
        int256 removeLiquidityFee;
        // A minimum reserve of asset/stable tokens that needs to be present after each swap expressed as a percentage
        // of total liquidity converted to stable using the current asset price. Range: [0, 1 ether]; 0 is 0% and
        // 1 ether is 100%.
        int256 tradeLiquidityReserveFactor;
    }

    /// @notice Can be used together with an ERC677 onTokenTransfer to remove liquidity.
    /// When LP tokens are redeemed for stable/asset, an instance of this type is
    /// expected as the `data` argument in an `transferAndCall` call between either the LP token or the
    /// `StakingIncentives` and the `SpotMarketAmm` contracts.  The `receiver` field allows the caller contract
    /// to specify the receiver of the stable and asset tokens.
    struct RemoveLiquidityData {
        // The recipient of the redeemed liquidity.
        address receiver;
        // The minimum amount of asset tokens to redeem in exchange for the provided share of liquidity.
        int256 minAssetAmount;
        // The minimum amount of stable tokens to redeem in exchange for the provided share of liquidity.
        int256 minStableAmount;
        // Whether to pay out liquidity using raw ETH for whichever token is WETH.
        bool useEth;
    }

    modifier atomicTradingExecution() {
        require(!inTradingExecution, "Not in trading flow");
        inTradingExecution = true;
        _;
        inTradingExecution = false;
    }

    /// @param _wethToken WETH's address used for dealing with WETH/ETH transfers.
    constructor(address _wethToken) {
        // slither-disable-next-line missing-zero-check
        wethToken = FsUtils.nonNull(_wethToken);
    }

    /// @notice Allow ETH to be sent to this contract for unwrapping WETH only.
    receive() external payable {
        require(msg.sender == wethToken, "Wrong sender");
    }

    /// @param _exchangeLedger The exchangeLedger associated with the token vault.
    /// @param _tokenVault Address of the token vault the AMM can draw funds from for hedging.
    /// @param _assetToken Address of the asset token for liquidity and trade calculations.
    /// @param _stableToken Address of the stable token for liquidity and trade calculations.
    /// @param _liquidityToken Address of the LP token LPs receive for providing liquidity.
    /// @param _liquidityIncentives Address of the incentives minted LP tokens are sent to for staking.
    /// @param _ammAdapter Address of the associated amm adapter.
    /// @param _oracle Address of the associated oracle.
    function initialize(
        address _exchangeLedger,
        address _tokenVault,
        address _assetToken,
        address _stableToken,
        address _liquidityToken,
        address _liquidityIncentives,
        address _ammAdapter,
        address _oracle,
        AmmConfig memory _ammConfig
    ) external initializer {
        initializeFsOwnable();

        // slither-disable-next-line missing-zero-check
        exchangeLedger = IExchangeLedger(FsUtils.nonNull(_exchangeLedger));
        // slither-disable-next-line missing-zero-check
        tokenVault = TokenVault(FsUtils.nonNull(_tokenVault));
        // slither-disable-next-line missing-zero-check
        assetToken = FsUtils.nonNull(_assetToken);
        // slither-disable-next-line missing-zero-check
        stableToken = FsUtils.nonNull(_stableToken);
        // slither-disable-next-line missing-zero-check
        liquidityToken = ILiquidityToken(FsUtils.nonNull(_liquidityToken));
        // slither-disable-next-line missing-zero-check
        liquidityIncentives = FsUtils.nonNull(_liquidityIncentives);
        // slither-disable-next-line missing-zero-check
        ammAdapter = IAmmAdapter(FsUtils.nonNull(_ammAdapter));
        // slither-disable-next-line missing-zero-check
        oracle = IOracle(FsUtils.nonNull(_oracle));
        setAmmConfig(_ammConfig);
        inTradingExecution = false;
    }

    /// @inheritdoc IAmm
    function getAssetPrice() external view override returns (int256 assetPrice) {
        return ammAdapter.getPrice(assetToken, stableToken);
    }

    /// @inheritdoc IAmm
    function trade(
        int256 assetAmount,
        int256 assetPrice,
        bool isClosingTraderPosition
    ) external override atomicTradingExecution returns (int256 stableAmount) {
        require(msg.sender == address(exchangeLedger), "Wrong sender");

        int256 stableBalanceBefore = vaultBalance(stableToken);
        int256 assetBalanceBefore = vaultBalance(assetToken);

        // This total value is the same before and after swap because the exchange ledger doesn't update the amm's
        // position after this trade function finishes executing.
        (int256 ammStableBalance, int256 ammAssetBalance) = ammBalance(assetPrice);
        int256 totalValue = ammStableBalance + FsMath.assetToStable(ammAssetBalance, assetPrice);

        // Swap and send received tokens directly to the vault. This eliminates the risk of having any funds being stuck
        // in this AMM.
        stableAmount = ammAdapter.swap(address(tokenVault), stableToken, assetToken, assetAmount);

        // Update the AMM's collateral to include its new stable position on the external spot
        // market.
        //
        // `atomicTradingExecution` prevents a reentrancy attack here.  We can not update
        // `collateral` before we know the `stableAmount` value.
        // Also, Slither suggests that changes to `collateral` should trigger events. It is not
        // completely wrong, but we would need to expose more internal state if we want to be able
        // to track all the changes in our accounting, so ignoring this suggestion for now.
        // slither-disable-next-line reentrancy-no-eth,events-maths
        collateral += stableAmount;

        int256 assetBalanceAfter = vaultBalance(assetToken);
        require(
            vaultBalance(stableToken) >= stableBalanceBefore + stableAmount,
            "Wrong stable balance"
        );
        require(assetBalanceAfter >= assetBalanceBefore + assetAmount, "Wrong asset balance");

        requireEnoughLiquidityLeft(
            isClosingTraderPosition,
            totalValue,
            assetBalanceAfter,
            assetPrice
        );
    }

    /// @inheritdoc IAmmAdapterCallback
    function sendPayment(
        address recipient,
        address token0,
        address token1,
        int256 amount0Owed,
        int256 amount1Owed
    ) external override {
        // We'll verify that payment is only requested as part of an ongoing trade execution to protect against a
        // malicious ammAdapter or a potential exploit that allows an attacker to take over the ammAdapter and call the
        // AMM from it.
        require(inTradingExecution, "Not in trading execution flow");

        require(msg.sender == address(ammAdapter), "Wrong address");
        require(
            (token0 == stableToken && token1 == assetToken) ||
                (token0 == assetToken && token1 == stableToken),
            "Wrong token"
        );
        // Validate that we need to send payment for exactly one of the two tokens.
        require(
            (amount0Owed > 0 && amount1Owed <= 0) || (amount1Owed > 0 && amount0Owed <= 0),
            "Invalid amount"
        );

        // There should be no risk of reentrancy here with transfers as the end users cannot call the AMM directly.
        // System-wide reentrancy should be handled at the TokenManager and exchangeLedger level.
        if (amount0Owed > 0) {
            // We could extract amount out of the if/else conditions but that'd require an unsafe cast
            // from int256 to int256.
            // slither-disable-next-line safe-cast
            uint256 amount = uint256(amount0Owed);
            // This might not be enough to cover token that charges a fee for transfer. An example is USDT.
            // The spot market would likely revert in those cases due to insufficient payment.
            // This is fine for now as we don't support those tokens yet.
            tokenVault.transfer(recipient, token0, amount);
        } else {
            // We have a `require` call above to validate that if `amount0Owed` is zero or negative,
            // then `amount1Owed` is positive.
            // slither-disable-next-line safe-cast
            uint256 amount = uint256(amount1Owed);
            tokenVault.transfer(recipient, token1, amount);
        }
    }

    /// @notice Add liquidity to the AMM
    /// Callers are expected to have approved the AMM with sufficient limits to pay for the stable/asset required
    /// for adding liquidity.
    ///
    /// When calculating the liquidity pool value, we convert value of the "asset" tokens
    /// into the "stable" tokens, using price provided by the price oracle.
    ///
    /// @param stableAmount The amount of liquidity to provide denoted in stable. The AMM will request payment for an
    /// equal amount of stable and asset tokens value wise.
    /// @param maxAssetAmount The maximum amount of assets to provide as liquidity. This allows the user to set bounds
    /// on prices as they need to provide equal values of stables and assets. 0 means no bounds.
    /// @return The amount of tokens that were minted to the liquidity provider.
    function addLiquidity(int256 stableAmount, int256 maxAssetAmount)
        external
        payable
        returns (int256)
    {
        // Liquidity can only be added if the exchange is in normal operation
        require(
            exchangeLedger.exchangeState() == IExchangeLedger.ExchangeState.NORMAL,
            "Exchange not in normal state"
        );

        // Don't accept raw ETH from msg.value if neither of the accepted tokens is WETH.
        if (msg.value > 0) {
            require(
                stableToken == wethToken || assetToken == wethToken,
                "Not a WETH pool, invalid msg.value"
            );
        }

        (int256 liquidityTokens, int256 totalShares, int256 assetAmount) =
            calculateAddLiquidityAmounts(stableAmount);
        // Users can set a bound so that if the price changes too much, the transaction would revert.
        // This removes the ability to front-run large liquidity providers.
        // A `maxAssetAmount` of zero means the user did not set a bound.
        if (maxAssetAmount != 0) {
            require(assetAmount <= maxAssetAmount, "maxAssetAmount requirement violated");
        }

        address provider = msg.sender;
        int256 newTotalShares = totalShares + liquidityTokens;
        emit LiquidityAdded(provider, assetAmount, stableAmount, liquidityTokens, newTotalShares);
        handleLiquidityPayment(provider, assetAmount, stableAmount, liquidityTokens);

        collateral += stableAmount;
        return liquidityTokens;
    }

    /// @dev Remove liquidity from the AMM
    /// Callers are expected to transfer the liquidity token into the AMM. The AMM will then attempt to burn tokenAmount
    /// to redeem liquidity.
    ///
    /// `minAssetAmount` and `minStableAmount` allow the liquidity provider to only withdraw when the volume of asset
    /// and share, respectively, is at or above the specified values.
    ///
    /// @param recipient The recipient of the redeemed liquidity.
    /// @param liquidityTokenAmount The amount of liquidity tokens to burn.
    /// @param minAssetAmount The minimum amount of asset tokens to redeem in exchange for the provided share of
    /// liquidity. Happens regardless of the amount of asset in the result.
    /// @param minStableAmount The minimum amount of stable tokens to redeem in exchange for the provided share of
    /// liquidity.
    /// @param useEth Whether to pay out liquidity using raw ETH for whichever token is WETH.
    function removeLiquidity(
        address recipient,
        int256 liquidityTokenAmount,
        int256 minAssetAmount,
        int256 minStableAmount,
        bool useEth
    ) private {
        // Liquidity can be removed if the exchange is in normal operation or paused
        require(
            exchangeLedger.exchangeState() != IExchangeLedger.ExchangeState.STOPPED,
            "Exchange is stopped"
        );

        if (liquidityTokenAmount == 0) return;

        FsUtils.Assert(liquidityTokenAmount > 0); // guaranteed by onTokenTransfer
        // Because this function is called by onTokenTransfer which guarantees we have
        FsUtils.Assert(uint256(liquidityTokenAmount) <= liquidityToken.balanceOf(address(this)));

        int256 price = oracle.getPrice(assetToken);
        (int256 assetAmount, int256 stableAmount) =
            calculateRemoveLiquidityAmounts(liquidityTokenAmount, price);

        // Users can set a bound so that if the pool ratio changes their transaction
        // will not mine. This removes the ability to front-run large liquidity providers.
        // A `minAssetAmount` or `minStableAmount` of zero means the user did not set a bound.
        require(assetAmount >= minAssetAmount, "minAssetAmount requirement violated");
        require(stableAmount >= minStableAmount, "minStableAmount requirement violated");

        // Check that we have enough asset and stable balance to return liquidity to LP.
        // For better error reporting, revert with insufficient asset/stable liquidity.
        (int256 stableBalance, int256 assetBalance) = ammBalance(price);
        require(int256(assetAmount) <= assetBalance, "Insufficient asset liquidity");
        require(int256(stableAmount) <= stableBalance, "Insufficient stable liquidity");

        // Update state before transfer calls in case of reentrancy.
        collateral -= stableAmount;

        // Burn the liquidity tokens corresponding to the withdrawn liquidity. burn() will only burn
        // tokens in this AMM's possession. The AMM by default has no liquidity token balance so if
        // we are able to burn `amount` of tokens this means that msg.sender must have transferred
        // these tokens in.
        liquidityToken.burn(FsMath.safeCastToUnsigned(liquidityTokenAmount));

        pay(recipient, assetToken, assetAmount, useEth);
        pay(recipient, stableToken, stableAmount, useEth);

        int256 updatedTotalSupply = FsMath.safeCastToSigned(liquidityToken.totalSupply());
        emit LiquidityRemoved(
            recipient,
            assetAmount,
            stableAmount,
            liquidityTokenAmount,
            updatedTotalSupply
        );
    }

    /// @inheritdoc IERC677Receiver
    /// @notice Receive transfer of LP token and allow LP to remove liquidity. Data is expected to contain an encoded
    /// version of `RemoveLiquidityData`.
    ///
    /// AMM will determine the split between asset and stable that a liquidity provider receives based on an internal
    /// state. But the total value will always be equal to the share of the total assets owned by the AMM, based on the
    /// share of the provided liquidity tokens.
    /// @param amount the amount of LP tokens send
    /// @param data the abi encoded RemoveLiquidityData struct describing the remove liquidity call.
    ///             See struct definition for the parameters and explanation.
    function onTokenTransfer(
        address, /* from */
        uint256 amount,
        bytes calldata data
    ) external override returns (bool success) {
        // Only accepts transfer of LP tokens. Other tokens should not be sent directly here without calling
        // addLiquidity.
        require(msg.sender == address(liquidityToken), "Incorrect sender");

        RemoveLiquidityData memory decodedData = abi.decode(data, (RemoveLiquidityData));
        address receiver = decodedData.receiver;
        int256 minAssetAmount = decodedData.minAssetAmount;
        int256 minStableAmount = decodedData.minStableAmount;
        bool useEth = decodedData.useEth;
        removeLiquidity(
            receiver,
            FsMath.safeCastToSigned(amount),
            minAssetAmount,
            minStableAmount,
            useEth
        );

        // Always return true as we would revert if something is unexpected.
        return true;
    }

    /// @notice Updates the config of the AMM, can only be performed by the voting executor.
    function setAmmConfig(AmmConfig memory _ammConfig) public onlyOwner {
        // removeLiquidityFee cannot be 100%.
        require(
            0 <= _ammConfig.removeLiquidityFee && _ammConfig.removeLiquidityFee < 1 ether,
            "Invalid remove liquidity fee"
        );
        require(
            0 <= _ammConfig.tradeLiquidityReserveFactor &&
                _ammConfig.tradeLiquidityReserveFactor <= 1 ether,
            "Invalid trade liquidity reserve factor"
        );

        emit AmmConfigChanged(ammConfig, _ammConfig);
        ammConfig = _ammConfig;
    }

    /// @notice Updates the oracle the AMM uses to compute prices for adding/removing liquidity, can only be performed
    /// by the voting executor.
    function setOracle(address _oracle) external onlyOwner {
        if (_oracle == address(oracle)) {
            return;
        }
        address oldOracle = address(oracle);
        oracle = IOracle(FsUtils.nonNull(_oracle));
        emit OracleChanged(oldOracle, _oracle);
    }

    /// @notice Allows voting executor to change the amm adapter. This can effectively change the spot market this AMM
    /// trades with.
    function setAmmAdapter(address _ammAdapter) external onlyOwner {
        if (_ammAdapter == address(ammAdapter)) {
            return;
        }
        emit AmmAdapterChanged(address(ammAdapter), address(_ammAdapter));
        ammAdapter = IAmmAdapter(_ammAdapter);
    }

    /// @notice Allows voting executor to change the liquidity incentives.
    function setLiquidityIncentives(address _liquidityIncentives) external onlyOwner {
        if (_liquidityIncentives == liquidityIncentives) {
            return;
        }
        emit LiquidityIncentivesChanged(liquidityIncentives, _liquidityIncentives);
        liquidityIncentives = _liquidityIncentives;
    }

    /// @notice Returns the amount of asset required to provide a given stableAmount. Also
    /// returns the number of liquidity tokens that currently would be minted for the stableAmount and assetAmount.
    /// @param stableAmount The amount of stable tokens the user wants to supply.
    function getLiquidityTokenAmount(int256 stableAmount)
        external
        view
        returns (int256 assetAmount, int256 liquidityTokenAmount)
    {
        (liquidityTokenAmount, , assetAmount) = calculateAddLiquidityAmounts(stableAmount);
    }

    /// @notice Returns the amounts of stable and asset the given amount of liquidity token owns.
    function getLiquidityValue(int256 liquidityTokenAmount)
        external
        view
        returns (int256 assetAmount, int256 stableAmount)
    {
        return getLiquidityValueInternal(liquidityTokenAmount, oracle.getPrice(assetToken));
    }

    /// @notice Returns the number of liquidity token amount that can be redeemed given current AMM positions.
    /// Since the AMM actively uses liquidity to swap with spot markets, the amount of remaining asset or stable tokens
    /// is potentially less than originally provided by LPs. Therefore, not 100% shares are redeemable at any point in
    /// time.
    function getRedeemableLiquidityTokenAmount() external view returns (int256) {
        int256 totalShares = FsMath.safeCastToSigned(liquidityToken.totalSupply());
        (int256 ammStable, int256 ammAsset) = ammBalance(oracle.getPrice(assetToken));
        int256 maxSharesForAsset =
            calculateMaxShares(ammAsset, vaultBalance(assetToken), totalShares);
        int256 maxSharesForStable =
            calculateMaxShares(ammStable, vaultBalance(stableToken), totalShares);
        return FsMath.min(maxSharesForAsset, maxSharesForStable);
    }

    function calculateMaxShares(
        int256 totalTokens,
        int256 availableTokens,
        int256 totalShares
    ) private pure returns (int256) {
        if (totalTokens <= availableTokens) {
            // Pool owns less than the available tokens, so all shares can be redeemed.
            return totalShares;
        } else {
            // This branch implies totalTokens > availableTokens and thus totalTokens is not-zero
            return (totalShares * availableTokens) / totalTokens;
        }
    }

    /// @notice Returns the asset and stable amounts, excluding fees, that the LP is entitled to for the specified
    /// amount of liquidity token.
    function calculateRemoveLiquidityAmounts(int256 _liquidityTokenAmount, int256 price)
        private
        view
        returns (int256 assetAmountSubFee, int256 stableAmountSubFee)
    {
        (int256 assetAmount, int256 stableAmount) =
            getLiquidityValueInternal(_liquidityTokenAmount, price);

        int256 remainingPortionAfterFee = FsMath.FIXED_POINT_BASED - ammConfig.removeLiquidityFee;
        assetAmountSubFee = (assetAmount * remainingPortionAfterFee) / FsMath.FIXED_POINT_BASED;
        stableAmountSubFee = (stableAmount * remainingPortionAfterFee) / FsMath.FIXED_POINT_BASED;
    }

    /// @notice Compute the amounts of stables/assets a given amount of LP token is worth. Allowing passing price in for
    /// gas saving (so that upstream functions only need to get oracle price once).
    function getLiquidityValueInternal(int256 liquidityTokenAmount, int256 price)
        private
        view
        returns (int256 assetAmount, int256 stableAmount)
    {
        int256 totalLPTokenSupply = FsMath.safeCastToSigned(liquidityToken.totalSupply());
        // Avoid division by 0. If there has been no liquidity added, LP tokens are worth nothing although unless
        // something went wrong somewhere, there should be LP tokens in circulation if there's been no liquidity added.
        if (totalLPTokenSupply == 0) {
            return (0, 0);
        }

        (int256 originalStableLiquidity, int256 originalAssetLiquidity) = ammBalance(price);
        assetAmount = (originalAssetLiquidity * liquidityTokenAmount) / totalLPTokenSupply;
        stableAmount = (originalStableLiquidity * liquidityTokenAmount) / totalLPTokenSupply;
    }

    /// @notice Request payment from msg.sender to add liquidity.
    function handleLiquidityPayment(
        address provider,
        int256 assetAmount,
        int256 stableAmount,
        int256 liquidityTokenAmount
    ) private {
        // Collect payments from msg.sender directly. We might potentially receive fewer tokens if there's a transfer
        // fee but this is alright for now as we'll control which tokens we support.
        handlePayment(provider, assetToken, assetAmount);
        handlePayment(provider, stableToken, stableAmount);

        // Mint the liquidity provider the liquidity token.
        // This should be done after payment to prevent reentrancy attacks.
        liquidityToken.mint(FsMath.safeCastToUnsigned(liquidityTokenAmount));

        //slither-disable-next-line uninitialized-local
        IStakingIncentives.StakingDeposit memory sd;
        sd.account = provider;

        // Send the newly minted LP tokens to the incentives contract for "forced" staking. LPs will be able to interact
        // with the LP incentives contract for token withdrawal/rewards.
        require(
            IERC677Token(liquidityToken).transferAndCall(
                liquidityIncentives,
                FsMath.safeCastToUnsigned(liquidityTokenAmount),
                abi.encode(sd)
            ),
            "TransferAndCall failed"
        );
    }

    /// @notice Takes payments from the caller for a specified amount. Raw ETH is accepted if the payment token is
    /// weth.
    function handlePayment(
        address provider,
        address token,
        int256 _amount
    ) private {
        uint256 amount = FsMath.safeCastToUnsigned(_amount);
        address vaultAddress = address(tokenVault);
        if (token == wethToken && msg.value > 0) {
            // There's no risk of collecting msg.value multiple times here because:
            // (1) Stable and asset tokens cannot be the same token so they can't both be weth.
            // (2) We wrap ETH into WETH using this contract's balance. This contract never has remaining balance
            // after a transaction as all funds are sent to the vault so if for some reason handlePayment is called
            // more than once, wrapping would fail.
            uint256 msgValue = msg.value;
            require(msgValue == amount, "msg.value doesn't match deltaStable");
            IWETH9(wethToken).deposit{ value: msgValue }();
            IERC20(wethToken).safeTransfer(vaultAddress, msgValue);
        } else {
            IERC20(token).safeTransferFrom(provider, vaultAddress, amount);
        }
    }

    /// @notice Pay the recipient a specified amount. Can pay in raw ETH if token is WETH and ETH payment is requested.
    function pay(
        address recipient,
        address token,
        int256 _amount,
        bool useEth
    ) private {
        uint256 amount = FsMath.safeCastToUnsigned(_amount);
        if (token == wethToken && useEth) {
            // Need to transfer WETH to this contract for unwrapping.
            tokenVault.transfer(address(this), wethToken, amount);
            IWETH9(wethToken).withdraw(amount);
            Address.sendValue(payable(recipient), amount);
        } else {
            tokenVault.transfer(recipient, token, amount);
        }
    }

    /// @notice Returns the asset amount to pair with the given stable amount to provide liquidity, the current total
    /// amount of LP shares (LP tokens), and the number of shares the LP would get by providing the given liquidity
    /// amount.
    function calculateAddLiquidityAmounts(int256 stableAmount)
        private
        view
        returns (
            int256 liquidityTokens,
            int256 totalLiquidityShares,
            int256 assetAmount
        )
    {
        int256 assetPrice = oracle.getPrice(assetToken);
        assetAmount = FsMath.stableToAsset(stableAmount, assetPrice);
        totalLiquidityShares = FsMath.safeCastToSigned(liquidityToken.totalSupply());

        if (totalLiquidityShares == 0) {
            // No existing liquidity so these are first shares we're minting.
            liquidityTokens = stableAmount;
        } else {
            int256 totalOriginalLiquidityValue = getOriginalLiquidityValue(assetPrice);
            require(totalOriginalLiquidityValue > 0, "Pool bankrupt");
            // Liquidity provider provides equal value of stable and asset token. Hence 2 * stableAmount is the
            // liquidity added to the pool.
            liquidityTokens =
                (2 * stableAmount * totalLiquidityShares) /
                totalOriginalLiquidityValue;
        }
    }

    /// @notice Returns the total value the original liquidity valued in stable token that this AMM got from LPs given
    /// the asset's price (in stable)
    function getOriginalLiquidityValue(int256 assetPrice) private view returns (int256) {
        (int256 stable, int256 asset) = ammBalance(assetPrice);
        return stable + FsMath.assetToStable(asset, assetPrice);
    }

    /// @notice Returns the AMM's balance of the stable / asset tokens in the vault.
    function ammBalance(int256 price)
        public
        view
        returns (int256 ammStableBalance, int256 ammAssetBalance)
    {
        (int256 ammStablePositionOnExchange, int256 ammAssetPositionOnExchange) =
            exchangeLedger.getAmmPosition(price, block.timestamp);
        // AMM's collateral includes its position on the external spot market which should net out against its stable
        // position on the internal Futureswap exchange to equal the fees (trade and time fees) the AMM has received
        // from traders. This is then added on top of the original liquidity added to get the total amount of stable
        // the AMM owns.
        ammStableBalance = collateral + ammStablePositionOnExchange;
        ammAssetBalance = vaultBalance(assetToken) + ammAssetPositionOnExchange;
    }

    /// @notice Returns the balance of the vault in specified tokens as an int256 for calculation convenience.
    function vaultBalance(address token) private view returns (int256) {
        return FsMath.safeCastToSigned(IERC20(token).balanceOf(address(tokenVault)));
    }

    /// @notice Check that there's enough liquidity left in the vault.
    /// vaultAssetBalance is only passed in to save gas as this function can technically recompute it easily.
    function requireEnoughLiquidityLeft(
        bool isClosingTraderPosition,
        int256 totalValue,
        int256 vaultAssetBalance,
        int256 assetPrice
    ) private view {
        // Skipping liquidity check if the trade is for closing a position. This avoids the system getting completely
        // stuck because low liquidity (e.g. LPs withdrawing too much liquidity).
        if (isClosingTraderPosition) {
            return;
        }

        int256 requiredReserves =
            (totalValue * ammConfig.tradeLiquidityReserveFactor) / FsMath.FIXED_POINT_BASED;
        require(requiredReserves >= 0, "Invalid required reserve value");

        // The amount of available AMM stable and asset balances that can be used to continue its market neutral
        // strategy.
        int256 availableAmmStable = collateral;
        int256 availableAmmAsset = FsMath.assetToStable(vaultAssetBalance, assetPrice);
        require(availableAmmStable >= requiredReserves, "Stable balance below required reserves");
        require(availableAmmAsset >= requiredReserves, "Asset balance below required reserves");
    }
}