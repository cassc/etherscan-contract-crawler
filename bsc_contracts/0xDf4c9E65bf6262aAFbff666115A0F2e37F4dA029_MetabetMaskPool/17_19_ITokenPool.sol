//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title the interface for the sport betting pool
/// @notice Declares the functions that the contract exposes externally
interface ITokenPool {

    // withdraw other token
    function withdrawToken(address _token, address _to, uint _amount)external;
}