// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IFundingRateController} from "./IFundingRateController.sol";

interface IUniswapOracleFundingRateController is IFundingRateController {
    /// @notice emitted when pool is set
    /// @param pool the new pool value
    event SetPool(address indexed pool);

    /// @notice emitted if _setPool is called with a pool
    /// that's tokens do not match pool()
    error PoolTokensDoNotMatch();
    error InvalidUniswapV3Pool();

    /// @notice The address of the Uniswap pool used for mark()
    /// @return pool address of the pool
    function pool() external returns (address);
}