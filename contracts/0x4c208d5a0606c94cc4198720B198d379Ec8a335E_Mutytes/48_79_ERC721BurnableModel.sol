// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc721BaseStorage, ERC721BaseStorage } from "../base/ERC721BaseStorage.sol";
import { ERC721TokenUtils } from "../utils/ERC721TokenUtils.sol";
import { ERC721InventoryUtils } from "../utils/ERC721InventoryUtils.sol";

abstract contract ERC721BurnableModel {
    using ERC721TokenUtils for uint256;
    using ERC721InventoryUtils for uint256;

    function _burn(address owner, uint256 tokenId) internal virtual {
        ERC721BaseStorage storage es = erc721BaseStorage();

        if (es.owners[tokenId] == owner) {
            delete es.owners[tokenId];
            es.inventories[owner]--;
        } else {
            es.inventories[owner] = es.inventories[owner].remove(
                tokenId.index()
            );
        }
    }
}