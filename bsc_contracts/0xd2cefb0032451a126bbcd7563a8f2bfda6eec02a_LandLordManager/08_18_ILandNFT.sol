// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface ILandNFT is IERC721Upgradeable {
  function mintLand(uint _id, address _owner) external;
  function creators(uint _id) external view returns (address);
}