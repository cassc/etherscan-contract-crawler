// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "IERC721AUpgradeable.sol";

interface IVoiceA is IERC721AUpgradeable {
  /* Events */
   event Mint(address indexed to, uint256 indexed tokenId, uint256 tokenURI);

  /* Methods */  function mintOne(address to, uint256 tokenURI, uint256 holdDuration) external;

  function mintBatch(address to, uint256[] calldata tokenURIs, uint256 holdDuration) external;

  function burn(uint256 tokenId) external;

  function transferFrom(
      address from,
      address to,
      uint256 tokenId
  ) external;

  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory _data
  ) external;

  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
  ) external;

  function bareTokenURI(uint256 tokenId) view external returns(uint256);

  function setBaseUri(string memory baseUri) external;

  function getBaseUri() external view returns (string memory);

  function setUseArweave(bool useArweave) external;

  function getUseArweave() external view returns (bool);
}