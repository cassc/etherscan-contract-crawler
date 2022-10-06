//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./PriceOracleInterface.sol";


abstract contract GammatrollerInterface {
    /// @notice Indicator that this is a Gammatroller contract (for inspection)
    bool public constant isGammatroller = true;

    //PriceOracle public oracle; -- ------------------------
    function getOracle() virtual external view returns (PriceOracleInterface);
    
    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata gTokens) virtual external returns (uint[] memory);
    function exitMarket(address gToken) virtual external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address gToken, address minter, uint mintAmount) virtual external returns (uint);

    function redeemAllowed(address gToken, address redeemer, uint redeemTokens) virtual external returns (uint);
    function redeemVerify(address gToken, address redeemer, uint redeemAmount, uint redeemTokens) virtual external;

    function borrowAllowed(address gToken, address borrower, uint borrowAmount) virtual external returns (uint);

    function repayBorrowAllowed(
        address gToken,
        address payer,
        address borrower,
        uint repayAmount) virtual external returns (uint);

    function liquidateBorrowAllowed(
        address gTokenBorrowed,
        address gTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) virtual external returns (uint);

    function seizeAllowed(
        address gTokenCollateral,
        address gTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external returns (uint);

    function transferAllowed(address gToken, address src, address dst, uint transferTokens) virtual external returns (uint);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address gTokenBorrowed,
        address gTokenCollateral,
        uint repayAmount) virtual external view returns (uint, uint);

    function updateFactor(address _user, uint256 _newiGammaBalance) virtual external;


    // delete later

    function _supportMarket(GTokenInterface gToken) virtual external returns (uint);
    function _setCollateralFactor(GTokenInterface gToken, uint newCollateralFactorMantissa) virtual external returns (uint);
    function getAllMarkets() virtual external returns (GTokenInterface[] memory);
    
}
