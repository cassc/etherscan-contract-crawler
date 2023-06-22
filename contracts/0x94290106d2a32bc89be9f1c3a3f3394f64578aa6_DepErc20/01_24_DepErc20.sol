// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "hardhat/console.sol";
import "./DepToken.sol";

/**
 * @title DepErc20 Contract
 * @notice DepTokens which wrap an EIP-20 underlying
 * @author Vortex
 */
contract DepErc20 is DepToken, DepErc20Interface {

    //string public prologue;

    /**
     * @notice set levErc20 
     * @param levErc20_ The address of the associated levErc20
     *
    function setLevErc20(LevErc20Interface levErc20_) public override{
        super.setLevErc20(levErc20_);
    }*/

    /**
     * @notice Initialize the new money market
     * @param underlying_ The address of the underlying asset
     * @param matrixpricer_ The address of the Matrixpricer
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param levErc20_ The address of the associated levErc20
     */
    function initialize(address underlying_,
                        MatrixpricerInterface matrixpricer_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_,
                        LevErc20Interface levErc20_
                        ) public override initializer {
        // DepToken initialize does the bulk of the work
        admin = payable(msg.sender);
        super.initialize(underlying_, matrixpricer_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_, levErc20_);

        // Set underlying and sanity check it
        underlying = underlying_;
        EIP20Interface(underlying).totalSupply();
        reserveFactorMantissa = 1e17;
    }

    /*function setPrologue() public {
        require(msg.sender == admin, "only admin may set prologue");
        prologue = 'deperc20 success';
    }*/

    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives DepTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) override external returns (uint) {
        require(mintAmount > 0, "cannot mint <= 0");
        mintInternal(mintAmount);   // 1usdt would be 1e6 here
        return NO_ERROR;
    }

    /**
     * @notice Sender redeems DepTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of DepTokens to redeem into underlying
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens, uint redeemAmount) override external returns (uint) {
        redeemInternal(redeemTokens, redeemAmount);
        return NO_ERROR;
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint borrowAmount) override external returns (uint) {
        require(msg.sender==address(levErc20), "only levToken can call borrow");
        return borrowInternal(borrowAmount);
    }

    function getUnborrowedUSDTBalance() override external view returns (uint) {
        return getCashExReserves() + getCmpBalanceInternal();
    }

    function getTotalBorrows() override external view returns (uint) {
        return getTotalBorrowsInternal();
    }

    function getTotalBorrowsAfterAccrueInterest() override external returns (uint) {
        require(msg.sender==address(levErc20), "only levToken can call getTotalBorrowsAfterAccrueInterest");
        return getTotalBorrowsAfterAccrueInterestInternal();
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay, or -1 for the full outstanding amount
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint repayAmount, bool liquidate) override external returns (uint) {
        require(msg.sender==address(levErc20), "only levToken can call repayBorrow");
        repayBorrowInternal(repayAmount, liquidate);
        return NO_ERROR;
    }
//
//    /**
//     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
//     * @param token The address of the ERC-20 token to sweep
//     */
//    function sweepToken(EIP20NonStandardInterface token) override external {
//        require(msg.sender == admin, "DepErc20::sweepToken: only admin can sweep tokens");
//        require(address(token) != underlying, "DepErc20::sweepToken: can not sweep underlying token");
//        uint256 balance = token.balanceOf(address(this));
//        token.transfer(admin, balance);
//    }

    /**
     * @notice The sender adds to reserves.
     * @param addAmount The amount fo underlying token to add as reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReserves(uint addAmount) override external returns (uint) {
        return _addReservesInternal(addAmount);
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() virtual override internal view returns (uint) {
        EIP20Interface token = EIP20Interface(underlying);
//        console.log("deperc20 cash prior=", token.balanceOf(address(this)));
        return token.balanceOf(address(this));  // usdt, decimals=6
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
    function doTransferIn(address from, uint amount) virtual override internal returns (uint) {
        // Read from storage once
        address underlying_ = underlying;
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying_);
        uint balanceBefore = EIP20Interface(underlying_).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);
        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of override external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = EIP20Interface(underlying_).balanceOf(address(this));
        //console.log("after balanceAfter");
        return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
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
    function doTransferOut(address payable to, uint amount) virtual override internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        token.transfer(to, amount);
        bool success;
        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                     // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of override external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}