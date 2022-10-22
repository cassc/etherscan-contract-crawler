// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../extensions/supply/ERC721SupplyStorage.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "./ERC721SupplyAdminInternal.sol";
import "./IERC721SupplyAdmin.sol";

/**
 * @title ERC721 - Supply - Admin - Ownable
 * @notice Allows owner of a EIP-721 contract to change max supply of tokens.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:peer-dependencies IERC721SupplyExtension
 * @custom:provides-interfaces IERC721SupplyAdmin
 */
contract ERC721SupplyOwnable is IERC721SupplyAdmin, ERC721SupplyAdminInternal, OwnableInternal {
    function setMaxSupply(uint256 newValue) public virtual onlyOwner {
        _setMaxSupply(newValue);
    }

    function freezeMaxSupply() public virtual onlyOwner {
        _freezeMaxSupply();
    }

    function maxSupplyFrozen() public view virtual override returns (bool) {
        return _maxSupplyFrozen();
    }
}