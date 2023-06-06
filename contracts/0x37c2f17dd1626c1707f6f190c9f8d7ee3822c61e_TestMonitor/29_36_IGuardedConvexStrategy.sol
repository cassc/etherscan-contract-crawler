// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// User gets to hold the ERC4626 vault shares as a deposit recipt and send them back to this contract for withdrawal
// uses StakedETC4626 vault to interacto with Curve and Convex
interface IGuardedConvexStrategy {
    // user methods
    // user sends eth and gets shares (lp token owneership)
    // despoit checks isPoolHealthy - if false revert
    // if sunset is true then revert
    function deposit(
        uint256 _ethAmountIn,
        uint256 _minSharesAmount
    ) external payable returns (uint256);

    function depositToReceiver(
        uint256 _ethAmountIn,
        uint256 _minUnderlying,
        address receiver
    ) external payable returns (uint256);

    // user states amount of shares and gets eth
    // user get ETH from idle in same proportion of the share amount
    function withdraw(
        uint256 _amountShares,
        uint256 _minAmountEth
    ) external returns (uint256);

    function withdrawToReceiver(
        uint256 _vaultShareAmount,
        uint256 _minETHAmount,
        address receiver
    ) external returns (uint256);

    // preview amount of shares to recieve for amount deposited
    function previewDeposit(
        uint256 _amountEth
    ) external view returns (uint256 _sharesOut);

    // preview amount of eth to recieve for amount of shares
    function previewWithdraw(
        uint256 _amountShares
    ) external view returns (uint256 _ethOut);

    receive() external payable;

    ////// previlged methods //////

    // admin methods

    // expires the strategy, blocks deposits allows withdrawals
    // TODO: replace with pauseable https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable
    function sunset() external;

    function sendIdleAmountToVault(uint256 _ethAmount) external;

    // Events

    event Deposit(
        uint256 amount,
        address indexed sender,
        uint256 shares,
        uint256 underlyingAmount
    );
    event Withdraw(uint256 amount, address indexed sender, uint256 shares);

    event AdjustIn(uint256 amount, address indexed sender);

    event AdjustOut(uint256 amount, address indexed sender);
}