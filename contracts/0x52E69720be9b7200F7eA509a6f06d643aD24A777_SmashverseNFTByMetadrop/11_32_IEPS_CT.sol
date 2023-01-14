// SPDX-License-Identifier: MIT
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//* IEPS_CT: EPS ComposeThis Interface
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

enum ValueType {
  none,
  characterString,
  number,
  date,
  chainAddress
}

struct AddedTrait {
  string trait;
  ValueType valueType;
  uint256 valueInteger;
  string valueString;
  address valueAddress;
}

interface IEPS_CT {
  event MetadataUpdate(
    uint256 chain,
    address tokenContract,
    uint256 tokenId,
    uint256 futureExecutionDate
  );

  event ENSReverseRegistrarSet(address ensReverseRegistrarAddress);

  function composeURIFromBaseURI(
    string memory baseString_,
    AddedTrait[] memory addedTraits_,
    uint256 startImageTag_,
    string[] memory imageTags_
  ) external view returns (string memory composedString_);

  function composeURIFromLookup(
    uint256 baseURIChain_,
    address baseURIContract_,
    uint256 baseURITokenId_,
    AddedTrait[] memory addedTraits_,
    uint256 startImageTag_,
    string[] memory imageTags_
  ) external view returns (string memory composedString_);

  function composeTraitsFromArray(AddedTrait[] memory addedTraits_)
    external
    view
    returns (string memory composedImageURL_);

  function composeImageFromBase(
    string memory baseImage_,
    uint256 startImageTag_,
    string[] memory imageTags_,
    address contractAddress,
    uint256 id
  ) external view returns (string memory composedImageURL_);

  function composeTraitsAndImage(
    string memory baseImage_,
    uint256 startImageTag_,
    string[] memory imageTags_,
    address contractAddress_,
    uint256 id_,
    AddedTrait[] memory addedTraits_
  )
    external
    view
    returns (string memory composedImageURL_, string memory composedTraits_);

  function triggerMetadataUpdate(
    uint256 chain,
    address tokenContract,
    uint256 tokenId,
    uint256 futureExecutionDate
  ) external;
}