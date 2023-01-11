// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

// Need to use IERC20Upgradeable because that is what SafeERC20Upgradeable requires
// but the interface is exactly the same as ERC20s so this still works with ERC20s
import { IERC20Upgradeable } from "../../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import { UniswapVaultStorage } from "../uniswap/UniswapVaultStorage.sol";

/// @notice Storage for all Sushi Vaults
/// For simplicity, we use the same storage for the MasterChefVault and the
/// MasterChefV2Vault, so that we minimize complexity in inheritance.
/// @author Recursive Research Inc
abstract contract SushiswapVaultStorageUnpadded is UniswapVaultStorage {
    /// @notice masterChef or masterChef V2
    address public rewarder;

    /// @notice pool ID for this token pair
    uint256 public pid;

    /// @notice SUSHI token for liquidity mining rewards
    IERC20Upgradeable public sushi;
}

abstract contract SushiswapVaultStorage is SushiswapVaultStorageUnpadded {
    // @dev Padding 100 words of storage for upgradeability. Follows OZ's guidance.
    uint256[100] private __gap;
}