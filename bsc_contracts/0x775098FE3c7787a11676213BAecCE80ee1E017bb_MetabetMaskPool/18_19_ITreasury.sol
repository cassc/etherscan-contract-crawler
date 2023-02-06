//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title the interface for the sport betting treasury
/// @notice Declares the functions that the `Treasury` contract exposes externally
interface ITreasury {

    // withdraw bnb
    function withdraw(uint _amount)external;

    // withdraw other token
    function withdrawToken(address _token, address _to, uint _amount)external;
}