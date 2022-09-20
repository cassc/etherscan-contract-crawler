// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '@abf-monorepo/protocol/contracts/libraries/SvgUtils.sol';
import '@abf-monorepo/protocol/contracts/interfaces/IRenderer.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';
import '../MergeMana.sol';
import '../storage/RendererPropsStorage.sol';

contract ManaEnergyRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  MergeMana public mergeMana;
  RendererPropsStorage public manaEnergyStorage;
  IRenderer public gifRenderer;

  uint8[4] public ENERGY_SPAWN_RECT = [0, 0, 128, 77];

  bytes public constant MANA_ENERGY_ID = 'mana-energy';
  bytes public constant MANA_ENERGY_CLASS = 'mana-energy';
  uint256 public constant MIN_NUM_DELAY_FRAMES = 0;
  uint256 public constant MAX_NUM_DELAY_FRAMES = 8;
  uint256 public constant MAX_DELAY_TYPES_PER_ENERGY_PROPS = 2;

  bytes public constant EMPTY_FULL_FRAME = hex'800000';

  constructor(
    address _mergeMana,
    address _manaEnergyStorage,
    address _gifRenderer
  ) {
    mergeMana = MergeMana(_mergeMana);
    manaEnergyStorage = RendererPropsStorage(_manaEnergyStorage);
    gifRenderer = IRenderer(_gifRenderer);
  }

  function name() public pure override returns (string memory) {
    return 'Mana Energy';
  }

  function owner() public view override(Ownable, IRenderer) returns (address) {
    return super.owner();
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
    return 'ipfs://bafkreih2jlxxhzdf3zpwvmto25apcsuo4kengs2h7panvotm5lwoppce24';
  }

  function renderAttributeKey() external pure override returns (string memory) {
    return 'image';
  }

  function getNumEnergySpawn(uint tokenId) public view returns (uint numSpawns) {
    uint totalUsableManaInUnits = (mergeMana.getTotalMana(tokenId)) / (10 ** mergeMana.numDecimals());
    while (numSpawns ** 2 < totalUsableManaInUnits) {
      numSpawns++;
    }
    return numSpawns - 1;
  }

  function renderRaw(bytes calldata props)
    public
    view
    override
    returns (bytes memory)
  {
    uint256 numSpawns = getNumEnergySpawn(BytesUtils.toUint256(props, 32));
    bytes memory seed = BytesUtils.slice(props, 32, 32);

    uint256 randomIndex = 0;

    uint256 numManaEnergyProps = manaEnergyStorage
      .currentMaxRendererPropsIndex();

    uint256[] memory energyRectPropIndexes = new uint256[](numSpawns);

    for (uint256 i = 0; i < numSpawns; ++i) {
      energyRectPropIndexes[i] = getEnergyRectPropIndex(
        numManaEnergyProps * MAX_DELAY_TYPES_PER_ENERGY_PROPS,
        seed,
        randomIndex + i
      );
    }
    randomIndex += numSpawns;

    (
      bytes memory styles,
      bytes[] memory energyRectProps,
      uint256 updatedRandomIndex
    ) = getAnimationStylesAndProps(energyRectPropIndexes, seed, randomIndex);
    randomIndex = updatedRandomIndex;

    bytes memory images;
    for (uint256 i = 0; i < energyRectProps.length; ++i) {
      bytes memory erp = energyRectProps[i];
      if (erp.length != 0) {
        images = abi.encodePacked(images, energyRectProps[i]);
      }
    }

    bytes memory rects;
    for (uint256 i = 0; i < numSpawns; ++i) {
      rects = abi.encodePacked(
        rects,
        getEnergyRect(energyRectPropIndexes[i], seed, randomIndex + i)
      );
    }

    return
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128">',
        images,
        rects,
        '<style>',
        styles,
        '</style>',
        '</svg>'
      );
  }

  function getAnimationStylesAndProps(
    uint256[] memory energyRectPropIndexes,
    bytes memory seed,
    uint256 randomIndex
  )
    public
    view
    returns (
      bytes memory styles,
      bytes[] memory images,
      uint256 updatedRandomIndex
    )
  {
    uint256 numManaEnergyProps = manaEnergyStorage
      .currentMaxRendererPropsIndex();

    styles = abi.encodePacked(
      '.',
      MANA_ENERGY_CLASS,
      ' { background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated; }'
    );

    images = new bytes[](numManaEnergyProps * MAX_DELAY_TYPES_PER_ENERGY_PROPS);

    for (uint256 i = 0; i < energyRectPropIndexes.length; ++i) {
      uint256 energyRectPropIndex = energyRectPropIndexes[i];
      if (images[energyRectPropIndex].length == 0) {
        bytes memory rendererProps = manaEnergyStorage.indexToRendererProps(
          uint16(energyRectPropIndex / MAX_DELAY_TYPES_PER_ENERGY_PROPS)
        );

        uint256 width = uint256(uint8(rendererProps[0]));
        uint256 height = uint256(uint8(rendererProps[1]));

        bytes memory randomSrc = abi.encodePacked(
          keccak256(abi.encodePacked(seed, randomIndex + i))
        );

        uint256 numFrames = MIN_NUM_DELAY_FRAMES +
          (uint256(uint8(randomSrc[0])) %
            (MAX_NUM_DELAY_FRAMES - MIN_NUM_DELAY_FRAMES));

        bytes memory modifiedRendererProps = rendererProps;
        for (uint256 x = 0; x < numFrames; ++x) {
          modifiedRendererProps = abi.encodePacked(
            modifiedRendererProps,
            EMPTY_FULL_FRAME
          );
        }

        images[energyRectPropIndex] = abi.encodePacked(
          '<image x="128" y="128" id="',
          MANA_ENERGY_ID,
          '-',
          energyRectPropIndex.toString(),
          '" class="',
          MANA_ENERGY_CLASS,
          ' ',
          '" width="',
          width.toString(),
          '" height="',
          height.toString(),
          '" href="',
          gifRenderer.render(modifiedRendererProps),
          '" />'
        );
      }
    }
    updatedRandomIndex = randomIndex + images.length;
  }

  function getEnergyRectPropIndex(
    uint256 numEnergyRectProps,
    bytes memory seed,
    uint256 index
  ) public pure returns (uint256 energyRectPropIndex) {
    bytes memory randomSource = abi.encodePacked(
      keccak256(abi.encodePacked(seed, index))
    );
    energyRectPropIndex =
      BytesUtils.toUint8(randomSource, 0) %
      numEnergyRectProps;
  }

  function getEnergyRect(
    uint256 energyRectPropIndex,
    bytes memory seed,
    uint256 index
  ) public view returns (bytes memory rect) {
    bytes memory randomSource = abi.encodePacked(
      keccak256(abi.encodePacked(seed, index))
    );

    uint256 x = ENERGY_SPAWN_RECT[0] +
      (BytesUtils.toUint8(randomSource, 1) %
        (ENERGY_SPAWN_RECT[2] - ENERGY_SPAWN_RECT[0]));
    uint256 y = ENERGY_SPAWN_RECT[1] +
      (BytesUtils.toUint8(randomSource, 2) %
        (ENERGY_SPAWN_RECT[3] - ENERGY_SPAWN_RECT[1]));

    rect = abi.encodePacked(
      '<use href="#',
      MANA_ENERGY_ID,
      '-',
      energyRectPropIndex.toString(),
      '" x="-',
      (128 - x).toString(),
      '" y="-',
      (128 - y).toString(),
      '"'
      ' />'
    );
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
          'data:image/svg+xml;base64,',
          Base64.encode(bytes(renderRaw(props)))
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
          (props.length / 3).toString(),
          '}'
        )
      );
  }
}