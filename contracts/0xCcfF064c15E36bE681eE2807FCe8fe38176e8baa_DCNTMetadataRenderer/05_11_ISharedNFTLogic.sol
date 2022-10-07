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
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IOnChainMetadata.sol";

/// Shared NFT logic for rendering metadata associated with editions
/// @dev Can safely be used for generic base64Encode and numberToString functions
contract ISharedNFTLogic is IOnChainMetadata {
  /// Generate edition metadata from storage information as base64-json blob
  /// Combines the media data and metadata
  /// @param name the token name
  /// @param tokenOfEdition Token ID for specific token
  /// @param songMetadata song metadata
  /// @param projectMetadata project metadata
  /// @param credits The credits of the track
  /// @param tags The tags of the track
  function createMetadataEdition(
    string memory name,
    uint256 tokenOfEdition,
    SongMetadata memory songMetadata,
    ProjectMetadata memory projectMetadata,
    Credit[] memory credits,
    string[] memory tags
  ) external pure returns (string memory) {}

  /// Encodes the argument json bytes into base64-data uri format
  /// @param json Raw json to base64 and turn into a data-uri
  function encodeMetadataJSON(bytes memory json)
    public
    pure
    returns (string memory)
  {}
}