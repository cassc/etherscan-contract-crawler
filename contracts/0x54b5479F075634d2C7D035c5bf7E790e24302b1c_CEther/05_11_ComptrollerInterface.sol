pragma solidity ^0.5.16;

contract ComptrollerInterface {
    bool public constant isComptroller = true;

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);
    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);
    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external;
    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint);

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}