// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../extensions/supply/ERC721SupplyStorage.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "./ERC721SupplyAdminStorage.sol";
import "./IERC721SupplyAdmin.sol";

abstract contract ERC721SupplyAdminInternal {
    using ERC721SupplyAdminStorage for ERC721SupplyAdminStorage.Layout;
    using ERC721SupplyStorage for ERC721SupplyStorage.Layout;

    function _setMaxSupply(uint256 newValue) internal virtual {
        if (ERC721SupplyAdminStorage.layout().maxSupplyFrozen) {
            revert IERC721SupplyAdmin.ErrMaxSupplyFrozen();
        }

        ERC721SupplyStorage.layout().maxSupply = newValue;
    }

    function _freezeMaxSupply() internal virtual {
        ERC721SupplyAdminStorage.layout().maxSupplyFrozen = true;
    }

    function _maxSupplyFrozen() internal view virtual returns (bool) {
        return ERC721SupplyAdminStorage.layout().maxSupplyFrozen;
    }
}