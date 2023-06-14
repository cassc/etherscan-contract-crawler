// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICToken {
    function accrueInterest() external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function decimals() external view returns (uint256);

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

    function getCash() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);
}