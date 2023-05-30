pragma solidity ^0.5.16;

import "./CToken.sol";

contract CEther is CToken {
    constructor(ComptrollerInterface comptroller_,
                InterestRateModel interestRateModel_,
                uint initialExchangeRateMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_,
                address payable admin_) public {

        admin = msg.sender;

        initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);
        admin = admin_;
    }


    function mint() external payable {
        (uint err,) = mintInternal(msg.value);
        requireNoError(err, "MINT_FAILED");
    }

    function redeem(uint redeemTokens) external returns (uint) {
        return redeemInternal(redeemTokens);
    }

    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return redeemUnderlyingInternal(redeemAmount);
    }

    function borrow(uint borrowAmount) external returns (uint) {
        return borrowInternal(borrowAmount);
    }

    function repayBorrow() external payable {
        (uint err,) = repayBorrowInternal(msg.value);
        requireNoError(err, "REPAY_BORROW_FAILED");
    }

    function repayBorrowBehalf(address borrower) external payable {
        (uint err,) = repayBorrowBehalfInternal(borrower, msg.value);
        requireNoError(err, "REPAY_BORROW_BEHALF_FAILED failed");
    }

    function liquidateBorrow(address borrower, CToken cTokenCollateral) external payable {
        (uint err,) = liquidateBorrowInternal(borrower, msg.value, cTokenCollateral);
        requireNoError(err, "LIQUIDATEBORROW_BEHALF_FAILED");
    }

    function () external payable {
        (uint err,) = mintInternal(msg.value);
        requireNoError(err, "MINT_FAILED");
    }

    function getCashPrior() internal view returns (uint) {
        (MathError err, uint startingBalance) = subUInt(address(this).balance, msg.value);
        require(err == MathError.NO_ERROR);
        return startingBalance;
    }

    function doTransferIn(address from, uint amount) internal returns (uint) {
        require(msg.sender == from, "SENDER_MISMATCH");
        require(msg.value == amount, "VALUE_MISMATCH");
        return amount;
    }

    function doTransferOut(address payable to, uint amount) internal {
        to.transfer(amount);
    }

    function requireNoError(uint errCode, string memory message) internal pure {
        if (errCode == uint(Error.NO_ERROR)) {
            return;
        }

        bytes memory fullMessage = new bytes(bytes(message).length + 5);
        uint i;

        for (i = 0; i < bytes(message).length; i++) {
            fullMessage[i] = bytes(message)[i];
        }

        fullMessage[i+0] = byte(uint8(32));
        fullMessage[i+1] = byte(uint8(40));
        fullMessage[i+2] = byte(uint8(48 + ( errCode / 10 )));
        fullMessage[i+3] = byte(uint8(48 + ( errCode % 10 )));
        fullMessage[i+4] = byte(uint8(41));

        require(errCode == uint(Error.NO_ERROR), string(fullMessage));
    }
}