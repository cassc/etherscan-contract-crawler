// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.4;

library SharedEvents {
    event Deposit(address indexed sender, uint256 shares);

    event TimeRebalance(
        address indexed hedger,
        uint256 auctionTriggerTime,
        uint256 amountEth,
        uint256 amountUsdc,
        uint256 amountOsqth
    );

    event NoRebalance(address indexed hedger, uint256 auctionTriggerTime, uint256 ratio);

    event PriceRebalance(address indexed hedger, uint256 amountEth, uint256 amountUsdc, uint256 amountOsqth);

    event Withdraw(address indexed hedger, uint256 shares, uint256 amountEth, uint256 amountUsdc, uint256 amountOsqth);

    event Rebalance(address indexed hedger, uint256 amountEth, uint256 amountUsdc, uint256 amountOsqth);

    event CollectFees(uint256 feesToVault0, uint256 feesToVault1, uint256 feesToProtocol0, uint256 feesToProtocol1);

    event Paused(bool changedState);

    // event Snapshot(int24 tick, uint256 totalAmount0, uint256 totalAmount1, uint256 totalSupply);
}