//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extensions/InternalExtension.sol";
import "./IERC721Hooks.sol";

contract ERC721HooksLogic is ERC721HooksExtension {
    /**
     * @dev See {IERC721Hooks-_beforeTokenTransfer}
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override _internal {}

    /**
     * @dev See {IERC721Hooks-_afterTokenTransfer}
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override _internal {}
}