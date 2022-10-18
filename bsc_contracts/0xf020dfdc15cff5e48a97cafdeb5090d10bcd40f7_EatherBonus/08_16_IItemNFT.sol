// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IItemNFT is IERC721Upgradeable {
  function mintItems(address _owner, uint8 _gene, uint16 _class, uint _price, uint _quantity) external;
  function getOwnerItems(address _owner) external view returns(uint[] memory);
}