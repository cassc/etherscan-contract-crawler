//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title the interface for the sport betting pool
/// @notice Declares the functions that the  contract exposes externally
interface IBNBPool {
    
    // withdraw BNB
    function withdraw(uint _amount)external;
}