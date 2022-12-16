// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC1155Burnable} from "./../interfaces/IERC1155Burnable.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC1155 Multi Token Standard, optional extension: Burnable (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC1155 (Multi Token Standard).
abstract contract ERC1155BurnableBase is Context, IERC1155Burnable {
    using ERC1155Storage for ERC1155Storage.Layout;

    /// @inheritdoc IERC1155Burnable
    function burnFrom(address from, uint256 id, uint256 value) external virtual override {
        ERC1155Storage.layout().burnFrom(_msgSender(), from, id, value);
    }

    /// @inheritdoc IERC1155Burnable
    function batchBurnFrom(address from, uint256[] calldata ids, uint256[] calldata values) external virtual override {
        ERC1155Storage.layout().batchBurnFrom(_msgSender(), from, ids, values);
    }
}