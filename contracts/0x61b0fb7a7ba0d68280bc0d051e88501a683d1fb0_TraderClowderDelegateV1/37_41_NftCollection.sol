// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library NftCollectionFunctions {

    // interface IDs
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    function transferNft(
        address collection,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(collection).safeTransferFrom(from, to, tokenId);
        } else {
            revert("Collection does not support ERC721");
        }
    }

    function ownerOf(
        address collection,
        uint256 tokenId
    ) internal view returns (address) {
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
            return IERC721(collection).ownerOf(tokenId);
        } else {
            revert("Collection does not support ERC721");
        }
    }
}