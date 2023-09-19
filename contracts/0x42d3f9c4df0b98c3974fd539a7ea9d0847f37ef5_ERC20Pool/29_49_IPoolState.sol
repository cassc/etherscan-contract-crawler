// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool State
 */
interface IPoolState {

    /**
     *  @notice Returns details of an auction for a given borrower address.
     *  @param  borrower_     Address of the borrower that is liquidated.
     *  @return kicker_       Address of the kicker that is kicking the auction.
     *  @return bondFactor_   The factor used for calculating bond size.
     *  @return bondSize_     The bond amount in quote token terms.
     *  @return kickTime_     Time the liquidation was initiated.
     *  @return kickMomp_     Price where the average loan utilizes deposit, at the time when the loan is liquidated (kicked).
     *  @return neutralPrice_ `Neutral Price` of auction.
     *  @return head_         Address of the head auction.
     *  @return next_         Address of the next auction in queue.
     *  @return prev_         Address of the prev auction in queue.
     *  @return alreadyTaken_ True if take has been called on auction
     */
    function auctionInfo(address borrower_)
        external
        view
        returns (
            address kicker_,
            uint256 bondFactor_,
            uint256 bondSize_,
            uint256 kickTime_,
            uint256 kickMomp_,
            uint256 neutralPrice_,
            address head_,
            address next_,
            address prev_,
            bool alreadyTaken_
        );

    /**
     *  @notice Returns pool related debt values.
     *  @return debt_                Current amount of debt owed by borrowers in pool.
     *  @return accruedDebt_         Debt owed by borrowers based on last inflator snapshot.
     *  @return debtInAuction_       Total amount of debt in auction.
     *  @return t0Debt2ToCollateral_ t0debt accross all borrowers divided by their collateral, used in determining a collateralization weighted debt.
     */
    function debtInfo()
        external
        view
        returns (
            uint256 debt_,
            uint256 accruedDebt_,
            uint256 debtInAuction_,
            uint256 t0Debt2ToCollateral_
        );

    /**
     *  @notice Mapping of borrower addresses to `Borrower` structs.
     *  @dev    NOTE: Cannot use appended underscore syntax for return params since struct is used.
     *  @param  borrower_   Address of the borrower.
     *  @return t0Debt_     Amount of debt borrower would have had if their loan was the first debt drawn from the pool.
     *  @return collateral_ Amount of collateral that the borrower has deposited, in collateral token.
     *  @return t0Np_       t0 `Neutral Price`
     */
    function borrowerInfo(address borrower_)
        external
        view
        returns (
            uint256 t0Debt_,
            uint256 collateral_,
            uint256 t0Np_
        );

    /**
     *  @notice Mapping of buckets indexes to `Bucket` structs.
     *  @dev    NOTE: Cannot use appended underscore syntax for return params since struct is used.
     *  @param  index_               Bucket index.
     *  @return lpAccumulator_       Amount of `LP` accumulated in current bucket.
     *  @return availableCollateral_ Amount of collateral available in current bucket.
     *  @return bankruptcyTime_      Timestamp when bucket become insolvent, `0` if healthy.
     *  @return bucketDeposit_       Amount of quote tokens in bucket.
     *  @return bucketScale_         Bucket multiplier.
     */
    function bucketInfo(uint256 index_)
        external
        view
        returns (
            uint256 lpAccumulator_,
            uint256 availableCollateral_,
            uint256 bankruptcyTime_,
            uint256 bucketDeposit_,
            uint256 bucketScale_
        );

    /**
     *  @notice Mapping of burnEventEpoch to `BurnEvent` structs.
     *  @dev    Reserve auctions correspond to burn events.
     *  @param  burnEventEpoch_  Id of the current reserve auction.
     *  @return burnBlock_       Block in which a reserve auction started.
     *  @return totalInterest_   Total interest as of the reserve auction.
     *  @return totalBurned_     Total ajna tokens burned as of the reserve auction.
     */
    function burnInfo(uint256 burnEventEpoch_) external view returns (uint256, uint256, uint256);

    /**
     *  @notice Returns the latest `burnEventEpoch` of reserve auctions.
     *  @dev    If a reserve auction is active, it refers to the current reserve auction. If no reserve auction is active, it refers to the last reserve auction.
     *  @return Current `burnEventEpoch`.
     */
    function currentBurnEpoch() external view returns (uint256);

