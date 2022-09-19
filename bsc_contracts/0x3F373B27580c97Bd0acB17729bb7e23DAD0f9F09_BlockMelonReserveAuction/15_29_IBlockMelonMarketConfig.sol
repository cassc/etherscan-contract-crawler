// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBlockMelonMarketConfig {
    /**
     * @notice Returns the market fee configarion values in basis points
     */
    function getFeeConfig()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}