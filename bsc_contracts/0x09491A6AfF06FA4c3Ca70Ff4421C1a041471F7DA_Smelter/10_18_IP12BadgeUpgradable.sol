//SPDX-License-Identifier: Apache-2.0
//from https://polygonscan.com/address/0xC18Eeac03F52ac67F956C3Fb7526a119475778dd#code=

pragma solidity 0.8.17;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IP12BadgeUpgradable is IERC721Upgradeable {
  /* ============ Events =============== */

  /* ============ Functions ============ */

  function isOwnerOf(address, uint256) external view returns (bool);

  function getNumMinted() external view returns (uint256);

  function cid(uint256 tokenId) external view returns (uint256);

  function addMinter(address) external;

  // mint
  function mint(address account, uint256 cid) external returns (uint256);

  /// @dev a public minters mapping
  function minters(address minter) external returns (bool);

  function mintBatch(
    address account,
    uint256 amount,
    uint256[] calldata cids
  ) external returns (uint256[] memory);

  function burn(address account, uint256 id) external;

  function burnBatch(address account, uint256[] calldata ids) external;
}