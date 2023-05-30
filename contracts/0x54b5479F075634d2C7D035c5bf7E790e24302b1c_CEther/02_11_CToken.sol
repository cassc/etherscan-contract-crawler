pragma solidity ^0.5.16;

import "./ComptrollerInterface.sol";
import "./CTokenInterfaces.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./EIP20Interface.sol";
import "./EIP20NonStandardInterface.sol";
import "./InterestRateModel.sol";

contract CToken is CTokenInterface, Exponential, TokenErrorReporter {
    function initialize(ComptrollerInterface comptroller_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_) public {
        require(msg.sender == admin, "only admin may initialize the market");
        require(accrualBlockNumber == 0 && borrowIndex == 0, "market may only be initialized once");

        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        require(initialExchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

        uint err = _setComptroller(comptroller_);
        require(err == uint(Error.NO_ERROR), "setting comptroller failed");

        accrualBlockNumber = getBlockNumber();
        borrowIndex = mantissaOne;

        err = _setInterestRateModelFresh(interestRateModel_);
        require(err == uint(Error.NO_ERROR), "setting interest rate model failed");

        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        _notEntered = true;
    }

    function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {
        uint allowed = comptroller.transferAllowed(address(this), src, dst, tokens);
        require(allowed == 0, "TRANSFER_COMPTROLLER_REJECTION");
        require(src != dst, "EQUAL_SRC_DST");

        uint startingAllowance = 0;
        if (spender == src) {
            startingAllowance = uint(-1);
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        MathError mathErr;
        uint allowanceNew;
        uint srcTokensNew;
        uint dstTokensNew;

        (mathErr, allowanceNew) = subUInt(startingAllowance, tokens);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_ALLOWANCE");

        (mathErr, srcTokensNew) = subUInt(accountTokens[src], tokens);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_SRC_TOKENS");

        (mathErr, dstTokensNew) = addUInt(accountTokens[dst], tokens);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_DST_TOKENS");

        accountTokens[src] = srcTokensNew;
        accountTokens[dst] = dstTokensNew;

        if (startingAllowance != uint(-1)) {
            transferAllowances[src][spender] = allowanceNew;
        }

        emit Transfer(src, dst, tokens);

        return uint(Error.NO_ERROR);
    }

    function transfer(address dst, uint256 amount) external nonReentrant returns (bool) {
        return transferTokens(msg.sender, msg.sender, dst, amount) == uint(Error.NO_ERROR);
    }

    function transferFrom(address src, address dst, uint256 amount) external nonReentrant returns (bool) {
        return transferTokens(msg.sender, src, dst, amount) == uint(Error.NO_ERROR);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    function balanceOf(address owner) external view returns (uint256) {
        return accountTokens[owner];
    }

    function balanceOfUnderlying(address owner) external returns (uint) {
        Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
        (MathError mErr, uint balance) = mulScalarTruncate(exchangeRate, accountTokens[owner]);
        require(mErr == MathError.NO_ERROR, "UNDERLYING_BALANCE_CANNOT_CALCULATED");
        return balance;
    }

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint) {
        uint cTokenBalance = accountTokens[account];
        uint borrowBalance;
        uint exchangeRateMantissa;

        MathError mErr;

        (mErr, borrowBalance) = borrowBalanceStoredInternal(account);
        require(mErr == MathError.NO_ERROR, "MATH_ERROR_BORROW_BALANCE");
                
        (mErr, exchangeRateMantissa) = exchangeRateStoredInternal();
        require(mErr == MathError.NO_ERROR, "MATH_ERROR_EXCHANGERATE");

        return (uint(Error.NO_ERROR), cTokenBalance, borrowBalance, exchangeRateMantissa);
    }

    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    function borrowRatePerBlock() external view returns (uint) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
    }

    function supplyRatePerBlock() external view returns (uint) {
        return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
    }

    function totalBorrowsCurrent() external nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");
        return totalBorrows;
    }

    function borrowBalanceCurrent(address account) external nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");
        return borrowBalanceStored(account);
    }

    function borrowBalanceStored(address account) public view returns (uint) {
        (MathError err, uint result) = borrowBalanceStoredInternal(account);
        require(err == MathError.NO_ERROR, "MATH_ERROR_BORROW_BALANCE_STORED");
        return result;
    }

    function borrowBalanceStoredInternal(address account) internal view returns (MathError, uint) {
        MathError mathErr;
        uint principalTimesIndex;
        uint result;

        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];
        if (borrowSnapshot.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }

        (mathErr, principalTimesIndex) = mulUInt(borrowSnapshot.principal, borrowIndex);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_PRINCIPAL_TIMES_INDEX");

        (mathErr, result) = divUInt(principalTimesIndex, borrowSnapshot.interestIndex);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_PRINCIPAL_TIMES_INDEX_DIV");

        return (MathError.NO_ERROR, result);
    }

    function exchangeRateCurrent() public nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");
        return exchangeRateStored();
    }

    function exchangeRateStored() public view returns (uint) {
        (MathError err, uint result) = exchangeRateStoredInternal();
        require(err == MathError.NO_ERROR, "MATH_ERROR_EXCHANGE_RATE_SOTRED");
        return result;
    }

    function exchangeRateStoredInternal() internal view returns (MathError, uint) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            return (MathError.NO_ERROR, initialExchangeRateMantissa);
        } else {
            uint totalCash = getCashPrior();
            uint cashPlusBorrowsMinusReserves;
            Exp memory exchangeRate;
            MathError mathErr;

            (mathErr, cashPlusBorrowsMinusReserves) = addThenSubUInt(totalCash, totalBorrows, totalReserves);
            require(mathErr == MathError.NO_ERROR, "MATH_ERROR_CASH_PLUS_BORROWS_MINUS_RESERVES");

            (mathErr, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
            require(mathErr == MathError.NO_ERROR, "MATH_ERROR_EXCHANGE_RATE");

            return (MathError.NO_ERROR, exchangeRate.mantissa);
        }
    }

    function getCash() external view returns (uint) {
        return getCashPrior();
    }

    function accrueInterest() public returns (uint) {
        uint currentBlockNumber = getBlockNumber();
        uint accrualBlockNumberPrior = accrualBlockNumber;

        if (accrualBlockNumberPrior == currentBlockNumber) {
            return uint(Error.NO_ERROR);
        }

        uint cashPrior = getCashPrior();
        uint borrowsPrior = totalBorrows;
        uint reservesPrior = totalReserves;
        uint borrowIndexPrior = borrowIndex;

        uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
        require(borrowRateMantissa <= borrowRateMaxMantissa, "BORROW_RATE_ABSURDLY_HIGH");

        (MathError mathErr, uint blockDelta) = subUInt(currentBlockNumber, accrualBlockNumberPrior);
        require(mathErr == MathError.NO_ERROR, "CANNOT_CALULATE_BLOCK_DELTA");

        Exp memory simpleInterestFactor;
        uint interestAccumulated;
        uint totalBorrowsNew;
        uint totalReservesNew;
        uint borrowIndexNew;

        (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa: borrowRateMantissa}), blockDelta);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_SIMPLE_INTEREST_FACTOR");

        (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, borrowsPrior);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_INTEREST_ACCUMULATED");

        (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, borrowsPrior);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_TOTAL_BORROW");

        (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, reservesPrior);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_TOTAL_RESERVES");

        (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_BORROW_INDEX");

        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return uint(Error.NO_ERROR);
    }

    function mintInternal(uint mintAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        require(error == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");
        return mintFresh(msg.sender, mintAmount);
    }

    struct MintLocalVars {
        Error err;
        MathError mathErr;
        uint exchangeRateMantissa;
        uint mintTokens;
        uint totalSupplyNew;
        uint accountTokensNew;
        uint actualMintAmount;
    }

    function mintFresh(address minter, uint mintAmount) internal returns (uint, uint) {
        uint allowed = comptroller.mintAllowed(address(this), minter, mintAmount);
        require(allowed == 0, "MINT_COMPTROLLER_REJECTION");
        require(accrualBlockNumber == getBlockNumber(), "NOT_EQUAL_BLOCKNUMBER");

        MintLocalVars memory vars;

        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_EXCHANGE_RATE");

        vars.actualMintAmount = doTransferIn(minter, mintAmount);

        (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(vars.actualMintAmount, Exp({mantissa: vars.exchangeRateMantissa}));
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_MINT_TOKENS");

        (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply, vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_TOTAL_SUPPLY");

        (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[minter], vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_ACCOUNT_TOKENS");

        totalSupply = vars.totalSupplyNew;
        accountTokens[minter] = vars.accountTokensNew;

        emit Mint(minter, vars.actualMintAmount, vars.mintTokens);
        emit Transfer(address(this), minter, vars.mintTokens);

        return (uint(Error.NO_ERROR), vars.actualMintAmount);
    }

    function redeemInternal(uint redeemTokens) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        require(error == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");

        return redeemFresh(msg.sender, redeemTokens, 0);
    }

    function redeemUnderlyingInternal(uint redeemAmount) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        require(error == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");
        return redeemFresh(msg.sender, 0, redeemAmount);
    }

    struct RedeemLocalVars {
        Error err;
        MathError mathErr;
        uint exchangeRateMantissa;
        uint redeemTokens;
        uint redeemAmount;
        uint totalSupplyNew;
        uint accountTokensNew;
    }

    function redeemFresh(address payable redeemer, uint redeemTokensIn, uint redeemAmountIn) internal returns (uint) {
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "INPUT_ALL_NOT_ZERO");

        RedeemLocalVars memory vars;

        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_EXCHANGE_RATE");

        if (redeemTokensIn > 0) {
            vars.redeemTokens = redeemTokensIn;
            (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), redeemTokensIn);
            require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_REDEEM_AMOUNT");
        } else {
            (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(redeemAmountIn, Exp({mantissa: vars.exchangeRateMantissa}));
            require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_REDEEM_TOKENS");
            vars.redeemAmount = redeemAmountIn;
        }

        uint allowed = comptroller.redeemAllowed(address(this), redeemer, vars.redeemTokens);
        require(allowed == 0, "REDEEM_COMPTROLLER_REJECTION");

        require(accrualBlockNumber == getBlockNumber(), "NOT_EQUAL_BLOCKNUMBER");

        (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply, vars.redeemTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_TOTAL_SUPPLY");

        (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[redeemer], vars.redeemTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_ACCOUNT_TOKENS");

        require(getCashPrior() >= vars.redeemAmount, "INSUFFICIENT_CASH");

        doTransferOut(redeemer, vars.redeemAmount);

        totalSupply = vars.totalSupplyNew;
        accountTokens[redeemer] = vars.accountTokensNew;

        emit Transfer(redeemer, address(this), vars.redeemTokens);
        emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens);

        comptroller.redeemVerify(address(this), redeemer, vars.redeemAmount, vars.redeemTokens);

        return uint(Error.NO_ERROR);
    }

    function borrowInternal(uint borrowAmount) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        require(error == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");
        return borrowFresh(msg.sender, borrowAmount);
    }

    struct BorrowLocalVars {
        MathError mathErr;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
    }

    function borrowFresh(address payable borrower, uint borrowAmount) internal returns (uint) {
        uint allowed = comptroller.borrowAllowed(address(this), borrower, borrowAmount);
        require(allowed == 0, "BORROW_COMPTROLLER_REJECTION");

        require(accrualBlockNumber == getBlockNumber(), "NOT_EQUAL_BLOCKNUMBER");
        require(getCashPrior() >= borrowAmount, "INSUFFICIENT_CASH");

        BorrowLocalVars memory vars;

        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_ACCOUNT_BORROWS");

        (vars.mathErr, vars.accountBorrowsNew) = addUInt(vars.accountBorrows, borrowAmount);
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_ACCOUNT_BORROWS_NEW");

        (vars.mathErr, vars.totalBorrowsNew) = addUInt(totalBorrows, borrowAmount);
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_TOTAL_BORROWS");

        doTransferOut(borrower, borrowAmount);

        accountBorrows[borrower].principal = vars.accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        emit Borrow(borrower, borrowAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

        return uint(Error.NO_ERROR);
    }

    function repayBorrowInternal(uint repayAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        require(error == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");
        return repayBorrowFresh(msg.sender, msg.sender, repayAmount);
    }

    function repayBorrowBehalfInternal(address borrower, uint repayAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        require(error == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");
        return repayBorrowFresh(msg.sender, borrower, repayAmount);
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
    }

    function repayBorrowFresh(address payer, address borrower, uint repayAmount) internal returns (uint, uint) {
        uint allowed = comptroller.repayBorrowAllowed(address(this), payer, borrower, repayAmount);
        require(allowed == 0, "BORROW_COMPTROLLER_REJECTION");

        require(accrualBlockNumber == getBlockNumber(), "NOT_EQUAL_BLOCKNUMBER");

        RepayBorrowLocalVars memory vars;

        vars.borrowerIndex = accountBorrows[borrower].interestIndex;

        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_ACCOUNT_BORROWS");

        if (repayAmount == uint(-1)) {
            vars.repayAmount = vars.accountBorrows;
        } else {
            vars.repayAmount = repayAmount;
        }

        vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);

        (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, vars.actualRepayAmount);
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_ACCOUNT_BORROWS");

        (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows, vars.actualRepayAmount);
        require(vars.mathErr == MathError.NO_ERROR, "MATH_ERROR_TOTAL_BORROWS");

        accountBorrows[borrower].principal = vars.accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        emit RepayBorrow(payer, borrower, vars.actualRepayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

        return (uint(Error.NO_ERROR), vars.actualRepayAmount);
    }

    function liquidateBorrowInternal(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        require(error == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");

        error = cTokenCollateral.accrueInterest();
        require(error == uint(Error.NO_ERROR), "CALLATERAL_ACCRUE_INTEREST_FAILED");

        return liquidateBorrowFresh(msg.sender, borrower, repayAmount, cTokenCollateral);
    }

    function liquidateBorrowFresh(address liquidator, address borrower, uint repayAmount, CTokenInterface cTokenCollateral) internal returns (uint, uint) {
        uint allowed = comptroller.liquidateBorrowAllowed(address(this), address(cTokenCollateral), liquidator, borrower, repayAmount);
        require(allowed == 0, "LIQUIDATE_COMPTROLLER_REJECTION");

        require(accrualBlockNumber == getBlockNumber(), "NOT_EQUAL_BLOCKNUMBER");
        require(cTokenCollateral.accrualBlockNumber() == getBlockNumber(), "COLLATERAL_NOT_EQUAL_BLOCKNUMBER");
        require(borrower != liquidator, "EQUAL_BORROWER_LIQUIDATOR");
        require(repayAmount != 0, "REPAY_AMOUNT_IS_ZERO");
        require(repayAmount != uint(-1), "INVALID_REPAY_AMOUNT");

        (uint repayBorrowError, uint actualRepayAmount) = repayBorrowFresh(liquidator, borrower, repayAmount);
        require(repayBorrowError == uint(Error.NO_ERROR), "LIQUIDATE_REPAY_BORROW_FRESH_FAILED");

        (uint amountSeizeError, uint seizeTokens) = comptroller.liquidateCalculateSeizeTokens(address(this), address(cTokenCollateral), actualRepayAmount);
        require(amountSeizeError == uint(Error.NO_ERROR), "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

        require(cTokenCollateral.balanceOf(borrower) >= seizeTokens, "LIQUIDATE_SEIZE_TOO_MUCH");
    
        uint seizeError;
        if (address(cTokenCollateral) == address(this)) {
            seizeError = seizeInternal(address(this), liquidator, borrower, seizeTokens);
        } else {
            seizeError = cTokenCollateral.seize(liquidator, borrower, seizeTokens);
        }

        require(seizeError == uint(Error.NO_ERROR), "TOKEN_SEIZURE_FAILED");

        emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(cTokenCollateral), seizeTokens);

        return (uint(Error.NO_ERROR), actualRepayAmount);
    }

    function seize(address liquidator, address borrower, uint seizeTokens) external nonReentrant returns (uint) {
        return seizeInternal(msg.sender, liquidator, borrower, seizeTokens);
    }

    function seizeInternal(address seizerToken, address liquidator, address borrower, uint seizeTokens) internal returns (uint) {
        uint allowed = comptroller.seizeAllowed(address(this), seizerToken, liquidator, borrower, seizeTokens);
        require(allowed == 0, "LIQUIDATE_SEIZE_COMPTROLLER_REJECTION");

        require(borrower != liquidator, "EQUAL_BORROWER_LIQUIDATOR");

        MathError mathErr;
        uint borrowerTokensNew;
        uint liquidatorTokensNew;

        (mathErr, borrowerTokensNew) = subUInt(accountTokens[borrower], seizeTokens);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_BORROWER_TOKENS");
        (mathErr, liquidatorTokensNew) = addUInt(accountTokens[liquidator], seizeTokens);
        require(mathErr == MathError.NO_ERROR, "MATH_ERROR_LIQUIDATOR_TOKENS");

        accountTokens[borrower] = borrowerTokensNew;
        accountTokens[liquidator] = liquidatorTokensNew;

        emit Transfer(borrower, liquidator, seizeTokens);

        return uint(Error.NO_ERROR);
    }

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint) {
        require(msg.sender == admin, "SET_PENDING_ADMIN_OWNER_CHECK");

        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    function _acceptAdmin() external returns (uint) {
        require(msg.sender == pendingAdmin && msg.sender != address(0), "ACCEPT_ADMIN_PENDING_ADMIN_CHECK");

        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        admin = pendingAdmin;
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return uint(Error.NO_ERROR);
    }

    function _setComptroller(ComptrollerInterface newComptroller) public returns (uint) {
       require(msg.sender == admin, "SET_COMPTROLLER_OWNER_CHECK");

        ComptrollerInterface oldComptroller = comptroller;
        require(newComptroller.isComptroller(), "ISNOT_COMPTROLLER");

        comptroller = newComptroller;

        emit NewComptroller(oldComptroller, newComptroller);

        return uint(Error.NO_ERROR);
    }

    function _setReserveFactor(uint newReserveFactorMantissa) external nonReentrant returns (uint) {
        uint error = accrueInterest();
        require(error == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    function _setReserveFactorFresh(uint newReserveFactorMantissa) internal returns (uint) {
        require(msg.sender == admin, "SET_RESERVE_FACTOR_ADMIN_CHECK");
        require(accrualBlockNumber == getBlockNumber(), "NOT_EQUAL_BLOCKNUMBER");
        require(newReserveFactorMantissa <= reserveFactorMaxMantissa, "SET_RESERVE_FACTOR_BOUNDS_CHECK");

        uint oldReserveFactorMantissa = reserveFactorMantissa;
        reserveFactorMantissa = newReserveFactorMantissa;

        emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    function _addReservesInternal(uint addAmount) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        require(error == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");

        (error, ) = _addReservesFresh(addAmount);
        return error;
    }

    function _addReservesFresh(uint addAmount) internal returns (uint, uint) {
        uint totalReservesNew;
        uint actualAddAmount;

        require(accrualBlockNumber == getBlockNumber(), "NOT_EQUAL_BLOCKNUMBER");

        actualAddAmount = doTransferIn(msg.sender, addAmount);

        totalReservesNew = totalReserves + actualAddAmount;
        require(totalReservesNew >= totalReserves, "MATH_ERROR_TOTAL_RESERVES");

        totalReserves = totalReservesNew;

        emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

        return (uint(Error.NO_ERROR), actualAddAmount);
    }

    function _reduceReserves(uint reduceAmount) external nonReentrant returns (uint) {
        uint error = accrueInterest();
        require(error == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");
        return _reduceReservesFresh(reduceAmount);
    }

    function _reduceReservesFresh(uint reduceAmount) internal returns (uint) {
        uint totalReservesNew;
        require(msg.sender == admin, "REDUCE_RESERVES_ADMIN_CHECK");
        require(accrualBlockNumber == getBlockNumber(), "NOT_EQUAL_BLOCKNUMBER");
        require(getCashPrior() >= reduceAmount, "INSUFFICIENT_CASH");
        require(reduceAmount <= totalReserves, "INSUFFICIENT_TOTAL_RESERVES");

        totalReservesNew = totalReserves - reduceAmount;
        require(totalReservesNew <= totalReserves, "MATH_ERROR_TOTAL_RESERVES");

        totalReserves = totalReservesNew;

        doTransferOut(admin, reduceAmount);

        emit ReservesReduced(admin, reduceAmount, totalReservesNew);

        return uint(Error.NO_ERROR);
    }

    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint) {
        uint error = accrueInterest();
        require(error == uint(Error.NO_ERROR), "ACCRUE_INTEREST_FAILED");
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal returns (uint) {
        InterestRateModel oldInterestRateModel;
        require(msg.sender == admin, "SET_INTEREST_RATE_MODEL_OWNER_CHECK");
        require(accrualBlockNumber == getBlockNumber(), "NOT_EQUAL_BLOCKNUMBER");

        oldInterestRateModel = interestRateModel;
        require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

        interestRateModel = newInterestRateModel;

        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

        return uint(Error.NO_ERROR);
    }

    function getCashPrior() internal view returns (uint);

    function doTransferIn(address from, uint amount) internal returns (uint);

    function doTransferOut(address payable to, uint amount) internal;

    modifier nonReentrant() {
        require(_notEntered, "REENTERED");
        _notEntered = false;
        _;
        _notEntered = true; 
    }
}