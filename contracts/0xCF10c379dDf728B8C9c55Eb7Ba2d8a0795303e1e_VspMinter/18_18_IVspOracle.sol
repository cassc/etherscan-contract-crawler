// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IOracle.sol";

interface IVspOracle is IOracle {
    /**
     * @notice Update underlying price providers (i.e. UniswapV2-Like)
     */
    function update() external;
}