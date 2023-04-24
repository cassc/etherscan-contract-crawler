pragma solidity ^0.8.10;

import "./CErc20Delegate.sol";
import "./Accountant/AccountantInterfaces.sol";
import "./Treasury/TreasuryInterfaces.sol";
import "./ErrorReporter.sol";
import "./NoteInterest.sol";

contract CNote is CErc20Delegate {
    event AccountantSet(address accountant, address accountantPrior);

    error FailedTransfer(uint256 amount);

    AccountantInterface public _accountant; // accountant private _accountant = Accountant(address(0));

    function setAccountantContract(address accountant_) public {
        require(
            msg.sender == admin,
            "CNote::_setAccountantContract:Only admin may call this function"
        );

        emit AccountantSet(accountant_, address(_accountant));
        _accountant = AccountantInterface(accountant_);
    }

    /**
     * @dev return the current address of the Accounant
     */
    function getAccountant() external view returns (address) {
        return address(_accountant);
    }

    /**
     * @dev getCashPrior retrieves balance of the accountant (not cNote contract)
     */
    function getCashPrior()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        EIP20Interface token = EIP20Interface(underlying);
        return token.balanceOf(address(_accountant));
    }

    function accrueInterest() public virtual override returns (uint256) {
        NoteRateModel(address(interestRateModel)).updateBaseRate(); //update the baseRate of Note
        return super.accrueInterest();
    }

    /**
     * @notice Calculates the exchange rate from Note to cNote
     * @dev This function does not accrue efore calculating the exchange rate
     * @return calculated exchange rate scaled by 1e18
     */
    function exchangeRateStoredInternal()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            /*
             * If there are no tokens minted:
             *  exchangeRate = initialExchangeRate
             */
            return initialExchangeRateMantissa;
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
             */
            uint256 cashPlusBorrowsMinusReserves = totalBorrows - totalReserves; // totalCash in cNote Lending Market is zero, thus it is not factored into the exchangeRate
            uint256 exchangeRate =
                cashPlusBorrowsMinusReserves * expScale / _totalSupply;

            return exchangeRate;
        }
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint256 amount)
        internal
        virtual
        override
        returns (uint256)
    {
        require(address(_accountant) != address(0)); //check that the accountant has been set

        EIP20Interface token = EIP20Interface(underlying);
        token.transferFrom(from, address(this), amount); //allowance set before

        //revert if transfer fails
        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of override external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "CNote::TOKEN_TRANSFER_IN_FAILED");

        uint256 balanceAfter = token.balanceOf(address(this)); // Calculate the amount that was *actually* transferred

        if (from != address(_accountant)) {
            uint256 err = _accountant.redeemMarket(balanceAfter); //Whatever is transferred into cNote is then redeemed by the accountant
            if (err != 0) {
                revert AccountantSupplyError(balanceAfter);
            }
        }

        return balanceAfter; // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address payable to, uint256 amount)
        internal
        virtual
        override
    {
        require(address(_accountant) != address(0)); //check that the accountant has been set
        EIP20Interface token = EIP20Interface(underlying);

        if (to != address(_accountant)) {
            uint256 err = _accountant.supplyMarket(amount); //Accountant redeems requisite cNote to supply this market
            if (err != 0) {
                revert AccountantRedeemError(amount);
            }
        }

        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of override external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }

    /**
     * @notice Users borrow assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     */
    function borrowFresh(address payable borrower, uint256 borrowAmount)
        internal
        override
    {
        /* Fail if borrow not allowed */
        uint256 allowed =
            comptroller.borrowAllowed(address(this), borrower, borrowAmount);
        if (allowed != 0) {
            revert BorrowComptrollerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert BorrowFreshnessCheck();
        }

        /* Fail gracefully if protocol has insufficient underlying cash */
        if (getCashPrior() < borrowAmount) {
            revert BorrowCashNotAvailable();
        }

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowNew = accountBorrow + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        uint256 accountBorrowsPrev = borrowBalanceStoredInternal(borrower);
        uint256 accountBorrowsNew = accountBorrowsPrev + borrowAmount;
        uint256 totalBorrowsNew = totalBorrows + borrowAmount;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferOut for the borrower and the borrowAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken borrowAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        doTransferOut(borrower, borrowAmount);

        /*
         * We write the previously calculated values into storage.
         *  These values must be updated after the accountant has received cTokens at the previous exchangeRate (without totalBorrows being updated)
        `*/
        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        /* We emit a Borrow event */
        emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);
    }

    /**
     * @notice User redeems cTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokensIn The number of cTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmountIn The number of underlying tokens to receive from redeeming cTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     */
    function redeemFresh(
        address payable redeemer,
        uint256 redeemTokensIn,
        uint256 redeemAmountIn
    )
        internal
        override
    {
        require(
            redeemTokensIn == 0 || redeemAmountIn == 0,
            "one of redeemTokensIn or redeemAmountIn must be zero"
        );
        /* exchangeRate = invoke Exchange Rate Stored() */
        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal()});
        uint256 redeemTokens;
        uint256 redeemAmount;
        /* If redeemTokensIn > 0: */
        if (redeemTokensIn > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokensIn
             *  redeemAmount = redeemTokensIn x exchangeRateCurrent
             */
            redeemTokens = redeemTokensIn;
            redeemAmount = mul_ScalarTruncate(exchangeRate, redeemTokensIn);
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmountIn / exchangeRate
             *  redeemAmount = redeemAmountIn
             */
            redeemTokens = div_(redeemAmountIn, exchangeRate);
            redeemAmount = redeemAmountIn;
        }

        /* Fail if redeem not allowed */
        uint256 allowed =
            comptroller.redeemAllowed(address(this), redeemer, redeemTokens);
        if (allowed != 0) {
            revert RedeemComptrollerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert RedeemFreshnessCheck();
        }

        /* Fail gracefully if protocol has insufficient cash */
        if (getCashPrior() < redeemAmount) {
            revert RedeemTransferOutNotPossible();
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        /*
         * We invoke doTransferOut for the redeemer and the redeemAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken has redeemAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         * accountant supplies market and receives cTokens at current exchange Rate
         */
        doTransferOut(redeemer, redeemAmount);

        /*
         * We write the previously calculated values into storage.
         *  totalSupply is updated after the accountant has supplied enough tokens for the transfer, and has received cTokens at the prior exchange Rate (without totalSupply being updated)
         */
        totalSupply = totalSupply - redeemTokens;
        accountTokens[redeemer] = accountTokens[redeemer] - redeemTokens;

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), redeemTokens);
        emit Redeem(redeemer, redeemAmount, redeemTokens);

        /* We call the defense hook */
        comptroller.redeemVerify(
            address(this), redeemer, redeemAmount, redeemTokens
        );
    }

    /**
     ** Reentrancy Guard **
     */
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() override {
        if (msg.sender != address(_accountant)) {
            require(_notEntered, "re-entered"); //this is required as the Accountant must redeem / mint before users are able to borrow / repayBorrow
        }
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }
}