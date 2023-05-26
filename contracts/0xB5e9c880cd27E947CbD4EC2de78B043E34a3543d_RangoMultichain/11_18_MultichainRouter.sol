// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title The root contract that handles Rango's interaction with MultichainOrg bridge
/// @author Uchiha Sasuke
/// @dev This is deployed as a separate contract from RangoV1
interface MultichainRouter {
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
    function anySwapOutNative(address token, address to, uint toChainID) external payable;
    function anySwapOut(address token, address to, uint amount, uint toChainID) external;
}