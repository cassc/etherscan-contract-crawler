// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IMetadataRenderer} from "../interfaces/IMetadataRenderer.sol";
import {IERC721Drop} from "../interfaces/IERC721Drop.sol";
import {IERC721MetadataUpgradeable} from
  "@openzeppelin/contracts-upgradeable/interfaces/IERC721MetadataUpgradeable.sol";
import {NFTMetadataRenderer} from "../utils/NFTMetadataRenderer.sol";
import {MetadataRenderAdminCheck} from "./MetadataRenderAdminCheck.sol";

interface DropConfigGetter {
  function config()
    external
    view
    returns (IERC721Drop.Configuration memory config);
}

interface IERC721 {
  function totalSupply() external view returns (uint256);
}

contract SequentialMetadataRenderer is
  IMetadataRenderer,
  MetadataRenderAdminCheck
{
  struct TokenEditionInfo {
    string description;
    string imageURI;
    string animationURI;
  }

  event MediaURIsUpdated(
    address indexed target, address sender, string imageURI, string animationURI
  );

  event EditionInitialized(
    address indexed target,
    string description,
    string imageURI,
    string animationURI
  );

  event DescriptionUpdated(
    address indexed target, address sender, string newDescription
  );

  error Invariant_AlreadyInitialized();
  error Invariant_NotInitialized();
  error Invariant_MustMatchLength();

  bool private initialized;
  uint256[] public startTokens;
  mapping(uint256 => TokenEditionInfo) public tokenInfos;

  function provisionTokenInfo(address target)
    internal
    view
    returns (uint256 newStartToken, TokenEditionInfo memory oldTokenInfo)
  {
    if (startTokens.length == 0) {
      revert Invariant_NotInitialized();
    }
    IERC721 collection = IERC721(target);
    uint256 totalSupply = collection.totalSupply();
    newStartToken = totalSupply + 1;

    uint256 oldStartToken = startTokens[startTokens.length - 1];
    oldTokenInfo = tokenInfos[oldStartToken];
  }

  function updateMediaURIs(
    address target,
    string memory imageURI,
    string memory animationURI
  ) external requireSenderAdmin(target) {
    (uint256 newStartToken, TokenEditionInfo memory oldTokenInfo) =
      provisionTokenInfo(target);

    startTokens.push(newStartToken);
    tokenInfos[newStartToken] = TokenEditionInfo({
      description: oldTokenInfo.description,
      imageURI: imageURI,
      animationURI: animationURI
    });
    emit MediaURIsUpdated(target, msg.sender, imageURI, animationURI);
  }

  function updateDescription(address target, string memory newDescription)
    external
    requireSenderAdmin(target)
  {
    (uint256 newStartToken, TokenEditionInfo memory oldTokenInfo) =
      provisionTokenInfo(target);

    startTokens.push(newStartToken);
    tokenInfos[newStartToken] = TokenEditionInfo({
      description: newDescription,
      imageURI: oldTokenInfo.imageURI,
      animationURI: oldTokenInfo.animationURI
    });

    emit DescriptionUpdated(target, msg.sender, newDescription);
  }

  function initializeWithData(bytes memory data)
    external
    requireSenderAdmin(msg.sender)
  {
    if (initialized) {
      revert Invariant_AlreadyInitialized();
    }

    // TODO: startTokenIds must always ascend
    (uint256[] memory startTokenIds, TokenEditionInfo[] memory ranges) =
      abi.decode(data, (uint256[], TokenEditionInfo[]));

    if (startTokenIds.length != ranges.length) {
      revert Invariant_MustMatchLength();
    }

    for (uint256 i = 0; i < ranges.length; i++) {
      uint256 startTokenId = startTokenIds[i];
      startTokens.push(startTokenId);
      TokenEditionInfo memory tokenInfo = ranges[i];
      tokenInfos[startTokenId] = tokenInfo;

      emit EditionInitialized(
        msg.sender,
        tokenInfo.description,
        tokenInfo.imageURI,
        tokenInfo.animationURI
        );
    }
    initialized = true;
  }

  function contractURI() external view override returns (string memory) {
    address target = msg.sender;
    (, TokenEditionInfo memory oldTokenInfo) = provisionTokenInfo(target);
    IERC721Drop.Configuration memory config = DropConfigGetter(target).config();

    return NFTMetadataRenderer.encodeContractURIJSON({
      name: IERC721MetadataUpgradeable(target).name(),
      description: oldTokenInfo.description,
      imageURI: oldTokenInfo.imageURI,
      animationURI: oldTokenInfo.animationURI,
      royaltyBPS: uint256(config.royaltyBPS),
      royaltyRecipient: config.fundsRecipient
    });
  }

  function tokenURI(uint256 tokenId)
    external
    view
    override
    returns (string memory)
  {
    TokenEditionInfo memory info;

    for (uint256 i = 0; i < startTokens.length; i++) {
      if (startTokens[i] > tokenId) {
        break;
      }
      info = tokenInfos[startTokens[i]];
    }

    address target = msg.sender;
    IERC721Drop media = IERC721Drop(target);
    uint256 maxSupply = media.saleDetails().maxSupply;
    if (maxSupply == type(uint64).max) {
      maxSupply = 0;
    }

    return NFTMetadataRenderer.createMetadataEdition({
      name: IERC721MetadataUpgradeable(target).name(),
      description: info.description,
      imageURI: info.imageURI,
      animationURI: info.animationURI,
      tokenOfEdition: tokenId,
      editionSize: maxSupply
    });
  }
}