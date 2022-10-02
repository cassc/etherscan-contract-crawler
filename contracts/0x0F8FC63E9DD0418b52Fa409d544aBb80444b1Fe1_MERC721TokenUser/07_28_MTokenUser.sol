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
 * @notice Abstract base for any type of MToken ("user" part)
 * @author mmo.finance, initially based on Compound
 */
contract MTokenUser is MTokenCommon, MTokenUserInterface {

    /**
     * @notice Returns the type of MToken implementation for this contract
     */
    function isMDelegatorUserImplementation() public pure returns (bool) {
        return true;
    }

    /**
     * @notice Transfer `tokens` amount of `mToken` from `src` to `dst` by `spender`
     * @dev Called internally for any mToken transfer (except seizing), whether the mToken is ERC-20, ERC-721, or anything else
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param mToken The mToken to transfer
     * @param tokens The number of tokens to transfer
     * @return Error code (0 = success)
     */
    function transferTokens(address src, address dst, uint240 mToken, uint tokens) internal returns (uint) {
        /* Fail if transfer not allowed */
        uint allowed = mtroller.transferAllowed(mToken, src, dst, tokens);
        if (allowed != 0) {
            return failOpaque(Error.MTROLLER_REJECTION, FailureInfo.TRANSFER_MTROLLER_REJECTION, allowed);
        }

        /* Do not allow self-transfers and transfers to/from zero address */
        if (src == dst || src == address(0) || dst == address(0)) {
            return fail(Error.BAD_INPUT, FailureInfo.TRANSFER_NOT_ALLOWED);
        }

        /* Do the calculations, checking for {under,over}flow */
        MathError mathErr;
        uint srcTokensNew;
        uint dstTokensNew;

        (mathErr, srcTokensNew) = subUInt(accountTokens[mToken][src], tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ENOUGH);
        }

        (mathErr, dstTokensNew) = addUInt(accountTokens[mToken][dst], tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_TOO_MUCH);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accountTokens[mToken][src] = srcTokensNew;
        accountTokens[mToken][dst] = dstTokensNew;

        /* We emit a Transfer event */
        emit Transfer(src, dst, mToken, tokens);

        // unused function
        // mtroller.transferVerify(mToken, src, dst, tokens);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Get the token balance of the `owner` for the token `mToken`
     * @param owner The address of the account to query
     * @param mToken The mToken to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner, uint240 mToken) public view returns (uint256) {
        return accountTokens[mToken][owner];
    }

    /**
     * @notice Get the underlying balance of the `owner` for the token `mToken`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @param mToken The mToken to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner, uint240 mToken) public nonReentrant returns (uint) {
        require(accrueInterest(mToken) == uint(Error.NO_ERROR), "accrue interest failed");
        Exp memory exchangeRate = Exp({mantissa: exchangeRateStored(mToken)});
        (MathError mErr, uint balance) = mulScalarTruncate(exchangeRate, accountTokens[mToken][owner]);
        require(mErr == MathError.NO_ERROR, "balance could not be calculated");
        return balance;
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by mtroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @param mToken The mToken to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account, uint240 mToken) external view returns (uint, uint, uint, uint) {
        uint mTokenBalance = accountTokens[mToken][account];
        uint borrowBalance;
        uint exchangeRateMantissa;
        MathError mErr;

        (mErr, borrowBalance) = borrowBalanceStoredInternal(account, mToken);
        if (mErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0, 0, 0);
        }

        (mErr, exchangeRateMantissa) = exchangeRateStoredInternal(mToken);
        if (mErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0, 0, 0);
        }

        return (uint(Error.NO_ERROR), mTokenBalance, borrowBalance, exchangeRateMantissa);
    }

    /**
     * @notice Returns the current per-block borrow interest rate for this mToken
     * @param mToken The mToken to get the borrow interest rate for
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock(uint240 mToken) external view returns (uint) {
        return interestRateModel.getBorrowRate(totalCashUnderlying[mToken], totalBorrows[mToken], totalReserves[mToken]);
    }

    /**
     * @notice Returns the current per-block supply interest rate for this mToken
     * @param mToken The mToken to get the supply interest rate for
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock(uint240 mToken) external view returns (uint) {
        return interestRateModel.getSupplyRate(totalCashUnderlying[mToken], totalBorrows[mToken], totalReserves[mToken], reserveFactorMantissa);
    }

    /**
     * @notice Returns the current total borrows plus accrued interest for this mToken
     * @param mToken The borrowed mToken
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent(uint240 mToken) external nonReentrant returns (uint) {
        require(accrueInterest(mToken) == uint(Error.NO_ERROR), "accrue interest failed");
        return totalBorrows[mToken];
    }

    /**
     * @notice Accrue interest to updated borrowIndex for this mToken and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @param mToken The borrowed mToken
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account, uint240 mToken) external nonReentrant returns (uint) {
        require(accrueInterest(mToken) == uint(Error.NO_ERROR), "accrue interest failed");
        return borrowBalanceStored(account, mToken);
    }

    /**
     * @notice Return how many mToken underlying an account has borrowed
     * @param account The address whose balance should be calculated
     * @param mToken The borrowed mToken
     * @return uint The calculated balance
     */
    function borrowBalanceStored(address account, uint240 mToken) public view returns (uint) {
        (MathError err, uint result) = borrowBalanceStoredInternal(account, mToken);
        require(err == MathError.NO_ERROR, "borrowBalanceStored: borrowBalanceStoredInternal failed");
        return result;
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @param mToken The mToken whose exchange rate should be calculated
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent(uint240 mToken) public nonReentrant returns (uint) {
        require(accrueInterest(mToken) == uint(Error.NO_ERROR), "accrue interest failed");
        return exchangeRateStored(mToken);
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @param mToken The mToken whose exchange rate should be calculated
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored(uint240 mToken) public view returns (uint) {
        (MathError err, uint result) = exchangeRateStoredInternal(mToken);
        require(err == MathError.NO_ERROR, "exchangeRateStored: exchangeRateStoredInternal failed");
        return result;
    }

    /**
     * @notice Get cash balance of this mToken in the underlying asset
     * @param mToken The mToken for which to get the cash balance
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash(uint240 mToken) external view returns (uint) {
        return totalCashUnderlying[mToken];
    }

    struct MintLocalVars {
        Error err;
        MathError mathErr;
        uint exchangeRateMantissa;
        uint mintTokens;
        uint totalSupplyNew;
        uint accountTokensNew;
        uint actualMintAmount;
        uint totalCashNew;
    }

    /**
     * @notice Sender supplies assets into the market and beneficiary receives mTokens in exchange.         
     * @dev Reverts on any error. Creates and lists new (sub-) mMarket if needed, and accrues interest.
     * @param beneficiary The address to receive the minted mTokens
     * @param underlyingTokenID The token ID of the underlying asset to supply (in case of ERC-721/-1155)
     * @param mintAmount The amount of the underlying asset to supply
     * @return (the new mToken, 
     *          the amount of tokens minted for the new mToken, 
     *          the actual amount of underlying paid)
     */
    function mintToInternal(address beneficiary, uint256 underlyingTokenID, uint mintAmount) internal returns (uint240, uint, uint) {
        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        uint240 mToken = mTokenFromUnderlying[underlyingTokenID];
        if (mToken == 0) {
            // mToken for this underlyingTokenID does not exist yet, create a new mToken
            require(totalCreatedMarkets < uint72(-1), "No more free markets available");
            totalCreatedMarkets++;
            if (getTokenType() == MTokenType.FUNGIBLE_MTOKEN) {
                require(totalCreatedMarkets == 1, "Invalid fungible token market");
            }
            mToken = mtroller.assembleToken(getTokenType(), uint72(totalCreatedMarkets), address(this));
            underlyingIDs[mToken] = underlyingTokenID;
            mTokenFromUnderlying[underlyingTokenID] = mToken;

            // Initialize block number and borrow index for the new mToken
            require(accrualBlockNumber[mToken] == 0 && borrowIndex[mToken] == 0, "Market already initialized");
            accrualBlockNumber[mToken] = getBlockNumber();
            borrowIndex[mToken] = mantissaOne;
        }

        /* Fail if mint not allowed. If allowed, this also lists the mToken market if not yet listed */
        uint error = mtroller.mintAllowed(mToken, msg.sender, mintAmount);
        require(error == uint(Error.NO_ERROR), "mint rejected by mTroller");

        /* Accrue interest (if needed this also initializes mToken interestModel and reserve factor) */
        error = accrueInterest(mToken);
        require(error == uint(Error.NO_ERROR), "mint accrue interest failed");

        MintLocalVars memory vars;

        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal(mToken);
        require(vars.mathErr == MathError.NO_ERROR, "mint exchange rate failed");

        /*
         *  We call `doTransferIn` for the msg.sender, the underlyingTokenID, and the mintAmount.
         *  Note: The mToken must handle variations between ETH, ERC-20, ERC-721, ERC-1155 underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the mToken holds an additional `actualMintAmount`
         *  of cash.
         */
        vars.actualMintAmount = doTransferIn(msg.sender, underlyingTokenID, mintAmount);

        /*
         * We get the current exchange rate and calculate the number of mTokens to be minted:
         *  mintTokens = actualMintAmount / exchangeRate
         */

        (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(vars.actualMintAmount, Exp({mantissa: vars.exchangeRateMantissa}));
        require(vars.mathErr == MathError.NO_ERROR, "MINT_EXCHANGE_CALCULATION_FAILED");
        require(vars.mintTokens > 0, "new token number is zero");

        /*
         * We calculate the new total supply of mTokens and beneficiary token balance, checking for overflow:
         *  totalSupplyNew = totalSupply + mintTokens
         *  accountTokensNew = accountTokens[beneficiary] + mintTokens
         */
        (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply[mToken], vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");

        (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[mToken][beneficiary], vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");

        (vars.mathErr, vars.totalCashNew) = addUInt(totalCashUnderlying[mToken], vars.actualMintAmount);
        require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_TOTAL_CASH_CALCULATION_FAILED");

        /* We write previously calculated values into storage */
        totalSupply[mToken] = vars.totalSupplyNew;
        accountTokens[mToken][beneficiary] = vars.accountTokensNew;
        totalCashUnderlying[mToken] = vars.totalCashNew;

        /* We emit a Mint event, and a mToken Transfer event */
        emit Mint(msg.sender, beneficiary, vars.actualMintAmount, mToken, vars.mintTokens);
        emit Transfer(address(this), beneficiary, mToken, vars.mintTokens);

        /* We call the defense hook */
        // unused function
        // mtroller.mintVerify(address(this), minter, vars.actualMintAmount, vars.mintTokens);

        return (mToken, vars.mintTokens, vars.actualMintAmount);
    }

    /**
     * @notice Sender repays their own borrow
     * @param mToken The mToken whose underlying to repay
     * @param repayAmount The amount of underlying to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function repayBorrowInternal(uint240 mToken, uint repayAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest(mToken);
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return (fail(Error(error), FailureInfo.REPAY_BORROW_ACCRUE_INTEREST_FAILED), 0);
        }
        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        return repayBorrowFresh(msg.sender, msg.sender, mToken, repayAmount);
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param mToken The mToken whose underlying to repay
     * @param repayAmount The amount of underlying to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function repayBorrowBehalfInternal(address borrower, uint240 mToken, uint repayAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest(mToken);
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return (fail(Error(error), FailureInfo.REPAY_BEHALF_ACCRUE_INTEREST_FAILED), 0);
        }
        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        return repayBorrowFresh(msg.sender, borrower, mToken, repayAmount);
    }

    struct RepayBorrowLocalVars {
        Error err;
        MathError mathErr;
        uint repayAmount;
        uint borrowerIndex;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
        uint actualRepayAmount;
        uint totalCashNew;
    }

    /**
     * @notice Borrows are repaid by another user (possibly the borrower).
     * @param payer the account paying off the borrow
     * @param borrower the account with the debt being payed off
     * @param mToken The mToken whose underlying to repay
     * @param repayAmount The amount of underlying to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function repayBorrowFresh(address payer, address borrower, uint240 mToken, uint repayAmount) internal returns (uint, uint) {
        /* Fail if repayBorrow not allowed */
        uint allowed = mtroller.repayBorrowAllowed(mToken, payer, borrower, repayAmount);
        if (allowed != 0) {
            return (failOpaque(Error.MTROLLER_REJECTION, FailureInfo.REPAY_BORROW_MTROLLER_REJECTION, allowed), 0);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber[mToken] != getBlockNumber()) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.REPAY_BORROW_FRESHNESS_CHECK), 0);
        }

        RepayBorrowLocalVars memory vars;

        /* We remember the original borrowerIndex for verification purposes */
        vars.borrowerIndex = accountBorrows[mToken][borrower].interestIndex;

        /* We fetch the amount the borrower owes, with accumulated interest */
        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower, mToken);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        /* If repayAmount == -1, repayAmount = accountBorrows */
        if (repayAmount == uint(-1)) {
            vars.repayAmount = vars.accountBorrows;
        } else {
            vars.repayAmount = repayAmount;
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the payer and the repayAmount
         *  Note: The mToken must handle variations between ETH, ERC-20, ERC-721, ERC-1155 underlying.
         *  On success, the mToken holds an additional actualRepayAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        uint256 underlyingID = underlyingIDs[mToken];
        vars.actualRepayAmount = doTransferIn(payer, underlyingID, vars.repayAmount);

        /*
         * We allow users to repay up to 2% more than their outstanding borrow, to allow for dealing with
         * uncertainties regarding e.g. interest accrual and fees during repay transaction execution. This
         * enables users to be (reasonably) sure to be able to repay their whole borrow in one transaction,
         * without leaving any remaining borrow pending, which - even if tiny - could preclude them e.g. from
         * redeeming an NFT collateral. Any overpayment remaining after paying for fees and accrued interest
         * is donated to the pool's cash.
         */
        if (vars.actualRepayAmount > vars.accountBorrows) {
            vars.repayAmount = vars.accountBorrows;
            uint overpayLimit; 
            (vars.mathErr, overpayLimit) = mulScalarTruncate(Exp({mantissa: 1.02e18}), vars.accountBorrows);
            require(vars.mathErr == MathError.NO_ERROR && vars.actualRepayAmount <= overpayLimit, "REPAY_BORROW_OVERPAY_FAILED");

        }
        else {
            vars.repayAmount = vars.actualRepayAmount;
        }

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - min(actualRepayAmount, accountBorrows)
         *  totalBorrowsNew = totalBorrows - min(actualRepayAmount, accountBorrows)
         *  totalCashNew = totalCashUnderlying[mToken] + actualRepayAmount
         */
        (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, vars.repayAmount);
        require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED");

        (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows[mToken], vars.repayAmount);
        require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED");

        (vars.mathErr, vars.totalCashNew) = addUInt(totalCashUnderlying[mToken], vars.actualRepayAmount);
        require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED");

        /* We write the previously calculated values into storage */
        accountBorrows[mToken][borrower].principal = vars.accountBorrowsNew;
        accountBorrows[mToken][borrower].interestIndex = borrowIndex[mToken];
        totalBorrows[mToken] = vars.totalBorrowsNew;
        totalCashUnderlying[mToken] = vars.totalCashNew;

        /* We emit a RepayBorrow event */
        emit RepayBorrow(payer, borrower, underlyingID, vars.actualRepayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

        /* We call the defense hook */
        // unused function
        // mtroller.repayBorrowVerify(mToken, payer, borrower, vars.actualRepayAmount, vars.borrowerIndex);

        return (uint(Error.NO_ERROR), vars.actualRepayAmount);
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this mToken to be liquidated
     * @param mTokenBorrowed The mToken with the outstanding underlying borrow
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param mTokenCollateral The mToken where to seize collateral from the borrower
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function liquidateBorrowInternal(address borrower, uint240 mTokenBorrowed, uint repayAmount, uint240 mTokenCollateral) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest(mTokenBorrowed);
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED), 0);
        }

        ( , , address collateralAddress) = mtroller.parseToken(mTokenCollateral);
        error = MTokenInterface(collateralAddress).accrueInterest(mTokenCollateral);
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED), 0);
        }

        // liquidateBorrowFresh emits borrow-specific logs on errors, so we don't need to
        return liquidateBorrowFresh(msg.sender, borrower, mTokenBorrowed, repayAmount, mTokenCollateral);
    }

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param liquidator The address repaying the borrow and seizing collateral
     * @param borrower The borrower of this mToken to be liquidated
     * @param mTokenBorrowed The mToken with the outstanding underlying borrow
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param mTokenCollateral The mToken where to seize collateral from the borrower
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function liquidateBorrowFresh(address liquidator, address borrower, uint240 mTokenBorrowed, uint repayAmount, uint240 mTokenCollateral) internal returns (uint, uint) {
        /* Fail if liquidate not allowed */
        uint allowed = mtroller.liquidateBorrowAllowed(mTokenBorrowed, mTokenCollateral, liquidator, borrower, repayAmount);
        if (allowed != 0) {
            return (failOpaque(Error.MTROLLER_REJECTION, FailureInfo.LIQUIDATE_MTROLLER_REJECTION, allowed), 0);
        }

        /* Verify mTokenBorrowed market's block number equals current block number */
        if (accrualBlockNumber[mTokenBorrowed] != getBlockNumber()) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_FRESHNESS_CHECK), 0);
        }

        /* Verify mTokenCollateral market's block number equals current block number */
        (MtrollerInterface.MTokenType collateralType, , address collateralAddress) = mtroller.parseToken(mTokenCollateral);
        if (MTokenCommon(collateralAddress).accrualBlockNumber(mTokenCollateral) != getBlockNumber()) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_COLLATERAL_FRESHNESS_CHECK), 0);
        }

        /* Fail if trying to directly liquidate a non-fungible collateral (need to use liquidateToPaymentToken instead) */
        if (collateralType != MTokenIdentifier.MTokenType.FUNGIBLE_MTOKEN) {
            return (fail(Error.INVALID_COLLATERAL, FailureInfo.LIQUIDATE_COLLATERAL_NOT_FUNGIBLE), 0);
        }
        
        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            return (fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_LIQUIDATOR_IS_BORROWER), 0);
        }

        /* Fail if repayAmount = 0 */
        if (repayAmount == 0) {
            return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_ZERO), 0);
        }

        /* Fail if repayAmount = -1 */
        if (repayAmount == uint(-1)) {
            return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX), 0);
        }

        /* Fail if repayBorrow fails */
        (uint seizeError, uint actualRepayAmount) = repayBorrowFresh(liquidator, borrower, mTokenBorrowed, repayAmount);
        if (seizeError != uint(Error.NO_ERROR)) {
            return (fail(Error(seizeError), FailureInfo.LIQUIDATE_REPAY_BORROW_FRESH_FAILED), 0);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We calculate the number of collateral tokens that will be seized */
        uint seizeTokens;
        (seizeError, seizeTokens) = mtroller.liquidateCalculateSeizeTokens(mTokenBorrowed, mTokenCollateral, actualRepayAmount);
        require(seizeError == uint(Error.NO_ERROR), "LIQUIDATE_MTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

        /* Revert if borrower collateral token balance < seizeTokens */
        require(MTokenInterface(collateralAddress).balanceOf(borrower, mTokenCollateral) >= seizeTokens, "LIQUIDATE_SEIZE_TOO_MUCH");

        // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
        if (collateralAddress == address(this)) {
            seizeError = seizeInternal(mTokenBorrowed, liquidator, borrower, mTokenCollateral, seizeTokens);
        } else {
            seizeError = MTokenInterface(collateralAddress).seize(mTokenBorrowed, liquidator, borrower, mTokenCollateral, seizeTokens);
        }

        /* Revert if seize tokens fails (since we cannot be sure of side effects) */
        require(seizeError == uint(Error.NO_ERROR), "token seizure failed");

        /* We emit a LiquidateBorrow event */
        emit LiquidateBorrow(liquidator, borrower, mTokenBorrowed, actualRepayAmount, mTokenCollateral, seizeTokens);

        /* We call the defense hook */
        // unused function
        // mtroller.liquidateBorrowVerify(address(this), address(mTokenCollateral), liquidator, borrower, actualRepayAmount, seizeTokens);

        return (uint(Error.NO_ERROR), actualRepayAmount);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Will fail unless called by another mToken during the process of liquidation.
     *  Its absolutely critical to use msg.sender as the borrowed mToken and not a parameter.
     * @param mTokenBorrowed The mToken doing the seizing (i.e., borrowed mToken market)
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param mTokenCollateral The mToken to seize (this market)
     * @param seizeTokens The number of mTokenCollateral tokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function seize(uint240 mTokenBorrowed, address liquidator, address borrower, uint240 mTokenCollateral, uint seizeTokens) external nonReentrant returns (uint) {
        ( , , address seizerAddress) = mtroller.parseToken(mTokenBorrowed);
        require(msg.sender == seizerAddress, "Only seizer mToken contract can seize the tokens");
        return seizeInternal(mTokenBorrowed, liquidator, borrower, mTokenCollateral, seizeTokens);
    }

    struct SeizeInternalLocalVars {
        MathError mathErr;
        uint borrowerTokensNew;
        uint liquidatorTokensNew;
        uint liquidatorSeizeTokens;
        uint protocolSeizeTokens;
        uint protocolSeizeAmount;
        uint exchangeRateMantissa;
        uint totalReservesNew;
        uint totalSupplyNew;
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
     *  Its absolutely critical to use msg.sender as the seizer mToken and not a parameter.
     * @param mTokenBorrowed The contract seizing the collateral (i.e. borrowed mToken market)
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param mTokenCollateral The mToken to seize (this market)
     * @param seizeTokens The number of mTokenCollateral tokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function seizeInternal(uint240 mTokenBorrowed, address liquidator, address borrower, uint240 mTokenCollateral, uint seizeTokens) internal returns (uint) {
        /* Fail if seize not allowed */
        uint allowed = mtroller.seizeAllowed(mTokenCollateral, mTokenBorrowed, liquidator, borrower, seizeTokens);
        if (allowed != 0) {
            return failOpaque(Error.MTROLLER_REJECTION, FailureInfo.LIQUIDATE_SEIZE_MTROLLER_REJECTION, allowed);
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            return fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER);
        }

        SeizeInternalLocalVars memory vars;

        /*
         * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
         *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
         *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
         */
        (vars.mathErr, vars.borrowerTokensNew) = subUInt(accountTokens[mTokenCollateral][borrower], seizeTokens);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED, uint(vars.mathErr));
        }

        vars.protocolSeizeTokens = mul_(seizeTokens, Exp({mantissa: protocolSeizeShareMantissa}));
        vars.liquidatorSeizeTokens = sub_(seizeTokens, vars.protocolSeizeTokens);

        /* if the protocol charges a liquidation fee, it is credited to this contract's reserves */
        if (vars.protocolSeizeTokens > 0) {
            (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal(mTokenCollateral);
            require(vars.mathErr == MathError.NO_ERROR, "exchange rate math error");

            vars.protocolSeizeAmount = mul_ScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), vars.protocolSeizeTokens);

            vars.totalReservesNew = add_(totalReserves[mTokenCollateral], vars.protocolSeizeAmount);
            vars.totalSupplyNew = sub_(totalSupply[mTokenCollateral], vars.protocolSeizeTokens);
        }

        (vars.mathErr, vars.liquidatorTokensNew) = addUInt(accountTokens[mTokenCollateral][liquidator], vars.liquidatorSeizeTokens);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED, uint(vars.mathErr));
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage and emit a Transfer event */
        accountTokens[mTokenCollateral][borrower] = vars.borrowerTokensNew;
        accountTokens[mTokenCollateral][liquidator] = vars.liquidatorTokensNew;
        emit Transfer(borrower, liquidator, mTokenCollateral, vars.liquidatorSeizeTokens);

        /* only need to update reserves and supply in case of a protocol fee */
        if (vars.protocolSeizeTokens > 0) {
            totalReserves[mTokenCollateral] = vars.totalReservesNew;
            totalSupply[mTokenCollateral] = vars.totalSupplyNew;
            emit Transfer(borrower, address(this), mTokenCollateral, vars.protocolSeizeTokens);
            emit ReservesAdded(address(this), mTokenCollateral, vars.protocolSeizeAmount, vars.totalReservesNew);
        }

        /* We call the defense hook */
        // unused function
        // mtroller.seizeVerify(mTokenCollateral, mTokenBorrowed, liquidator, borrower, seizeTokens);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accrues interest and reduces reserves for mToken by transferring from msg.sender
     * @param mToken The mToken whose reserves to increase
     * @param addAmount Amount of addition to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReservesInternal(uint240 mToken, uint addAmount) internal nonReentrant returns (uint) {
        uint error = accrueInterest(mToken);
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
            return fail(Error(error), FailureInfo.ADD_RESERVES_ACCRUE_INTEREST_FAILED);
        }

        // _addReservesFresh emits reserve-addition-specific logs on errors, so we don't need to.
        (error, ) = _addReservesFresh(mToken, addAmount);
        return error;
    }

    /**
     * @notice Add reserves to mToken by transferring from caller
     * @dev Requires fresh interest accrual
     * @param mToken The mToken whose reserves to increase
     * @param addAmount Amount of addition to reserves
     * @return (uint, uint) An error code (0=success, otherwise a failure (see ErrorReporter.sol for details)) and the actual amount added, net token fees
     */
    function _addReservesFresh(uint240 mToken, uint addAmount) internal returns (uint, uint) {
        MathError mathErr;
        uint totalReservesNew;
        uint totalCashNew;
        uint actualAddAmount;

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber[mToken] != getBlockNumber()) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.ADD_RESERVES_FRESH_CHECK), addAmount);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the caller and the addAmount
         *  Note: The mToken must handle variations between ETH, ERC-20, ERC-721, ERC-1155 underlying.
         *  On success, the mToken holds an additional addAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *  it returns the amount actually transferred, in case of a fee.
         */

        uint256 underlyingID = underlyingIDs[mToken];
        actualAddAmount = doTransferIn(msg.sender, underlyingID, addAmount);

        /* Add actualAddAmount to totalReserves and totalCash, revert on overflow */
        (mathErr, totalReservesNew) = addUInt(totalReserves[mToken], actualAddAmount);
        require(mathErr == MathError.NO_ERROR, "ADD_RESERVES_TOTAL_RESERVES_CALCULATION_FAILED");

        (mathErr, totalCashNew) = addUInt(totalCashUnderlying[mToken], actualAddAmount);
        require(mathErr == MathError.NO_ERROR, "ADD_RESERVES_TOTAL_CASH_CALCULATION_FAILED");

        // Store new values for total reserves and total cash
        totalReserves[mToken] = totalReservesNew;
        totalCashUnderlying[mToken] = totalCashNew;

        emit ReservesAdded(msg.sender, mToken, actualAddAmount, totalReservesNew);

        /* Return (NO_ERROR, actualAddAmount) */
        return (uint(Error.NO_ERROR), actualAddAmount);
    }

    /**
     * @notice Transfers underlying assets into this contract
     * @dev Performs a transfer in, reverting upon failure. This may revert due to insufficient 
     * balance or insufficient allowance.
     * @param from the address where to transfer underlying assets from
     * @param underlyingID the ID of the underlying asset (in case of a NFT) or 1 (in case of a fungible asset)
     * @param amount the amount of underlying to transfer (for fungible assets) or 1 (for NFTs)
     * @return (uint) Returns the amount actually transferred to the protocol (in case of a fee).
     */
    function doTransferIn(address from, uint256 underlyingID, uint amount) internal returns (uint);
}