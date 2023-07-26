// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./TokenStorage.sol";

/**
 * @title dForce's lending Token event Contract
 * @author dForce
 */
contract TokenEvent is TokenStorage {
    //----------------------------------
    //********** User Events ***********
    //----------------------------------

    event UpdateInterest(
        uint256 currentBlockNumber,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 cash,
        uint256 totalBorrows,
        uint256 totalReserves
    );

    event Mint(
        address sender,
        address recipient,
        uint256 mintAmount,
        uint256 mintTokens
    );

    event Redeem(
        address from,
        address recipient,
        uint256 redeemiTokenAmount,
        uint256 redeemUnderlyingAmount
    );

    /**
     * @dev Emits when underlying is borrowed.
     */
    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 accountBorrows,
        uint256 accountInterestIndex,
        uint256 totalBorrows
    );

    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 accountInterestIndex,
        uint256 totalBorrows
    );

    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address iTokenCollateral,
        uint256 seizeTokens
    );

    event Flashloan(
        address loaner,
        uint256 loanAmount,
        uint256 flashloanFee,
        uint256 protocolFee,
        uint256 timestamp
    );

    //----------------------------------
    //********** Owner Events **********
    //----------------------------------

    event NewReserveRatio(uint256 oldReserveRatio, uint256 newReserveRatio);
    event NewFlashloanFeeRatio(
        uint256 oldFlashloanFeeRatio,
        uint256 newFlashloanFeeRatio
    );
    event NewProtocolFeeRatio(
        uint256 oldProtocolFeeRatio,
        uint256 newProtocolFeeRatio
    );
    event NewFlashloanFee(
        uint256 oldFlashloanFeeRatio,
        uint256 newFlashloanFeeRatio,
        uint256 oldProtocolFeeRatio,
        uint256 newProtocolFeeRatio
    );

    event NewInterestRateModel(
        IInterestRateModelInterface oldInterestRateModel,
        IInterestRateModelInterface newInterestRateModel
    );

    event NewController(
        IControllerInterface oldController,
        IControllerInterface newController
    );

    event ReservesWithdrawn(
        address admin,
        uint256 amount,
        uint256 newTotalReserves,
        uint256 oldTotalReserves
    );
}