// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library DataTypesPeerToPool {
    struct Repayment {
        // The loan token amount due for given period; initially, expressed in relative terms (100%=BASE), once
        // finalized in absolute terms (in loanToken)
        uint128 loanTokenDue;
        // The coll token amount that can be converted for given period; initially, expressed in relative terms w.r.t.
        // loanTokenDue (e.g., convert every 1 loanToken for 8 collToken), once finalized in absolute terms (in collToken)
        uint128 collTokenDueIfConverted;
        // Timestamp when repayment is due
        uint40 dueTimestamp;
    }

    struct LoanTerms {
        // Min subscription amount (in loan token) that the borrower deems acceptable
        uint128 minTotalSubscriptions;
        // Max subscription amount (in loan token) that the borrower deems acceptable
        uint128 maxTotalSubscriptions;
        // The number of collateral tokens the borrower pledges per loan token borrowed as collateral for default case
        uint128 collPerLoanToken;
        // Borrower who can finalize given loan proposal
        address borrower;
        // Array of scheduled repayments
        Repayment[] repaymentSchedule;
    }

    struct StaticLoanProposalData {
        // Factory address from which the loan proposal is created
        address factory;
        // Funding pool address that is associated with given loan proposal and from which loan liquidity can be
        // sourced
        address fundingPool;
        // Address of collateral token to be used for given loan proposal
        address collToken;
        // Address of arranger who can manage the loan proposal contract
        address arranger;
        // Address of whitelist authority who can manage the lender whitelist (optional)
        address whitelistAuthority;
        // Unsubscribe grace period (in seconds), i.e., after acceptance by borrower lenders can unsubscribe and
        // remove liquidity for this duration before being locked-in
        uint256 unsubscribeGracePeriod;
        // Conversion grace period (in seconds), i.e., lenders can exercise their conversion right between
        // [dueTimeStamp, dueTimeStamp+conversionGracePeriod]
        uint256 conversionGracePeriod;
        // Repayment grace period (in seconds), i.e., borrowers can repay between
        // [dueTimeStamp+conversionGracePeriod, dueTimeStamp+conversionGracePeriod+repaymentGracePeriod]
        uint256 repaymentGracePeriod;
    }

    struct DynamicLoanProposalData {
        // Arranger fee charged on final loan amount, initially in relative terms (100%=BASE), and after finalization
        // in absolute terms (in loan token)
        uint256 arrangerFee;
        // The gross loan amount; initially this is zero and gets set once loan proposal gets accepted and finalized;
        // note that the borrower receives the gross loan amount minus any arranger and protocol fees
        uint256 grossLoanAmount;
        // Final collateral amount reserved for defaults; initially this is zero and gets set once loan proposal got
        // accepted and finalized
        uint256 finalCollAmountReservedForDefault;
        // Final collateral amount reserved for conversions; initially this is zero and gets set once loan proposal got
        // accepted and finalized
        uint256 finalCollAmountReservedForConversions;
        // Timestamp when the loan terms get accepted by borrower and after which they cannot be changed anymore
        uint256 loanTermsLockedTime;
        // Current repayment index, mapping to currently relevant repayment schedule element; note the
        // currentRepaymentIdx (initially 0) only ever gets incremented on repay
        uint256 currentRepaymentIdx;
        // Status of current loan proposal
        DataTypesPeerToPool.LoanStatus status;
        // Protocol fee, initially in relative terms (100%=BASE), and after finalization in absolute terms (in loan token);
        // note that the relative protocol fee is locked in at the time when the loan proposal is created
        uint256 protocolFee;
    }

    enum LoanStatus {
        WITHOUT_LOAN_TERMS,
        IN_NEGOTIATION,
        LOAN_TERMS_LOCKED,
        READY_TO_EXECUTE,
        ROLLBACK,
        LOAN_DEPLOYED,
        DEFAULTED
    }
}