// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./RegistryAccess.sol";
import "./TradeTrustTokenBurnable.sol";
import "./TradeTrustTokenMintable.sol";
import "./TradeTrustTokenRestorable.sol";
import "../interfaces/ITradeTrustToken.sol";

abstract contract TradeTrustTokenBase is
  TradeTrustSBT,
  RegistryAccess,
  TradeTrustTokenBurnable,
  TradeTrustTokenMintable,
  TradeTrustTokenRestorable
{
  function __TradeTrustTokenBase_init(
    string memory name,
    string memory symbol,
    address admin
  ) internal onlyInitializing {
    __TradeTrustSBT_init(name, symbol);
    __RegistryAccess_init(admin);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(
      TradeTrustSBT,
      RegistryAccess,
      TradeTrustTokenRestorable,
      TradeTrustTokenMintable,
      TradeTrustTokenBurnable
    )
    returns (bool)
  {
    return interfaceId == type(ITradeTrustToken).interfaceId || super.supportsInterface(interfaceId);
  }

  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(TradeTrustSBT, TradeTrustTokenBurnable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);

    address titleEscrow = titleEscrowFactory().getAddress(address(this), tokenId);
    if (to != address(this) && to != titleEscrow && to != BURN_ADDRESS) {
      revert TransferFailure();
    }
  }
}