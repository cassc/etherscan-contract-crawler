// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RoyaltySupport.sol";

interface IMarketplaceV2 is IMarketplace {
  function tokenURI(address collection, uint256 tokenId) external view returns (string memory);
}

abstract contract RoyaltySupportV2 {
  function marketplace() public view virtual returns (IMarketplaceV2);

  function contractURI() external view returns (string memory) {
    return marketplace().collectionURI(address(this));
  }

  function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256) {
    return marketplace().royaltyInfo(address(this), tokenId, value);
  }

  event RoyaltiesReceivedEvent(address, address, uint256);

  function royaltiesReceived(
    address _recipient,
    address _buyer,
    uint256 amount
  ) external virtual {
    emit RoyaltiesReceivedEvent(_recipient, _buyer, amount);
  }
}