// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20SafeTransfers} from "./../interfaces/IERC20SafeTransfers.sol";
import {ERC20Storage} from "./../libraries/ERC20Storage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC20 Fungible Token Standard, optional extension: Safe Transfers (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC20 (Fungible Token Standard).
abstract contract ERC20SafeTransfersBase is Context, IERC20SafeTransfers {
    using ERC20Storage for ERC20Storage.Layout;

    /// @inheritdoc IERC20SafeTransfers
    function safeTransfer(address to, uint256 value, bytes calldata data) external virtual override returns (bool) {
        ERC20Storage.layout().safeTransfer(_msgSender(), to, value, data);
        return true;
    }

    /// @inheritdoc IERC20SafeTransfers
    function safeTransferFrom(address from, address to, uint256 value, bytes calldata data) external virtual override returns (bool) {
        ERC20Storage.layout().safeTransferFrom(_msgSender(), from, to, value, data);
        return true;
    }
}