    /**
     *  @notice Returns information about the pool `EMA (Exponential Moving Average)` variables.
     *  @return debtColEma_   Debt squared to collateral Exponential, numerator to `TU` calculation.
     *  @return lupt0DebtEma_ Exponential of `LUP * t0 debt`, denominator to `TU` calculation
     *  @return debtEma_      Exponential debt moving average.
     *  @return depositEma_   sample of meaningful deposit Exponential, denominator to `MAU` calculation.
     */
    function emasInfo()
        external
        view
        returns (
            uint256 debtColEma_,
            uint256 lupt0DebtEma_,
            uint256 debtEma_,
            uint256 depositEma_
    );

    /**
     *  @notice Returns information about pool inflator.
     *  @return inflator_   Pool inflator value.
     *  @return lastUpdate_ The timestamp of the last `inflator` update.
     */
    function inflatorInfo()
        external
        view
        returns (
            uint256 inflator_,
            uint256 lastUpdate_
    );

    /**
     *  @notice Returns information about pool interest rate.
     *  @return interestRate_       Current interest rate in pool.
     *  @return interestRateUpdate_ The timestamp of the last interest rate update.
     */
    function interestRateInfo()
        external
        view
        returns (
            uint256 interestRate_,
            uint256 interestRateUpdate_
        );


    /**
     *  @notice Returns details about kicker balances.
     *  @param  kicker_    The address of the kicker to retrieved info for.
     *  @return claimable_ Amount of quote token kicker can claim / withdraw from pool at any time.
     *  @return locked_    Amount of quote token kicker locked in auctions (as bonds).
     */
    function kickerInfo(address kicker_)
        external
        view
        returns (
            uint256 claimable_,
            uint256 locked_
        );

    /**
     *  @notice Mapping of buckets indexes and owner addresses to `Lender` structs.
     *  @param  index_       Bucket index.
     *  @param  lender_      Address of the liquidity provider.
     *  @return lpBalance_   Amount of `LP` owner has in current bucket.
     *  @return depositTime_ Time the user last deposited quote token.
     */
    function lenderInfo(
        uint256 index_,
        address lender_
    )
        external
        view
        returns (
            uint256 lpBalance_,
            uint256 depositTime_
    );

    /**
     *  @notice Return the `LP` allowance a `LP` owner provided to a spender.
     *  @param  index_     Bucket index.
     *  @param  spender_   Address of the `LP` spender.
     *  @param  owner_     The initial owner of the `LP`.
     *  @return allowance_ Amount of `LP` spender can utilize.
     */
    function lpAllowance(
        uint256 index_,
        address spender_,
        address owner_
    ) external view returns (uint256 allowance_);

    /**
     *  @notice Returns information about a loan in the pool.
     *  @param  loanId_         Loan's id within loan heap. Max loan is position `1`.
     *  @return borrower_       Borrower address at the given position.
     *  @return thresholdPrice_ Borrower threshold price in pool.
     */
    function loanInfo(
        uint256 loanId_
    )
        external
        view
        returns (
            address borrower_,
            uint256 thresholdPrice_
    );

    /**
     *  @notice Returns information about pool loans.
     *  @return maxBorrower_       Borrower address with highest threshold price.
     *  @return maxThresholdPrice_ Highest threshold price in pool.
     *  @return noOfLoans_         Total number of loans.
     */
    function loansInfo()
        external
        view
        returns (
            address maxBorrower_,
            uint256 maxThresholdPrice_,
            uint256 noOfLoans_
    );

    /**
     *  @notice Returns information about pool reserves.
     *  @return liquidationBondEscrowed_ Amount of liquidation bond across all liquidators.
     *  @return reserveAuctionUnclaimed_ Amount of claimable reserves which has not been taken in the `Claimable Reserve Auction`.
     *  @return reserveAuctionKicked_    Time a `Claimable Reserve Auction` was last kicked.
     *  @return totalInterestEarned_     Total interest earned by all lenders in the pool
     */
    function reservesInfo()
        external
        view
        returns (
            uint256 liquidationBondEscrowed_,
            uint256 reserveAuctionUnclaimed_,
            uint256 reserveAuctionKicked_,
            uint256 totalInterestEarned_
    );

