// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface CToken {
    function accrueInterest() external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrow(uint256 borrowAmount) external returns (uint256);

    function mint() external payable; // For ETH

    function mint(uint256 mintAmount) external returns (uint256); // For ERC20

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow() external payable; // For ETH

    function repayBorrow(uint256 repayAmount) external returns (uint256); // For ERC20

    function transfer(address user, uint256 amount) external returns (bool);

    function getCash() external view returns (uint256);

    function transferFrom(
        address owner,
        address user,
        uint256 amount
    ) external returns (bool);

    function underlying() external view returns (address);
}

interface Comptroller {
    function claimComp(address holder, address[] memory) external;

    function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function compAccrued(address holder) external view returns (uint256);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function markets(address market)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isCompted
        );
}