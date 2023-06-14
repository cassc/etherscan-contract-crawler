pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "./lib/SafeUInt128.sol";
import "./lib/SafeInt256.sol";
import "./lib/ABDKMath64x64.sol";
import "./lib/SafeMath.sol";

import "./utils/Governed.sol";
import "./utils/Common.sol";

import "@openzeppelin/contracts/utils/SafeCast.sol";

/**
 * @title CashMarket
 * @notice Marketplace for trading cash to fCash tokens. Implements a specialized AMM for trading such assets.
 */
contract CashMarket is Governed {
    using SafeUInt128 for uint128;
    using SafeMath for uint256;
    using SafeInt256 for int256;

    // This is used in _tradeCalculation to shift the ln calculation
    int128 internal constant PRECISION_64x64 = 0x3b9aca000000000000000000;
    uint256 internal constant MAX64 = 0x7FFFFFFFFFFFFFFF;
    int64 internal constant LN_1E18 = 0x09a667e259;
    bool internal constant CHECK_FC = true;
    bool internal constant DEFER_CHECK = false;

    /**
     * @dev skip
     */
    function initializeDependencies() external {
        // Setting dependencies can only be done once here. With proxy contracts the addresses shouldn't
        // change as we upgrade the logic.
        Governed.CoreContracts[] memory dependencies = new Governed.CoreContracts[](3);
        dependencies[0] = CoreContracts.Escrow;
        dependencies[1] = CoreContracts.Portfolios;
        dependencies[2] = CoreContracts.ERC1155Trade;
        _setDependencies(dependencies);
    }

    // Defines the fields for each market in each maturity.
    struct Market {
        // Total amount of fCash available for purchase in the market.
        uint128 totalfCash;
        // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
        uint128 totalLiquidity;
        // Total amount of cash available for purchase in the market.
        uint128 totalCurrentCash;
        // These factors are set when the market is instantiated by a liquidity provider via the global
        // settings and then held constant for the duration of the maturity. We cannot change them without
        // really messing up the market rates.
        uint16 rateScalar;
        uint32 rateAnchor;
        // This is the implied rate that we use to smooth the anchor rate between trades.
        uint32 lastImpliedRate;
    }

    // This is a mapping between a maturity and its corresponding market.
    mapping(uint32 => Market) public markets;

    /********** Governance Parameters *********************/

    // These next parameters are set by the Portfolios contract and are immutable, except for G_NUM_MATURITIES
    uint8 public CASH_GROUP;
    uint32 internal constant INSTRUMENT_PRECISION = 1e9;
    uint32 public G_MATURITY_LENGTH;
    uint32 public G_NUM_MATURITIES;

    // These are governance parameters for the market itself and can be set by the owner.

    // The maximum trade size denominated in local currency
    uint128 public G_MAX_TRADE_SIZE;

    // The y-axis shift of the rate curve
    uint32 public G_RATE_ANCHOR;
    // The slope of the rate curve
    uint16 public G_RATE_SCALAR;
    // The fee in basis points given to liquidity providers
    uint32 public G_LIQUIDITY_FEE;
    // The fee as a percentage of the cash traded given to the protocol
    uint128 public G_TRANSACTION_FEE;

    /**
     * @notice Sets governance parameters on the rate oracle.
     * @dev skip
     * @param cashGroupId this cannot change once set
     * @param precision will only take effect on a new maturity
     * @param maturityLength will take effect immediately, must be careful
     * @param numMaturities will take effect immediately, makers can create new markets
     */
    function setParameters(
        uint8 cashGroupId,
        uint16 /* instrumentId */,
        uint32 precision,
        uint32 maturityLength,
        uint32 numMaturities,
        uint32 /* maxRate */
    ) external {
        require(calledByPortfolios(), "20");

        // These values cannot be reset once set.
        if (CASH_GROUP == 0) {
            CASH_GROUP = cashGroupId;
        }

        require(precision == 1e9, "51");
        G_MATURITY_LENGTH = maturityLength;
        G_NUM_MATURITIES = numMaturities;
    }

    /**
     * @notice Sets rate factors that will determine the liquidity curve. Rate Anchor is set as the target annualized exchange
     * rate so 1.10 * INSTRUMENT_PRECISION represents a target annualized rate of 10%. Rate anchor will be scaled accordingly
     * when a fCash market is initialized. As a general default, INSTRUMENT_PRECISION will be set to 1e9.
     * @dev governance
     * @param rateAnchor the offset of the liquidity curve
     * @param rateScalar the sensitivity of the liquidity curve to changes
     */
    function setRateFactors(uint32 rateAnchor, uint16 rateScalar) external onlyOwner {
        require(rateScalar > 0 && rateAnchor > 0, "14");
        G_RATE_SCALAR = rateScalar;
        G_RATE_ANCHOR = rateAnchor;

        emit UpdateRateFactors(rateAnchor, rateScalar);
    }

    /**
     * @notice Sets the maximum amount that can be traded in a single trade.
     * @dev governance
     * @param amount the max trade size
     */
    function setMaxTradeSize(uint128 amount) external onlyOwner {
        G_MAX_TRADE_SIZE = amount;

        emit UpdateMaxTradeSize(amount);
    }

    /**
     * @notice Sets fee parameters for the market. Liquidity Fees are set as basis points and shift the traded
     * exchange rate. A basis point is the equivalent of 1e5 if INSTRUMENT_PRECISION is set to 1e9.
     * Transaction fees are set as a percentage shifted by 1e18. For example a 1% transaction fee will be set
     * as 1.01e18.
     * @dev governance
     * @param liquidityFee a change in the traded exchange rate paid to liquidity providers
     * @param transactionFee percentage of a transaction that accrues to the reserve account
     */
    function setFee(uint32 liquidityFee, uint128 transactionFee) external onlyOwner {
        G_LIQUIDITY_FEE = liquidityFee;
        G_TRANSACTION_FEE = transactionFee;

        emit UpdateFees(liquidityFee, transactionFee);
    }

    /********** Governance Parameters *********************/

    /********** Events ************************************/
    /**
     * @notice Emitted when rate factors are updated, will take effect at the next maturity
     * @param rateAnchor the new rate anchor
     * @param rateScalar the new rate scalar
     */
    event UpdateRateFactors(uint32 rateAnchor, uint16 rateScalar);

    /**
     * @notice Emitted when max trade size is updated, takes effect immediately
     * @param maxTradeSize the new max trade size
     */
    event UpdateMaxTradeSize(uint128 maxTradeSize);

    /**
     * @notice Emitted when fees are updated, takes effect immediately
     * @param liquidityFee the new liquidity fee
     * @param transactionFee the new transaction fee
     */
    event UpdateFees(uint32 liquidityFee, uint128 transactionFee);

    /**
     * @notice Emitted when liquidity is added to a maturity
     * @param account the account that performed the trade
     * @param maturity the maturity that this trade affects
     * @param tokens amount of liquidity tokens issued
     * @param fCash amount of fCash tokens added
     * @param cash amount of cash tokens added
     */
    event AddLiquidity(
        address indexed account,
        uint32 maturity,
        uint128 tokens,
        uint128 fCash,
        uint128 cash
    );

    /**
     * @notice Emitted when liquidity is removed from a maturity
     * @param account the account that performed the trade
     * @param maturity the maturity that this trade affects
     * @param tokens amount of liquidity tokens burned
     * @param fCash amount of fCash tokens removed
     * @param cash amount of cash tokens removed
     */
    event RemoveLiquidity(
        address indexed account,
        uint32 maturity,
        uint128 tokens,
        uint128 fCash,
        uint128 cash
    );

    /**
     * @notice Emitted when cash is taken from a maturity
     * @param account the account that performed the trade
     * @param maturity the maturity that this trade affects
     * @param fCash amount of fCash tokens added
     * @param cash amount of cash tokens removed
     * @param fee amount of transaction fee charged
     */
    event TakeCurrentCash(address indexed account, uint32 maturity, uint128 fCash, uint128 cash, uint128 fee);

    /**
     * @notice Emitted when fCash is taken from a maturity
     * @param account the account that performed the trade
     * @param maturity the maturity that this trade affects
     * @param fCash amount of fCash tokens removed
     * @param cash amount of cash tokens added
     * @param fee amount of transaction fee charged
     */
    event TakefCash(address indexed account, uint32 maturity, uint128 fCash, uint128 cash, uint128 fee);

    /********** Events ************************************/

    /********** Liquidity Tokens **************************/

    /**
     * @notice Adds some amount of cash to the liquidity pool up to the corresponding amount defined by
     * `maxfCash`. Mints liquidity tokens back to the sender.
     * @dev - TRADE_FAILED_MAX_TIME: maturity specified is not yet active
     * - MARKET_INACTIVE: maturity is not a valid one
     * - OVER_MAX_FCASH: fCash amount required exceeds supplied maxfCash
     * - OUT_OF_IMPLIED_RATE_BOUNDS: depositing cash would require more fCash than specified
     * - INSUFFICIENT_BALANCE: insufficient cash to deposit into market
     * @param maturity the maturity to add liquidity to
     * @param cash the amount of cash to add to the pool
     * @param maxfCash the max amount of fCash to add to the pool. When initializing a pool this is the
     * amount of fCash that will be added.
     * @param minImpliedRate the minimum implied rate that we will add liquidity at
     * @param maxImpliedRate the maximum implied rate that we will add liquidity at
     * @param maxTime after this time the trade will fail
     */
    function addLiquidity(
        uint32 maturity,
        uint128 cash,
        uint128 maxfCash,
        uint32 minImpliedRate,
        uint32 maxImpliedRate,
        uint32 maxTime
    ) external {
        Common.Asset[] memory assets = _addLiquidity(
            msg.sender,
            maturity,
            cash,
            maxfCash,
            minImpliedRate,
            maxImpliedRate,
            maxTime
        );

        // This will do a free collateral check before it adds to the portfolio.
        Portfolios().upsertAccountAssetBatch(msg.sender, assets, CHECK_FC);
    }

    /**
     * @notice Used by ERC1155 contract to add liquidity
     * @dev skip
     */
    function addLiquidityOnBehalf(
        address account,
        uint32 maturity,
        uint128 cash,
        uint128 maxfCash,
        uint32 minImpliedRate,
        uint32 maxImpliedRate
    ) external {
        require(calledByERC1155Trade(), "20");

        Common.Asset[] memory assets = _addLiquidity(
            account,
            maturity,
            cash,
            maxfCash,
            minImpliedRate,
            maxImpliedRate,
            uint32(block.timestamp)
        );

        Portfolios().upsertAccountAssetBatch(account, assets, DEFER_CHECK);
    }

    function _addLiquidity(
        address account,
        uint32 maturity,
        uint128 cash,
        uint128 maxfCash,
        uint32 minImpliedRate,
        uint32 maxImpliedRate,
        uint32 maxTime
    ) internal returns (Common.Asset[] memory) {
        _isValidBlock(maturity, maxTime);
        uint32 timeToMaturity = maturity - uint32(block.timestamp);
        Market memory market = markets[maturity];

        uint128 fCash;
        uint128 liquidityTokenAmount;
        if (market.totalLiquidity == 0) {
            // We check the rateScalar to determine if the market exists or not. The reason for this is that once we
            // initialize a market we will set the rateScalar and rateAnchor based on global values for the duration
            // of the market. The proportion of fCash to cash that the first liquidity provider sets here will
            // determine the initial exchange rate of the market (taking into account rateScalar and rateAnchor, of course).
            // Governance will never allow rateScalar to be set to 0.
            if (market.rateScalar == 0) {
                market.rateScalar = G_RATE_SCALAR;
            }

            // G_RATE_ANCHOR is stored as the annualized rate. Here we normalize it to the rate that is required given the
            // time to maturity. (RATE_ANCHOR - 1) * timeToMaturity / SECONDS_IN_YEAR + 1
            market.rateAnchor = SafeCast.toUint32(
                uint256(G_RATE_ANCHOR)
                    .sub(INSTRUMENT_PRECISION)
                    .mul(timeToMaturity)
                    .div(Common.SECONDS_IN_YEAR)
                    .add(INSTRUMENT_PRECISION)
            );

            market.totalfCash = maxfCash;
            market.totalCurrentCash = cash;
            market.totalLiquidity = cash;
            // We have to initialize this to the exchange rate implied by the proportion of cash to fCash.
            uint32 impliedRate = _getImpliedRateRequire(market, timeToMaturity);
            require(minImpliedRate <= maxImpliedRate 
                && minImpliedRate <= impliedRate && impliedRate <= maxImpliedRate,
                "31"
            );
            market.lastImpliedRate = impliedRate;

            liquidityTokenAmount = cash;
            fCash = maxfCash;
        } else {
            // We calculate the amount of liquidity tokens to mint based on the share of the fCash
            // that the liquidity provider is depositing.
            liquidityTokenAmount = SafeCast.toUint128(
                uint256(market.totalLiquidity).mul(cash).div(market.totalCurrentCash)
            );

            // We use the prevailing proportion to calculate the required amount of current cash to deposit.
            fCash = SafeCast.toUint128(uint256(market.totalfCash).mul(cash).div(market.totalCurrentCash));
            require(fCash <= maxfCash, "43");

            // Add the fCash and cash to the pool.
            market.totalfCash = market.totalfCash.add(fCash);
            market.totalCurrentCash = market.totalCurrentCash.add(cash);
            market.totalLiquidity = market.totalLiquidity.add(liquidityTokenAmount);

            // If this proportion has moved beyond what the liquidity provider is willing to pay then we
            // will revert here. The implied rate will not change when liquidity is added.
            require(minImpliedRate <= maxImpliedRate 
                && minImpliedRate <= market.lastImpliedRate && market.lastImpliedRate <= maxImpliedRate,
                "31"
            );

        }

        markets[maturity] = market;

        // Move the cash into the contract's cash balances account. This must happen before the trade
        // is placed so that the free collateral check is correct.
        Escrow().depositIntoMarket(account, CASH_GROUP, cash, 0);

        // Providing liquidity results in two tokens generated, a liquidity token and a CASH_PAYER which
        // represents the obligation that offsets the fCash in the market.
        Common.Asset[] memory assets = new Common.Asset[](2);
        // This is the liquidity token
        assets[0] = Common.Asset(
            CASH_GROUP,
            0,
            maturity,
            Common.getLiquidityToken(),
            0,
            liquidityTokenAmount
        );

        // This is the CASH_PAYER
        assets[1] = Common.Asset(
            CASH_GROUP,
            0,
            maturity,
            Common.getCashPayer(),
            0,
            fCash
        );

        emit AddLiquidity(account, maturity, liquidityTokenAmount, fCash, cash);

        return assets;
    }

    /**
     * @notice Removes liquidity from the fCash market. The sender's liquidity tokens are burned and they
     * are credited back with fCash and cash at the prevailing exchange rate. This function
     * only works when removing liquidity from an active market. For markets that are matured, the sender
     * must settle their liquidity token via `Portfolios.settleMaturedAssets`.
     * @dev - TRADE_FAILED_MAX_TIME: maturity specified is not yet active
     * - MARKET_INACTIVE: maturity is not a valid one
     * - INSUFFICIENT_BALANCE: account does not have sufficient tokens to remove
     * @param maturity the maturity to remove liquidity from
     * @param amount the amount of liquidity tokens to burn
     * @param maxTime after this block the trade will fail
     * @return the amount of cash claim the removed liquidity tokens have
     */
    function removeLiquidity(
        uint32 maturity,
        uint128 amount,
        uint32 maxTime
    ) external returns (uint128) {
        (Common.Asset[] memory assets, uint128 cash) = _removeLiquidity(
            msg.sender,
            maturity,
            amount,
            maxTime
        );

        // This function call will check if the account in question actually has
        // enough liquidity tokens to remove.
        Portfolios().upsertAccountAssetBatch(msg.sender, assets, CHECK_FC);

        return cash;
    }

    /**
     * @notice Used by ERC1155 contract to remove liquidity
     * @dev skip
     */
    function removeLiquidityOnBehalf(
        address account,
        uint32 maturity,
        uint128 amount
    ) external returns (uint128) {
        require(calledByERC1155Trade(), "20");

        (Common.Asset[] memory assets, uint128 cash) = _removeLiquidity(
            account,
            maturity,
            amount,
            uint32(block.timestamp)
        );

        Portfolios().upsertAccountAssetBatch(account, assets, DEFER_CHECK);

        return cash;
    }

    function _removeLiquidity(
        address account,
        uint32 maturity,
        uint128 amount,
        uint32 maxTime
    ) internal returns (Common.Asset[] memory, uint128) {
        // This method only works when the market is active.
        uint32 blockTime = uint32(block.timestamp);
        require(blockTime <= maxTime, "18");
        require(blockTime < maturity, "3");

        Market memory market = markets[maturity];

        // Here we calculate the amount of current cash that the liquidity token represents.
        uint128 cash = SafeCast.toUint128(uint256(market.totalCurrentCash).mul(amount).div(market.totalLiquidity));
        market.totalCurrentCash = market.totalCurrentCash.sub(cash);

        // This is the amount of fCash that the liquidity token has a claim to.
        uint128 fCashAmount = SafeCast.toUint128(uint256(market.totalfCash).mul(amount).div(market.totalLiquidity));
        market.totalfCash = market.totalfCash.sub(fCashAmount);

        // We do this calculation after the previous two so that we do not mess with the totalLiquidity
        // figure when calculating fCash and cash.
        market.totalLiquidity = market.totalLiquidity.sub(amount);

        markets[maturity] = market;

        // Move the cash from the contract's cash balances account back to the sender. This must happen
        // before the free collateral check in the Portfolio call below.
        Escrow().withdrawFromMarket(account, CASH_GROUP, cash, 0);

        Common.Asset[] memory assets = new Common.Asset[](2);
        // This will remove the liquidity tokens
        assets[0] = Common.Asset(
            CASH_GROUP,
            0,
            maturity,
            // We mark this as a "PAYER" liquidity token so the portfolio reduces the balance
            Common.makeCounterparty(Common.getLiquidityToken()),
            0,
            amount
        );

        // This is the CASH_RECEIVER
        assets[1] = Common.Asset(
            CASH_GROUP,
            0,
            maturity,
            Common.getCashReceiver(),
            0,
            fCashAmount
        );

        emit RemoveLiquidity(account, maturity, amount, fCashAmount, cash);
        return (assets, cash);
    }

    /**
     * @notice Settles a liquidity token into fCash and cash. Can only be called by the Portfolios contract.
     * @dev skip
     * @param account the account that is holding the token
     * @param tokenAmount the amount of token to settle
     * @param maturity when the token matures
     * @return the amount of cash to settle to the account
     */
    function settleLiquidityToken(
        address account,
        uint128 tokenAmount,
        uint32 maturity
    ) external returns (uint128) {
        require(calledByPortfolios(), "20");

        (uint128 cash, uint128 fCash) = _settleLiquidityToken(tokenAmount, maturity);

        // Move the cash from the contract's cash balances account back to the sender
        Escrow().withdrawFromMarket(account, CASH_GROUP, cash, 0);

        // No need to remove the liquidity token from the portfolio, the calling function will take care of this.

        // The liquidity token carries with it an obligation to pay a certain amount of fCash and we credit that
        // amount plus any appreciation here. This amount will be added to the cashBalances for the account to offset
        // the CASH_PAYER token that was created when the liquidity token was minted.
        return fCash;
    }

    /**
     * @notice Internal method for settling liquidity tokens, calculates the values for cash and fCash
     *
     * @param tokenAmount the amount of token to settle
     * @param maturity when the token matures
     * @return the amount of cash and fCash
     */
    function _settleLiquidityToken(uint128 tokenAmount, uint32 maturity) internal returns (uint128, uint128) {
        Market memory market = markets[maturity];

        // Here we calculate the amount of cash that the liquidity token represents.
        uint128 cash = SafeCast.toUint128(uint256(market.totalCurrentCash).mul(tokenAmount).div(market.totalLiquidity));
        market.totalCurrentCash = market.totalCurrentCash.sub(cash);

        // This is the amount of fCash that the liquidity token has a claim to.
        uint128 fCash = SafeCast.toUint128(uint256(market.totalfCash).mul(tokenAmount).div(market.totalLiquidity));
        market.totalfCash = market.totalfCash.sub(fCash);

        // We do this calculation after the previous two so that we do not mess with the totalLiquidity
        // figure when calculating fCash and cash.
        market.totalLiquidity = market.totalLiquidity.sub(tokenAmount);

        markets[maturity] = market;

        return (cash, fCash);
    }

    /********** Liquidity Tokens **************************/

    /********** Trading Cash ******************************/

    /**
     * @notice Given the amount of fCash put into a market, how much cash this would
     * purchase at the current block.
     * @param maturity the maturity of the fCash
     * @param fCashAmount the amount of fCash to input
     * @return the amount of cash this would purchase, returns 0 if the trade will fail
     */
    function getfCashToCurrentCash(uint32 maturity, uint128 fCashAmount) public view returns (uint128) {
        return getfCashToCurrentCashAtTime(maturity, fCashAmount, uint32(block.timestamp));
    }

    /**
     * @notice Given the amount of fCash put into a market, how much cash this would
     * purchase at the given time. fCash exchange rates change as we go towards maturity.
     * @dev - CANNOT_GET_PRICE_FOR_MATURITY: can only get prices before the maturity
     * @param maturity the maturity of the fCash
     * @param fCashAmount the amount of fCash to input
     * @param blockTime the specified block time
     * @return the amount of cash this would purchase, returns 0 if the trade will fail
     */
    function getfCashToCurrentCashAtTime(
        uint32 maturity,
        uint128 fCashAmount,
        uint32 blockTime
    ) public view returns (uint128) {
        Market memory interimMarket = markets[maturity];
        require(blockTime < maturity, "41");

        uint32 timeToMaturity = maturity - blockTime;

        ( /* market */, uint128 cash) = _tradeCalculation(interimMarket, int256(fCashAmount), timeToMaturity);
        // On trade failure, we will simply return 0
        uint128 fee = _calculateTransactionFee(cash, timeToMaturity);
        return cash.sub(fee);
    }

    /**
     * @notice Receive cash in exchange for a fCash obligation. Equivalent to borrowing
     * cash at a fixed rate.
     * @dev - TRADE_FAILED_MAX_TIME: maturity specified is not yet active
     * - MARKET_INACTIVE: maturity is not a valid one
     * - TRADE_FAILED_TOO_LARGE: trade is larger than allowed by the governance settings
     * - TRADE_FAILED_LACK_OF_LIQUIDITY: there is insufficient liquidity in this maturity to handle the trade
     * - TRADE_FAILED_SLIPPAGE: trade is greater than the max implied rate set
     * - INSUFFICIENT_FREE_COLLATERAL: insufficient free collateral to take on the debt
     * @param maturity the maturity of the fCash being exchanged for current cash
     * @param fCashAmount the amount of fCash to sell, will convert this amount to current cash
     *  at the prevailing exchange rate.
     * @param maxTime after this time the trade will not settle
     * @param maxImpliedRate the maximum implied maturity rate that the borrower will accept
     * @return the amount of cash purchased, `fCashAmount - cash` determines the fixed interested owed.
     */
    function takeCurrentCash(
        uint32 maturity,
        uint128 fCashAmount,
        uint32 maxTime,
        uint32 maxImpliedRate
    ) external returns (uint128) {
        (Common.Asset memory asset, uint128 cash) = _takeCurrentCash(
            msg.sender,
            maturity,
            fCashAmount,
            maxTime,
            maxImpliedRate
        );

        // This will do a free collateral check before it adds to the portfolio.
        Portfolios().upsertAccountAsset(msg.sender, asset, CHECK_FC);

        return cash;
    }

    /**
     * @notice Used by ERC1155 contract to take cash
     * @dev skip
     */
    function takeCurrentCashOnBehalf(
        address account,
        uint32 maturity,
        uint128 fCashAmount,
        uint32 maxImpliedRate
    ) external returns (uint128) {
        require(calledByERC1155Trade(), "20");

        (Common.Asset memory asset, uint128 cash) = _takeCurrentCash(
            account,
            maturity,
            fCashAmount,
            uint32(block.timestamp),
            maxImpliedRate
        );

        Portfolios().upsertAccountAsset(account, asset, DEFER_CHECK);

        return cash;
    }

    function _takeCurrentCash(
        address account,
        uint32 maturity,
        uint128 fCashAmount,
        uint32 maxTime,
        uint32 maxImpliedRate
    ) internal returns (Common.Asset memory, uint128) {
        _isValidBlock(maturity, maxTime);
        require(fCashAmount <= G_MAX_TRADE_SIZE, "16");

        uint128 cash = _updateMarket(maturity, int256(fCashAmount));
        require(cash > 0, "15");

        uint32 timeToMaturity = maturity - uint32(block.timestamp);
        uint128 fee = _calculateTransactionFee(cash, timeToMaturity);
        uint32 impliedRate = _calculateImpliedRate(cash.sub(fee), fCashAmount, timeToMaturity);
        require(impliedRate <= maxImpliedRate, "17");

        // Move the cash from the contract's cash balances account to the sender. This must happen before
        // the call to insert the trade below in order for the free collateral check to work properly.
        Escrow().withdrawFromMarket(account, CASH_GROUP, cash, fee);

        // The sender now has an obligation to pay cash at maturity.
        Common.Asset memory asset = Common.Asset(
            CASH_GROUP,
            0,
            maturity,
            Common.getCashPayer(),
            0,
            fCashAmount
        );

        emit TakeCurrentCash(account, maturity, fCashAmount, cash, fee);

        return (asset, cash);
    }

    /**
     * @notice Given the amount of fCash to purchase, returns the amount of cash this would cost at the current
     * block.
     * @param maturity the maturity of the fCash
     * @param fCashAmount the amount of fCash to purchase
     * @return the amount of cash this would cost, returns 0 on trade failure
     */
    function getCurrentCashTofCash(uint32 maturity, uint128 fCashAmount) public view returns (uint128) {
        return getCurrentCashTofCashAtTime(maturity, fCashAmount, uint32(block.timestamp));
    }

    /**
     * @notice Given the amount of fCash to purchase, returns the amount of cash this would cost.
     * @dev - CANNOT_GET_PRICE_FOR_MATURITY: can only get prices before the maturity
     * @param maturity the maturity of the fCash
     * @param fCashAmount the amount of fCash to purchase
     * @param blockTime the time to calculate the price at
     * @return the amount of cash this would cost, returns 0 on trade failure
     */
    function getCurrentCashTofCashAtTime(
        uint32 maturity,
        uint128 fCashAmount,
        uint32 blockTime
    ) public view returns (uint128) {
        Market memory interimMarket = markets[maturity];
        require(blockTime < maturity, "41");

        uint32 timeToMaturity = maturity - blockTime;

        ( /* market */, uint128 cash) = _tradeCalculation(interimMarket, int256(fCashAmount).neg(), timeToMaturity);
        uint128 fee = _calculateTransactionFee(cash, timeToMaturity);
        // On trade failure, we will simply return 0
        return cash.add(fee);
    }

    /**
     * @notice Deposit cash in return for the right to receive cash at the specified maturity. Equivalent to lending
     * cash at a fixed rate.
     * @dev - TRADE_FAILED_MAX_TIME: maturity specified is not yet active
     * - MARKET_INACTIVE: maturity is not a valid one
     * - TRADE_FAILED_TOO_LARGE: trade is larger than allowed by the governance settings
     * - TRADE_FAILED_LACK_OF_LIQUIDITY: there is insufficient liquidity in this maturity to handle the trade
     * - TRADE_FAILED_SLIPPAGE: trade is lower than the min implied rate set
     * - INSUFFICIENT_BALANCE: not enough cash to complete this trade
     * @param maturity the maturity to receive fCash in
     * @param fCashAmount the amount of fCash to purchase
     * @param maxTime after this time the trade will not settle
     * @param minImpliedRate the minimum implied rate that the lender will accept
     * @return the amount of cash deposited to the market, `fCashAmount - cash` is the interest to be received
     */
    function takefCash(
        uint32 maturity,
        uint128 fCashAmount,
        uint32 maxTime,
        uint128 minImpliedRate
    ) external returns (uint128) {
        (Common.Asset memory asset, uint128 cash) = _takefCash(
            msg.sender,
            maturity,
            fCashAmount,
            maxTime,
            minImpliedRate
        );

        // This will do a free collateral check before it adds to the portfolio.
        Portfolios().upsertAccountAsset(msg.sender, asset, CHECK_FC);

        return cash;
    }

    /**
     * @notice Used by ERC1155 contract to take fCash
     * @dev skip
     */
    function takefCashOnBehalf(
        address account,
        uint32 maturity,
        uint128 fCashAmount,
        uint32 minImpliedRate
    ) external returns (uint128) {
        require(calledByERC1155Trade(), "20");

        (Common.Asset memory asset, uint128 cash) = _takefCash(
            account,
            maturity,
            fCashAmount,
            uint32(block.timestamp),
            minImpliedRate
        );

        Portfolios().upsertAccountAsset(account, asset, DEFER_CHECK);

        return cash;
    }

    function _takefCash(
        address account,
        uint32 maturity,
        uint128 fCashAmount,
        uint32 maxTime,
        uint128 minImpliedRate
    ) internal returns (Common.Asset memory, uint128) {
        _isValidBlock(maturity, maxTime);
        require(fCashAmount <= G_MAX_TRADE_SIZE, "16");

        uint128 cash = _updateMarket(maturity, int256(fCashAmount).neg());
        require(cash > 0, "15");

        uint32 timeToMaturity = maturity - uint32(block.timestamp);
        uint128 fee = _calculateTransactionFee(cash, timeToMaturity);

        uint32 impliedRate = _calculateImpliedRate(cash.add(fee), fCashAmount, timeToMaturity);
        require(impliedRate >= minImpliedRate, "17");

        // Move the cash from the sender to the contract address. This must happen before the
        // insert trade call below.
        Escrow().depositIntoMarket(account, CASH_GROUP, cash, fee);

        Common.Asset memory asset = Common.Asset(
            CASH_GROUP,
            0,
            maturity,
            Common.getCashReceiver(),
            0,
            fCashAmount
        );

        emit TakefCash(account, maturity, fCashAmount, cash, fee);

        return (asset, cash);
    }

    /********** Trading Cash ******************************/

    /********** Liquidation *******************************/

    /**
     * @notice Turns fCash tokens into a current cash. Used by portfolios when settling cash.
     * This method currently sells `maxfCash` every time since it's not possible to calculate the
     * amount of fCash to sell from `cashRequired`.
     * @dev skip
     * @param account that holds the fCash
     * @param cashRequired amount of cash that needs to be raised
     * @param maxfCash the maximum amount of fCash that can be sold
     * @param maturity the maturity of the fCash
     */
    function tradeCashReceiver(
        address account,
        uint128 cashRequired,
        uint128 maxfCash,
        uint32 maturity
    ) external returns (uint128) {
        require(calledByPortfolios(), "20");

        uint128 cash = _updateMarket(maturity, int256(maxfCash));

        // Here we've sold cash in excess of what was required, so we credit the remaining back
        // to the account that was holding the trade.
        if (cash > cashRequired) {
            Escrow().withdrawFromMarket(
                account,
                CASH_GROUP,
                cash - cashRequired,
                0
            );

            cash = cashRequired;
        }

        return cash;
    }

    /**
     * @notice Called by the portfolios contract when a liquidity token is being converted for cash.
     * @dev skip
     * @param cashRequired the amount of cash required
     * @param maxTokenAmount the max balance of tokens available
     * @param maturity when the token matures
     * @return the amount of cash raised, fCash raised, tokens removed
     */
    function tradeLiquidityToken(
        uint128 cashRequired,
        uint128 maxTokenAmount,
        uint32 maturity
    ) external returns (uint128, uint128, uint128) {
        require(calledByPortfolios(), "20");
        Market memory market = markets[maturity];

        // This is the total claim on cash that the tokens have.
        uint128 tokensToRemove = maxTokenAmount;
        uint128 cashAmount = SafeCast.toUint128(
            uint256(market.totalCurrentCash).mul(tokensToRemove).div(market.totalLiquidity)
        );

        if (cashAmount > cashRequired) {
            // If the total claim is greater than required, we only want to remove part of the liquidity.
            tokensToRemove = SafeCast.toUint128(
                uint256(cashRequired).mul(market.totalLiquidity).div(market.totalCurrentCash)
            );
            cashAmount = cashRequired;
        }

        // This method will credit the cashAmount back to the balances on the escrow contract.
        uint128 fCashAmount;
        (cashAmount, fCashAmount) = _settleLiquidityToken(tokensToRemove, maturity);

        return (cashAmount, fCashAmount, tokensToRemove);
    }

    /********** Liquidation *******************************/

    /********** Rate Methods ******************************/

    /**
     * @notice Returns the market object at the specified maturity
     * @param maturity the maturity of the market
     * @return A market object with these values:
     *  - `totalfCash`: total amount of fCash available at the maturity
     *  - `totalLiquidity`: total amount of liquidity tokens
     *  - `totalCurrentCash`: total amount of current cash available at maturity
     *  - `rateScalar`: determines the slippage rate during trading
     *  - `rateAnchor`: determines the base rate at market instantiation
     *  - `lastImpliedRate`: the last rate that the market traded at, used to smooth rates between periods of
     *     trading inactivity.
     */
    function getMarket(uint32 maturity) external view returns (Market memory) {
        return markets[maturity];
    }

    /**
     * @notice Returns the current mid exchange rate of cash to fCash. This is NOT the rate that users will be able to trade it, those
     * calculations depend on trade size and you must use the `getCurrentCashTofCash` or `getfCashToCurrentCash` methods.
     * @param maturity the maturity to get the rate for
     * @return a tuple where the first value is the exchange rate and the second value is a boolean indicating
     *  whether or not the maturity is active
     */
    function getRate(uint32 maturity) public view returns (uint32, bool) {
        Market memory market = markets[maturity];
        if (block.timestamp >= maturity) {
            // The exchange rate is 1 after we hit maturity for the fCash market.
            return (INSTRUMENT_PRECISION, true);
        } else {
            uint32 timeToMaturity = maturity - uint32(block.timestamp);
            bool success;
            uint32 rate;

            (market.rateAnchor, success) = _getNewRateAnchor(market, timeToMaturity);
            if (!success) revert("50");

            (rate, success) = _getExchangeRate(market, timeToMaturity, 0);
            if (!success) revert("50");

            return (rate, false);
        }
    }

    /**
     * @notice Gets the exchange rates for all the active markets.
     * @return an array of rates starting from the most current maturity to the furthest maturity
     */
    function getMarketRates() external view returns (uint32[] memory) {
        uint32[] memory marketRates = new uint32[](G_NUM_MATURITIES);
        uint32 maturity = uint32(block.timestamp) - (uint32(block.timestamp) % G_MATURITY_LENGTH) + G_MATURITY_LENGTH;
        for (uint256 i; i < marketRates.length; i++) {
            (uint32 rate, ) = getRate(maturity);
            marketRates[i] = rate;

            maturity = maturity + G_MATURITY_LENGTH;
        }

        return marketRates;
    }

    /**
     * @notice Gets the maturities for all the active markets.
     * @return an array of timestamps of the currently active maturities
     */
    function getActiveMaturities() external view returns (uint32[] memory) {
        uint32[] memory ids = new uint32[](G_NUM_MATURITIES);
        uint32 blockTime = uint32(block.timestamp);
        uint32 currentMaturity = blockTime - (blockTime % G_MATURITY_LENGTH) + G_MATURITY_LENGTH;
        for (uint256 i; i < ids.length; i++) {
            ids[i] = currentMaturity + uint32(i) * G_MATURITY_LENGTH;
        }
        return ids;
    }

    /*********** Internal Methods ********************/

    function _calculateTransactionFee(uint128 cash, uint32 timeToMaturity) internal view returns (uint128) {
        return SafeCast.toUint128(
            uint256(cash)
                .mul(G_TRANSACTION_FEE)
                .mul(timeToMaturity)
                .div(G_MATURITY_LENGTH)
                .div(Common.DECIMALS)
        );
    }

    function _updateMarket(uint32 maturity, int256 fCashAmount) internal returns (uint128) {
        Market memory interimMarket = markets[maturity];
        uint32 timeToMaturity = maturity - uint32(block.timestamp);
        uint128 cash;
        // Here we are selling fCash in return for cash
        (interimMarket, cash) = _tradeCalculation(interimMarket, fCashAmount, timeToMaturity);

        // Cash value of 0 signifies a failed trade
        if (cash > 0) {
            markets[maturity] = interimMarket;
        }

        return cash;
    }

    /**
     * @notice Checks if the maturity and max time supplied are valid. The requirements are:
     *  - blockTime <= maxTime < maturity <= maxMaturity
     *  - maturity % G_MATURITY_LENGTH == 0
     * Reverts if the block is not valid.
     */
    function _isValidBlock(uint32 maturity, uint32 maxTime) internal view returns (bool) {
        uint32 blockTime = uint32(block.timestamp);
        require(blockTime <= maxTime, "18");
        require(blockTime < maturity, "3");
        // If the number of maturitys is set to zero then we prevent all new trades.
        require(maturity % G_MATURITY_LENGTH == 0, "3");
        require(G_NUM_MATURITIES > 0, "3");

        uint32 maxMaturity = blockTime - (blockTime % G_MATURITY_LENGTH) + (G_MATURITY_LENGTH * G_NUM_MATURITIES);
        require(maturity <= maxMaturity, "3");
    }

    /**
     * @notice Does the trade calculation and returns the required objects for the contract methods to interpret.
     *
     * @param interimMarket the market to do the calculations over
     * @param fCashAmount the fCash amount specified
     * @param timeToMaturity number of seconds until maturity
     * @return (new market object, cash)
     */
    function _tradeCalculation(
        Market memory interimMarket,
        int256 fCashAmount,
        uint32 timeToMaturity
    ) internal view returns (Market memory, uint128) {
        if (fCashAmount < 0 && interimMarket.totalfCash < fCashAmount.neg()) {
            // We return false if there is not enough fCash to support this trade.
            return (interimMarket, 0);
        }

        // Get the new rate anchor for this market, this accounts for the anchor rate changing as we
        // roll down to maturity. This needs to be saved to the market if we actually trade.
        bool success;
        (interimMarket.rateAnchor, success) = _getNewRateAnchor(interimMarket, timeToMaturity);
        if (!success) return (interimMarket, 0);

        // Calculate the exchange rate the user will actually trade at, we simulate the fCash amount
        // added or subtracted to the numerator of the proportion.
        uint256 tradeExchangeRate;
        (tradeExchangeRate, success) = _getExchangeRate(interimMarket, timeToMaturity, fCashAmount);
        if (!success) return (interimMarket, 0);

        // The fee amount will decrease as we roll down to maturity
        uint256 fee = uint256(G_LIQUIDITY_FEE).mul(timeToMaturity).div(G_MATURITY_LENGTH);
        if (fCashAmount > 0) {
            uint256 postFeeRate = tradeExchangeRate + fee;
            // This is an overflow on the fee
            if (postFeeRate < tradeExchangeRate) return (interimMarket, 0);
            tradeExchangeRate = postFeeRate;
        } else {
            uint256 postFeeRate = tradeExchangeRate - fee;
            // This is an underflow on the fee
            if (postFeeRate > tradeExchangeRate) return (interimMarket, 0);
            tradeExchangeRate = postFeeRate;
        }

        if (tradeExchangeRate < INSTRUMENT_PRECISION) {
            // We do not allow negative exchange rates.
            return (interimMarket, 0);
        }

        // cash = fCashAmount / exchangeRate
        uint128 cash = SafeCast.toUint128(uint256(fCashAmount.abs()).mul(INSTRUMENT_PRECISION).div(tradeExchangeRate));

        // Update the markets accordingly.
        if (fCashAmount > 0) {
            if (interimMarket.totalCurrentCash < cash) {
                // There is not enough cash to support this trade.
                return (interimMarket, 0);
            }

            interimMarket.totalfCash = interimMarket.totalfCash.add(uint128(fCashAmount));
            interimMarket.totalCurrentCash = interimMarket.totalCurrentCash.sub(cash);
        } else {
            interimMarket.totalfCash = interimMarket.totalfCash.sub(uint128(fCashAmount.abs()));
            interimMarket.totalCurrentCash = interimMarket.totalCurrentCash.add(cash);
        }

        // Now calculate the implied rate, this will be used for future rolldown calculations.
        uint32 impliedRate;
        (impliedRate, success) = _getImpliedRate(interimMarket, timeToMaturity);

        if (!success) return (interimMarket, 0);

        interimMarket.lastImpliedRate = impliedRate;

        return (interimMarket, cash);
    }

    /**
     * The rate anchor will update as the market rolls down to maturity. The calculation is:
     * newAnchor = anchor - [currentImpliedRate - lastImpliedRate] * (timeToMaturity / MATURITY_SIZE)
     * where:
     * lastImpliedRate = (exchangeRate' - 1) * (MATURITY_SIZE / timeToMaturity')
     *      (calculated when the last trade in the market was made)
     * timeToMaturity = maturity - currentBlockTime
     * @return the new rate anchor and a boolean that signifies success
     */
    function _getNewRateAnchor(Market memory market, uint32 timeToMaturity) internal view returns (uint32, bool) {
        (uint32 impliedRate, bool success) = _getImpliedRate(market, timeToMaturity);

        if (!success) return (0, false);

        int256 rateDifference = int256(impliedRate)
            .sub(market.lastImpliedRate)
            .mul(timeToMaturity)
            .div(G_MATURITY_LENGTH);
        int256 newRateAnchor = int256(market.rateAnchor).sub(rateDifference);

        if (newRateAnchor < 0 || newRateAnchor > Common.MAX_UINT_32) return (0, false);

        return (uint32(newRateAnchor), true);
    }

    /**
     * This is the implied rate calculated after a trade is made or when liquidity is added to the pool initially.
     * @return the implied rate and a bool that is true on success
     */
    function _getImpliedRate(Market memory market, uint32 timeToMaturity) internal view returns (uint32, bool) {
        (uint32 exchangeRate, bool success) = _getExchangeRate(market, timeToMaturity, 0);

        if (!success) return (0, false);
        if (exchangeRate < INSTRUMENT_PRECISION) return (0, false);

        uint256 rate = uint256(exchangeRate - INSTRUMENT_PRECISION)
            .mul(G_MATURITY_LENGTH)
            .div(timeToMaturity);

        if (rate > Common.MAX_UINT_32) return (0, false);

        return (uint32(rate), true);
    }

    /**
     * @notice This function reverts if the implied rate is negative.
     */
    function _getImpliedRateRequire(Market memory market, uint32 timeToMaturity) internal view returns (uint32) {
        (uint32 impliedRate, bool success) = _getImpliedRate(market, timeToMaturity);

        require(success, "50");

        return impliedRate;
    }

    function _calculateImpliedRate(
        uint128 cash,
        uint128 fCash,
        uint32 timeToMaturity
    ) internal view returns (uint32) {
        uint256 exchangeRate = uint256(fCash).mul(INSTRUMENT_PRECISION).div(cash);
        return SafeCast.toUint32(exchangeRate.sub(INSTRUMENT_PRECISION).mul(G_MATURITY_LENGTH).div(timeToMaturity));
    }

    /**
     * @dev It is important that this call does not revert, if it does it may prevent liquidation
     * or settlement from finishing. We return a rate of 0 to signify a failure.
     *
     * Takes a market in memory and calculates the following exchange rate:
     * (1 / G_RATE_SCALAR) * ln(proportion / (1 - proportion)) + G_RATE_ANCHOR
     * where:
     * proportion = totalfCash / (totalfCash + totalCurrentCash)
     */
    function _getExchangeRate(
        Market memory market,
        uint32 timeToMaturity,
        int256 fCashAmount
    ) internal view returns (uint32, bool) {
        // These two conditions will result in divide by zero errors.
        if (market.totalfCash.add(market.totalCurrentCash) == 0 || market.totalCurrentCash == 0) {
            return (0, false);
        }

        // This will always be positive, we do a check beforehand in _tradeCalculation
        uint256 numerator = uint256(int256(market.totalfCash).add(fCashAmount));
        // This is always less than DECIMALS
        uint256 proportion = numerator.mul(Common.DECIMALS).div(market.totalfCash.add(market.totalCurrentCash));

        // proportion' = proportion / (1 - proportion)
        proportion = proportion.mul(Common.DECIMALS).div(uint256(Common.DECIMALS).sub(proportion));

        // (1 / scalar) * ln(proportion') + anchor_rate
        (int256 abdkResult, bool success) = _abdkMath(proportion);

        if (!success) return (0, false);

        // The rate scalar will increase towards maturity, this will lower the impact of changes
        // to the proportion as we get towards maturity.
        int256 rateScalar = int256(market.rateScalar).mul(G_MATURITY_LENGTH).div(timeToMaturity);
        if (rateScalar > Common.MAX_UINT_32) return (0, false);

        // This is ln(1e18), subtract this to scale proportion back. There is no potential for overflow
        // in int256 space with the addition and subtraction here.
        int256 rate = ((abdkResult - LN_1E18) / rateScalar) + market.rateAnchor;
        
        // These checks simply prevent math errors, not negative interest rates.
        if (rate < 0) {
            return (0, false);
        } else if (rate > Common.MAX_UINT_32) {
            return (0, false);
        } else {
            return (uint32(rate), true);
        }
    }

    function _abdkMath(uint256 proportion) internal pure returns (uint64, bool) {
        // This is the max 64 bit integer for ABDKMath. Note that this will fail when the
        // market reaches a proportion of 9.2 due to the MAX64 value.
        if (proportion > MAX64) return (0, false);

        int128 abdkProportion = ABDKMath64x64.fromUInt(proportion);
        // If abdkProportion is negative, this means that it is less than 1 and will
        // return a negative log so we exit here
        if (abdkProportion <= 0) return (0, false);

        int256 abdkLog = ABDKMath64x64.ln(abdkProportion);
        // This is the 64x64 multiplication with the 64x64 represenation of 1e9. The max value of
        // this due to MAX64 is ln(MAX64) * 1e9 = 43668272375
        int256 result = (abdkLog * PRECISION_64x64) >> 64;

        if (result < ABDKMath64x64.MIN_64x64 || result > ABDKMath64x64.MAX_64x64) {
            return (0, false);
        }

        // Will pass int128 conversion after the overflow checks above. We convert to a uint here because we have
        // already checked that proportion is positive and so we cannot return a negative log.
        return (ABDKMath64x64.toUInt(int128(result)), true);
    }
}