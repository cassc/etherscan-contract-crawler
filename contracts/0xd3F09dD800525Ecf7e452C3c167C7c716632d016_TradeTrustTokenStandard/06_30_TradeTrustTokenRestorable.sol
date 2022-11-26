// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./TradeTrustSBT.sol";
import "./RegistryAccess.sol";
import "../interfaces/ITradeTrustTokenRestorable.sol";

abstract contract TradeTrustTokenRestorable is TradeTrustSBT, RegistryAccess, ITradeTrustTokenRestorable {
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(TradeTrustSBT, RegistryAccess)
    returns (bool)
  {
    return interfaceId == type(ITradeTrustTokenRestorable).interfaceId || super.supportsInterface(interfaceId);
  }

  function restore(uint256 tokenId) external virtual override whenNotPaused onlyRole(RESTORER_ROLE) returns (address) {
    if (!_exists(tokenId)) {
      revert InvalidTokenId();
    }
    if (ownerOf(tokenId) != address(this)) {
      revert TokenNotSurrendered();
    }

    address titleEscrow = titleEscrowFactory().getAddress(address(this), tokenId);
    _registryTransferTo(titleEscrow, tokenId);

    return titleEscrow;
  }
}