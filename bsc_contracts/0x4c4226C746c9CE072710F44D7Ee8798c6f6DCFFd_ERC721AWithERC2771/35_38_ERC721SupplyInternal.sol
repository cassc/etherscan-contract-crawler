// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "../../base/ERC721ABaseInternal.sol";
import "./IERC721SupplyInternal.sol";

abstract contract ERC721SupplyInternal is IERC721SupplyInternal {
    using ERC721SupplyStorage for ERC721SupplyStorage.Layout;

    function _totalSupply() internal view virtual returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex` times.
        unchecked {
            return ERC721SupplyStorage.layout().currentIndex - ERC721SupplyStorage.layout().burnCounter;
        }
    }

    function _maxSupply() internal view returns (uint256) {
        return ERC721SupplyStorage.layout().maxSupply;
    }
}