// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../extensions/supply/ERC20SupplyStorage.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "./ERC20SupplyAdminInternal.sol";
import "./IERC20SupplyAdmin.sol";

/**
 * @title ERC20 - Supply - Admin - Ownable
 * @notice Allows owner of a EIP-721 contract to change max supply of tokens.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:peer-dependencies IERC20SupplyExtension
 * @custom:provides-interfaces IERC20SupplyAdmin
 */
contract ERC20SupplyOwnable is IERC20SupplyAdmin, ERC20SupplyAdminInternal, OwnableInternal {
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