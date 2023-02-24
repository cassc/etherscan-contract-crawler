// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./MTokenStorage.sol";
import "./interfaces/IInterestRateModel.sol";
import "./libraries/ErrorCodes.sol";

/**
 * @title Minterest MToken Contract
 * @notice Abstract base for MTokens
 * @author Minterest
 */
contract MToken is MTokenStorage {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the money market
     * @param supervisor_ The address of the Supervisor
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ EIP-20 name of this token
     * @param symbol_ EIP-20 symbol of this token
     * @param decimals_ EIP-20 decimal precision of this token
     * @param underlying_ The address of the underlying asset
     */
    function initialize(
        address admin_,
        ISupervisor supervisor_,
        IInterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        IERC20 underlying_
    ) external initializer {
        // Set initial exchange rate
        require(initialExchangeRateMantissa_ > 0, ErrorCodes.ZERO_EXCHANGE_RATE);
        initialExchangeRateMantissa = initialExchangeRateMantissa_;

        // Set the supervisor
        supervisor = supervisor_;

        // Initialize block number and borrow index (block number mocks depend on supervisor being set)
        accrualBlockNumber = getBlockNumber();
        borrowIndex = EXP_SCALE; // = 1e18

        // Set the interest rate model (depends on block number / borrow index)
        setInterestRateModelFresh(interestRateModel_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TIMELOCK, admin_);

        underlying = underlying_;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        maxFlashLoanShare = 1.0e18; // 100%
        flashLoanFeeShare = 0.0009e18; // 0.09%
    }

    /// @inheritdoc IMToken
    function totalSupply() external view returns (uint256) {
        return totalTokenSupply;
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     */
    function transferTokens(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) internal {
        /* Do not allow self-transfers */
        require(src != dst, ErrorCodes.INVALID_DESTINATION);

        // Reverts if transfer is not allowed
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        supervisor.beforeTransfer(this, src, dst, tokens);

        /* Get the allowance, infinite for the account owner */
        uint256 startingAllowance = 0;
        if (spender == src) {
            startingAllowance = type(uint256).max;
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS

        accountTokens[src] -= tokens;
        accountTokens[dst] += tokens;

        if (startingAllowance != type(uint256).max) {
            transferAllowances[src][spender] = startingAllowance - tokens;
        }

        emit Transfer(src, dst, tokens);
    }

    /// @inheritdoc IMToken
    function transfer(address dst, uint256 amount) external nonReentrant returns (bool) {
        transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    /// @inheritdoc IMToken
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external nonReentrant returns (bool) {
        transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    /// @inheritdoc IMToken
    function approve(address spender, uint256 amount) external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /// @inheritdoc IMToken
    function allowance(address owner, address spender) external view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /// @inheritdoc IMToken
    function balanceOf(address owner) external view returns (uint256) {
        return accountTokens[owner];
    }

    /// @inheritdoc IMToken
    function balanceOfUnderlying(address owner) external returns (uint256) {
        return (accountTokens[owner] * exchangeRateCurrent()) / EXP_SCALE;
    }

    /// @inheritdoc IMToken
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 mTokenBalance = accountTokens[account];
        uint256 borrowBalance = borrowBalanceStoredInternal(account);
        uint256 exchangeRateMantissa = exchangeRateStoredInternal();
        return (mTokenBalance, borrowBalance, exchangeRateMantissa);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    /// @inheritdoc IMToken
    function borrowRatePerBlock() external view returns (uint256) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalProtocolInterest);
    }

    /// @inheritdoc IMToken
    function supplyRatePerBlock() external view returns (uint256) {
        return
            interestRateModel.getSupplyRate(
                getCashPrior(),
                totalBorrows,
                totalProtocolInterest,
                protocolInterestFactorMantissa
            );
    }

    /// @inheritdoc IMToken
    function totalBorrowsCurrent() external nonReentrant returns (uint256) {
        accrueInterest();
        return totalBorrows;
    }

    /// @inheritdoc IMToken
    function borrowBalanceCurrent(address account) external nonReentrant returns (uint256) {
        accrueInterest();
        return borrowBalanceStored(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) public view returns (uint256) {
        return borrowBalanceStoredInternal(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return the calculated balance
     */
    function borrowBalanceStoredInternal(address account) internal view returns (uint256) {
        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) return 0;

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        return (borrowSnapshot.principal * borrowIndex) / borrowSnapshot.interestIndex;
    }

    /// @inheritdoc IMToken
    function exchangeRateCurrent() public nonReentrant returns (uint256) {
        accrueInterest();
        return exchangeRateStored();
    }

    /// @inheritdoc IMToken
    function exchangeRateStored() public view returns (uint256) {
        return exchangeRateStoredInternal();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return calculated exchange rate scaled by 1e18
     */
    function exchangeRateStoredInternal() internal view virtual returns (uint256) {
        if (totalTokenSupply == 0) {
            /*
             * If there are no tokens lent:
             *  exchangeRate = initialExchangeRate
             */
            return initialExchangeRateMantissa;
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalProtocolInterest) / totalTokenSupply
             */
            return ((getCashPrior() + totalBorrows - totalProtocolInterest) * EXP_SCALE) / totalTokenSupply;
        }
    }

    /// @inheritdoc IMToken
    function getCash() external view returns (uint256) {
        return getCashPrior();
    }

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() internal view virtual returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /// @inheritdoc IMToken
    function accrueInterest() public virtual {
        /* Remember the initial block number */
        uint256 currentBlockNumber = getBlockNumber();
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) return;

        /* Read the previous values out of storage */
        uint256 cashPrior = getCashPrior();
        uint256 borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint256 borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, totalBorrows, totalProtocolInterest);
        require(borrowRateMantissa <= borrowRateMaxMantissa, ErrorCodes.BORROW_RATE_TOO_HIGH);

        /* Calculate the number of blocks elapsed since the last accrual */
        uint256 blockDelta = currentBlockNumber - accrualBlockNumberPrior;

        /*
         * Calculate the interest accumulated into borrows and protocol interest and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrows += interestAccumulated
         *  totalProtocolInterest += interestAccumulated * protocolInterestFactor
         *  borrowIndex = simpleInterestFactor * borrowIndex + borrowIndex
         */
        uint256 simpleInterestFactor = borrowRateMantissa * blockDelta;
        uint256 interestAccumulated = (totalBorrows * simpleInterestFactor) / EXP_SCALE;
        totalBorrows += interestAccumulated;
        totalProtocolInterest += (interestAccumulated * protocolInterestFactorMantissa) / EXP_SCALE;
        borrowIndex = borrowIndexPrior + (borrowIndexPrior * simpleInterestFactor) / EXP_SCALE;

        accrualBlockNumber = currentBlockNumber;

        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndex, totalBorrows, totalProtocolInterest);
    }

    /// @inheritdoc IMToken
    function lend(uint256 lendAmount) external {
        accrueInterest();
        lendFresh(msg.sender, lendAmount, true);
    }

    /**
     * @notice Account supplies assets into the market and receives mTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param lender The address of the account which is supplying the assets
     * @param lendAmount The amount of the underlying asset to supply
     * @return actualLendAmount actual lend amount
     */
    function lendFresh(
        address lender,
        uint256 lendAmount,
        bool isERC20based
    ) internal nonReentrant returns (uint256 actualLendAmount) {
        supervisor.beforeLend(this, lender);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        uint256 exchangeRateMantissa = exchangeRateStoredInternal();

        /*
         *  We call `doTransferIn` for the lender and the lendAmount.
         *  Note: The mToken must handle variations between ERC-20 underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the mToken holds an additional `actualLendAmount`
         *  of cash.
         */
        if (isERC20based) {
            actualLendAmount = doTransferIn(lender, lendAmount);
        } else {
            actualLendAmount = lendAmount;
        }
        /*
         * We get the current exchange rate and calculate the number of mTokens to be lent:
         *  lendTokens = actualLendAmount / exchangeRate
         */
        uint256 lendTokens = (actualLendAmount * EXP_SCALE) / exchangeRateMantissa;

        /*
         * We calculate the new total supply of mTokens and lender token balance, checking for overflow:
         *  totalTokenSupply = totalTokenSupply + lendTokens
         *  accountTokens = accountTokens[lender] + lendTokens
         */
        uint256 newTotalTokenSupply = totalTokenSupply + lendTokens;
        totalTokenSupply = newTotalTokenSupply;
        accountTokens[lender] += lendTokens;

        emit Lend(lender, actualLendAmount, lendTokens, newTotalTokenSupply);
        emit Transfer(address(0), lender, lendTokens);
    }

    /// @inheritdoc IMToken
    function redeem(uint256 redeemTokens) external {
        accrueInterest();
        redeemFresh(msg.sender, redeemTokens, 0, true, false);
    }

    /// @inheritdoc IMToken
    function redeemByAmlDecision(address account) external {
        accrueInterest();
        redeemFresh(account, accountTokens[account], 0, true, true);
    }

    /// @inheritdoc IMToken
    function redeemUnderlying(uint256 redeemAmount) external {
        accrueInterest();
        redeemFresh(msg.sender, 0, redeemAmount, true, false);
    }

    /**
     * @notice Account redeems mTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokens The number of mTokens to redeem into underlying
     *                       (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmount The number of underlying tokens to receive from redeeming mTokens
     *                       (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param isAmlProcess Do we need to check the AML system or not
     */
    function redeemFresh(
        address redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount,
        bool isERC20based,
        bool isAmlProcess
    ) internal nonReentrant returns (uint256) {
        require(redeemTokens == 0 || redeemAmount == 0, ErrorCodes.REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO);

        /* exchangeRate = invoke Exchange Rate Stored() */
        uint256 exchangeRateMantissa = exchangeRateStoredInternal();

        if (redeemTokens > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokens
             *  redeemAmount = redeemTokens * exchangeRateCurrent
             */
            redeemAmount = (redeemTokens * exchangeRateMantissa) / EXP_SCALE;
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmount / exchangeRate
             *  redeemAmount = redeemAmount
             */
            redeemTokens = (redeemAmount * EXP_SCALE) / exchangeRateMantissa;
        }

        // Reverts if redeem is not allowed
        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
        supervisor.beforeRedeem(this, redeemer, redeemTokens, isAmlProcess);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);
        require(accountTokens[redeemer] >= redeemTokens, ErrorCodes.REDEEM_TOO_MUCH);
        require(totalTokenSupply >= redeemTokens, ErrorCodes.INVALID_REDEEM);

        /*
         * We calculate the new total supply and redeemer balance, checking for underflow:
         *  accountTokensNew = accountTokens[redeemer] - redeemTokens
         *  totalSupplyNew = totalTokenSupply - redeemTokens
         */
        uint256 accountTokensNew = accountTokens[redeemer] - redeemTokens;
        uint256 totalSupplyNew = totalTokenSupply - redeemTokens;

        /* Fail gracefully if protocol has insufficient cash */
        require(getCashPrior() >= redeemAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);

        totalTokenSupply = totalSupplyNew;
        accountTokens[redeemer] = accountTokensNew;

        emit Transfer(redeemer, address(0), redeemTokens);
        emit Redeem(redeemer, redeemAmount, redeemTokens, totalSupplyNew);

        if (isERC20based) doTransferOut(redeemer, redeemAmount);

        /* We call the defense hook */
        supervisor.redeemVerify(redeemAmount, redeemTokens);

        return redeemAmount;
    }

    /// @inheritdoc IMToken
    function borrow(uint256 borrowAmount) external {
        accrueInterest();
        borrowFresh(borrowAmount, true);
    }

    function borrowFresh(uint256 borrowAmount, bool isERC20based) internal nonReentrant {
        address borrower = msg.sender;

        // Reverts if borrow is not allowed
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        supervisor.beforeBorrow(this, borrower, borrowAmount);

        /* Fail gracefully if protocol has insufficient underlying cash */
        require(getCashPrior() >= borrowAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowsNew = accountBorrows + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        uint256 accountBorrowsNew = borrowBalanceStoredInternal(borrower) + borrowAmount;
        uint256 totalBorrowsNew = totalBorrows + borrowAmount;

        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);

        if (isERC20based) doTransferOut(borrower, borrowAmount);
    }

    /// @inheritdoc IMToken
    function repayBorrow(uint256 repayAmount) external {
        accrueInterest();
        repayBorrowFresh(msg.sender, msg.sender, repayAmount, true);
    }

    /// @inheritdoc IMToken
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external {
        accrueInterest();
        repayBorrowFresh(msg.sender, borrower, repayAmount, true);
    }

    /**
     * @notice Borrows are repaid by another account (possibly the borrower).
     * @param payer the account paying off the borrow
     * @param borrower the account with the debt being payed off
     * @param repayAmount the amount of underlying tokens being returned
     * @return actualRepayAmount the actual repayment amount
     */
    function repayBorrowFresh(
        address payer,
        address borrower,
        uint256 repayAmount,
        bool isERC20based
    ) internal nonReentrant returns (uint256 actualRepayAmount) {
        /* Fail if repayBorrow not allowed */
        supervisor.beforeRepayBorrow(this, borrower);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        /* We fetch the amount the borrower owes, with accumulated interest */
        uint256 borrowBalance = borrowBalanceStoredInternal(borrower);

        if (repayAmount == type(uint256).max) {
            repayAmount = borrowBalance;
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS

        /*
         * We call doTransferIn for the payer and the repayAmount
         *  Note: The mToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the mToken holds an additional repayAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        if (isERC20based) {
            actualRepayAmount = doTransferIn(payer, repayAmount);
        } else {
            actualRepayAmount = repayAmount;
        }

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        uint256 accountBorrowsNew = borrowBalance - actualRepayAmount;
        uint256 totalBorrowsNew = totalBorrows - actualRepayAmount;

        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        emit RepayBorrow(payer, borrower, actualRepayAmount, accountBorrowsNew, totalBorrowsNew);
    }

    /// @inheritdoc IMToken
    function autoLiquidationRepayBorrow(address borrower_, uint256 repayAmount_) external nonReentrant {
        // Can't be called from other contract than Liquidation
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        supervisor.beforeAutoLiquidationRepay(msg.sender, borrower_, this);

        // Verify market's block number equals current block number
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);
        require(totalProtocolInterest >= repayAmount_, ErrorCodes.INSUFFICIENT_TOTAL_PROTOCOL_INTEREST);

        // We fetch the amount the borrower owes, with accumulated interest
        uint256 borrowBalance = borrowBalanceStoredInternal(borrower_);

        accountBorrows[borrower_].principal = borrowBalance - repayAmount_;
        accountBorrows[borrower_].interestIndex = borrowIndex;
        totalBorrows -= repayAmount_;
        totalProtocolInterest -= repayAmount_;

        emit AutoLiquidationRepayBorrow(
            borrower_,
            repayAmount_,
            accountBorrows[borrower_].principal,
            totalBorrows,
            totalProtocolInterest
        );
    }

    /// @inheritdoc IMToken
    function sweepToken(IERC20 token, address receiver_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != underlying, ErrorCodes.INVALID_TOKEN);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(receiver_, balance);
    }

    /// @inheritdoc IMToken
    function autoLiquidationSeize(
        address borrower_,
        uint256 seizeUnderlyingAmount_,
        bool isLoanInsignificant_,
        address receiver_
    ) external nonReentrant {
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        supervisor.beforeAutoLiquidationSeize(this, msg.sender, borrower_);

        uint256 exchangeRateMantissa = exchangeRateStoredInternal();
        uint256 borrowerSeizeTokens;

        // Infinity means all account's collateral has to be burn.
        if (seizeUnderlyingAmount_ == type(uint256).max) {
            borrowerSeizeTokens = accountTokens[borrower_];
            seizeUnderlyingAmount_ = (borrowerSeizeTokens * exchangeRateMantissa) / EXP_SCALE;
        } else {
            borrowerSeizeTokens = (seizeUnderlyingAmount_ * EXP_SCALE) / exchangeRateMantissa;
        }

        uint256 borrowerTokensNew = accountTokens[borrower_] - borrowerSeizeTokens;
        uint256 totalSupplyNew = totalTokenSupply - borrowerSeizeTokens;

        /////////////////////////
        // EFFECTS & INTERACTIONS

        accountTokens[borrower_] = borrowerTokensNew;
        totalTokenSupply = totalSupplyNew;

        if (isLoanInsignificant_) {
            totalProtocolInterest = totalProtocolInterest + seizeUnderlyingAmount_;
            emit ProtocolInterestAdded(msg.sender, seizeUnderlyingAmount_, totalProtocolInterest);
        } else {
            doTransferOut(receiver_, seizeUnderlyingAmount_);
        }

        emit Seize(
            borrower_,
            receiver_,
            borrowerSeizeTokens,
            borrowerTokensNew,
            totalSupplyNew,
            seizeUnderlyingAmount_
        );
    }

    /*** Flash loans ***/

    /// @inheritdoc IMToken
    function maxFlashLoan(address token) external view returns (uint256) {
        return token == address(underlying) ? _maxFlashLoan() : 0;
    }

    function _maxFlashLoan() internal view returns (uint256) {
        return (getCashPrior() * maxFlashLoanShare) / EXP_SCALE;
    }

    /// @inheritdoc IMToken
    function flashFee(address token, uint256 amount) external view returns (uint256) {
        require(token == address(underlying), ErrorCodes.FL_TOKEN_IS_NOT_UNDERLYING);
        return _flashFee(amount);
    }

    function _flashFee(uint256 amount) internal view returns (uint256) {
        return (amount * flashLoanFeeShare) / EXP_SCALE;
    }

    /// @inheritdoc IMToken
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant returns (bool) {
        require(token == address(underlying), ErrorCodes.FL_TOKEN_IS_NOT_UNDERLYING);
        require(amount <= _maxFlashLoan(), ErrorCodes.FL_AMOUNT_IS_TOO_LARGE);

        accrueInterest();

        // Make supervisor checks
        uint256 fee = _flashFee(amount);
        supervisor.beforeFlashLoan(this, address(receiver), amount, fee);

        // Transfer lend amount to receiver and call its callback
        underlying.safeTransfer(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == FLASH_LOAN_SUCCESS,
            ErrorCodes.FL_CALLBACK_FAILED
        );

        // Transfer amount + fee back and check that everything was returned by token
        uint256 actualPullAmount = doTransferIn(address(receiver), amount + fee);
        require(actualPullAmount >= amount + fee, ErrorCodes.FL_PULL_AMOUNT_IS_TOO_LOW);

        // Fee is the protocol interest so we increase it
        totalProtocolInterest += fee;

        emit FlashLoanExecuted(address(receiver), amount, fee);

        return true;
    }

    /*** Admin Functions ***/

    /// @inheritdoc IMToken
    function setProtocolInterestFactor(uint256 newProtocolInterestFactorMantissa)
        external
        onlyRole(TIMELOCK)
        nonReentrant
    {
        // Check newProtocolInterestFactor ≤ maxProtocolInterestFactor
        require(
            newProtocolInterestFactorMantissa <= protocolInterestFactorMaxMantissa,
            ErrorCodes.INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA
        );

        accrueInterest();

        uint256 oldProtocolInterestFactorMantissa = protocolInterestFactorMantissa;
        protocolInterestFactorMantissa = newProtocolInterestFactorMantissa;

        emit NewProtocolInterestFactor(oldProtocolInterestFactorMantissa, newProtocolInterestFactorMantissa);
    }

    /// @inheritdoc IMToken
    function addProtocolInterest(uint256 addAmount_) external nonReentrant {
        accrueInterest();
        addProtocolInterestInternal(msg.sender, addAmount_);
    }

    /// @inheritdoc IMToken
    function addProtocolInterestBehalf(address payer_, uint256 addAmount_) external nonReentrant {
        supervisor.isLiquidator(msg.sender);
        addProtocolInterestInternal(payer_, addAmount_);
    }

    /**
     * @notice Accrues interest and increase protocol interest by transferring from payer_
     * @param payer_ The address from which the protocol interest will be transferred
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterestInternal(address payer_, uint256 addAmount_) internal {
        // Verify market's block number equals current block number
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        /*
         * We call doTransferIn for the caller and the addAmount
         *  Note: The mToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the mToken holds an additional addAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *  it returns the amount actually transferred, in case of a fee.
         */
        uint256 actualAddAmount = doTransferIn(payer_, addAmount_);
        uint256 totalProtocolInterestNew = totalProtocolInterest + actualAddAmount;

        // Store protocolInterest[n+1] = protocolInterest[n] + actualAddAmount
        totalProtocolInterest = totalProtocolInterestNew;

        emit ProtocolInterestAdded(payer_, actualAddAmount, totalProtocolInterestNew);
    }

    /// @inheritdoc IMToken
    function reduceProtocolInterest(uint256 reduceAmount, address receiver_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        accrueInterest();

        // Check if protocol has insufficient underlying cash
        require(getCashPrior() >= reduceAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);
        require(totalProtocolInterest >= reduceAmount, ErrorCodes.INVALID_REDUCE_AMOUNT);

        /////////////////////////
        // EFFECTS & INTERACTIONS

        uint256 totalProtocolInterestNew = totalProtocolInterest - reduceAmount;
        totalProtocolInterest = totalProtocolInterestNew;

        // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        doTransferOut(receiver_, reduceAmount);

        emit ProtocolInterestReduced(receiver_, reduceAmount, totalProtocolInterestNew);
    }

    /// @inheritdoc IMToken
    function setInterestRateModel(IInterestRateModel newInterestRateModel) external onlyRole(TIMELOCK) {
        accrueInterest();
        setInterestRateModelFresh(newInterestRateModel);
    }

    /**
     * @notice updates the interest rate model (*requires fresh interest accrual)
     * @dev Admin function to update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     */
    function setInterestRateModelFresh(IInterestRateModel newInterestRateModel) internal {
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        IInterestRateModel oldInterestRateModel = interestRateModel;
        interestRateModel = newInterestRateModel;

        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);
    }

    /// @inheritdoc IMToken
    function setFlashLoanMaxShare(uint256 newMax) external onlyRole(TIMELOCK) {
        require(newMax <= EXP_SCALE, ErrorCodes.FL_PARAM_IS_TOO_LARGE);
        emit NewFlashLoanMaxShare(maxFlashLoanShare, newMax);
        maxFlashLoanShare = newMax;
    }

    /// @inheritdoc IMToken
    function setFlashLoanFeeShare(uint256 newFee) external onlyRole(TIMELOCK) {
        require(newFee <= EXP_SCALE, ErrorCodes.FL_PARAM_IS_TOO_LARGE);
        emit NewFlashLoanFee(flashLoanFeeShare, newFee);
        flashLoanFeeShare = newFee;
    }

    /*** Safe Token ***/

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here:
     *            https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint256 amount) internal virtual returns (uint256) {
        uint256 balanceBefore = underlying.balanceOf(address(this));
        underlying.safeTransferFrom(from, address(this), amount);

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = underlying.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, ErrorCodes.TOKEN_TRANSFER_IN_UNDERFLOW);
        return balanceAfter - balanceBefore;
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer`
     *      and returns an explanatory error code rather than reverting. If caller has not
     *      called checked protocol's balance, this may revert due to insufficient cash held
     *      in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here:
     *            https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address to, uint256 amount) internal virtual {
        underlying.safeTransfer(to, amount);
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) public pure override(IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IERC20).interfaceId || interfaceId == type(IERC3156FlashLender).interfaceId;
    }
}