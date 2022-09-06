// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc721BaseStorage, ERC721BaseStorage } from "../base/ERC721BaseStorage.sol";
import { ERC721InventoryUtils } from "../utils/ERC721InventoryUtils.sol";

abstract contract ERC721MintableModel {
    using ERC721InventoryUtils for uint256;

    function _maxMintBalance() internal view virtual returns (uint256) {
        return ERC721InventoryUtils.SLOTS_PER_INVENTORY;
    }

    function _mintBalanceOf(address owner) internal view virtual returns (uint256) {
        return erc721BaseStorage().inventories[owner].current();
    }

    function _mint(address to, uint256 amount) internal virtual {
        ERC721BaseStorage storage es = erc721BaseStorage();
        es.inventories[to] = es.inventories[to].add(amount);
    }
}