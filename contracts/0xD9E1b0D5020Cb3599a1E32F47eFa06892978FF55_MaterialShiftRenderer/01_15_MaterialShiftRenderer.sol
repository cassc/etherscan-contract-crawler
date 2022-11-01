// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../libraries/ColorShifters.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';
import '@abf-monorepo/protocol/contracts/interfaces/IRenderer.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/renderers/ConfiguredGifImageRenderer.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

contract MaterialShiftRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  ConfiguredGifImageRenderer configuredGifImageRenderer;
  IRenderer gifImageRenderer;

  constructor(address _configuredGifImageRenderer, address _gifImageRenderer) {
    configuredGifImageRenderer = ConfiguredGifImageRenderer(
      _configuredGifImageRenderer
    );
    gifImageRenderer = IRenderer(_gifImageRenderer);
  }

  function owner() public view override(Ownable, IRenderer) returns (address) {
    return super.owner();
  }

  function getConfiguration(uint256 index) public view returns (bytes memory) {
    return SSTORE2Map.read(bytes32(index));
  }

  function name() public pure override returns (string memory) {
    return 'Configured Single Frame Gif';
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IRenderer).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function propsSize() external pure override returns (uint256) {
    return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  }

  function additionalMetadataURI()
    external
    pure
    override
    returns (string memory)
  {
    return 'ipfs://bafkreihcz67yvvlotbn4x3p35wdbpde27rldihlzoqg2klbme7u6lehxna';
  }

  function renderAttributeKey() external pure override returns (string memory) {
    return 'image';
  }

  function getNewConfiguration(bytes calldata props)
    public
    view
    returns (bytes memory)
  {
    // lerpValue ranges from 0 to 10
    uint8 lerpValue = BytesUtils.toUint8(props, 0);
    lerpValue /= 25;

    //from 0 to 16
    /*
    uint8 majorIdx = BytesUtils.toUint8(props, 1) / 16;
    uint8 minorIdx = BytesUtils.toUint8(props, 1) % 16;
    */

    //from 0 to 8
    /*
    uint8 seedAtribute1 = BytesUtils.toUint8(props, 2) / 16;
    seedAtribute1 /= 2;
    uint8 seedAtribute2 = BytesUtils.toUint8(props, 2) % 16;
    seedAtribute2 /= 2;

    uint8 seedAtribute3 = BytesUtils.toUint8(props, 3) / 16;
    seedAtribute3 /= 2;
    uint8 seedAtribute4 = BytesUtils.toUint8(props, 3) % 16;
    seedAtribute4 /= 2;

    uint8 seedAtribute5 = BytesUtils.toUint8(props, 4) / 16;
    seedAtribute5 /= 2;
    uint8 seedAtribute6 = BytesUtils.toUint8(props, 4) % 16;
    seedAtribute6 /= 2;
    */

    uint256 configIdx = uint256(BytesUtils.toUint32(props, 5));
    bytes memory configuration = configuredGifImageRenderer.getConfiguration(
      configIdx
    );

    //config + transparent + material * pixelSize
    bytes memory colors = BytesUtils.slice(
      configuration,
      6,
      ColorShifters.NUM_MATERIALS * 3
    );
    bytes memory newColors = colors;

    newColors = applyMajors(
      newColors,
      lerpValue,
      BytesUtils.toUint8(props, 1) / 16,
      BytesUtils.toUint8(props, 2) / 16
    );

    // apply minor color alterations
    newColors = applyMinors(
      newColors,
      lerpValue,
      BytesUtils.toUint8(props, 3) / 16,
      BytesUtils.toUint8(props, 3) % 16,
      BytesUtils.toUint8(props, 4) / 16,
      BytesUtils.toUint8(props, 4) % 16
    );

    // if colors are not modified at all, corrupts the colors
    for (uint256 i = 0; i < colors.length; i++) {
      if (colors[i] != newColors[i]) {
        i = colors.length;
      }
      if (i == colors.length - 1) {
        newColors = ColorShifters.corrupted(
          newColors,
          lerpValue * ((BytesUtils.toUint8(props, 1) % 16) + 1)
        );
      }
    }

    // rebuild configuration
    return
      abi.encodePacked(
        BytesUtils.slice(configuration, 0, 6),
        newColors,
        BytesUtils.slice(
          configuration,
          6 + ColorShifters.NUM_MATERIALS * 3,
          configuration.length - (6 + ColorShifters.NUM_MATERIALS * 3)
        )
      );
  }

  function renderRaw(bytes calldata props)
    public
    view
    override
    returns (bytes memory)
  {
    return
      gifImageRenderer.renderRaw(
        abi.encodePacked(getNewConfiguration(props), props[9:])
      );
  }

  function applyMajors(
    bytes memory colors,
    uint8 lerpValue,
    uint8 majorIdx,
    uint8 seedAtribute
  ) public pure returns (bytes memory) {
    // rescales seed attribute to 4 to 8
    seedAtribute /= 4;
    seedAtribute += 4;

    if (majorIdx % 2 == 0) {
      majorIdx /= 2; //0 to 8
      if (majorIdx == 0) {
        colors = ColorShifters.glow(colors, (lerpValue / 2) * seedAtribute);
      } else if (majorIdx == 1) {
        colors = ColorShifters.blackGlow(
          colors,
          (lerpValue / 2) * seedAtribute
        );
      } else if (majorIdx == 2) {
        colors = ColorShifters.hueContrast(colors, lerpValue * seedAtribute);
      } else if (majorIdx == 3) {
        colors = ColorShifters.colorFlip(
          colors,
          lerpValue * (seedAtribute / 2)
        );
      } else if (majorIdx == 4) {
        colors = ColorShifters.hueHighlight(colors, lerpValue * (seedAtribute));
      } else if (majorIdx == 5) {
        colors = ColorShifters.twoToneHue(colors, lerpValue * seedAtribute);
      } else {
        colors = ColorShifters.hueShift(colors, lerpValue * seedAtribute);
      }
    }
    return colors;
  }

  function applyMinors(
    bytes memory colors,
    uint8 lerpValue,
    uint8 seedAtribute1,
    uint8 seedAtribute2,
    uint8 seedAtribute3,
    uint8 seedAtribute4
  ) public pure returns (bytes memory) {
    lerpValue = (lerpValue * 2) / 3;

    seedAtribute1 /= 4;
    seedAtribute1 += 4;
    seedAtribute2 /= 4;
    seedAtribute2 += 4;
    seedAtribute3 /= 4;
    seedAtribute3 += 4;
    seedAtribute4 /= 4;
    seedAtribute4 += 4;

    if (seedAtribute1 > 4) {
      colors = ColorShifters.saturationShift(colors, lerpValue * seedAtribute1);
    }
    if (seedAtribute2 > 4) {
      colors = ColorShifters.valueShift(colors, lerpValue * seedAtribute2);
    }
    if (seedAtribute3 > 4) {
      colors = ColorShifters.contrast(colors, lerpValue * seedAtribute3);
    }
    if (seedAtribute4 > 4) {
      colors = ColorShifters.colorContrast(colors, lerpValue * seedAtribute4);
    }
    return colors;
  }

  function render(bytes calldata props)
    external
    view
    override
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          'data:image/gif;base64,',
          Base64.encode(renderRaw(props))
        )
      );
  }

  function attributes(bytes calldata props)
    external
    pure
    override
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '{"trait_type": "Data Length", "value":',
          props.length.toString(),
          '}'
        )
      );
  }
}