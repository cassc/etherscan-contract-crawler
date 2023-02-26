// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAirERC721 is IERC721 {
  event AddMinter(address indexed newMinter);

  event RemoveMinter(address indexed oldMinter);

  function mint(address account) external;

  function mintBatch(address account, uint256 amount) external;

  function burn(address account, uint256 tokenId) external;

  function burnBatch(address account, uint256[] calldata tokenIds) external;
}