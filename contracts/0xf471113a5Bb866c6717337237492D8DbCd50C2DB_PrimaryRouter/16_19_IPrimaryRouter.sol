// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title This interface is specific for the frigg router
/// @author Frigg team
interface IPrimaryRouter {
    function buy(address friggTokenAddress, uint256 inputTokenAmount) external payable;

    function sell(address friggTokenAddress, uint256 inputFriggTokenAmount) external payable;
}