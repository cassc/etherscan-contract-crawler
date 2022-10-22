// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../extensions/supply/ERC20SupplyStorage.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "./ERC20SupplyAdminStorage.sol";
import "./IERC20SupplyAdmin.sol";

abstract contract ERC20SupplyAdminInternal {
    using ERC20SupplyAdminStorage for ERC20SupplyAdminStorage.Layout;
    using ERC20SupplyStorage for ERC20SupplyStorage.Layout;

    function _setMaxSupply(uint256 newValue) internal virtual {
        if (ERC20SupplyAdminStorage.layout().maxSupplyFrozen) {
            revert IERC20SupplyAdmin.ErrMaxSupplyFrozen();
        }

        ERC20SupplyStorage.layout().maxSupply = newValue;
    }

    function _freezeMaxSupply() internal virtual {
        ERC20SupplyAdminStorage.layout().maxSupplyFrozen = true;
    }

    function _maxSupplyFrozen() internal view virtual returns (bool) {
        return ERC20SupplyAdminStorage.layout().maxSupplyFrozen;
    }
}