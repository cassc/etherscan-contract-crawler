// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc721BaseStorage, ERC721BaseStorage } from "./ERC721BaseStorage.sol";
import { ERC721TokenUtils } from "../utils/ERC721TokenUtils.sol";
import { ERC721InventoryUtils } from "../utils/ERC721InventoryUtils.sol";

abstract contract ERC721BaseModel {
    using ERC721TokenUtils for uint256;
    using ERC721InventoryUtils for uint256;
    
    function _balanceOf(address owner) internal view virtual returns (uint256) {
        return erc721BaseStorage().inventories[owner].balance();
    }
    
    function _ownerOf(uint256 tokenId) internal view virtual returns (address owner) {
        ERC721BaseStorage storage es = erc721BaseStorage();
        owner = es.owners[tokenId];

        if (owner == address(0)) {
            address holder = tokenId.holder();
            if (es.inventories[holder].has(tokenId.index())) {
                owner = holder;
            }
        }
    }

    function _tokenExists(uint256 tokenId) internal view virtual returns (bool) {
        ERC721BaseStorage storage es = erc721BaseStorage();

        if (es.owners[tokenId] == address(0)) {
            return es.inventories[tokenId.holder()].has(tokenId.index());
        }
        
        return true;
    }
}