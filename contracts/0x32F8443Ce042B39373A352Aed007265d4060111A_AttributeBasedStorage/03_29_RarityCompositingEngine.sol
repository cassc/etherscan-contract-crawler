// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import './RendererPropsStorage.sol';
import './ChunkedDataStorage.sol';

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/renderers/LayerCompositeRenderer.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';

contract RarityCompositingEngine is Ownable {
  uint256 public constant MAX_UINT_16 = 0xFFFF;
  uint256 public constant RARITY_DATA_TUPLE_NUM_BYTES = 4;

  address public immutable COMPOSITING_RENDERER;
  address public immutable ATTRIBUTE_RENDERER;
  uint256 public immutable MAX_LAYERS;
  bytes public GLOBAL_ATTRIBUTE_PREFIX;

  // storage contracts
  RendererPropsStorage public rendererPropsStorage;
  ChunkedDataStorage public layerStorage;
  ChunkedDataStorage public attributeStorage;

  uint256 constant NUM_DECIMALS = 2; // units are in bps
  uint256 constant ONE_UNIT = 10**NUM_DECIMALS; // represents 0.01x
  uint256 constant ONE_HUNDRED_PERCENT = 100 * ONE_UNIT; // represents 1.00x

  struct LayerData {
    uint8 layerType;
    bytes rarityData;
  }

  struct AttributeData {
    bool shouldShowInAttributes;
    bool shouldShowInRendererProps;
    uint16 rendererDataIndex;
    string key;
    string value;
    bytes prefix;
  }

  constructor(
    uint256 _maxLayers,
    address _compositingRenderer,
    address _attributeRenderer,
    bytes memory _globalAttributePrefix,
    address _rendererPropsStorage,
    address _layerStorage,
    address _attributeStorage
  ) {
    MAX_LAYERS = _maxLayers;
    COMPOSITING_RENDERER = _compositingRenderer;
    ATTRIBUTE_RENDERER = _attributeRenderer;
    GLOBAL_ATTRIBUTE_PREFIX = _globalAttributePrefix;
    rendererPropsStorage = RendererPropsStorage(_rendererPropsStorage);
    layerStorage = ChunkedDataStorage(_layerStorage);
    attributeStorage = ChunkedDataStorage(_attributeStorage);
  }

  function setRendererPropsStorage(address _rendererPropsStorage)
    public
    onlyOwner
  {
    rendererPropsStorage = RendererPropsStorage(_rendererPropsStorage);
  }

  function setLayerStorage(address _layerStorage) public onlyOwner {
    layerStorage = ChunkedDataStorage(_layerStorage);
  }

  function setAttributeStorage(address _attributeStorage) public onlyOwner {
    attributeStorage = ChunkedDataStorage(_attributeStorage);
  }

  function decodeLayerData(bytes memory data)
    public
    pure
    returns (LayerData memory ld)
  {
    if (data.length != 0) {
      ld.layerType = uint8(data[0]);
      ld.rarityData = BytesUtils.slice(data, 1, data.length - 1);
    }
  }

  function decodeAttributeData(bytes memory data)
    public
    pure
    returns (AttributeData memory ad)
  {
    if (data.length != 0) {
      ad.shouldShowInAttributes = uint8(data[0]) == 1;
      ad.shouldShowInRendererProps = uint8(data[1]) == 1;
      ad.rendererDataIndex = BytesUtils.toUint16(data, 2);
      uint8 keyLength = uint8(data[4]);
      ad.key = string(BytesUtils.slice(data, 5, keyLength));
      uint8 valueLength = uint8(data[5 + keyLength]);
      ad.value = string(BytesUtils.slice(data, 6 + keyLength, valueLength));
      ad.prefix = BytesUtils.slice(
        data,
        6 + keyLength + valueLength,
        data.length - (6 + keyLength + valueLength)
      );
    }
  }

  function resolveLayerIndex(
    uint16[] memory attributeIndexes,
    uint256 layerIndex
  ) public view returns (uint256) {
    require(
      layerIndex != 0,
      'RarityCompositingEngine: layerIndex can not be zero'
    );
    LayerData memory layerData = decodeLayerData(
      layerStorage.indexToData(layerIndex)
    );
    if (layerData.layerType == 1) {
      uint16 rootAttributeIndex = attributeIndexes[
        BytesUtils.toUint16(layerData.rarityData, 0)
      ];
      require(
        rootAttributeIndex != 0,
        'RarityCompositingEngine: Root attribute has not been set yet'
      );
      uint256 dependentLayerIndex = 0;
      for (uint256 j = 2; j < layerData.rarityData.length; j += 4) {
        if (
          BytesUtils.toUint16(layerData.rarityData, j) == rootAttributeIndex
        ) {
          dependentLayerIndex = BytesUtils.toUint16(
            layerData.rarityData,
            j + 2
          );
          break;
        }
      }
      require(
        dependentLayerIndex != 0,
        'RarityCompositingEngine: No dependent layerIndex was found'
      );
      return resolveLayerIndex(attributeIndexes, dependentLayerIndex);
    } else if (layerData.layerType == 0) {
      return layerIndex;
    }
    return 0;
  }

  function applyRarityMultiplier(
    uint256 rarityMultiplier,
    uint256[] memory rarityData
  )
    public
    pure
    returns (
      uint256 appliedRaritySum,
      uint256[] memory appliedRarityData,
      uint256[] memory rarityMultipliers
    )
  {
    rarityMultipliers = new uint256[](rarityData.length);

    if (rarityData.length == 0) {
      return (0, rarityData, rarityMultipliers);
    }

    if (rarityData.length == 2) {
      return (rarityData[1], rarityData, rarityMultipliers);
    }

    // sum the current rarity values
    uint256 highestRarityWeight = rarityData[1];
    uint256 lowestRarityWeight = rarityData[rarityData.length - 1];

    if (highestRarityWeight - lowestRarityWeight == 0) {
      for (uint256 i = 1; i < rarityData.length; i += 2) {
        appliedRaritySum += rarityData[i];
      }
      return (appliedRaritySum, rarityData, rarityMultipliers);
    }

    appliedRarityData = rarityData;

    uint256 a = (rarityMultiplier * ONE_UNIT) /
      ((highestRarityWeight - lowestRarityWeight)**2);

    for (uint256 i = 1; i < rarityData.length; i += 2) {
      uint256 scaledRarityMultiplier = (a *
        (highestRarityWeight - rarityData[i])**2) / ONE_UNIT;
      uint256 appliedRarity = ((ONE_HUNDRED_PERCENT + scaledRarityMultiplier) *
        rarityData[i]) / ONE_UNIT;
      rarityMultipliers[i] = scaledRarityMultiplier;
      appliedRarityData[i] = appliedRarity;
      appliedRaritySum += appliedRarityData[i];
    }
  }

  function getRarity(uint256 rarityMultiplier, bytes memory seed)
    public
    view
    returns (uint256[] memory layerIndexes, uint16[] memory attributeIndexes)
  {
    // attributeIndexes are the keys to the actual visual output data for a specific layer index
    attributeIndexes = new uint16[](MAX_LAYERS);

    // layerIndexes are the keys to the actual layer and its corresponding rarity data
    layerIndexes = new uint256[](MAX_LAYERS);
    // set default layer indexes
    for (uint16 i = 0; i < MAX_LAYERS; ++i) {
      layerIndexes[i] = i + 1;
    }

    for (uint16 i = 0; i < MAX_LAYERS; ++i) {
      layerIndexes[i] = resolveLayerIndex(attributeIndexes, layerIndexes[i]);
      LayerData memory layerData = decodeLayerData(
        layerStorage.indexToData(layerIndexes[i])
      );
      uint256 randomSource = uint256(keccak256(abi.encodePacked(seed, i)));

      uint256[] memory rarityData = new uint256[](
        (layerData.rarityData.length) / 2
      );
      for (uint256 j = 0; j < layerData.rarityData.length; j += 2) {
        rarityData[j / 2] = BytesUtils.toUint16(layerData.rarityData, j);
      }

      (
        uint256 appliedRaritySum,
        uint256[] memory appliedRarityData,

      ) = applyRarityMultiplier(rarityMultiplier, rarityData);
      // get attribute for this layer
      uint16 attributeIndex = 0;
      uint256 rarityValue = randomSource % appliedRaritySum;
      uint256 acc = 0;
      for (uint256 j = 1; j < appliedRarityData.length; j += 2) {
        acc += appliedRarityData[j];
        if (acc >= rarityValue) {
          attributeIndex = uint16(appliedRarityData[j - 1]);
          break;
        }
      }
      require(
        attributeIndex != 0,
        'RarityCompositingEngine: No attribute was found for layer.'
      );
      attributeIndexes[i] = attributeIndex;
    }
  }

  function getRendererProps(uint16[] memory attributeIndexes)
    public
    view
    returns (address[] memory renderers, bytes[] memory rendererProps)
  {
    uint256 numNonrendereredAttributes = 0;
    for (uint256 i = 0; i < attributeIndexes.length; ++i) {
      AttributeData memory ad = decodeAttributeData(
        attributeStorage.indexToData(attributeIndexes[i])
      );
      if (!ad.shouldShowInRendererProps) {
        numNonrendereredAttributes++;
      }
    }

    renderers = new address[](
      attributeIndexes.length - numNonrendereredAttributes
    );
    rendererProps = new bytes[](
      attributeIndexes.length - numNonrendereredAttributes
    );

    uint256 numRenderersStored = 0;
    for (uint256 i = 0; i < attributeIndexes.length; ++i) {
      AttributeData memory ad = decodeAttributeData(
        attributeStorage.indexToData(attributeIndexes[i])
      );
      if (ad.shouldShowInRendererProps) {
        uint256 rendererIndex = attributeIndexes.length -
          numNonrendereredAttributes -
          1 -
          numRenderersStored;
        renderers[rendererIndex] = ATTRIBUTE_RENDERER;
        rendererProps[rendererIndex] = abi.encodePacked(
          GLOBAL_ATTRIBUTE_PREFIX,
          ad.prefix,
          rendererPropsStorage.indexToRendererProps(ad.rendererDataIndex)
        );
        numRenderersStored++;
      }
    }
  }

  function getAttributesJSON(uint16[] memory attributeIndexes)
    public
    view
    returns (string memory)
  {
    bytes memory attributes = '[';
    for (uint256 i = 0; i < attributeIndexes.length; ++i) {
      AttributeData memory ad = decodeAttributeData(
        attributeStorage.indexToData(attributeIndexes[i])
      );
      if (ad.shouldShowInAttributes) {
        attributes = abi.encodePacked(
          attributes,
          (attributes.length == 1) ? '' : ',',
          '{"value":"',
          ad.value,
          '","trait_type":"',
          ad.key,
          '"}'
        );
      }
    }
    attributes = abi.encodePacked(attributes, ']');
    return string(attributes);
  }

  function getRender(uint16[] memory attributeIndexes)
    public
    view
    returns (string memory)
  {
    LayerCompositeRenderer renderer = LayerCompositeRenderer(
      COMPOSITING_RENDERER
    );
    (
      address[] memory renderers,
      bytes[] memory rendererProps
    ) = getRendererProps(attributeIndexes);
    return renderer.render(renderer.encodeProps(renderers, rendererProps));
  }

  function getRenderRaw(uint16[] memory attributeIndexes)
    public
    view
    returns (bytes memory)
  {
    LayerCompositeRenderer renderer = LayerCompositeRenderer(
      COMPOSITING_RENDERER
    );
    (
      address[] memory renderers,
      bytes[] memory rendererProps
    ) = getRendererProps(attributeIndexes);
    return renderer.renderRaw(renderer.encodeProps(renderers, rendererProps));
  }
}