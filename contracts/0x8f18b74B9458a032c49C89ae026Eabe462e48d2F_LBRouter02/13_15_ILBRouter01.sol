// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "./IERC20.sol";

import "./IWETH.sol";
import "./ILBExchangeRouter.sol";
import "./ILBLiquidityRouter.sol";

/// @dev full interface for router
interface ILBRouter01 is ILBExchangeRouter, ILBLiquidityRouter {
    function factory() external pure returns (address);

    function weth() external pure returns (IWETH);
}