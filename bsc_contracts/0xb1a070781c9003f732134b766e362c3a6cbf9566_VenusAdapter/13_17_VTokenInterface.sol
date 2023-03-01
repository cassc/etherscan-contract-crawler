//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface VTokenInterface {
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function balanceOfUnderlying(address owner) external returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function getCash() external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function accrueInterest() external returns (uint);

    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateStored() external view returns (uint);
}