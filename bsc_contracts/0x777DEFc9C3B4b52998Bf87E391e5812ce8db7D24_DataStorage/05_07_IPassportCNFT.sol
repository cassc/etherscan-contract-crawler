// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IPassportCNFT {
  function _composedNFT_parentTokenId(
    uint256 composedTokenId,
    address composedNftAddress
  ) external view returns (uint256);

  function mintManyTokens(
    address receiver_,
    uint256 tokenAmount_,
    string memory agencyId_
  ) external returns (uint256[] memory);

  function mintToken(
    address receiver_,
    string memory agencyId_,
    string memory tokenAnimationURL_, // custom animation_url (can be empty string)
    string memory metadataType_, // "default", "hotel", "flight", "activity" for stamp. Empty string for passport
    string memory tokenImageURL_ // custom image_url (can be empty string)
  ) external returns (uint256);
}