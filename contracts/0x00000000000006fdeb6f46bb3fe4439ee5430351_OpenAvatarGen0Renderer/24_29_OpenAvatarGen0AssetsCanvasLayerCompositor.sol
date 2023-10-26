// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {IOpenAvatarGen0AssetsPaletteStoreRead} from '../interfaces/assets/IOpenAvatarGen0AssetsPaletteStore.sol';
import {OptionalPatternHeader, PatternHeader} from '../interfaces/assets/IOpenAvatarGen0AssetsPatternStore.sol';
import {IOpenAvatarGen0AssetsCanvasLayerCompositor, LayerPatternPalette} from '../interfaces/render/IOpenAvatarGen0AssetsCanvasLayerCompositor.sol';
import {KeepAlive} from '../lib/KeepAlive.sol';
import {PixelBlender} from '../lib/PixelBlender.sol';
import {IOpenAvatarGen0AssetsRead} from '../../IOpenAvatarGen0Assets.sol';

/**
 * @title OpenAvatarGen0AssetsCanvasLayerCompositor
 * @dev This contract composes layer patterns into a single image.
 * @dev A pattern is a 2d byte array with a corresponding color palette.
 * @dev The values of the pattern array are indexes into the color palette.
 */
contract OpenAvatarGen0AssetsCanvasLayerCompositor is
  KeepAlive,
  PixelBlender,
  IOpenAvatarGen0AssetsCanvasLayerCompositor
{
  /// @dev Error reverted when the component is already initialized.
  error AlreadyInitialized();
  /// @dev Error reverted when provided address does not support the required interface.
  error InterfaceUnsupported(address contractAddress, bytes4 interfaceId);
  /// @dev Error reverted when the canvas bytes per pixel is not 4.
  error InvalidCanvasBytesPerPixel();
  /// @dev Error reverted when the canvas size is invalid.
  error InvalidCanvasSize(uint8 canvasId, uint invalidNumBytes);
  /// @dev Error reverted when the mask length is invalid.
  error InvalidMaskLength(uint maskLength, uint canvasSize);

  /// @dev The transparent alpha value.
  bytes1 public constant TRANSPARENT = 0x00;
  /// @dev The opaque alpha value.
  bytes1 public constant OPAQUE = 0xff;

  /// @dev The
  IOpenAvatarGen0AssetsRead public openAvatarGen0AssetsRead;

  /// @dev The ERC-165 interface id for the OpenAvatarGen0AssetsCanvasLayerCompositor (for clients).
  bytes4 private constant INTERFACE_ID_OPENAVATAR_GEN0_ASSETS_CANVAS_LAYER_COMPOSITOR = 0x2638c94b;
  /// @dev The ERC-165 interface id for the OpenAvatarGen0AssetsRead (dependency).
  bytes4 private constant INTERFACE_ID_OPENAVATAR_GEN0_ASSETS_READ = 0x67bf31d1;

  constructor(address ownerProxy) {
    // will be deployed by ImmutableCreate2Factory and then transferred to the
    // configured owner.
    // using a proxy allows for using same constructor args and thus same
    // bytecode for all instances of this contract.

    address wantOwner = Ownable(ownerProxy).owner();
    if (owner() != wantOwner) {
      transferOwnership(wantOwner);
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // ERC-165: Standard Interface Detection
  /////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Checks if the contract supports an interface.
   * @param interfaceId The interface identifier, as specified in ERC-165.
   * @return True if the contract supports interfaceID, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      interfaceId == INTERFACE_ID_OPENAVATAR_GEN0_ASSETS_CANVAS_LAYER_COMPOSITOR;
  }

  /////////////////////////////////////////////////////////////////////////////
  // Initialize Dependencies
  /////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Initialize the contract.
   * @param openAvatarGen0Assets_ The address of the asset store read interface
   * contract.
   */
  function initialize(address openAvatarGen0Assets_) external onlyOwner {
    setOpenAvatarGen0Assets(openAvatarGen0Assets_);
  }

  /**
   * @notice Check if the contract has been initialized.
   * @return True if the contract has been initialized, false otherwise.
   */
  function isInitialized() external view returns (bool) {
    return address(openAvatarGen0AssetsRead) != address(0);
  }

  /**
   * @dev Get the OpenAvatarGen0Assets address.
   * @return The OpenAvatarGen0Assets address.
   */
  function getOpenAvatarGen0Assets() external view returns (address) {
    return address(openAvatarGen0AssetsRead);
  }

  /**
   * @notice Set the asset store.
   * @param openAvatarGen0Assets_ The address of the asset store read interface
   * contract.
   */
  function setOpenAvatarGen0Assets(address openAvatarGen0Assets_) internal {
    // only set once
    if (address(openAvatarGen0AssetsRead) != address(0)) revert AlreadyInitialized();

    // check ERC-165 support
    // only read interface is required
    if (!IERC165(openAvatarGen0Assets_).supportsInterface(INTERFACE_ID_OPENAVATAR_GEN0_ASSETS_READ)) {
      revert InterfaceUnsupported(openAvatarGen0Assets_, INTERFACE_ID_OPENAVATAR_GEN0_ASSETS_READ);
    }

    // set
    openAvatarGen0AssetsRead = IOpenAvatarGen0AssetsRead(openAvatarGen0Assets_);

    // sanity check
    if (openAvatarGen0AssetsRead.getBytesPerPixel() != 4) revert InvalidCanvasBytesPerPixel();
  }

  /////////////////////////////////////////////////////////////////////////////
  // Layer Composition
  /////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Create a layer composition.
   * @param canvasId The id of the canvas to use
   * @param layerPatternPalette The layer, pattern, and palette to use for each
   * layer
   */
  function createLayerComposition(
    uint8 canvasId,
    LayerPatternPalette[] memory layerPatternPalette
  ) external view override returns (bytes memory) {
    bytes memory out = new bytes(openAvatarGen0AssetsRead.getCanvasNumBytes(canvasId));
    _drawLayerComposition(out, canvasId, layerPatternPalette);
    return out;
  }

  /**
   * @dev Draw a layer composition onto the image
   * @param out The image to draw the layer composition onto
   * @param canvasId The id of the canvas to use
   * @param layerPatternPalette The layer, pattern, and palette to use for each
   * layer
   */
  function drawLayerComposition(
    bytes memory out,
    uint8 canvasId,
    LayerPatternPalette[] memory layerPatternPalette
  ) public view override returns (bytes memory) {
    _drawLayerComposition(out, canvasId, layerPatternPalette);
    return out;
  }

  /**
   * @dev Draw a layer composition onto the image
   * @param out The image to draw the layer composition onto
   * @param canvasId The id of the canvas to use
   * @param layerPatternPalette The layer, pattern, and palette to use for each
   * layer
   */
  function _drawLayerComposition(
    bytes memory out,
    uint8 canvasId,
    LayerPatternPalette[] memory layerPatternPalette
  ) internal view {
    // sanity check so we don't out of bounds for bad input
    if (out.length != openAvatarGen0AssetsRead.getCanvasNumBytes(canvasId)) {
      revert InvalidCanvasSize(canvasId, out.length);
    }

    uint length = layerPatternPalette.length;
    for (uint i = 0; i < length; ) {
      LayerPatternPalette memory lpp = layerPatternPalette[i];
      _drawLayer(out, canvasId, lpp.layer, lpp.pattern, lpp.palette);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Overlay a layer on top of the image
   * @param image The image to overlay the layer on top of
   * @param canvasId The id of the canvas to use
   * @param layer The index of the layer to overlay
   * @param pattern The index of the pattern to use for the layer
   * @param palette The index of the palette to use for the layer/pattern
   */
  function drawLayer(
    bytes memory image,
    uint8 canvasId,
    uint8 layer,
    uint8 pattern,
    uint8 palette
  ) public view override returns (bytes memory) {
    _drawLayer(image, canvasId, layer, pattern, palette);
    return image;
  }

  /**
   * @dev Overlay a layer on top of the image
   * @param image The image to overlay the layer on top of
   * @param canvasId The id of the canvas to use
   * @param layer The index of the layer to overlay
   * @param pattern The index of the pattern to use for the layer
   * @param palette The index of the palette to use for the layer/pattern
   */
  function _drawLayer(bytes memory image, uint8 canvasId, uint8 layer, uint8 pattern, uint8 palette) internal view {
    OptionalPatternHeader memory optionalHeader = openAvatarGen0AssetsRead.getPatternHeader(canvasId, layer, pattern);
    // gracefully handle missing pattern
    if (optionalHeader.exists) {
      bytes memory patternData = openAvatarGen0AssetsRead.getPatternData(canvasId, layer, pattern);
      // transparent patterns will exist and have length 0
      if (patternData.length > 0) {
        bytes4[] memory paletteData = openAvatarGen0AssetsRead.getPalette(optionalHeader.header.paletteCode, palette);
        // gracefully handle missing palette
        if (paletteData.length > 0) {
          _drawPattern(image, canvasId, optionalHeader.header, patternData, paletteData);
        }
      }
    }
  }

  /**
   * @dev Overlay a layer on top of the image
   * @param image The image to overlay the layer on top of
   * @param mask The mask to apply to the pattern before overlaying it
   * @param canvasId The id of the canvas to use
   * @param layer The index of the layer to overlay
   * @param pattern The index of the pattern to use for the layer
   * @param palette The index of the palette to use for the layer/pattern
   */
  function drawMaskedLayer(
    bytes memory image,
    bytes memory mask,
    uint8 canvasId,
    uint8 layer,
    uint8 pattern,
    uint8 palette
  ) public view override returns (bytes memory) {
    _drawMaskedLayer(image, mask, canvasId, layer, pattern, palette);
    return image;
  }

  /**
   * @dev Overlay a layer on top of the image
   * @param image The image to overlay the layer on top of
   * @param mask The mask to apply to the pattern before overlaying it
   * @param canvasId The id of the canvas to use
   * @param layer The index of the layer to overlay
   * @param pattern The index of the pattern to use for the layer
   * @param palette The index of the palette to use for the layer/pattern
   */
  function _drawMaskedLayer(
    bytes memory image,
    bytes memory mask,
    uint8 canvasId,
    uint8 layer,
    uint8 pattern,
    uint8 palette
  ) internal view {
    OptionalPatternHeader memory optionalHeader = openAvatarGen0AssetsRead.getPatternHeader(canvasId, layer, pattern);
    // gracefully handle missing pattern
    if (optionalHeader.exists) {
      bytes memory patternData = openAvatarGen0AssetsRead.getPatternData(canvasId, layer, pattern);
      // transparent patterns will exist and have length 0
      if (patternData.length > 0) {
        bytes4[] memory paletteData = openAvatarGen0AssetsRead.getPalette(optionalHeader.header.paletteCode, palette);
        // gracefully handle missing palette
        if (paletteData.length > 0) {
          _drawMaskedPattern(image, mask, canvasId, optionalHeader.header, patternData, paletteData);
        }
      }
    }
  }

  /**
   * @dev Overlay a pattern on top of the image
   * @param image The image to overlay the layer on top of
   * @param header The header of the pattern to use for the layer
   * @param pattern The pattern to use for the layer
   * @param palette The palette to use for the layer/pattern
   */
  function drawPattern(
    bytes memory image,
    uint8 canvasId,
    PatternHeader memory header,
    bytes memory pattern,
    bytes4[] memory palette
  ) public view returns (bytes memory) {
    _drawPattern(image, canvasId, header, pattern, palette);
    return image;
  }

  /**
   * @dev Overlay a pattern on top of the image
   * @param image The image to overlay the layer on top of
   * @param header The header of the pattern to use for the layer
   * @param pattern The pattern to use for the layer
   * @param palette The palette to use for the layer/pattern
   */
  function _drawPattern(
    bytes memory image,
    uint8 canvasId,
    PatternHeader memory header,
    bytes memory pattern,
    bytes4[] memory palette
  ) internal view {
    _drawMaskedPattern(
      image,
      // this is wasteful
      new bytes(openAvatarGen0AssetsRead.getCanvasNumPixels(canvasId)),
      canvasId,
      header,
      pattern,
      palette
    );
  }

  /**
   * @dev Overlay a pattern on top of the image
   * @param image The image to overlay the layer on top of
   * @param header The header of the pattern to use for the layer
   * @param pattern The pattern to use for the layer
   * @param palette The palette to use for the layer/pattern
   */
  function drawMaskedPattern(
    bytes memory image,
    bytes memory mask,
    uint8 canvasId,
    PatternHeader memory header,
    bytes memory pattern,
    bytes4[] memory palette
  ) public view returns (bytes memory) {
    _drawMaskedPattern(image, mask, canvasId, header, pattern, palette);
    return image;
  }

  /**
   * @dev Overlay a pattern on top of the image, applying a mask
   * @param image The image to overlay the layer on top of
   * @param mask The mask to apply to the pattern before overlaying it
   * @param header The header of the pattern to use for the layer
   * @param pattern The pattern to use for the layer
   * @param palette The palette to use for the layer/pattern
   */
  function _drawMaskedPattern(
    bytes memory image,
    bytes memory mask,
    uint8 canvasId,
    PatternHeader memory header,
    bytes memory pattern,
    bytes4[] memory palette
  ) internal view {
    unchecked {
      uint8 canvasWidth = openAvatarGen0AssetsRead.getCanvasWidth(canvasId);
      // loop through pixels in the image
      for (uint y = 0; y < header.height; ) {
        uint colY = y + header.offsetY;
        for (uint x = 0; x < header.width; ) {
          uint rowX = x + header.offsetX;
          uint imagePixel = colY * canvasWidth + rowX;
          if (imagePixel < mask.length && mask[imagePixel] != 0) {
            // skip transparent pixels
            ++x;
            continue;
          }

          // calculate the offset of the pixel in the pattern
          // get the color index from the pattern
          uint8 colorIndex = uint8(pattern[y * header.width + x]);
          // colorIndex == 0 means transparent
          if (colorIndex > 0) {
            // get the color from the palette
            bytes4 rgba = palette[colorIndex];

            // calculate the offset of the pixel in the image
            uint offset = 4 * imagePixel;
            if (rgba[3] == OPAQUE) {
              image[offset] = rgba[0];
              image[offset + 1] = rgba[1];
              image[offset + 2] = rgba[2];
              image[offset + 3] = OPAQUE;

              // solhint-disable-next-line no-empty-blocks
            } else if (rgba[3] == TRANSPARENT) {
              // do nothing
            } else {
              // blend the pixel with the existing pixel
              // again there are two subcases based on whether the existing
              // pixel is transparent or not
              if (image[offset + 3] == TRANSPARENT) {
                // CASE 1: existing pixel is transparent
                // so just copy the pixel exactly
                // including the semi-transparent alpha value
                image[offset] = rgba[0];
                image[offset + 1] = rgba[1];
                image[offset + 2] = rgba[2];
                image[offset + 3] = rgba[3];
              } else {
                // CASE 2: existing pixel is not transparent
                // we need to blend
                image[offset] = bytes1(blendPixel(uint8(rgba[0]), uint8(image[offset]), uint8(rgba[3])));
                image[offset + 1] = bytes1(blendPixel(uint8(rgba[1]), uint8(image[offset + 1]), uint8(rgba[3])));
                image[offset + 2] = bytes1(blendPixel(uint8(rgba[2]), uint8(image[offset + 2]), uint8(rgba[3])));
                image[offset + 3] = bytes1(blendAlpha(uint8(rgba[3]), uint8(image[offset + 3])));
              }
            }
          }
          ++x;
        }
        ++y;
      }
    }
  }
}