// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IOpenAvatarGen0RendererDecorator} from '../../IOpenAvatarGen0Renderer.sol';
import {OpenAvatarGen0AssetsCanvasIdStore} from '../assets/OpenAvatarGen0AssetsCanvasIdStore.sol';
import {IOpenAvatarGen0AssetsCanvasLayerCompositor, LayerPatternPalette} from '../interfaces/render/IOpenAvatarGen0AssetsCanvasLayerCompositor.sol';
import {IOpenAvatarGen0CanvasRenderer} from '../interfaces/render/IOpenAvatarGen0CanvasRenderer.sol';
import {ImageEncoder} from '../lib/ImageEncoder.sol';
import {DNA} from '../lib/DNA.sol';
import {OpenAvatarGen0AssetsCanvasLayerCompositor} from './OpenAvatarGen0AssetsCanvasLayerCompositor.sol';

/**
 * @title OpenAvatarGen0CanvasRenderer
 * @dev This contract renders a DNA as an image in a variety of formats.
 */
contract OpenAvatarGen0CanvasRenderer is
  IOpenAvatarGen0CanvasRenderer,
  IOpenAvatarGen0RendererDecorator,
  ImageEncoder,
  OpenAvatarGen0AssetsCanvasIdStore,
  OpenAvatarGen0AssetsCanvasLayerCompositor
{
  using DNA for bytes32;

  /// @dev The layer index for the body layer.
  uint8 public constant LAYER_INDEX_BODY = 10;
  /// @dev The layer index for the tattoos layer.
  uint8 public constant LAYER_INDEX_TATTOOS = 20;
  /// @dev The layer index for the makeup layer.
  uint8 public constant LAYER_INDEX_MAKEUP = 30;
  /// @dev The layer index for the left eye layer.
  uint8 public constant LAYER_INDEX_LEFT_EYE = 40;
  /// @dev The layer index for the right eye layer.
  uint8 public constant LAYER_INDEX_RIGHT_EYE = 50;
  /// @dev The layer index for the bottomwear layer.
  uint8 public constant LAYER_INDEX_BOTTOMWEAR = 60;
  /// @dev The layer index for the footwear layer.
  uint8 public constant LAYER_INDEX_FOOTWEAR = 70;
  /// @dev The layer index for the topwear layer.
  uint8 public constant LAYER_INDEX_TOPWEAR = 80;
  /// @dev The layer index for the handwear layer.
  uint8 public constant LAYER_INDEX_HANDWEAR = 90;
  /// @dev The layer index for the outerwear layer.
  uint8 public constant LAYER_INDEX_OUTERWEAR = 100;
  /// @dev The layer index for the jewelry layer.
  uint8 public constant LAYER_INDEX_JEWELRY = 110;
  /// @dev The layer index for the facial hair layer.
  uint8 public constant LAYER_INDEX_FACIAL_HAIR = 120;
  /// @dev The layer index for the facewear layer.
  uint8 public constant LAYER_INDEX_FACEWEAR = 130;
  /// @dev The layer index for the eyewear layer.
  uint8 public constant LAYER_INDEX_EYEWEAR = 140;
  /// @dev The layer index for the hair layer.
  uint8 public constant LAYER_INDEX_HAIR = 150;

  /// @dev scale the base PNG to an SVG by this factor
  uint public constant SVG_SCALE = 10;

  constructor(
    address ownerProxy,
    uint8 canvasId_
  )
    OpenAvatarGen0AssetsCanvasIdStore(canvasId_)
    OpenAvatarGen0AssetsCanvasLayerCompositor(ownerProxy)
  // solhint-disable-next-line no-empty-blocks
  {

  }

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
  ) public pure virtual override(OpenAvatarGen0AssetsCanvasLayerCompositor) returns (bool) {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      // IOpenAvatarGen0AssetsCanvasLayerCompositor
      interfaceId == 0xb93e4881 || // ERC165 interface ID for IOpenAvatarGen0Renderer.
      interfaceId == 0x00a663b1 || // ERC165 interface ID for IOpenAvatarGen0RendererDecorator.
      interfaceId == 0x13247985 || // ERC165 interface ID for IOpenAvatarGen0CanvasRenderer.
      interfaceId == 0x2638c94b; // ERC165 interface ID for IOpenAvatarGen0AssetsCanvasLayerCompositor.
  }

  /////////////////////////////////////////////////////////////////////////////
  // Drawing
  /////////////////////////////////////////////////////////////////////////////

  function drawOpenAvatar(uint8 canvasId, bytes32 dna) external view returns (bytes memory) {
    return _drawOpenAvatar(canvasId, dna);
  }

  function _drawOpenAvatar(uint8 canvasId, bytes32 dna) internal view returns (bytes memory) {
    bytes memory image = new bytes(openAvatarGen0AssetsRead.getCanvasNumBytes(canvasId));
    return _drawOpenAvatarOverlay(image, canvasId, dna);
  }

  function drawOpenAvatarOverlay(bytes memory image, uint8 canvasId, bytes32 dna) external view returns (bytes memory) {
    return _drawOpenAvatarOverlay(image, canvasId, dna);
  }

  /**
   * @notice Compose the given DNA into a single image, on top of the given
   * base image.
   * @param image The base image.
   * @param canvasId The canvas ID. Between [0, 11]. Behavior for 12 or
   * higher undefined.
   * @param dna The DNA to compose.
   * @return The image.
   */
  function _drawOpenAvatarOverlay(
    bytes memory image,
    uint8 canvasId,
    bytes32 dna
  ) internal view returns (bytes memory) {
    uint expectedNumBytes = openAvatarGen0AssetsRead.getCanvasNumBytes(canvasId);
    // sanity check the provided image array
    // must be at least as long as the expected image length
    if (image.length < expectedNumBytes) {
      revert InvalidCanvasSize(canvasId, image.length);
    }

    /**
     * A 32 byte hex string
     * @dev The DNA string is a 32 byte hex string.
     * @dev The DNA string is immutable.
     * @dev The bytes represent the following:
     * The bytes represent the following:
     * ZZZZ YYYY XXXX WWWW VVVV UUUU TTTT SSSS
     * 0000 0000 0000 0000 0000 0000 0000 0000
     *
     *    Bytes  |  Chars  | Description
     *  ---------|---------|-------------
     *   [0:1]   | [0:3]   |  body
     *   [2:3]   | [4:7]   |  tattoos
     *   [4:5]   | [8:11]  |  makeup
     *   [6:7]   | [12:15] |  left eye
     *   [8:9]   | [16:19] |  right eye
     *   [10:11] | [20:23] |  bottomwear
     *   [12:13] | [24:27] |  footwear
     *   [14:15] | [28:31] |  topwear
     *   [16:17] | [32:35] |  handwear
     *   [18:19] | [36:39] |  outerwear
     *   [20:21] | [40:43] |  jewelry
     *   [22:23] | [44:47] |  facial hair
     *   [24:25] | [48:51] |  facewear
     *   [26:27] | [52:55] |  eyewear
     *   [28:29] | [56:59] |  hair
     *   [30:31] | [60:63] |  reserved
     *
     * Each 2-byte section is a struct of the following:
     *   [0] | [0:1] |  pattern
     *   [1] | [2:3] |  palette
     */
    LayerPatternPalette[] memory layers = new LayerPatternPalette[](15);
    layers[0] = LayerPatternPalette(LAYER_INDEX_BODY, dna.bodyPattern(), dna.bodyPalette());
    layers[1] = LayerPatternPalette(LAYER_INDEX_TATTOOS, dna.tattoosPattern(), dna.tattoosPalette());
    layers[2] = LayerPatternPalette(LAYER_INDEX_MAKEUP, dna.makeupPattern(), dna.makeupPalette());
    layers[3] = LayerPatternPalette(LAYER_INDEX_LEFT_EYE, dna.leftEyePattern(), dna.leftEyePalette());
    layers[4] = LayerPatternPalette(LAYER_INDEX_RIGHT_EYE, dna.rightEyePattern(), dna.rightEyePalette());
    layers[5] = LayerPatternPalette(LAYER_INDEX_BOTTOMWEAR, dna.bottomwearPattern(), dna.bottomwearPalette());
    layers[6] = LayerPatternPalette(LAYER_INDEX_FOOTWEAR, dna.footwearPattern(), dna.footwearPalette());
    layers[7] = LayerPatternPalette(LAYER_INDEX_TOPWEAR, dna.topwearPattern(), dna.topwearPalette());
    layers[8] = LayerPatternPalette(LAYER_INDEX_OUTERWEAR, dna.outerwearPattern(), dna.outerwearPalette());
    layers[9] = LayerPatternPalette(LAYER_INDEX_HANDWEAR, dna.handwearPattern(), dna.handwearPalette());
    layers[10] = LayerPatternPalette(LAYER_INDEX_JEWELRY, dna.jewelryPattern(), dna.jewelryPalette());
    layers[11] = LayerPatternPalette(LAYER_INDEX_FACIAL_HAIR, dna.facialHairPattern(), dna.facialHairPalette());
    layers[12] = LayerPatternPalette(LAYER_INDEX_FACEWEAR, dna.facewearPattern(), dna.facewearPalette());
    layers[13] = LayerPatternPalette(LAYER_INDEX_EYEWEAR, dna.eyewearPattern(), dna.eyewearPalette());
    layers[14] = LayerPatternPalette(LAYER_INDEX_HAIR, dna.hairPattern(), dna.hairPalette());

    return drawLayerComposition(image, canvasId, layers);
  }

  /**
   * @notice Render the given DNA as a base64-encoded SVG URI.
   * @param dna The DNA to render.
   * @return The SVG URI.
   */
  function renderURI(bytes32 dna) public view override returns (string memory) {
    return string(abi.encodePacked('data:image/svg+xml;base64,', renderBase64SVG(dna)));
  }

  /**
   * @notice Render the dna as a byte array.
   * @param dna The DNA to render.
   * @return The byte array of the image.
   */
  function renderHex(bytes32 dna) public view override returns (bytes memory) {
    return _drawOpenAvatar(canvasId, dna);
  }

  /**
   * @notice Render the given DNA as a PNG.
   * @param dna The DNA to render.
   * @return The PNG image.
   */
  function renderPNG(bytes32 dna) public view override returns (bytes memory) {
    return
      encodePNG(
        _drawOpenAvatar(canvasId, dna),
        openAvatarGen0AssetsRead.getCanvasWidth(canvasId),
        openAvatarGen0AssetsRead.getCanvasHeight(canvasId),
        openAvatarGen0AssetsRead.hasAlphaChannel()
      );
  }

  /**
   * @notice Render the given DNA as a base64-encoded PNG.
   * @param dna The DNA to render.
   * @return The PNG image.
   */
  function renderBase64PNG(bytes32 dna) public view override returns (bytes memory) {
    return
      encodeBase64PNG(
        _drawOpenAvatar(canvasId, dna),
        openAvatarGen0AssetsRead.getCanvasWidth(canvasId),
        openAvatarGen0AssetsRead.getCanvasHeight(canvasId),
        openAvatarGen0AssetsRead.hasAlphaChannel()
      );
  }

  function renderSVG(bytes32 dna) public view override returns (bytes memory) {
    uint width = openAvatarGen0AssetsRead.getCanvasWidth(canvasId);
    uint height = openAvatarGen0AssetsRead.getCanvasHeight(canvasId);
    return
      encodeSVG(
        _drawOpenAvatar(canvasId, dna),
        width,
        height,
        openAvatarGen0AssetsRead.hasAlphaChannel(),
        SVG_SCALE * width,
        SVG_SCALE * height
      );
  }

  function renderBase64SVG(bytes32 dna) public view override returns (bytes memory) {
    uint width = openAvatarGen0AssetsRead.getCanvasWidth(canvasId);
    uint height = openAvatarGen0AssetsRead.getCanvasHeight(canvasId);
    return
      encodeBase64SVG(
        _drawOpenAvatar(canvasId, dna),
        width,
        height,
        openAvatarGen0AssetsRead.hasAlphaChannel(),
        SVG_SCALE * width,
        SVG_SCALE * height
      );
  }
}