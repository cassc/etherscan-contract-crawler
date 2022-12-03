// SPDX-License-Identifier: MIT
// GM2 Contracts (last updated v0.0.1)

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract GM2981 is IERC2981, ERC165 {
  address internal _royaltyAddress;
  uint16 internal _royaltyPercentage;

  constructor(address royaltyAddress_, uint16 royaltyPercentage_) {
    require(royaltyAddress_ != address(0), 'Invalid royalty address');
    require(royaltyPercentage_ <= 2000, 'Invalid royalty percentage(MAX:2000)');
    _royaltyAddress = royaltyAddress_;
    _royaltyPercentage = royaltyPercentage_;
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    _beforeRoyaltyInfo(tokenId);
    receiver = _royaltyAddress;
    royaltyAmount = _calculatePercentage(salePrice, _royaltyPercentage);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function _beforeRoyaltyInfo(uint256) internal view virtual {}

  function _calculatePercentage(uint256 value, uint16 percent) internal pure returns (uint256) {
    return (value * percent) / 10000; //HUNDRED PERCENT is 10000
  }
}