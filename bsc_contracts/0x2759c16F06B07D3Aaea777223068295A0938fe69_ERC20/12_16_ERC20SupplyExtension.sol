// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "../../base/ERC20BaseInternal.sol";
import "./ERC20SupplyStorage.sol";
import "./ERC20SupplyInternal.sol";
import "./IERC20SupplyExtension.sol";

abstract contract ERC20SupplyExtension is IERC20SupplyExtension, ERC20BaseInternal, ERC20SupplyInternal {
    using ERC20SupplyStorage for ERC20SupplyStorage.Layout;

    function maxSupply() external view virtual override returns (uint256) {
        return _maxSupply();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == address(0)) {
            if (to != address(0)) {
                if (_totalSupply() + amount > ERC20SupplyStorage.layout().maxSupply) {
                    revert ErrMaxSupplyExceeded();
                }
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}