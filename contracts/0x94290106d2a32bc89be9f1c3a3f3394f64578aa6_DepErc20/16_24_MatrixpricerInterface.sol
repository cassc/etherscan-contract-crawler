// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

abstract contract MatrixpricerInterface {
    /// @notice Indicator that this is a Matrixpricer contract (for inspection)
    bool public constant isMatrixpricer = true;

    /*** Supported functions ***/
    function mintAllowed(address depToken, address minter) virtual external returns (uint);

    function redeemAllowed(address depToken, address redeemer, uint redeemTokens) virtual external returns (uint);

    function borrowAllowed(address depToken, address borrower) virtual external returns (uint);

    function repayBorrowAllowed(
        address depToken,
        address borrower) virtual external returns (uint);

    function transferAllowed(address depToken, address src, address dst, uint transferTokens) virtual external returns (uint);
}