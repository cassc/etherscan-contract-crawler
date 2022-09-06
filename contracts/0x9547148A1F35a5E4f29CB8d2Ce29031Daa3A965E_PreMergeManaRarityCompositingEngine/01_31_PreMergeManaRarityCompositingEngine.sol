// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '../storage/RendererPropsStorage.sol';
import '../storage/ChunkedDataStorage.sol';
import '../Merge.sol';
import '../MergeMana.sol';
import '../rces/RarityCompositingEngine.sol';
import '../libraries/DecimalUtils.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/renderers/LayerCompositeRenderer.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';

contract PreMergeManaRarityCompositingEngine is Ownable {
  using Strings for uint256;

  RarityCompositingEngine public rce;
  MergeMana public mergeMana;

  // metadata
  string public description;

  constructor(address _rce, address _mergeMana) {
    rce = RarityCompositingEngine(_rce);
    mergeMana = MergeMana(_mergeMana);
  }

  function setDescription(string memory _description) public onlyOwner {
    description = _description;
  }

  function setMergeMana(address _mergeMana) public onlyOwner {
    mergeMana = MergeMana(_mergeMana);
  }

  function setRCE(address _rce) public onlyOwner {
    rce = RarityCompositingEngine(_rce);
  }

  function getRarity(uint256 rarityMultiplier, bytes memory seed)
    public
    view
    returns (uint256[] memory layerIndexes, uint16[] memory attributeIndexes)
  {
    // getRarity modifies rceAttributeIndexes to prefix it with the tokenId for getRendererProps
    (
      uint256[] memory rceLayerIndexes,
      uint16[] memory rceAttributeIndexes
    ) = rce.getRarity(rarityMultiplier, seed);

    layerIndexes = new uint256[](rceLayerIndexes.length + 1);
    for (uint256 i = 1; i < layerIndexes.length; ++i) {
      layerIndexes[i] = rceLayerIndexes[i - 1];
    }
    attributeIndexes = new uint16[](rceAttributeIndexes.length + 1);
    attributeIndexes[0] = uint16(BytesUtils.toUint256(seed, 32));
    for (uint256 i = 1; i < attributeIndexes.length; ++i) {
      attributeIndexes[i] = rceAttributeIndexes[i - 1];
    }
  }

  function getRendererProps(uint16[] memory attributeIndexes)
    public
    view
    returns (address[] memory renderers, bytes[] memory rendererProps)
  {
    uint16[] memory rceAttributeIndexes = new uint16[](
      attributeIndexes.length - 1
    );
    for (uint256 i = 0; i < rceAttributeIndexes.length; ++i) {
      rceAttributeIndexes[i] = attributeIndexes[i + 1];
    }
    return rce.getRendererProps(rceAttributeIndexes);
  }

  function getAttributesJSON(uint16[] memory attributeIndexes)
    public
    view
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          getActualAttributesJSON(attributeIndexes),
          getDescriptionJSON()
        )
      );
  }

  function getDescriptionJSON() public view returns (string memory) {
    if (abi.encodePacked(description).length == 0) {
      return '';
    }
    return string(abi.encodePacked(', "description": "', description, '"'));
  }

  function getStatefulManaAttributesJSON(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    uint256 numDecimals = mergeMana.numDecimals();

    string memory totalMana = DecimalUtils.toDecimalString(
      mergeMana.getTotalManaWithNoPenalties(tokenId),
      numDecimals
    );

    bytes memory attributes = abi.encodePacked(
      _getAttributeObjectWithMaxValue(
        'Usable mana',
        DecimalUtils.toDecimalString(
          mergeMana.getTotalMana(tokenId),
          numDecimals
        ),
        totalMana
      ),
      ''
      // ',',
      // _getAttributeObjectWithMaxValue(
      //   'Channelabe mana',
      //   DecimalUtils.toDecimalString(
      //     mergeMana.getBoostedMana(tokenId) + mergeMana.getInherentMana(tokenId),
      //     numDecimals
      //   ),
      //   totalMana
      // ),
      // mergeMana.channelingRitualDestinationTokenId(tokenId) != 0 ? abi.encodePacked(
      // ',',
      // _getAttributeObjectNumber(
      //   'Channeling To',
      //   mergeMana.channelingRitualDestinationTokenId(tokenId).toString()
      // )) : bytes('')
    );
    return string(attributes);
  }

  function getBaseManaAttributesJSON(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    uint256 numDecimals = mergeMana.numDecimals();

    string memory totalMana = DecimalUtils.toDecimalString(
      mergeMana.getTotalManaWithNoPenalties(tokenId),
      numDecimals
    );

    bytes memory attributes = abi.encodePacked(
      // _getAttributeObjectWithMaxValue(
      //   'Total mana',
      //   totalMana,
      //   totalMana
      // ),
      // ',',
      // _getAttributeObjectBoostNumber(
      //   'Channeled mana',
      //   DecimalUtils.toDecimalString(
      //     mergeMana.channeledMana(tokenId),
      //     numDecimals
      //   ),
      //  totalMana
      // ),
      // ',',
      _getAttributeObjectBoostNumber(
        'Inherent mana',
        DecimalUtils.toDecimalString(
          mergeMana.getInherentManaWithNoPenalties(tokenId),
          numDecimals
        ),
        totalMana
      ),
      ',',
      _getAttributeObjectBoostNumber(
        'Boosted mana',
        DecimalUtils.toDecimalString(
          mergeMana.boostedMana(tokenId),
          numDecimals
        ),
        totalMana
      )
    );
    return string(attributes);
  }

  function getActualAttributesJSON(uint16[] memory attributeIndexes)
    public
    view
    returns (string memory)
  {
    uint256 tokenId = uint256(attributeIndexes[0]);
    uint16[] memory rceAttributeIndexes = new uint16[](
      attributeIndexes.length - 1
    );
    for (uint256 i = 0; i < rceAttributeIndexes.length; ++i) {
      rceAttributeIndexes[i] = attributeIndexes[i + 1];
    }
    bytes memory rceAttributesJSON = abi.encodePacked(
      rce.getAttributesJSON(rceAttributeIndexes)
    );

    bytes memory attributes = abi.encodePacked(
      BytesUtils.slice(rceAttributesJSON, 0, rceAttributesJSON.length - 1),
      ',',
      getBaseManaAttributesJSON(tokenId),
      ',',
      getStatefulManaAttributesJSON(tokenId),
      ']'
    );
    return string(attributes);
  }

  function _getAttributeObjectBoostNumber(
    string memory traitType,
    string memory value,
    string memory maxValue
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"value":',
          value,
          ',"max_value":',
          maxValue,
          ',"trait_type":"',
          traitType,
          '", "display_type": "boost_number" }'
        )
      );
  }

  function _getAttributeObjectNumber(
    string memory traitType,
    string memory value
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"value":',
          value,
          ',"trait_type":"',
          traitType,
          '", "display_type": "number" }'
        )
      );
  }

  function _getAttributeObjectWithMaxValue(
    string memory traitType,
    string memory value,
    string memory maxValue
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"value":',
          value,
          ',"max_value":',
          maxValue,
          ',"trait_type":"',
          traitType,
          '"}'
        )
      );
  }

  function _getAttributeObject(string memory traitType, string memory value)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked('{"value":', value, ',"trait_type":"', traitType, '"}')
      );
  }

  function getRender(uint16[] memory attributeIndexes)
    public
    view
    returns (string memory)
  {
    LayerCompositeRenderer renderer = LayerCompositeRenderer(
      rce.COMPOSITING_RENDERER()
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
      rce.COMPOSITING_RENDERER()
    );
    (
      address[] memory renderers,
      bytes[] memory rendererProps
    ) = getRendererProps(attributeIndexes);
    return renderer.renderRaw(renderer.encodeProps(renderers, rendererProps));
  }
}