    /**
     *  @notice Returns the `pledgedCollateral` state variable.
     *  @return The total pledged collateral in the system, in WAD units.
     */
    function pledgedCollateral() external view returns (uint256);

    /**
     *  @notice Returns the total number of active auctions in pool.
     *  @return totalAuctions_ Number of active auctions.
     */
    function totalAuctionsInPool() external view returns (uint256);

     /**
     *  @notice Returns the `t0Debt` state variable.
     *  @dev    This value should be multiplied by inflator in order to calculate current debt of the pool.
     *  @return The total `t0Debt` in the system, in `WAD` units.
     */
    function totalT0Debt() external view returns (uint256);

    /**
     *  @notice Returns the `t0DebtInAuction` state variable.
     *  @dev    This value should be multiplied by inflator in order to calculate current debt in auction of the pool.
     *  @return The total `t0DebtInAuction` in the system, in `WAD` units.
     */
    function totalT0DebtInAuction() external view returns (uint256);

    /**
     *  @notice Mapping of addresses that can transfer `LP` to a given lender.
     *  @param  lender_     Lender that receives `LP`.
     *  @param  transferor_ Transferor that transfers `LP`.
     *  @return True if the transferor is approved by lender.
     */
    function approvedTransferors(
        address lender_,
        address transferor_
    ) external view returns (bool);

}

/*********************/
/*** State Structs ***/
/*********************/

/******************/
/*** Pool State ***/
/******************/

/// @dev Struct holding inflator state.
struct InflatorState {
    uint208 inflator;       // [WAD] pool's inflator
    uint48  inflatorUpdate; // [SEC] last time pool's inflator was updated
}

/// @dev Struct holding pool interest state.
struct InterestState {
    uint208 interestRate;        // [WAD] pool's interest rate
    uint48  interestRateUpdate;  // [SEC] last time pool's interest rate was updated (not before 12 hours passed)
    uint256 debt;                // [WAD] previous update's debt
    uint256 meaningfulDeposit;   // [WAD] previous update's meaningfulDeposit
    uint256 t0Debt2ToCollateral; // [WAD] utilization weight accumulator, tracks debt and collateral relationship accross borrowers 
    uint256 debtCol;             // [WAD] previous debt squared to collateral
    uint256 lupt0Debt;           // [WAD] previous LUP * t0 debt
}

/// @dev Struct holding pool EMAs state.
struct EmaState {
    uint256 debtEma;             // [WAD] sample of debt EMA, numerator to MAU calculation
    uint256 depositEma;          // [WAD] sample of meaningful deposit EMA, denominator to MAU calculation
    uint256 debtColEma;          // [WAD] debt squared to collateral EMA, numerator to TU calculation
    uint256 lupt0DebtEma;        // [WAD] EMA of LUP * t0 debt, denominator to TU calculation
    uint256 emaUpdate;           // [SEC] last time pool's EMAs were updated
}

/// @dev Struct holding pool balances state.
struct PoolBalancesState {
    uint256 pledgedCollateral; // [WAD] total collateral pledged in pool
    uint256 t0DebtInAuction;   // [WAD] Total debt in auction used to restrict LPB holder from withdrawing
    uint256 t0Debt;            // [WAD] Pool debt as if the whole amount was incurred upon the first loan
}

/// @dev Struct holding pool params (in memory only).
struct PoolState {
    uint8   poolType;             // pool type, can be ERC20 or ERC721
    uint256 t0Debt;               // [WAD] t0 debt in pool
    uint256 t0DebtInAuction;      // [WAD] t0 debt in auction within pool
    uint256 debt;                 // [WAD] total debt in pool, accrued in current block
    uint256 collateral;           // [WAD] total collateral pledged in pool
    uint256 inflator;             // [WAD] current pool inflator
    bool    isNewInterestAccrued; // true if new interest already accrued in current block
    uint256 rate;                 // [WAD] pool's current interest rate
    uint256 quoteTokenScale;      // [WAD] quote token scale of the pool. Same as quote token dust.
}

/*********************/
/*** Buckets State ***/
/*********************/

