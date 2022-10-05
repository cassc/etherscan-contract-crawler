//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title the interface for the sport prediction treasury
/// @notice Declares the functions that the `SportPredictionTreasury` contract exposes externally
interface IRanceTreasury {

    // withdraw CRO
    function withdraw(uint _amount)external;

    // withdraw other token
    function withdrawToken(address _token, address _to, uint _amount)external;
}