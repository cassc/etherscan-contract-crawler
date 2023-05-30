pragma solidity ^0.5.16;

contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata sTokens) external returns (uint[] memory);
    function exitMarket(address sToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address sToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address sToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address sToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address sToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address sToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address sToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address sToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address sToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address sTokenBorrowed,
        address sTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address sTokenBorrowed,
        address sTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address sTokenCollateral,
        address sTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address sTokenCollateral,
        address sTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address sToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address sToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address sTokenBorrowed,
        address sTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}