// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '../storage/RendererPropsStorage.sol';
import '../storage/ChunkedDataStorage.sol';
import '../Merge.sol';
import '../MergeMana.sol';
import './RarityCompositingEngine.sol';
import '../libraries/DecimalUtils.sol';
import '../libraries/NftMetadataUtils.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/renderers/LayerCompositeRenderer.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';

contract LiveServiceRarityCompositingEngine is Ownable {
  using Strings for uint256;

  RarityCompositingEngine public rce;

  // image renderer contracts
  address public compositingRenderer;

  mapping(uint256 => address) visualLayersRenderers;
  uint256 public maxVisualLayersIndex;

  mapping(uint256 => uint256) visualLayerIndexRemap;

  // metadata renderer contracts
  mapping(uint256 => address) genericMetadataRenderers;
  uint256 public maxGenericRenderersIndex;

  mapping(uint256 => address) attributeMetadataRenderers;
  uint256 public maxAttributeRenderersIndex;

  constructor(address _rce, address _compositingRenderer) {
    rce = RarityCompositingEngine(_rce);
    compositingRenderer = _compositingRenderer;
  }

  function setCompositingRenderer(address _compositingRenderer)
    public
    onlyOwner
  {
    compositingRenderer = _compositingRenderer;
  }

  function setVisualLayerRenderers(
    uint256[] memory indexes,
    address[] memory renderers
  ) public onlyOwner {
    for (uint256 i = 0; i < indexes.length; ++i) {
      visualLayersRenderers[indexes[i]] = renderers[i];
    }
  }

  function setVisualLayerIndexRemap(
    uint256[] memory indexes,
    uint256[] memory attributeIndexes
  ) public onlyOwner {
    for (uint256 i = 0; i < indexes.length; ++i) {
      visualLayerIndexRemap[indexes[i]] = attributeIndexes[i];
    }
  }

  function setAttributeMetadataRenderers(
    uint256[] memory indexes,
    address[] memory renderers
  ) public onlyOwner {
    for (uint256 i = 0; i < indexes.length; ++i) {
      attributeMetadataRenderers[indexes[i]] = renderers[i];
    }
  }

  function setGenericMetadataRenderers(
    uint256[] memory indexes,
    address[] memory renderers
  ) public onlyOwner {
    for (uint256 i = 0; i < indexes.length; ++i) {
      genericMetadataRenderers[indexes[i]] = renderers[i];
    }
  }

  function setMaxVisualLayersIndex(uint256 _maxVisualLayersIndex)
    public
    onlyOwner
  {
    maxVisualLayersIndex = _maxVisualLayersIndex;
  }

  function setMaxAttributeRenderersIndex(uint256 _maxAttributeRenderersIndex)
    public
    onlyOwner
  {
    maxAttributeRenderersIndex = _maxAttributeRenderersIndex;
  }

  function setMaxGenericRenderersIndex(uint256 _maxGenericRenderersIndex)
    public
    onlyOwner
  {
    maxGenericRenderersIndex = _maxGenericRenderersIndex;
  }

  function encodeAttributeIndexesWithLiveServiceData(
    bytes memory seed,
    uint16[] memory attributeIndexes
  ) public pure returns (uint16[] memory encodedAttributeIndexes) {
    encodedAttributeIndexes = new uint16[](attributeIndexes.length + 1);
    encodedAttributeIndexes[0] = uint16(BytesUtils.toUint256(seed, 32));
    for (uint256 i = 1; i < encodedAttributeIndexes.length; ++i) {
      encodedAttributeIndexes[i] = attributeIndexes[i - 1];
    }
  }

  function decodeAttributeIndexesWithLiveServiceData(
    uint16[] memory encodedAttributeIndexes
  ) public pure returns (uint256 tokenId, uint16[] memory attributeIndexes) {
    tokenId = uint256(encodedAttributeIndexes[0]);
    attributeIndexes = new uint16[](encodedAttributeIndexes.length - 1);
    for (uint256 i = 0; i < attributeIndexes.length; ++i) {
      attributeIndexes[i] = encodedAttributeIndexes[i + 1];
    }
  }

  function getRarity(uint256 rarityMultiplier, bytes memory seed)
    public
    view
    returns (uint256[] memory layerIndexes, uint16[] memory attributeIndexes)
  {
    (
      uint256[] memory rceLayerIndexes,
      uint16[] memory rceAttributeIndexes
    ) = rce.getRarity(rarityMultiplier, seed);

    layerIndexes = rceLayerIndexes;
    attributeIndexes = encodeAttributeIndexesWithLiveServiceData(
      seed,
      rceAttributeIndexes
    );
  }

  function getRendererProps(uint16[] memory encodedAttributeIndexes)
    public
    view
    returns (address[] memory renderers, bytes[] memory rendererProps)
  {
    (
      uint256 tokenId,
      uint16[] memory rceAttributeIndexes
    ) = decodeAttributeIndexesWithLiveServiceData(encodedAttributeIndexes);

    renderers = new address[](maxVisualLayersIndex);
    rendererProps = new bytes[](maxVisualLayersIndex);

    for (uint256 i = 0; i < maxVisualLayersIndex; ++i) {
      renderers[i] = visualLayersRenderers[i];
      uint256 remapIndex = visualLayerIndexRemap[i];
      // if remapIndex bigger than the original rce's max layer is considered void
      if (remapIndex > rceAttributeIndexes.length) {
        rendererProps[i] = abi.encode(i, tokenId, rceAttributeIndexes);
      } else {
        RarityCompositingEngine.AttributeData memory ad = rce
          .decodeAttributeData(
            rce.attributeStorage().indexToData(rceAttributeIndexes[remapIndex])
          );
        if (ad.shouldShowInRendererProps) {
          rendererProps[i] = abi.encode(
            i,
            tokenId,
            rceAttributeIndexes[remapIndex]
          );
        } else {
          renderers[i] = address(0);
        }
      }
    }
  }

  function getAttributesJSON(uint16[] memory attributeIndexes)
    public
    view
    returns (string memory)
  {
    bytes memory props = abi.encode(attributeIndexes);
    string[] memory attributesArray = new string[](maxAttributeRenderersIndex);
    for (uint256 i = 0; i < maxAttributeRenderersIndex; ++i) {
      IRenderer renderer = IRenderer(attributeMetadataRenderers[i]);
      attributesArray[i] = renderer.render(props);
    }
    string[] memory metadataComponents = new string[](
      1 + maxGenericRenderersIndex
    );
    metadataComponents[0] = NftMetadataUtils.array(attributesArray);
    for (uint256 i = 0; i < maxGenericRenderersIndex; ++i) {
      IRenderer renderer = IRenderer(genericMetadataRenderers[i]);
      metadataComponents[i + 1] = NftMetadataUtils.keyValue(
        renderer.renderAttributeKey(),
        renderer.render(props)
      );
    }
    return NftMetadataUtils.delimit(metadataComponents);
  }

  function getRender(uint16[] memory attributeIndexes)
    public
    view
    returns (string memory)
  {
    LayerCompositeRenderer renderer = LayerCompositeRenderer(
      compositingRenderer
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
      compositingRenderer
    );
    (
      address[] memory renderers,
      bytes[] memory rendererProps
    ) = getRendererProps(attributeIndexes);
    return renderer.renderRaw(renderer.encodeProps(renderers, rendererProps));
  }
}