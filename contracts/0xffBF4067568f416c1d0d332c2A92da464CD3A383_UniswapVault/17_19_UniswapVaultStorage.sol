// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

/// @notice Storage for uniswap vaults
/// @author Recursive Research Inc
abstract contract UniswapVaultStorageUnpadded {
    /// @notice UniswapV2Factory address
    address public factory;

    /// @notice UniswapV2Router02 address
    address public router;

    // @notice UniswapV2Pair address for token0 and token1
    address public pair;
}

abstract contract UniswapVaultStorage is UniswapVaultStorageUnpadded {
    // @dev Padding 100 words of storage for upgradeability. Follows OZ's guidance.
    uint256[100] private __gap;
}