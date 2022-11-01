// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '../libraries/NftMetadataUtils.sol';
import '../rces/LiveServiceRarityCompositingEngine.sol';
import '../rces/RarityCompositingEngine.sol';
import '../MergeMana.sol';
import '../libraries/DecimalUtils.sol';
import '../rituals/TransmutationRitual.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';
import '@abf-monorepo/protocol/contracts/interfaces/IRenderer.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

contract TransmutationRitualAttributesRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  TransmutationRitual public ritual;

  constructor(address _ritual) {
    ritual = TransmutationRitual(_ritual);
  }

  function owner() public view override(Ownable, IRenderer) returns (address) {
    return super.owner();
  }

  function name() public pure override returns (string memory) {
    return 'TransmutationRitualAttributesRenderer';
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
    return 'attributes';
  }

  function renderRaw(bytes calldata props)
    public
    view
    override
    returns (bytes memory)
  {
    uint16[] memory encodedAttributeIndexes = abi.decode(props, (uint16[]));
    uint256 tokenId = uint256(encodedAttributeIndexes[0]);

    string[] memory components = new string[](1);
    components[0] = getStatefulSpellAttributes(tokenId);
    return bytes(NftMetadataUtils.delimit(components));
  }

  function getStatefulSpellAttributes(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    bytes32 spell = ritual.getSpell(tokenId);
    bool isEmptySpell = uint256(spell) == 0;

    bytes memory materialSeed = abi.encodePacked(
      ritual.getComputedSeed(tokenId, ritual.getSpell(tokenId))
    );

    string[] memory components = new string[](2);
    components[0] = NftMetadataUtils.getAttributeObjectWithMaxValue(
      'Spell Strength',
      isEmptySpell
        ? '0'
        : uint256(uint8(BytesUtils.toUint8(materialSeed, 0)) / 25).toString(),
      '10'
    );
    components[1] = NftMetadataUtils.getSimpleAttributeObject(
      'Transmutation style',
      isEmptySpell
        ? NftMetadataUtils.stringWrap('None')
        : NftMetadataUtils.stringWrap(
          getMajorLabel(BytesUtils.toUint8(materialSeed, 1) / 16)
        )
    );

    return NftMetadataUtils.delimit(components);
  }

  function getMajorLabel(uint8 majorIdx) public pure returns (string memory) {
    if (majorIdx % 2 == 0) {
      majorIdx /= 2; //0 to 8
      if (majorIdx == 0) {
        return 'Glow';
      } else if (majorIdx == 1) {
        return 'Black Glow';
      } else if (majorIdx == 2) {
        return 'Contrasting Hue';
      } else if (majorIdx == 3) {
        return 'Inversion';
      } else if (majorIdx == 4) {
        return 'Highlight';
      } else if (majorIdx == 5) {
        return 'Two tone';
      } else {
        return 'Hue shift';
      }
    }
    return 'Chaos';
  }

  function render(bytes calldata props)
    external
    view
    override
    returns (string memory)
  {
    return string(renderRaw(props));
  }

  function attributes(bytes calldata props)
    external
    pure
    override
    returns (string memory)
  {
    return '';
  }
}