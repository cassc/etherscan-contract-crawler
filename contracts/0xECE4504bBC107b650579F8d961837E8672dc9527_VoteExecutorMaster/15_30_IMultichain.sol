//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IMultichain {
     // Swaps `amount` `token` from this chain to `toChainID` chain with recipient `to` by minting with `underlying`
    //  Token == anyXYZ coin
    // Address to = address to receive
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
}