// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./SBTUpgradeable.sol";
import "../interfaces/ITitleEscrow.sol";
import "../interfaces/ITitleEscrowFactory.sol";
import "../interfaces/TradeTrustTokenErrors.sol";
import "../interfaces/ITradeTrustSBT.sol";

abstract contract TradeTrustSBT is SBTUpgradeable, PausableUpgradeable, TradeTrustTokenErrors, ITradeTrustSBT {
  function __TradeTrustSBT_init(string memory name, string memory symbol) internal onlyInitializing {
    __SBT_init(name, symbol);
    __Pausable_init();
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(SBTUpgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return interfaceId == type(ITradeTrustSBT).interfaceId || SBTUpgradeable.supportsInterface(interfaceId);
  }

  function onERC721Received(
    address, /* _operator */
    address, /* _from */
    uint256, /* _tokenId */
    bytes memory /* _data */
  ) public pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function _registryTransferTo(address to, uint256 tokenId) internal {
    this.transferFrom(address(this), to, tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function genesis() public view virtual override returns (uint256);

  function titleEscrowFactory() public view virtual override returns (ITitleEscrowFactory);
}