/// @dev Struct holding lender state.
struct Lender {
    uint256 lps;         // [WAD] Lender LP accumulator
    uint256 depositTime; // timestamp of last deposit
}

/// @dev Struct holding bucket state.
struct Bucket {
    uint256 lps;                        // [WAD] Bucket LP accumulator
    uint256 collateral;                 // [WAD] Available collateral tokens deposited in the bucket
    uint256 bankruptcyTime;             // Timestamp when bucket become insolvent, 0 if healthy
    mapping(address => Lender) lenders; // lender address to Lender struct mapping
}

/**********************/
/*** Deposits State ***/
/**********************/

/// @dev Struct holding deposits (Fenwick) values and scaling.
struct DepositsState {
    uint256[8193] values;  // Array of values in the FenwickTree.
    uint256[8193] scaling; // Array of values which scale (multiply) the FenwickTree accross indexes.
}

/*******************/
/*** Loans State ***/
/*******************/

/// @dev Struct holding loans state.
struct LoansState {
    Loan[] loans;
    mapping (address => uint)     indices;   // borrower address => loan index mapping
    mapping (address => Borrower) borrowers; // borrower address => Borrower struct mapping
}

/// @dev Struct holding loan state.
struct Loan {
    address borrower;       // borrower address
    uint96  thresholdPrice; // [WAD] Loan's threshold price.
}

/// @dev Struct holding borrower state.
struct Borrower {
    uint256 t0Debt;     // [WAD] Borrower debt time-adjusted as if it was incurred upon first loan of pool.
    uint256 collateral; // [WAD] Collateral deposited by borrower.
    uint256 t0Np;       // [WAD] Neutral Price time-adjusted as if it was incurred upon first loan of pool.
}

/**********************/
/*** Auctions State ***/
/**********************/

/// @dev Struct holding pool auctions state.
struct AuctionsState {
    uint96  noOfAuctions;                         // total number of auctions in pool
    address head;                                 // first address in auction queue
    address tail;                                 // last address in auction queue
    uint256 totalBondEscrowed;                    // [WAD] total amount of quote token posted as auction kick bonds
    mapping(address => Liquidation) liquidations; // mapping of borrower address and auction details
    mapping(address => Kicker)      kickers;      // mapping of kicker address and kicker balances
}

/// @dev Struct holding liquidation state.
struct Liquidation {
    address kicker;       // address that initiated liquidation
    uint96  bondFactor;   // [WAD] bond factor used to start liquidation
    uint96  kickTime;     // timestamp when liquidation was started
    address prev;         // previous liquidated borrower in auctions queue
    uint96  kickMomp;     // [WAD] Momp when liquidation was started
    address next;         // next liquidated borrower in auctions queue
    uint160 bondSize;     // [WAD] liquidation bond size
    uint96  neutralPrice; // [WAD] Neutral Price when liquidation was started
    bool    alreadyTaken; // true if take has been called on auction
}

/// @dev Struct holding kicker state.
struct Kicker {
    uint256 claimable; // [WAD] kicker's claimable balance
    uint256 locked;    // [WAD] kicker's balance of tokens locked in auction bonds
}

/******************************/
/*** Reserve Auctions State ***/
/******************************/

/// @dev Struct holding reserve auction state.
struct ReserveAuctionState {
    uint256 kicked;                            // Time a Claimable Reserve Auction was last kicked.
    uint256 unclaimed;                         // [WAD] Amount of claimable reserves which has not been taken in the Claimable Reserve Auction.
    uint256 latestBurnEventEpoch;              // Latest burn event epoch.
    uint256 totalAjnaBurned;                   // [WAD] Total ajna burned in the pool.
    uint256 totalInterestEarned;               // [WAD] Total interest earned by all lenders in the pool.
    mapping (uint256 => BurnEvent) burnEvents; // Mapping burnEventEpoch => BurnEvent.
}

/// @dev Struct holding burn event state.
struct BurnEvent {
    uint256 timestamp;     // time at which the burn event occured
    uint256 totalInterest; // [WAD] current pool interest accumulator `PoolCommons.accrueInterest().newInterest`
    uint256 totalBurned;   // [WAD] burn amount accumulator
}