//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface PriceOracleInterface {
    /**
     * @notice Get the underlying price of a vToken asset
     * @param vToken The vToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address vToken) external view returns (uint);
}

interface VAIControllerInterface {
    function getVAIRepayAmount(address account) external view returns (uint);
}

interface ComptrollerInterface {
    enum Action {
        MINT,
        REDEEM,
        BORROW,
        REPAY,
        SEIZE,
        LIQUIDATE,
        TRANSFER,
        ENTER_MARKET,
        EXIT_MARKET
    }

    function enterMarkets(address[] calldata vTokens) external returns (uint[] memory);
    function exitMarket(address vToken) external returns (uint);

    /*** Policy Hooks ***/
    function mintAllowed(address vToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address vToken, address minter, uint mintAmount, uint mintTokens) external;
    function redeemAllowed(address vToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address vToken, address redeemer, uint redeemAmount, uint redeemTokens) external;
    function borrowAllowed(address vToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address vToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address vToken,
        address payer,
        address borrower,
        uint repayAmount
    ) external returns (uint);

    function repayBorrowVerify(
        address vToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external returns (uint);

    function liquidateBorrowVerify(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens
    ) external;

    function seizeAllowed(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external returns (uint);

    function seizeVerify(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external;

    function transferAllowed(address vToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address vToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/
    function liquidateCalculateSeizeTokens(
        address vTokenBorrowed,
        address vTokenCollateral,
        uint repayAmount
    ) external view returns (uint, uint);

    function actionPaused(address market, Action action) external view returns (bool);

    function setMintedVAIOf(address owner, uint amount) external returns (uint);

    function markets(address) external view returns (bool isListed, uint collateralFactorMantissa, bool isVenus);
    function oracle() external view returns (PriceOracleInterface);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
    function getAssetsIn(address) external view returns (address[] memory);
    function claimVenus(address) external;
    function venusAccrued(address) external view returns (uint);
    function venusSupplySpeeds(address) external view returns (uint);
    function venusBorrowSpeeds(address) external view returns (uint);
    function getAllMarkets() external view returns (address[] memory);
    function venusSupplierIndex(address, address) external view returns (uint);
    function venusInitialIndex() external view returns (uint224);
    function venusBorrowerIndex(address, address) external view returns (uint);
    function venusBorrowState(address) external view returns (uint224, uint32);
    function venusSupplyState(address) external view returns (uint224, uint32);
    function vaiController() external view returns (VAIControllerInterface);
}