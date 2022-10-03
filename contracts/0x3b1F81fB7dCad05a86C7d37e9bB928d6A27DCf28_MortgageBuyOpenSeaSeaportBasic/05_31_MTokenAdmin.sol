pragma solidity ^0.5.16;

import "./MTokenCommon.sol";
import "./MTokenInterfaces.sol";
import "./MtrollerInterface.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./compound/EIP20Interface.sol";
import "./compound/InterestRateModel.sol";
import "./open-zeppelin/token/ERC20/IERC20.sol";
import "./open-zeppelin/token/ERC721/IERC721.sol";

/**
 * @title Contract for MToken
 * @notice Abstract base for any type of MToken ("admin" part)
 * @author mmo.finance, initially based on Compound
 */
contract MTokenAdmin is MTokenCommon, MTokenAdminInterface {

    /**
     * @notice Constructs a new MTokenAdmin
     */
    constructor() public MTokenCommon() {
        implementedSelectors.push(bytes4(keccak256('isMDelegatorAdminImplementation()')));
        implementedSelectors.push(bytes4(keccak256('_setFlashReceiverWhiteList(address,bool)')));
        implementedSelectors.push(bytes4(keccak256('_setInterestRateModel(address)')));
        implementedSelectors.push(bytes4(keccak256('_setTokenAuction(address)')));
        implementedSelectors.push(bytes4(keccak256('_setMtroller(address)')));
        implementedSelectors.push(bytes4(keccak256('_setGlobalProtocolParameters(uint256,uint256,uint256,uint256)')));
        implementedSelectors.push(bytes4(keccak256('_setGlobalAuctionParameters(uint256,uint256,uint256,uint256,uint256)')));
        implementedSelectors.push(bytes4(keccak256('_reduceReserves(uint240,uint256)')));
        implementedSelectors.push(bytes4(keccak256('_sweepERC20(address)')));
        implementedSelectors.push(bytes4(keccak256('_sweepERC721(address,uint256)')));
    }

    /**
     * @notice Returns the type of implementation for this contract
     */
    function isMDelegatorAdminImplementation() public pure returns (bool) {
        return true;
    }

    /*** Admin functions ***/

    /**
     * @notice Initializes a new MToken money market
     * @param underlyingContract_ The contract address of the underlying asset for this MToken
     * @param mtroller_ The address of the Mtroller
     * @param interestRateModel_ The address of the interest rate model
     * @param reserveFactorMantissa_ The fraction of interest to set aside for reserves, scaled by 1e18
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param protocolSeizeShareMantissa_ The fraction of seized collateral added to reserves, scaled by 1e18
     * @param name_ EIP-20 name of this MToken
     * @param symbol_ EIP-20 symbol of this MToken
     * @param decimals_ EIP-20 decimal precision of this MToken
     */
    function initialize(address underlyingContract_,
                MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                uint reserveFactorMantissa_,
                uint initialExchangeRateMantissa_,
                uint protocolSeizeShareMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_) internal {

        require(msg.sender == getAdmin(), "only admin can initialize token contract");

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
        _notEntered2 = true;

        // Allow initialization only once
        require(underlyingContract == address(0), "already initialized");

        // Set the underlying contract address
        underlyingContract = underlyingContract_;

        // Set the interest rate model
        uint err = _setInterestRateModel(interestRateModel_);
        require(err == uint(Error.NO_ERROR), "setting interest rate model failed");

        // Set the mtroller
        err = _setMtroller(mtroller_);
        require(err == uint(Error.NO_ERROR), "setting mtroller failed");

        // Set initial exchange rate, the reserve factor, the protocol seize share, and the one-time borrow fee
        err = _setGlobalProtocolParameters(initialExchangeRateMantissa_, reserveFactorMantissa_, protocolSeizeShareMantissa_, 0.8e16);
        require(err == uint(Error.NO_ERROR), "setting global protocol parameters failed");

        // Set global auction parameters
        err = _setGlobalAuctionParameters(auctionMinGracePeriod, 500, 0, 5e16, 0);
        require(err == uint(Error.NO_ERROR), "setting global auction parameters failed");

        // Set the mToken name and symbol
        mName = name_;
        mSymbol = symbol_;
        mDecimals = decimals_;

        // Initialize the market for the anchor token
        uint240 tokenAnchor = mtroller.getAnchorToken(address(this));
        require(accrualBlockNumber[tokenAnchor] == 0 && borrowIndex[tokenAnchor] == 0, "market may only be initialized once");
        accrualBlockNumber[tokenAnchor] = getBlockNumber();
        borrowIndex[tokenAnchor] = mantissaOne;

        // Accrue interest to execute changes
        err = accrueInterest(tokenAnchor);
        require(err == uint(Error.NO_ERROR), "accrue interest failed");
    }


    struct RedeemLocalVars {
        Error err;
        MathError mathErr;
        uint exchangeRateMantissa;
        uint redeemTokens;
        uint redeemAmount;
        uint totalSupplyNew;
        uint accountTokensNew;
        uint totalCashNew;
    }

    /**
     * @notice Sender redeems mTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mToken The mToken to redeem
     * @param redeemTokensIn The number of mTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmountIn The number of underlying tokens to receive from redeeming mTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param beneficiary The account that will get the redeemed underlying asset
     * @param sellPrice In case of redeem followed directly by a sale to another user, this is the (minimum) price to collect from the buyer
     * @param transferHandler If this is nonzero, the redeem is directly followed by a sale, the details of which are handled by a contract at this address (see Mortgage.sol)
     * @param transferParams Call parameters for the transferHandler call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemInternal(uint240 mToken, uint redeemTokensIn, uint redeemAmountIn, address payable beneficiary, uint sellPrice, address payable transferHandler, bytes memory transferParams) internal returns (uint) {
        address payable redeemer = msg.sender;
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

        uint err = accrueInterest(mToken);
        if (err != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
            return fail(Error(err), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
        }

        RedeemLocalVars memory vars;

        /* exchangeRate = invoke Exchange Rate Stored() */
        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal(mToken);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr));
        }

        /* If redeemTokensIn > 0: */
        if (redeemTokensIn > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokensIn
             *  redeemAmount = redeemTokensIn x exchangeRateCurrent
             */
            vars.redeemTokens = redeemTokensIn;

            (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), redeemTokensIn);
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED, uint(vars.mathErr));
            }
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmountIn / exchangeRate
             *  redeemAmount = redeemAmountIn
             */

            (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(redeemAmountIn, Exp({mantissa: vars.exchangeRateMantissa}));
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED, uint(vars.mathErr));
            }

            vars.redeemAmount = redeemAmountIn;
        }

        /*
         * We calculate the new total supply and redeemer balance, checking for underflow:
         *  totalSupplyNew = totalSupply - redeemTokens
         *  accountTokensNew = accountTokens[redeemer] - redeemTokens
         */
        (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply[mToken], vars.redeemTokens);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED, uint(vars.mathErr));
        }

        (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[mToken][redeemer], vars.redeemTokens);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        /* Fail gracefully if protocol has insufficient underlying cash */
        (vars.mathErr, vars.totalCashNew) = subUInt(totalCashUnderlying[mToken], vars.redeemAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDEEM_TRANSFER_OUT_NOT_POSSIBLE);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferOut for the redeemer and the redeemAmount.
         *  Note: The mToken must handle variations between ETH, ERC-20, ERC-721, ERC-1155 underlying.
         *  On success, the mToken has redeemAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        uint256 underlyingID = underlyingIDs[mToken];
        // check transferHandler is whitelisted (if used)
        if (transferHandler != address(0)) {
            require(flashReceiverIsWhitelisted[transferHandler] || flashReceiverIsWhitelisted[address(0)], "flash receiver not whitelisted");
        }
        doTransferOut(beneficiary, underlyingID, vars.redeemAmount, sellPrice, transferHandler, transferParams);

        /* We write previously calculated values into storage */
        totalSupply[mToken] = vars.totalSupplyNew;
        accountTokens[mToken][redeemer] = vars.accountTokensNew;
        totalCashUnderlying[mToken] = vars.totalCashNew;

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), mToken, vars.redeemTokens);
        emit Redeem(redeemer, mToken, vars.redeemTokens, underlyingID, vars.redeemAmount);

        /* Revert whole transaction if redeem not allowed (i.e., user has any shortfall at the end). 
         * We do this at the end to allow for redeems that include a sales transaction which can balance
         * user's liquidity 
         */
        err = mtroller.redeemAllowed(mToken, redeemer, 0);
        requireNoError(err, "redeem failed");

        /* We call the defense hook */
        mtroller.redeemVerify(mToken, redeemer, vars.redeemAmount, vars.redeemTokens);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param mToken The mToken whose underlying to borrow
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrowInternal(uint240 mToken, uint borrowAmount) internal returns (uint) {
        // borrowFresh emits borrow-specific logs on errors, so we don't need to
        (uint err, ) = borrowPrivate(msg.sender, mToken, borrowAmount, address(0));
        return err;
    }

    /**
     * @notice Sender borrows assets from the protocol to a receiver address in spite of having 
     * insufficient collateral, but repays borrow or adds collateral to correct balance in the same block
     * @param mToken The mToken whose underlying to borrow
     * @param downPaymentAmount Additional funds transferred from sender to receiver (down payment)
     * @param borrowAmount The amount of the underlying asset to borrow
     * @param receiver The address receiving the borrowed funds. This address must be able to receive
     * the corresponding underlying of mToken and it must implement FlashLoanReceiverInterface. Any
     * such receiver address must be whitelisted before by admin, unless admin has enables all addresses
     * by whitelisting address(0).
     * @param flashParams Any other data necessary for flash loan repayment
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function flashBorrowInternal(uint240 mToken, uint downPaymentAmount, uint borrowAmount, address payable receiver, bytes memory flashParams) internal nonReentrant2 returns (uint) {
        // check receiver is not null, and is whitelisted
        require(receiver != address(0), "invalid flash loan receiver");
        require(flashReceiverIsWhitelisted[receiver] || flashReceiverIsWhitelisted[address(0)], "flash receiver not whitelisted");

        // Revert if flash borrowing fails (need to revert because of side-effects such as down payment)
        uint error;
        uint paidOutAmount;
        if (borrowAmount > 0) {
            (error, paidOutAmount) = borrowPrivate(msg.sender, mToken, borrowAmount, receiver);
            require(error == uint(Error.NO_ERROR), "flash borrow not allowed"); 
        }

        /* Get down payment (if any) from the sender and also transfer it to the receiver. 
         * Reverts if anything goes wrong.
         */
        uint256 underlyingID = underlyingIDs[mToken];
        if (downPaymentAmount > 0) {
            MathError mathErr;
            uint downPaymentPaid = doTransferOutFromSender(receiver, underlyingID, downPaymentAmount);
            (mathErr, paidOutAmount) = addUInt(paidOutAmount, downPaymentPaid);
            require(mathErr == MathError.NO_ERROR, "down payment calculation failed");
        }

        /* Call user-defined code that eventually repays borrow or increases collaterals sufficiently */
        error = FlashLoanReceiverInterface(receiver).executeFlashOperation(msg.sender, mToken, borrowAmount, paidOutAmount, flashParams);
        require(error == uint(Error.NO_ERROR), "execute flash operation failed");

        /* Revert whole transaction if sender (=borrower) has any shortfall remaining at the end */
        error = mtroller.borrowAllowed(mToken, msg.sender, 0);
        require(error == 0, "flash loan failed");

        emit FlashBorrow(msg.sender, underlyingID, receiver, downPaymentAmount, borrowAmount, paidOutAmount);

        return uint(Error.NO_ERROR);
    }

    struct BorrowLocalVars {
        MathError mathErr;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
        uint totalCashNew;
        uint protocolFee;
        uint amountPaidOut;
        uint amountBorrowerReceived;
        uint totalReservesNew;
    }

    /**
     * @notice Borrows assets from the protocol to a certain address
     * @param borrower The address that borrows and receives assets
     * @param mToken The mToken whose underlying to borrow
     * @param borrowAmount The amount of the underlying asset to borrow
     * @param receiver The address receiving the borrowed funds in case of a flash loan, otherwise 0
     * @return (possible error code 0=success, otherwise a failure (see ErrorReporter.sol for details),
     *          amount actually received by borrower (borrowAmount - protocol fees - token transfer fees))
     */
    function borrowPrivate(address payable borrower, uint240 mToken, uint borrowAmount, address payable receiver) private nonReentrant returns (uint, uint) {
        /* Accrue interest */
        uint error = accrueInterest(mToken);
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return (fail(Error(error), FailureInfo.BORROW_ACCRUE_INTEREST_FAILED), 0);
        }

        /* Fail if borrow not allowed (flash: fail if already has shortfall before borrowing anything) */
        if (receiver != address(0)) {
            error = mtroller.borrowAllowed(mToken, borrower, 0);
        }
        else {
            error = mtroller.borrowAllowed(mToken, borrower, borrowAmount);
        }
        if (error != 0) {
            return (failOpaque(Error.MTROLLER_REJECTION, FailureInfo.BORROW_MTROLLER_REJECTION, error), 0);
        }

        // /* Verify market's block number equals current block number */
        // if (accrualBlockNumber[mToken] != getBlockNumber()) {
        //     return (fail(Error.MARKET_NOT_FRESH, FailureInfo.BORROW_FRESHNESS_CHECK), 0);
        // }

        BorrowLocalVars memory vars;

        /* Fail gracefully if protocol has insufficient underlying cash */
        (vars.mathErr, vars.totalCashNew) = subUInt(totalCashUnderlying[mToken], borrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.BORROW_CASH_NOT_AVAILABLE), 0);
        }

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowsNew = accountBorrows + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower, mToken);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        (vars.mathErr, vars.accountBorrowsNew) = addUInt(vars.accountBorrows, borrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        (vars.mathErr, vars.totalBorrowsNew) = addUInt(totalBorrows[mToken], borrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        /*
         * We calculate the one-time platform fee (if any) on new borrows:
         *  protocolFee = borrowFeeMantissa * borrowAmount
         *  amountPaidOut = borrowAmount - protocolFee
         */

        (vars.mathErr, vars.protocolFee) = mulScalarTruncate(Exp({mantissa: borrowFeeMantissa}), borrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_PLATFORM_FEE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        (vars.mathErr, vars.amountPaidOut) = subUInt(borrowAmount, vars.protocolFee);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_PLATFORM_FEE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        /* Add protocolFee to totalReserves and totalCash, revert on overflow */
        (vars.mathErr, vars.totalReservesNew) = addUInt(totalReserves[mToken], vars.protocolFee);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_PLATFORM_FEE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        (vars.mathErr, vars.totalCashNew) = addUInt(vars.totalCashNew, vars.protocolFee);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_PLATFORM_FEE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferOut for the borrower and the effective amountPaidOut.
         *  Note: The mToken must handle variations between ETH, ERC-20, ERC-721, ERC-1155 underlying.
         *  On success, the mToken has amountPaidOut less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        uint256 underlyingID = underlyingIDs[mToken];
        if (receiver != address(0)) {
            vars.amountBorrowerReceived = doTransferOut(receiver, underlyingID, vars.amountPaidOut, 0, address(0), "");
        }
        else {
            vars.amountBorrowerReceived = doTransferOut(borrower, underlyingID, vars.amountPaidOut, 0, address(0), "");
        }

        /* We write the previously calculated values into storage */
        accountBorrows[mToken][borrower].principal = vars.accountBorrowsNew;
        accountBorrows[mToken][borrower].interestIndex = borrowIndex[mToken];
        totalBorrows[mToken] = vars.totalBorrowsNew;
        totalCashUnderlying[mToken] = vars.totalCashNew;

        if (vars.protocolFee != 0) {
            totalReserves[mToken] = vars.totalReservesNew;
            emit ReservesAdded(address(this), mToken, vars.protocolFee, vars.totalReservesNew);
        }

        /* We emit a Borrow event */
        emit Borrow(borrower, underlyingID, borrowAmount, vars.amountBorrowerReceived, vars.accountBorrowsNew, vars.totalBorrowsNew);

        /* We call the defense hook */
        // unused function
        // mtroller.borrowVerify(address(this), borrower, borrowAmount);

        return (uint(Error.NO_ERROR), vars.amountBorrowerReceived);
    }

    /*** Admin Functions ***/

    /**
     * @notice Manages the whitelist for flash loan receivers
     * @dev Admin function to manage whitelist entries for flash loan receivers
     * @param candidate the receiver address to take on/off the whitelist. putting the zero address
     * on the whitelist (candidate = 0, state = true) enables any address as flash loan receiver,
     * effectively disabling whitelisting
     * @param state true to put on whitelist, false to take off
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setFlashReceiverWhiteList(address candidate, bool state) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_FLASH_WHITELIST_OWNER_CHECK);
        }

        // if state is modified, set new whitelist state and emit event
        if (flashReceiverIsWhitelisted[candidate] != state) {
            flashReceiverIsWhitelisted[candidate] = state;
            emit FlashReceiverWhitelistChanged(candidate, state);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice sets a new interest rate model
     * @dev Admin function to set a new interest rate model.
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public nonReentrant returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_INTEREST_RATE_MODEL_OWNER_CHECK);
        }

        InterestRateModel oldInterestRateModel = interestRateModel;
        // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
        require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

        // Set new interest rate model
        interestRateModel = newInterestRateModel;

        // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);
        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice sets a new token auction contract
     * @dev Admin function to set a new token auction contract.
     * @param newTokenAuction the new token auction contract to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setTokenAuction(TokenAuction newTokenAuction) public nonReentrant returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_TOKEN_AUCTION_OWNER_CHECK);
        }

        TokenAuction oldTokenAuction = tokenAuction;

        // Set new interest rate model
        tokenAuction = newTokenAuction;

        // Emit NewTokenAuction(oldTokenAuction, newTokenAuction);
        emit NewTokenAuction(oldTokenAuction, newTokenAuction);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets a new mtroller for the market
      * @dev Admin function to set a new mtroller
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setMtroller(MtrollerInterface newMtroller) public nonReentrant returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MTROLLER_OWNER_CHECK);
        }

        MtrollerInterface oldMtroller = mtroller;
        // Ensure invoke mtroller.isMtroller() returns true
        require(MtrollerUserInterface(newMtroller).isMDelegatorUserImplementation(), "invalid mtroller");
        require(MtrollerAdminInterface(newMtroller).isMDelegatorAdminImplementation(), "invalid mtroller");

        // Set market's mtroller to newMtroller
        mtroller = newMtroller;

        // Emit NewMtroller(oldMtroller, newMtroller)
        emit NewMtroller(oldMtroller, newMtroller);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets new values for the modifiable global parameters of the protocol
      * @dev Admin function to set global parameters. Setting a value of a parameter to uint(-1) means to not
      * change the current value of that parameter.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setGlobalProtocolParameters(uint _initialExchangeRateMantissa, uint _reserveFactorMantissa, uint _protocolSeizeShareMantissa, uint _borrowFeeMantissa) public returns (uint) {

        require(msg.sender == getAdmin(), "only admin can set global protocol parameters");

        if (_initialExchangeRateMantissa != uint(-1) && _initialExchangeRateMantissa != initialExchangeRateMantissa) {
            if (_initialExchangeRateMantissa == 0) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            initialExchangeRateMantissa = _initialExchangeRateMantissa;
        }

        if (_reserveFactorMantissa != uint(-1) && _reserveFactorMantissa != reserveFactorMantissa) {
            if (_reserveFactorMantissa > reserveFactorMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            reserveFactorMantissa = _reserveFactorMantissa;
        }

        if (_protocolSeizeShareMantissa != uint(-1) && _protocolSeizeShareMantissa != protocolSeizeShareMantissa) {
            if (_protocolSeizeShareMantissa > protocolSeizeShareMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            protocolSeizeShareMantissa = _protocolSeizeShareMantissa;
        }

        if (_borrowFeeMantissa != uint(-1) && _borrowFeeMantissa != borrowFeeMantissa) {
            if (_borrowFeeMantissa > borrowFeeMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            borrowFeeMantissa = _borrowFeeMantissa;
        }

        emit NewGlobalProtocolParameters(initialExchangeRateMantissa, reserveFactorMantissa, protocolSeizeShareMantissa, borrowFeeMantissa);

        return uint(Error.NO_ERROR);
    }

    function _setGlobalAuctionParameters(
            uint _auctionGracePeriod,
            uint _preferredLiquidatorHeadstart,
            uint _minimumOfferMantissa,
            uint _liquidatorAuctionFeeMantissa,
            uint _protocolAuctionFeeMantissa
            ) public returns (uint) {

        require(msg.sender == getAdmin(), "only admin can set global auction parameters");

        if (_auctionGracePeriod != uint(-1) && _auctionGracePeriod != auctionGracePeriod) {
            if (_auctionGracePeriod < auctionMinGracePeriod || _auctionGracePeriod > auctionMaxGracePeriod) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            auctionGracePeriod = _auctionGracePeriod;
        }

        if (_preferredLiquidatorHeadstart != uint(-1) && _preferredLiquidatorHeadstart != preferredLiquidatorHeadstart) {
            if (_preferredLiquidatorHeadstart > preferredLiquidatorMaxHeadstart) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            preferredLiquidatorHeadstart = _preferredLiquidatorHeadstart;
        }

        if (_minimumOfferMantissa != uint(-1) && _minimumOfferMantissa != minimumOfferMantissa) {
            if (_minimumOfferMantissa > minimumOfferMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            minimumOfferMantissa = _minimumOfferMantissa;
        }

        if (_liquidatorAuctionFeeMantissa != uint(-1) && _liquidatorAuctionFeeMantissa != liquidatorAuctionFeeMantissa) {
            if (_liquidatorAuctionFeeMantissa > liquidatorAuctionFeeMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            }
            liquidatorAuctionFeeMantissa = _liquidatorAuctionFeeMantissa;
        }

        if (_protocolAuctionFeeMantissa != uint(-1) && _protocolAuctionFeeMantissa != protocolAuctionFeeMantissa) {
            if (_protocolAuctionFeeMantissa > protocolAuctionFeeMaxMantissa) {
                return fail(Error.BAD_INPUT, FailureInfo.SET_GLOBAL_PARAMETERS_VALUE_CHECK);
            } 
            protocolAuctionFeeMantissa = _protocolAuctionFeeMantissa;
        }

        emit NewGlobalAuctionParameters(auctionGracePeriod, preferredLiquidatorHeadstart, minimumOfferMantissa, liquidatorAuctionFeeMantissa, protocolAuctionFeeMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accrues interest and reduces reserves for mToken by transferring to admin
     * @param mToken The mToken whose reserves to reduce
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves(uint240 mToken, uint reduceAmount) external nonReentrant returns (uint) {
        uint error = accrueInterest(mToken);
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
            return fail(Error(error), FailureInfo.REDUCE_RESERVES_ACCRUE_INTEREST_FAILED);
        }
        // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
        return _reduceReservesFresh(mToken, reduceAmount);
    }

    /**
     * @notice Reduces reserves for mToken by transferring to admin
     * @dev Requires fresh interest accrual
     * @param mToken The mToken whose reserves to reduce
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReservesFresh(uint240 mToken, uint reduceAmount) internal returns (uint) {
        MathError mathErr;
        uint totalReservesNew;
        uint totalCashNew;

        // Check caller is admin
        address payable admin = getAdmin();
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.REDUCE_RESERVES_ADMIN_CHECK);
        }

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber[mToken] != getBlockNumber()) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDUCE_RESERVES_FRESH_CHECK);
        }

        /* Fail gracefully if protocol has insufficient reserves */
        (mathErr, totalReservesNew) = subUInt(totalReserves[mToken], reduceAmount);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.BAD_INPUT, FailureInfo.REDUCE_RESERVES_VALIDATION);
        }

        /* Fail gracefully if protocol has insufficient underlying cash */
        (mathErr, totalCashNew) = subUInt(totalCashUnderlying[mToken], reduceAmount);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDUCE_RESERVES_CASH_NOT_AVAILABLE);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferOut for admin and the reduceAmount.
         *  Note: The mToken must handle variations between ETH, ERC-20, ERC-721, ERC-1155 underlying.
         *  On success, the mToken has reduceAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        uint256 underlyingID = underlyingIDs[mToken];
        doTransferOut(admin, underlyingID, reduceAmount, 0, address(0), "");

        /* We write the previously calculated values into storage */
        totalReserves[mToken] = totalReservesNew;
        totalCashUnderlying[mToken] = totalCashNew;

        emit ReservesReduced(admin, mToken, reduceAmount, totalReservesNew);

        return uint(Error.NO_ERROR);
    }

    /*** Safe Token ***/

    /**
     * @notice Transfers underlying assets out of this contract
     * @dev Performs a transfer out, reverting upon failure.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     * @param to the address where to transfer underlying assets to
     * @param underlyingID the ID of the underlying asset (in case of a NFT) or 1 (in case of a fungible asset)
     * @param amount the amount of underlying to transfer (for fungible assets) or oneUnit (for NFTs)
     * @return (uint) Returns the amount actually transferred out (lower in case of a fee).
     */
    function doTransferOut(address payable to, uint256 underlyingID, uint amount, uint sellPrice, address payable transferHandler, bytes memory transferParams) internal returns (uint);

    /**
     * @notice Transfers underlying assets from sender to a beneficiary (e.g. for flash loan down payment)
     * @dev Performs a transfer from, reverting upon failure (e.g. insufficient allowance from owner)
     * @param to the address where to transfer underlying assets to
     * @param underlyingID the ID of the underlying asset (in case of a NFT) or 1 (in case of a fungible asset)
     * @param amount the amount of underlying to transfer (for fungible assets) or oneUnit (for NFTs)
     * @return (uint) Returns the amount actually transferred (lower in case of a fee).
     */
    function doTransferOutFromSender(address payable to, uint256 underlyingID, uint amount) internal returns (uint);

    /**
        @notice Admin may collect any ERC-20 token that have been transferred to this contract 
                inadvertently (otherwise they would be locked forever).
        @param tokenContract The contract address of the "lost" token.
        @return (uint) Returns the amount of tokens successfully collected, otherwise reverts.
    */
    function _sweepERC20(address tokenContract) external nonReentrant returns (uint) {
        address admin = getAdmin();
        require(msg.sender == admin, "Only admin can do that");
        require(tokenContract != underlyingContract, "Cannot sweep underlying asset");
        uint256 amount = IERC20(tokenContract).balanceOf(address(this));
        require(amount > 0, "No leftover tokens found");
        IERC20(tokenContract).transfer(admin, amount);
        return amount;
    }

    /**
        @notice Admin may collect any ERC-721 token that have been transferred to this contract 
                inadvertently (otherwise they would be locked forever).
        @dev Reverts upon any failure.        
        @param tokenContract The contract address of the "lost" token.
        @param tokenID The ID of the "lost" token.
    */
    function _sweepERC721(address tokenContract, uint256 tokenID) external nonReentrant {
        address admin = getAdmin();
        require(msg.sender == admin, "Only admin can do that");
        if (tokenContract == underlyingContract) {
            // Only allow to sweep tokens that are not in use as supplied assets
            uint240 mToken = mTokenFromUnderlying[tokenID];
            if (mToken != 0) {
                require(IERC721(tokenContract).ownerOf(mToken) == address(0), "Cannot sweep regular asset");
            }
        }
        require(address(this) == IERC721(tokenContract).ownerOf(tokenID), "Token not owned by contract");
        IERC721(tokenContract).safeTransferFrom(address(this), admin, tokenID);
    }
}

contract MTokenInterfaceFull is MTokenAdmin, MTokenInterface {}