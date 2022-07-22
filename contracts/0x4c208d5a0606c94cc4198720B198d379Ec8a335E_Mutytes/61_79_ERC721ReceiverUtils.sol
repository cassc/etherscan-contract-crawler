// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Receiver } from "../IERC721Receiver.sol";

/**
 * @title ERC721 token receiver utilities
 */
library ERC721ReceiverUtils {
    error UnexpectedNonERC721Receiver(address receiver);

    function enforceOnReceived(
        address to,
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) internal {
        if (checkOnERC721Received(to, operator, from, tokenId, data)) {
            return;
        }

        revert UnexpectedNonERC721Receiver(to);
    }
    
    function checkOnERC721Received(
        address to,
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        try
            IERC721Receiver(to).onERC721Received(operator, from, tokenId, data)
        returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory) {
            return false;
        }
    }
}