// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

interface IBridgeAnyswap {

    // Swaps `amount` `token` from this chain to `toChainID` chain with recipient `to`
    function anySwapOut(address token, address to, uint amount, uint toChainID) external;

    // Swaps `amount` `token` from this chain to `toChainID` chain with recipient `to` by minting with `underlying`
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
}

interface IUnderlying {
    function underlying() external view returns (address);
}