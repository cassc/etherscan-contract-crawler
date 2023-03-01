//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./VTokenInterface.sol";

interface VBNBInterface is VTokenInterface {
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address vTokenCollateral) external payable;
}