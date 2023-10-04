// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library DataTypesPeerToPeer {
    struct Loan {
        // address of borrower
        address borrower;
        // address of coll token
        address collToken;
        // address of loan token
        address loanToken;
        // timestamp after which any portion of loan unpaid defaults
        uint40 expiry;
        // timestamp before which borrower cannot repay
        uint40 earliestRepay;
        // initial collateral amount of loan
        uint128 initCollAmount;
        // loan amount given
        uint128 initLoanAmount;
        // full repay amount at start of loan
        uint128 initRepayAmount;
        // amount repaid (loan token) up until current time
        // note: partial repayments are allowed
        uint128 amountRepaidSoFar;
        // amount reclaimed (coll token) up until current time
        // note: partial repayments are allowed
        uint128 amountReclaimedSoFar;
        // flag tracking if collateral has been unlocked by vault
        bool collUnlocked;
        // address of the compartment housing the collateral
        address collTokenCompartmentAddr;
    }

    struct QuoteTuple {
        // loan amount per one unit of collateral if no oracle
        // LTV in terms of the constant BASE (10 ** 18) if using oracle
        uint256 loanPerCollUnitOrLtv;
        // interest rate percentage in BASE (can be negative but greater than -BASE)
        // i.e. -100% < interestRatePct since repay amount of 0 is not allowed
        // also interestRatePctInBase is not annualized
        int256 interestRatePctInBase;
        // fee percentage,in BASE, which will be paid in upfront in collateral
        uint256 upfrontFeePctInBase;
        // length of the loan in seconds
        uint256 tenor;
    }

    struct GeneralQuoteInfo {
        // address of collateral token
        address collToken;
        // address of loan token
        address loanToken;
        // address of oracle (optional)
        address oracleAddr;
        // min loan amount (in loan token) prevent griefing attacks or
        // amounts lender feels isn't worth unlocking on default
        uint256 minLoan;
        // max loan amount (in loan token) if lender wants a cap
        uint256 maxLoan;
        // timestamp after which quote automatically invalidates
        uint256 validUntil;
        // time, in seconds, that loan cannot be exercised
        uint256 earliestRepayTenor;
        // address of compartment implementation (optional)
        address borrowerCompartmentImplementation;
        // will invalidate quote after one use
        // if false, will be a standing quote
        bool isSingleUse;
        // whitelist address (optional)
        address whitelistAddr;
        // flag indicating whether whitelistAddr refers to a single whitelisted
        // borrower or to a whitelist authority that can whitelist multiple addresses
        bool isWhitelistAddrSingleBorrower;
    }

    struct OnChainQuote {
        // general quote info
        GeneralQuoteInfo generalQuoteInfo;
        // array of quote parameters
        QuoteTuple[] quoteTuples;
        // provides more distinguishability of quotes to reduce
        // likelihood of collisions w.r.t. quote creations and invalidations
        bytes32 salt;
    }

    struct OffChainQuote {
        // general quote info
        GeneralQuoteInfo generalQuoteInfo;
        // root of the merkle tree, where the merkle tree encodes all QuoteTuples the lender accepts
        bytes32 quoteTuplesRoot;
        // provides more distinguishability of quotes to reduce
        // likelihood of collisions w.r.t. quote creations and invalidations
        bytes32 salt;
        // for invalidating multiple parallel quotes in one click
        uint256 nonce;
        // array of compact signatures from vault signers
        bytes[] compactSigs;
    }

    struct LoanRepayInstructions {
        // loan id being repaid
        uint256 targetLoanId;
        // repay amount after transfer fees in loan token
        uint128 targetRepayAmount;
        // expected transfer fees in loan token (=0 for tokens without transfer fee)
        // note: amount that borrower sends is targetRepayAmount + expectedTransferFee
        uint128 expectedTransferFee;
        // deadline to prevent stale transactions
        uint256 deadline;
        // e.g., for using collateral to payoff debt via DEX
        address callbackAddr;
        // any data needed by callback
        bytes callbackData;
    }

    struct BorrowTransferInstructions {
        // amount of collateral sent
        uint256 collSendAmount;
        // sum of (i) protocol fee and (ii) transfer fees (if any) associated with sending any collateral to vault
        uint256 expectedProtocolAndVaultTransferFee;
        // transfer fees associated with sending any collateral to compartment (if used)
        uint256 expectedCompartmentTransferFee;
        // deadline to prevent stale transactions
        uint256 deadline;
        // slippage protection if oracle price is too loose
        uint256 minLoanAmount;
        // e.g., for one-click leverage
        address callbackAddr;
        // any data needed by callback
        bytes callbackData;
        // any data needed by myso token manager
        bytes mysoTokenManagerData;
    }

    struct TransferInstructions {
        // collateral token receiver
        address collReceiver;
        // effective upfront fee in collateral tokens (vault or compartment)
        uint256 upfrontFee;
    }

    struct WrappedERC721TokenInfo {
        // address of the ERC721_TOKEN
        address tokenAddr;
        // array of ERC721_TOKEN ids
        uint256[] tokenIds;
    }

    struct WrappedERC20TokenInfo {
        // token addresse
        address tokenAddr;
        // token amounts
        uint256 tokenAmount;
    }

    struct OnChainQuoteInfo {
        // hash of on chain quote
        bytes32 quoteHash;
        // valid until timestamp
        uint256 validUntil;
    }

    enum WhitelistState {
        // not whitelisted
        NOT_WHITELISTED,
        // can be used as loan or collateral token
        ERC20_TOKEN,
        // can be be used as oracle
        ORACLE,
        // can be used as compartment
        COMPARTMENT,
        // can be used as callback contract
        CALLBACK,
        // can be used as loan or collateral token, but if collateral then must
        // be used in conjunction with a compartment (e.g., for stETH with possible
        // negative rebase that could otherwise affect other borrowers in the vault)
        ERC20_TOKEN_REQUIRING_COMPARTMENT,
        // can be used in conjunction with an ERC721 wrapper
        ERC721_TOKEN,
        // can be used as ERC721 wrapper contract
        ERC721WRAPPER,
        // can be used as ERC20 wrapper contract
        ERC20WRAPPER,
        // can be used as MYSO token manager contract
        MYSO_TOKEN_MANAGER,
        // can be used as quote policy manager contract
        QUOTE_POLICY_MANAGER
    }
}