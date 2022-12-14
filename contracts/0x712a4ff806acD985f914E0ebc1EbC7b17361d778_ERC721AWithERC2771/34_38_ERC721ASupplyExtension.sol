// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "../../base/ERC721ABaseInternal.sol";
import "./ERC721SupplyStorage.sol";
import "./ERC721SupplyInternal.sol";
import "./IERC721SupplyExtension.sol";

abstract contract ERC721ASupplyExtension is IERC721SupplyExtension, ERC721ABaseInternal, ERC721SupplyInternal {
    using ERC721SupplyStorage for ERC721SupplyStorage.Layout;

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply();
    }

    function maxSupply() external view virtual override returns (uint256) {
        return _maxSupply();
    }

    /**
     * @dev See {ERC721A-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (from == address(0)) {
            if (to != address(0)) {
                if (_totalSupply() + quantity > ERC721SupplyStorage.layout().maxSupply) {
                    revert ErrMaxSupplyExceeded();
                }
            }
        }

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}