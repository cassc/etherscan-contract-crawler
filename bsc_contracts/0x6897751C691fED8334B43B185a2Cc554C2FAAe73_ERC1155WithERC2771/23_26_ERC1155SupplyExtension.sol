// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC1155SupplyInternal.sol";
import "./IERC1155SupplyExtension.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 */
abstract contract ERC1155SupplyExtension is IERC1155SupplyExtension, ERC1155SupplyInternal {
    /**
     * @inheritdoc IERC1155SupplyExtension
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply(id);
    }

    /**
     * @inheritdoc IERC1155SupplyExtension
     */
    function maxSupply(uint256 id) public view virtual returns (uint256) {
        return _maxSupply(id);
    }

    /**
     * @inheritdoc IERC1155SupplyExtension
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return _exists(id);
    }
}