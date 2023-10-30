// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { PRBMathSD59x18 } from "@prb-math/contracts/PRBMathSD59x18.sol";
import { Math }           from '@openzeppelin/contracts/utils/math/Math.sol';

import { PoolType } from '../../interfaces/pool/IPool.sol';

import { Buckets } from '../internal/Buckets.sol';
import { Maths }   from '../internal/Maths.sol';

    error BucketIndexOutOfBounds();
    error BucketPriceOutOfBounds();

    /*************************/
    /*** Price Conversions ***/
    /*************************/

    /// @dev constant price indices defining the min and max of the potential price range
    int256  constant MAX_BUCKET_INDEX  =  4_156;
    int256  constant MIN_BUCKET_INDEX  = -3_232;
    uint256 constant MAX_FENWICK_INDEX =  7_388;

    uint256 constant MIN_PRICE = 99_836_282_890;
    uint256 constant MAX_PRICE = 1_004_968_987.606512354182109771 * 1e18;

    uint256 constant MAX_NEUTRAL_PRICE = 50_248_449_380.325617709105488550 * 1e18; // 50 * MAX_PRICE

    /// @dev deposit buffer (extra margin) used for calculating reserves
    uint256 constant DEPOSIT_BUFFER = 1.000000001 * 1e18;

    /// @dev step amounts in basis points. This is a constant across pools at `0.005`, achieved by dividing `WAD` by `10,000`
    int256 constant FLOAT_STEP_INT = 1.005 * 1e18;

    /**
     *  @notice Calculates the price (`WAD` precision) for a given `Fenwick` index.
     *  @dev    Reverts with `BucketIndexOutOfBounds` if index exceeds maximum constant.
     *  @dev    Uses fixed-point math to get around lack of floating point numbers in `EVM`.
     *  @dev    Fenwick index is converted to bucket index.
     *  @dev    Fenwick index to bucket index conversion:
     *  @dev      `1.00`      : bucket index `0`,     fenwick index `4156`: `7388-4156-3232=0`.
     *  @dev      `MAX_PRICE` : bucket index `4156`,  fenwick index `0`:    `7388-0-3232=4156`.
     *  @dev      `MIN_PRICE` : bucket index - `3232`, fenwick index `7388`: `7388-7388-3232=-3232`.
     *  @dev    `V1`: `price = MIN_PRICE + (FLOAT_STEP * index)`
     *  @dev    `V2`: `price = MAX_PRICE * (FLOAT_STEP ** (abs(int256(index - MAX_PRICE_INDEX))));`
     *  @dev    `V3 (final)`: `x^y = 2^(y*log_2(x))`
     */
    function _priceAt(
        uint256 index_
    ) pure returns (uint256) {
        // Lowest Fenwick index is highest price, so invert the index and offset by highest bucket index.
        int256 bucketIndex = MAX_BUCKET_INDEX - int256(index_);
        if (bucketIndex < MIN_BUCKET_INDEX || bucketIndex > MAX_BUCKET_INDEX) revert BucketIndexOutOfBounds();

        return uint256(
            PRBMathSD59x18.exp2(
                PRBMathSD59x18.mul(
                    PRBMathSD59x18.fromInt(bucketIndex),
                    PRBMathSD59x18.log2(FLOAT_STEP_INT)
                )
            )
        );
    }

    /**
     *  @notice Calculates the  Fenwick  index for a given price.
     *  @dev    Reverts with `BucketPriceOutOfBounds` if price exceeds maximum constant.
     *  @dev    Price expected to be inputted as a `WAD` (`18` decimal).
     *  @dev    `V1`: `bucket index = (price - MIN_PRICE) / FLOAT_STEP`
     *  @dev    `V2`: `bucket index = (log(FLOAT_STEP) * price) /  MAX_PRICE`
     *  @dev    `V3 (final)`: `bucket index =  log_2(price) / log_2(FLOAT_STEP)`
     *  @dev    `Fenwick index = 7388 - bucket index + 3232`
     */
    function _indexOf(
        uint256 price_
    ) pure returns (uint256) {
        if (price_ < MIN_PRICE || price_ > MAX_PRICE) revert BucketPriceOutOfBounds();

        int256 index = PRBMathSD59x18.div(
            PRBMathSD59x18.log2(int256(price_)),
            PRBMathSD59x18.log2(FLOAT_STEP_INT)
        );

        int256 ceilIndex = PRBMathSD59x18.ceil(index);
        if (index < 0 && ceilIndex - index > 0.5 * 1e18) {
            return uint256(4157 - PRBMathSD59x18.toInt(ceilIndex));
        }
        return uint256(4156 - PRBMathSD59x18.toInt(ceilIndex));
    }

    /**********************/
    /*** Pool Utilities ***/
    /**********************/

    /**
     *  @notice Calculates the minimum debt amount that can be borrowed or can remain in a loan in pool.
     *  @param  debt_          The debt amount to calculate minimum debt amount for.
     *  @param  loansCount_    The number of loans in pool.
     *  @return minDebtAmount_ Minimum debt amount value of the pool.
     */
    function _minDebtAmount(
        uint256 debt_,
        uint256 loansCount_
    ) pure returns (uint256 minDebtAmount_) {
        if (loansCount_ != 0) {
            minDebtAmount_ = Maths.wdiv(Maths.wdiv(debt_, Maths.wad(loansCount_)), 10**19);
        }
    }

    /**
     *  @notice Calculates origination fee for a given interest rate.
     *  @notice Calculated as greater of the current annualized interest rate divided by `52` (one week of interest) or `5` bps.
     *  @param  interestRate_ The current interest rate.
     *  @return Fee rate based upon the given interest rate.
     */
    function _borrowFeeRate(
        uint256 interestRate_
    ) pure returns (uint256) {
        // greater of the current annualized interest rate divided by 52 (one week of interest) or 5 bps
        return Maths.max(Maths.wdiv(interestRate_, 52 * 1e18), 0.0005 * 1e18);
    }

    /**
     * @notice Calculates the unutilized deposit fee, charged to lenders who deposit below the `LUP`.
     * @param  interestRate_ The current interest rate.
     * @return Fee rate based upon the given interest rate, capped at 10%.
     */
    function _depositFeeRate(
        uint256 interestRate_
    ) pure returns (uint256) {
        // current annualized rate divided by 365 (24 hours of interest), capped at 10%
        return Maths.min(Maths.wdiv(interestRate_, 365 * 1e18), 0.1 * 1e18);
    }

    /**
     *  @notice Calculates debt-weighted average threshold price.
     *  @param  t0Debt_              Pool debt owed by borrowers in `t0` terms.
     *  @param  inflator_            Pool's borrower inflator.
     *  @param  t0Debt2ToCollateral_ `t0-debt-squared-to-collateral` accumulator. 
     */
    function _dwatp(
        uint256 t0Debt_,
        uint256 inflator_,
        uint256 t0Debt2ToCollateral_
    ) pure returns (uint256) {
        return t0Debt_ == 0 ? 0 : Maths.wdiv(Maths.wmul(inflator_, t0Debt2ToCollateral_), t0Debt_);
    }

    /**
     *  @notice Collateralization calculation.
     *  @param debt_       Debt to calculate collateralization for.
     *  @param collateral_ Collateral to calculate collateralization for.
     *  @param price_      Price to calculate collateralization for.
     *  @param type_       Type of the pool.
     *  @return `True` if collateralization calculated is equal or greater than `1`.
     */
    function _isCollateralized(
        uint256 debt_,
        uint256 collateral_,
        uint256 price_,
        uint8 type_
    ) pure returns (bool) {
        if (type_ == uint8(PoolType.ERC20)) return Maths.wmul(collateral_, price_) >= debt_;
        else {
            //slither-disable-next-line divide-before-multiply
            collateral_ = (collateral_ / Maths.WAD) * Maths.WAD; // use collateral floor
            return Maths.wmul(collateral_, price_) >= debt_;
        }
    }

    /**
     *  @notice Price precision adjustment used in calculating collateral dust for a bucket.
     *          To ensure the accuracy of the exchange rate calculation, buckets with smaller prices require
     *          larger minimum amounts of collateral.  This formula imposes a lower bound independent of token scale.
     *  @param  bucketIndex_              Index of the bucket, or `0` for encumbered collateral with no bucket affinity.
     *  @return pricePrecisionAdjustment_ Unscaled integer of the minimum number of decimal places the dust limit requires.
     */
    function _getCollateralDustPricePrecisionAdjustment(
        uint256 bucketIndex_
    ) pure returns (uint256 pricePrecisionAdjustment_) {
        // conditional is a gas optimization
        if (bucketIndex_ > 3900) {
            int256 bucketOffset = int256(bucketIndex_ - 3900);
            int256 result = PRBMathSD59x18.sqrt(PRBMathSD59x18.div(bucketOffset * 1e18, int256(36 * 1e18)));
            pricePrecisionAdjustment_ = uint256(result / 1e18);
        }
    }

    /**
     *  @notice Returns the amount of collateral calculated for the given amount of `LP`.
     *  @dev    The value returned is capped at collateral amount available in bucket.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lenderLPBalance_  The amount of `LP` to calculate collateral for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return collateralAmount_ Amount of collateral calculated for the given `LP `amount.
     */
    function _lpToCollateral(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 lenderLPBalance_,
        uint256 bucketPrice_
    ) pure returns (uint256 collateralAmount_) {
        collateralAmount_ = Buckets.lpToCollateral(
            bucketCollateral_,
            bucketLP_,
            deposit_,
            lenderLPBalance_,
            bucketPrice_,
            Math.Rounding.Down
        );

        if (collateralAmount_ > bucketCollateral_) {
            // user is owed more collateral than is available in the bucket
            collateralAmount_ = bucketCollateral_;
        }
    }

    /**
     *  @notice Returns the amount of quote tokens calculated for the given amount of `LP`.
     *  @dev    The value returned is capped at available bucket deposit.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lenderLPBalance_  The amount of `LP` to calculate quote token amount for.
     *  @param  maxQuoteToken_    The max quote token amount to calculate `LP` for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return quoteTokenAmount_ Amount of quote tokens calculated for the given `LP` amount, capped at available bucket deposit.
     */
    function _lpToQuoteToken(
        uint256 bucketLP_,
        uint256 bucketCollateral_,
        uint256 deposit_,
        uint256 lenderLPBalance_,
        uint256 maxQuoteToken_,
        uint256 bucketPrice_
    ) pure returns (uint256 quoteTokenAmount_) {
        quoteTokenAmount_ = Buckets.lpToQuoteTokens(
            bucketCollateral_,
            bucketLP_,
            deposit_,
            lenderLPBalance_,
            bucketPrice_,
            Math.Rounding.Down
        );

        if (quoteTokenAmount_ > deposit_)       quoteTokenAmount_ = deposit_;
        if (quoteTokenAmount_ > maxQuoteToken_) quoteTokenAmount_ = maxQuoteToken_;
    }

    /**
     *  @notice Rounds a token amount down to the minimum amount permissible by the token scale.
     *  @param  amount_       Value to be rounded.
     *  @param  tokenScale_   Scale of the token, presented as a power of `10`.
     *  @return scaledAmount_ Rounded value.
     */
    function _roundToScale(
        uint256 amount_,
        uint256 tokenScale_
    ) pure returns (uint256 scaledAmount_) {
        scaledAmount_ = (amount_ / tokenScale_) * tokenScale_;
    }

    /**
     *  @notice Rounds a token amount up to the next amount permissible by the token scale.
     *  @param  amount_       Value to be rounded.
     *  @param  tokenScale_   Scale of the token, presented as a power of `10`.
     *  @return scaledAmount_ Rounded value.
     */
    function _roundUpToScale(
        uint256 amount_,
        uint256 tokenScale_
    ) pure returns (uint256 scaledAmount_) {
        if (amount_ % tokenScale_ == 0)
            scaledAmount_ = amount_;
        else
            scaledAmount_ = _roundToScale(amount_, tokenScale_) + tokenScale_;
    }

    /*********************************/
    /*** Reserve Auction Utilities ***/
    /*********************************/

    uint256 constant MINUTE_HALF_LIFE    = 0.988514020352896135_356867505 * 1e27;  // 0.5^(1/60)

    /**
     *  @notice Calculates claimable reserves within the pool.
     *  @dev    Claimable reserve auctions and escrowed auction bonds are guaranteed by the pool.
     *  @param  debt_                    Pool's debt.
     *  @param  poolSize_                Pool's deposit size.
     *  @param  totalBondEscrowed_       Total bond escrowed.
     *  @param  reserveAuctionUnclaimed_ Pool's unclaimed reserve auction.
     *  @param  quoteTokenBalance_       Pool's quote token balance.
     *  @return claimable_               Calculated pool reserves.
     */  
    function _claimableReserves(
        uint256 debt_,
        uint256 poolSize_,
        uint256 totalBondEscrowed_,
        uint256 reserveAuctionUnclaimed_,
        uint256 quoteTokenBalance_
    ) pure returns (uint256 claimable_) {
        uint256 guaranteedFunds = totalBondEscrowed_ + reserveAuctionUnclaimed_;

        // calculate claimable reserves if there's quote token excess
        if (quoteTokenBalance_ > guaranteedFunds) {
            claimable_ = Maths.wmul(0.995 * 1e18, debt_) + quoteTokenBalance_;

            claimable_ -= Maths.min(
                claimable_,
                // require 1.0 + 1e-9 deposit buffer (extra margin) for deposits
                Maths.wmul(DEPOSIT_BUFFER, poolSize_) + guaranteedFunds
            );

            // incremental claimable reserve should not exceed excess quote in pool
            claimable_ = Maths.min(
                claimable_,
                quoteTokenBalance_ - guaranteedFunds
            );
        }
    }

    /**
     *  @notice Calculates reserves auction price.
     *  @param  reserveAuctionKicked_ Time when reserve auction was started (kicked).
     *  @return price_                Calculated auction price.
     */     
    function _reserveAuctionPrice(
        uint256 reserveAuctionKicked_
    ) view returns (uint256 price_) {
        if (reserveAuctionKicked_ != 0) {
            uint256 secondsElapsed   = block.timestamp - reserveAuctionKicked_;
            uint256 hoursComponent   = 1e27 >> secondsElapsed / 3600;
            uint256 minutesComponent = Maths.rpow(MINUTE_HALF_LIFE, secondsElapsed % 3600 / 60);

            price_ = Maths.rayToWad(1_000_000_000 * Maths.rmul(hoursComponent, minutesComponent));
        }
    }

    /*************************/
    /*** Auction Utilities ***/
    /*************************/

    /**
     *  @notice Calculates auction price.
     *  @param  kickMomp_     `MOMP` recorded at the time of kick.
     *  @param  neutralPrice_ `Neutral Price` of the auction.
     *  @param  kickTime_      Time when auction was kicked.
     *  @return price_         Calculated auction price.
     */
    function _auctionPrice(
        uint256 kickMomp_,
        uint256 neutralPrice_,
        uint256 kickTime_
    ) view returns (uint256 price_) {
        uint256 elapsedHours = Maths.wdiv((block.timestamp - kickTime_) * 1e18, 1 hours * 1e18);

        elapsedHours -= Maths.min(elapsedHours, 1e18);  // price locked during cure period

        int256 timeAdjustment  = PRBMathSD59x18.mul(-1 * 1e18, int256(elapsedHours)); 
        uint256 referencePrice = Maths.max(kickMomp_, neutralPrice_); 

        price_ = 32 * Maths.wmul(referencePrice, uint256(PRBMathSD59x18.exp2(timeAdjustment)));
    }

    /**
     *  @notice Calculates bond penalty factor.
     *  @dev    Called in kick and take.
     *  @param debt_         Borrower debt.
     *  @param collateral_   Borrower collateral.
     *  @param neutralPrice_ `NP` of auction.
     *  @param bondFactor_   Factor used to determine bondSize.
     *  @param auctionPrice_ Auction price at the time of call.
     *  @return bpf_         Factor used in determining bond `reward` (positive) or `penalty` (negative).
     */
    function _bpf(
        uint256 debt_,
        uint256 collateral_,
        uint256 neutralPrice_,
        uint256 bondFactor_,
        uint256 auctionPrice_
    ) pure returns (int256) {
        int256 thresholdPrice = int256(Maths.wdiv(debt_, collateral_));

        int256 sign;
        if (thresholdPrice < int256(neutralPrice_)) {
            // BPF = BondFactor * min(1, max(-1, (neutralPrice - price) / (neutralPrice - thresholdPrice)))
            sign = Maths.minInt(
                1e18,
                Maths.maxInt(
                    -1 * 1e18,
                    PRBMathSD59x18.div(
                        int256(neutralPrice_) - int256(auctionPrice_),
                        int256(neutralPrice_) - thresholdPrice
                    )
                )
            );
        } else {
            int256 val = int256(neutralPrice_) - int256(auctionPrice_);
            if (val < 0 )      sign = -1e18;
            else if (val != 0) sign = 1e18;
        }

        return PRBMathSD59x18.mul(int256(bondFactor_), sign);
    }

    /**
     *  @notice Calculates bond parameters of an auction.
     *  @param  borrowerDebt_ Borrower's debt before entering in liquidation.
     *  @param  collateral_   Borrower's collateral before entering in liquidation.
     *  @param  momp_         Current pool `momp`.
     */
    function _bondParams(
        uint256 borrowerDebt_,
        uint256 collateral_,
        uint256 momp_
    ) pure returns (uint256 bondFactor_, uint256 bondSize_) {
        uint256 thresholdPrice = (borrowerDebt_ * Maths.WAD) / collateral_;

        // bondFactor = min(30%, max(1%, (MOMP - thresholdPrice) / MOMP))
        if (thresholdPrice >= momp_) {
            bondFactor_ = 0.01 * 1e18;
        } else {
            bondFactor_ = Maths.min(
                0.3 * 1e18,
                Maths.max(
                    0.01 * 1e18,
                    1e18 - Maths.wdiv(thresholdPrice, momp_)
                )
            );
        }

        bondSize_ = Maths.wmul(bondFactor_,  borrowerDebt_);
    }