// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============
import "./interfaces/IMetadataRenderer.sol";
import {MusicMetadata} from "./utils/MusicMetadata.sol";
import {Credits} from "./utils/Credits.sol";
import {ISharedNFTLogic} from "./interfaces/ISharedNFTLogic.sol";
import "erc721a/contracts/IERC721A.sol";

/// @notice DCNTMetadataRenderer for editions support
contract DCNTMetadataRenderer is IMetadataRenderer, MusicMetadata, Credits {
  /// @notice Reference to Shared NFT logic library
  ISharedNFTLogic private immutable sharedNFTLogic;

  /// @notice Constructor for library
  /// @param _sharedNFTLogic reference to shared NFT logic library
  constructor(ISharedNFTLogic _sharedNFTLogic) {
    sharedNFTLogic = _sharedNFTLogic;
  }

  /// @notice Default initializer for edition data from a specific contract
  /// @param data data to init with
  function initializeWithData(bytes memory data) external {
    // data format: description, imageURI, animationURI
    (
      string memory description,
      string memory imageURI,
      string memory animationURI
    ) = abi.decode(data, (string, string, string));

    songMetadatas[msg.sender].songPublishingData.description = description;
    songMetadatas[msg.sender].song.audio.losslessAudio = animationURI;
    songMetadatas[msg.sender].song.artwork.artworkUri = imageURI;

    emit EditionInitialized({
      target: msg.sender,
      description: description,
      imageURI: imageURI,
      animationURI: animationURI
    });
  }

  /// @notice Update everything in 1 transaction.
  /// @param target target for contract to update metadata for
  /// @param _songMetadata song metadata
  /// @param _projectMetadata project metadata
  /// @param _tags tags
  /// @param _credits credits for the track
  function bulkUpdate(
    address target,
    SongMetadata memory _songMetadata,
    ProjectMetadata memory _projectMetadata,
    string[] memory _tags,
    Credit[] calldata _credits
  ) external requireSenderAdmin(target) {
    songMetadatas[target] = _songMetadata;
    projectMetadatas[target] = _projectMetadata;
    updateTags(target, _tags);
    updateCredits(target, _credits);

    emit SongUpdated({
      target: target,
      sender: msg.sender,
      songMetadata: _songMetadata,
      projectMetadata: _projectMetadata,
      tags: _tags,
      credits: _credits
    });
  }

  /// @notice Contract URI information getter
  /// @return contract uri (if set)
  function contractURI() external view override returns (string memory) {
    address target = msg.sender;
    bytes memory imageSpace = bytes("");
    if (bytes(songMetadatas[target].song.artwork.artworkUri).length > 0) {
      imageSpace = abi.encodePacked(
        '", "image": "',
        songMetadatas[target].song.artwork.artworkUri
      );
    }
    return
      string(
        sharedNFTLogic.encodeMetadataJSON(
          abi.encodePacked(
            '{"name": "',
            songMetadatas[target].songPublishingData.title,
            '", "description": "',
            songMetadatas[target].songPublishingData.description,
            imageSpace,
            '"}'
          )
        )
      );
  }

  /// @notice Token URI information getter
  /// @param tokenId to get uri for
  /// @return contract uri (if set)
  function tokenURI(uint256 tokenId)
    external
    view
    override
    returns (string memory)
  {
    address target = msg.sender;

    return tokenURITarget(tokenId, target);
  }

  /// @notice Token URI information getter
  /// @param tokenId to get uri for
  /// @return contract uri (if set)
  function tokenURITarget(uint256 tokenId, address target)
    public
    view
    returns (string memory)
  {
    return
      sharedNFTLogic.createMetadataEdition({
        name: IERC721A(target).name(),
        tokenOfEdition: tokenId,
        songMetadata: songMetadatas[target],
        projectMetadata: projectMetadatas[target],
        credits: credits[target],
        tags: trackTags[target]
      });
  }
}