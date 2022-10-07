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
import {IOnChainMetadata} from "../interfaces/IOnChainMetadata.sol";
import {MetadataRenderAdminCheck} from "./MetadataRenderAdminCheck.sol";

contract MusicMetadata is MetadataRenderAdminCheck, IOnChainMetadata {
  mapping(address => SongMetadata) public songMetadatas;
  mapping(address => ProjectMetadata) public projectMetadatas;
  mapping(address => string[]) internal trackTags;

  /// @notice Update media URIs
  /// @param target target for contract to update metadata for
  /// @param imageURI new image uri address
  /// @param animationURI new animation uri address
  function updateMediaURIs(
    address target,
    string memory imageURI,
    string memory animationURI
  ) external requireSenderAdmin(target) {
    songMetadatas[target].song.artwork.artworkUri = imageURI;
    songMetadatas[target].song.audio.losslessAudio = animationURI;
    emit MediaURIsUpdated({
      target: target,
      sender: msg.sender,
      imageURI: imageURI,
      animationURI: animationURI
    });
  }

  /// @notice Admin function to update description
  /// @param target target description
  /// @param newDescription new description
  function updateDescription(address target, string memory newDescription)
    external
    requireSenderAdmin(target)
  {
    songMetadatas[target].songPublishingData.description = newDescription;

    emit DescriptionUpdated({
      target: target,
      sender: msg.sender,
      newDescription: newDescription
    });
  }

  /// @notice Admin function to update description
  /// @param target target description
  /// @param tags The tags of the track
  function updateTags(address target, string[] memory tags)
    public
    requireSenderAdmin(target)
  {
    trackTags[target] = tags;

    emit TagsUpdated({target: target, sender: msg.sender, tags: tags});
  }
}