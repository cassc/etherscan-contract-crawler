// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Detailed} from "./../interfaces/IERC20Detailed.sol";
import {ERC20DetailedStorage} from "./../libraries/ERC20DetailedStorage.sol";

/// @title ERC20 Fungible Token Standard, optional extension: Detailed (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC20 (Fungible Token Standard).
abstract contract ERC20DetailedBase is IERC20Detailed {
    using ERC20DetailedStorage for ERC20DetailedStorage.Layout;

    /// @inheritdoc IERC20Detailed
    function name() external view override returns (string memory) {
        return ERC20DetailedStorage.layout().name();
    }

    /// @inheritdoc IERC20Detailed
    function symbol() external view override returns (string memory) {
        return ERC20DetailedStorage.layout().symbol();
    }

    /// @inheritdoc IERC20Detailed
    function decimals() external view override returns (uint8) {
        return ERC20DetailedStorage.layout().decimals();
    }
}