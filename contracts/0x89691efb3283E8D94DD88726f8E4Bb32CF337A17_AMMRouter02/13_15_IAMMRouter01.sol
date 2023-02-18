// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;

import "./IAMMExchangeRouter.sol";
import "./IAMMLiquidityRouter.sol";
import "./IWETH.sol";


/// @dev full interface for router
interface IAMMRouter01 is IAMMExchangeRouter, IAMMLiquidityRouter {
    function factory() external pure returns (address);

    function weth() external pure returns (IWETH);
}