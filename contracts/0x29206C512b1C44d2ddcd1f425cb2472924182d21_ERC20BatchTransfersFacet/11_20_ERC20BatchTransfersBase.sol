// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20BatchTransfers} from "./../interfaces/IERC20BatchTransfers.sol";
import {ERC20Storage} from "./../libraries/ERC20Storage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC20 Fungible Token Standard, optional extension: Batch Transfers (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC20 (Fungible Token Standard).
abstract contract ERC20BatchTransfersBase is Context, IERC20BatchTransfers {
    using ERC20Storage for ERC20Storage.Layout;

    /// @inheritdoc IERC20BatchTransfers
    function batchTransfer(address[] calldata recipients, uint256[] calldata values) external virtual override returns (bool) {
        ERC20Storage.layout().batchTransfer(_msgSender(), recipients, values);
        return true;
    }

    /// @inheritdoc IERC20BatchTransfers
    function batchTransferFrom(address from, address[] calldata recipients, uint256[] calldata values) external virtual override returns (bool) {
        ERC20Storage.layout().batchTransferFrom(_msgSender(), from, recipients, values);
        return true;
    }
}