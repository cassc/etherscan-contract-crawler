pragma solidity ^0.5.16;

contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata xTokens) external returns (uint[] memory);
    function exitMarket(address xToken) external returns (uint);

    /*** Policy Hooks ***/

    function swapHelperAddress() external view returns (address);

    function liquidatorAddress() external view returns (address);

    function mintAllowed(address xToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address xToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address xToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address xToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address xToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address xToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address xToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address xToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address xTokenBorrowed,
        address xTokenCollateral,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address xTokenBorrowed,
        address xTokenCollateral,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address xTokenCollateral,
        address xTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address xTokenCollateral,
        address xTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address xToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address xToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address xTokenBorrowed,
        address xTokenCollateral,
        uint repayAmount) external returns (uint, uint);
}