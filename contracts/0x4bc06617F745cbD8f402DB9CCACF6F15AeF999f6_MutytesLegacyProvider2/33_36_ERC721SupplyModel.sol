// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc721SupplyStorage as es } from "./ERC721SupplyStorage.sol";

abstract contract ERC721SupplyModel {
    function _initialSupply() internal view virtual returns (uint256) {
        return es().initialSupply;
    }

    function _maxSupply() internal view virtual returns (uint256) {
        return es().maxSupply;
    }

    function _availableSupply() internal view virtual returns (uint256) {
        return es().availableSupply;
    }

    function _setInitialSupply(uint256 supply) internal virtual {
        es().initialSupply = supply;
    }

    function _setMaxSupply(uint256 supply) internal virtual {
        es().maxSupply = supply;
    }

    function _setAvailableSupply(uint256 supply) internal virtual {
        es().availableSupply = supply;
    }

    function _updateInitialSupply(uint256 amount) internal virtual {
        es().initialSupply -= amount;
    }

    function _updateMaxSupply(uint256 amount) internal virtual {
        es().maxSupply -= amount;
    }

    function _updateAvailableSupply(uint256 amount) internal virtual {
        es().availableSupply -= amount;
    }
}