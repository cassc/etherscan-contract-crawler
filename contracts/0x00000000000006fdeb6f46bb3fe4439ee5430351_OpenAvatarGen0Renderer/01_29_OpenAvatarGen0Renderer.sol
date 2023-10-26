// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {ENSReverseClaimer} from './core/lib/ENSReverseClaimer.sol';
import {OpenAvatarGen0CanvasRenderer} from './core/render/OpenAvatarGen0CanvasRenderer.sol';
import {OpenAvatarGenerationZero} from './OpenAvatarGenerationZero.sol';

/**
 * @title OpenAvatarGen0Renderer
 * @author Cory Gabrielsen (cory.eth)
 *
 * @dev This contract is responsible for rendering an Avatar based on its DNA.
 *      Avatars are rendered as 32x32 RGBA images with transparency around
 *      the Avatar's body. Avatars are rendered using hand-drawn, original art
 *      created by the contract author (one pixel at a time with a ball mouse).
 *
 * Immutable:
 * Once initialized, the contract is immutable.
 * Art stored in OpenAvatarGen0Assets is immutable (append-only storage).
 * So, rendering is deterministic.
 *
 * Gas:
 * Due to PNG encoding, rendering may cost 10,000,000+ gas.
 * With further base64 encoding (i.e. token URI), combined rendering and
 * encoding may cost 15,000,000+ gas.
 *
 * Terminology:
 * - Canvas Id (uint8): Selects from an array of canvases
 * - Layer Index (uint8): Selects from an array of layers for a given canvas
 * - Pattern Index (uint8): Selects from an array of patterns for a given layer
 * - Palette Index (uint8): Selects from an array of palettes for a given
 *                          pattern
 * - Color Index (uint8): Selects from an array of colors for a given palette
 * - Color (bytes4): RGBA
 *
 * Structure:
 * - Every layer contains an array of selectable patterns.
 * - Each pattern references a specific palette code.
 * - Each palette code corresponds to an array of palettes.
 * - Each pattern (uncompressed) is a 32x32=1024 array of color indices.
 *      - compressed as [height, width, offsetX, offsetY, bytes]
 *  -Each palette is an array of RGBA (bytes4[]) which always starts with
 *   0x00000000 (transparent).
 * - So, a color index of 0x00 is transparent.
 * - In essence, each byte in a pattern is a color index which defines an
 *   RGBA color in the corresponding palette array to draw for that pixel.
 *
 * Rendering:
 * Layers are drawn one over another, from lowest to highest layer index,
 * with alpha-blending. The 32-byte Avatar DNA is interpretted to as
 * defining the pattern and palette for each layer. Pixels are drawn based
 * on color derived from DNA-encoded pattern and palette index. If a DNA
 * defines an invalid index, the layer is drawn as transparent.
 *
 * DNA:
 * It should be noted that while OpenAvatar DNA is interpretted here as
 * implicitly defining asset references for drawing the Avatar, the concept
 * of DNA is designed as a standalone building block. Application-specific
 * re-interpretations of OpenAvatar DNA are entirely possible and encouraged.
 *
 * Encoding:
 * Avatars are rendered as base64-encoded PNGs, embedded within an SVG. The
 * SVG embeds the PNG as a <foreignObject>, chosen due to Safari's lack of
 * support (bug?) for "image-rendering: pixelated" of <image> elements within
 * SVGs.
 */
contract OpenAvatarGen0Renderer is OpenAvatarGenerationZero, OpenAvatarGen0CanvasRenderer, ENSReverseClaimer {
  /// @dev The canvas ID for the default, front-facing Avatar pose.
  uint8 public constant CANVAS_ID = 0;

  // solhint-disable-next-line no-empty-blocks
  constructor(address ownerProxy) OpenAvatarGen0CanvasRenderer(ownerProxy, CANVAS_ID) {}

  /////////////////////////////////////////////////////////////////////////////
  // ERC-165: Standard Interface Detection
  /////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Checks if the contract supports an interface.
   * @param interfaceId The interface identifier, as specified in ERC-165.
   * @return True if the contract supports interfaceID, false otherwise.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public pure override(OpenAvatarGenerationZero, OpenAvatarGen0CanvasRenderer) returns (bool) {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      // IOpenAvatar
      interfaceId == 0xfdf02ac8 || // ERC165 interface ID for IOpenAvatarGeneration.
      interfaceId == 0x7b65147c || // ERC165 interface ID for IOpenAvatarSentinel.
      interfaceId == 0x86953eb4 || // ERC165 interface ID for IOpenAvatar.
      // IOpenAvatarGen0AssetsCanvasLayerCompositor
      interfaceId == 0xb93e4881 || // ERC165 interface ID for IOpenAvatarGen0Renderer.
      interfaceId == 0x00a663b1 || // ERC165 interface ID for IOpenAvatarGen0RendererDecorator.
      interfaceId == 0x13247985 || // ERC165 interface ID for IOpenAvatarGen0CanvasRenderer.
      interfaceId == 0x2638c94b; // ERC165 interface ID for IOpenAvatarGen0AssetsCanvasLayerCompositor.
  }
}