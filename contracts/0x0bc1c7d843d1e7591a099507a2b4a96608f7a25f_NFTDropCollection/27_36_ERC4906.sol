// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

/**
 * @title ERC-4906: Metadata Update Event
 * @dev See https://eips.ethereum.org/EIPS/eip-4906
 */
contract ERC4906 is ERC165Upgradeable {
  /**
   * @notice This event emits when the metadata of a token is changed.
   * So that the third-party platforms such as NFT market could
   * timely update the images and related attributes of the NFT.
   * @param tokenId The ID of the NFT whose metadata is changed.
   */
  event MetadataUpdate(uint256 tokenId);

  /**
   * @notice This event emits when the metadata of a range of tokens is changed.
   * So that the third-party platforms such as NFT market could
   * timely update the images and related attributes of the NFTs.
   * @param fromTokenId The ID of the first NFT whose metadata is changed.
   * @param toTokenId The ID of the last NFT whose metadata is changed.
   */
  event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool isSupported) {
    // 0x49064906 is a magic number based on the EIP number.
    isSupported = interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}