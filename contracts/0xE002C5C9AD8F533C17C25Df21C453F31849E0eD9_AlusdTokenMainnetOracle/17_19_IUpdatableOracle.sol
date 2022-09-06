// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ITokenOracle.sol";

interface IUpdatableOracle is ITokenOracle {
    /**
     * @notice Update underlying price providers (i.e. UniswapV2-Like)
     */
    function update() external;
}