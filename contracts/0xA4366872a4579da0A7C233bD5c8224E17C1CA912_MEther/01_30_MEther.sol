// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./MToken.sol";
import "./interfaces/IMEther.sol";
import "./interfaces/IWETH9.sol";

/**
 * @title Minterest MEther Contract
 * @author Minterest
 */
contract MEther is IMEther, MToken {
    /// @inheritdoc IMEther
    function lendNative() external payable {
        accrueInterest();
        lendFresh(msg.sender, msg.value, false);
        IWETH9(address(underlying)).deposit{value: msg.value}();
    }

    /// @inheritdoc IMEther
    function redeemNative(uint256 redeemTokens) external {
        accrueInterest();
        uint256 redeemAmount = redeemFresh(msg.sender, redeemTokens, 0, false, false);
        IWETH9(address(underlying)).withdraw(redeemAmount);
        payable(msg.sender).transfer(redeemAmount);
    }

    /// @inheritdoc IMEther
    function redeemUnderlyingNative(uint256 redeemAmount) external {
        accrueInterest();
        redeemFresh(msg.sender, 0, redeemAmount, false, false);
        IWETH9(address(underlying)).withdraw(redeemAmount);
        // slither-disable-next-line arbitrary-send-eth
        payable(msg.sender).transfer(redeemAmount);
    }

    /// @inheritdoc IMEther
    function borrowNative(uint256 borrowAmount) external {
        accrueInterest();
        borrowFresh(borrowAmount, false);
        IWETH9(address(underlying)).withdraw(borrowAmount);
        // slither-disable-next-line arbitrary-send-eth
        payable(msg.sender).transfer(borrowAmount);
    }

    /// @inheritdoc IMEther
    function repayBorrowNative() external payable {
        accrueInterest();
        repayBorrowFresh(msg.sender, msg.sender, msg.value, false);
        IWETH9(address(underlying)).deposit{value: msg.value}();
    }

    /// @inheritdoc IMEther
    function repayBorrowBehalfNative(address borrower) external payable {
        accrueInterest();
        repayBorrowFresh(msg.sender, borrower, msg.value, false);
        IWETH9(address(underlying)).deposit{value: msg.value}();
    }

    // @notice Used only to receive ETH from WETH contract
    receive() external payable {}
}