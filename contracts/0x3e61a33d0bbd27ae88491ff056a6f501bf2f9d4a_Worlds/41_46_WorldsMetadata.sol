// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { LibString } from "solady/src/utils/LibString.sol";
import { StringsLibrary } from "../../libraries/StringsLibrary.sol";

import { ERC4906 } from "../collections/ERC4906.sol";
import { FoundationTreasuryNode } from "../shared/FoundationTreasuryNode.sol";

import { WorldsUserRoles } from "./WorldsUserRoles.sol";

error WorldsMetadata_Invalid_Svg_Template();
error WorldsMetadata_Name_Already_Set();
error WorldsMetadata_Name_Required();
error WorldsMetadata_Svg_Template_Already_Set();

/**
 * @title Defines a unique tokenURI for each World NFT.
 * @author HardlyDifficult
 */
abstract contract WorldsMetadata is FoundationTreasuryNode, ERC721Upgradeable, ERC4906, WorldsUserRoles {
  using LibString for string;
  using StringsLibrary for uint256;

  /// @notice Stores the name of each World.
  mapping(uint256 worldId => string name) private $worldIdToName;

  /// @notice An admin managed template for the tokenURI image of each World.
  string private $svgTemplate;

  // Constants used to construct the tokenURI.
  string private constant uriBeforeName = 'data:application/json;utf8,{"name": "';
  string private constant uriBeforeImage = '", "image": "data:image/svg+xml;base64,';
  string private constant uriSuffix = '"}';
  string private constant worldIdPlaceholder = "{{worldId}}";

  ////////////////////////////////////////////////////////////////
  // Setup
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Called by a Foundation admin to set the SVG template used by the tokenURI image of each World.
   * @param svgTemplate The plaintext svg with {{worldId}} as a placeholder for the World's ID.
   */
  function adminUpdateSvgTemplate(string calldata svgTemplate) external onlyFoundationAdmin {
    if (svgTemplate.indexOf(worldIdPlaceholder) == LibString.NOT_FOUND) {
      revert WorldsMetadata_Invalid_Svg_Template();
    }
    if (svgTemplate.eq($svgTemplate)) {
      revert WorldsMetadata_Svg_Template_Already_Set();
    }

    $svgTemplate = svgTemplate;

    emit BatchMetadataUpdate(0, type(uint256).max);
  }

  ////////////////////////////////////////////////////////////////
  // On Mint
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Set the metadata for a given World when that World is initially created.
   * @param worldId The World to set metadata for.
   * @param name The name of the World.
   */
  function _mintMetadata(uint256 worldId, string memory name) internal {
    _updateWorldName(worldId, name);
  }

  ////////////////////////////////////////////////////////////////
  // World Name
  ////////////////////////////////////////////////////////////////

  /**
   * @notice Allows a curator to update the tokenURI for a World NFT.
   * @param worldId The id of the World NFT to update.
   * @param name The name of the World.
   * @dev Callable by the World owner, admin, or editor.
   */
  function updateWorldName(uint256 worldId, string calldata name) external onlyEditor(worldId) {
    _updateWorldName(worldId, name);

    // The metadata update event is not recommended on mint, only including it for post mint changes.
    emit MetadataUpdate(worldId);
  }

  function _updateWorldName(uint256 worldId, string memory name) private {
    if (bytes(name).length == 0) {
      revert WorldsMetadata_Name_Required();
    }
    if (name.eq($worldIdToName[worldId])) {
      // Revert if the transaction is a no-op.
      revert WorldsMetadata_Name_Already_Set();
    }

    $worldIdToName[worldId] = name;
  }

  /**
   * @notice Returns the name of a given World.
   */
  function getWorldName(uint256 worldId) external view returns (string memory name) {
    name = $worldIdToName[worldId];
  }

  ////////////////////////////////////////////////////////////////
  // ERC-721 Metadata Standard
  ////////////////////////////////////////////////////////////////

  function tokenURI(uint256 worldId) public view virtual override returns (string memory uri) {
    _requireMinted(worldId);

    uri = string.concat(
      uriBeforeName,
      $worldIdToName[worldId].escapeJSON(false),
      uriBeforeImage,
      Base64.encode(bytes($svgTemplate.replace(worldIdPlaceholder, worldId.padLeadingZeros(6)))),
      uriSuffix
    );
  }

  ////////////////////////////////////////////////////////////////
  // Cleanup
  ////////////////////////////////////////////////////////////////

  /// @dev Cleans up a World's metadata when it's burned.
  function _burn(uint256 worldId) internal virtual override {
    delete $worldIdToName[worldId];

    super._burn(worldId);
  }

  ////////////////////////////////////////////////////////////////
  // Inheritance Requirements
  // (no-ops to avoid compile errors)
  ////////////////////////////////////////////////////////////////

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC4906, ERC721Upgradeable) returns (bool isSupported) {
    isSupported = super.supportsInterface(interfaceId);
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new variables without shifting
   * down storage in the inheritance chain. See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This file uses a total of 1,000 slots.
   */
  uint256[998] private __gap;
}