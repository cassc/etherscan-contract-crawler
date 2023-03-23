// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {CollectionType} from "./libraries/OrderEnums.sol";

/**
 * @title TokenTransferrer
 * @notice This contract contains a function to transfer NFTs from a proxy to the recipient
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract TokenTransferrer {
    function _transferTokenToRecipient(
        CollectionType collectionType,
        address collection,
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (collectionType == CollectionType.ERC721) {
            IERC721(collection).transferFrom(address(this), recipient, tokenId);
        } else if (collectionType == CollectionType.ERC1155) {
            IERC1155(collection).safeTransferFrom(address(this), recipient, tokenId, amount, "");
        }
    }
}