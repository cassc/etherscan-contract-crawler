// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapRouterErrors} from "./IButtonswapRouterErrors.sol";

interface IRootButtonswapRouter is IButtonswapRouterErrors {
    /**
     * @notice Returns the address of the Buttonswap Factory
     * @return factory The address of the Buttonswap Factory
     */
    function factory() external view returns (address factory);
}