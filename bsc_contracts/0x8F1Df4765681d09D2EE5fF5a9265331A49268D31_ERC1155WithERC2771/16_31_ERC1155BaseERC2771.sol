// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../metatx/ERC2771ContextInternal.sol";

import "./ERC1155Base.sol";

/**
 * @title Base ERC1155 contract with meta-transactions support (via ERC2771).
 */
abstract contract ERC1155BaseERC2771 is ERC1155Base, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}