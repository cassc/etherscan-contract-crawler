// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplace {
  function royaltyInfo(
    address collection,
    uint256,
    uint256 value
  ) external view returns (address, uint256);

  function collectionURI(address collection) external view returns (string memory);
}

abstract contract RoyaltySupport {
  function marketplace() public view virtual returns (IMarketplace);

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