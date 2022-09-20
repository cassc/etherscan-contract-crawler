// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '../libraries/NftMetadataUtils.sol';
import '../rces/LiveServiceRarityCompositingEngine.sol';
import '../rces/RarityCompositingEngine.sol';
import '../MergeMana.sol';
import '../libraries/DecimalUtils.sol';

import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';
import '@abf-monorepo/protocol/contracts/interfaces/IRenderer.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

contract MergeManaAttributesRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  LiveServiceRarityCompositingEngine public liveRce;
  MergeMana public mergeMana;

  constructor(address _liveRce, address _mergeMana) {
    liveRce = LiveServiceRarityCompositingEngine(_liveRce);
    mergeMana = MergeMana(_mergeMana);
  }

  function setMergeMana(address _mergeMana) public onlyOwner {
    mergeMana = MergeMana(_mergeMana);
  }

  function setLiveRCE(address _liveRce) public onlyOwner {
    liveRce = LiveServiceRarityCompositingEngine(_liveRce);
  }

  function owner() public view override(Ownable, IRenderer) returns (address) {
    return super.owner();
  }

  function name() public pure override returns (string memory) {
    return 'Merge Mana Attributes';
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

    string[] memory components = new string[](2);
    components[0] = getBaseManaAttributes(tokenId);
    components[1] = getStatefulManaAttributes(tokenId);
    return bytes(NftMetadataUtils.delimit(components));
  }

  function getBaseManaAttributes(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    uint256 numDecimals = mergeMana.numDecimals();

    string memory totalMana = DecimalUtils.toDecimalString(
      mergeMana.getTotalManaWithNoPenalties(tokenId),
      numDecimals
    );

    string[] memory components = new string[](2);
    components[0] = NftMetadataUtils
      .getAttributeObjectWithDisplayTypeAndMaxValue(
        'Inherent Mana',
        DecimalUtils.toDecimalString(
          mergeMana.getInherentManaWithNoPenalties(tokenId),
          numDecimals
        ),
        NftMetadataUtils.BOOST_NUMBER_DISPLAY_TYPE,
        totalMana
      );

    components[1] = NftMetadataUtils
      .getAttributeObjectWithDisplayTypeAndMaxValue(
        'Boosted Mana',
        DecimalUtils.toDecimalString(
          mergeMana.boostedMana(tokenId),
          numDecimals
        ),
        NftMetadataUtils.BOOST_NUMBER_DISPLAY_TYPE,
        totalMana
      );

    // components[2] = NftMetadataUtils
    //   .getAttributeObjectWithDisplayTypeAndMaxValue(
    //     'Channeled Mana',
    //     DecimalUtils.toDecimalString(
    //       mergeMana.channeledMana(tokenId),
    //       numDecimals
    //     ),
    //     NftMetadataUtils.BOOST_NUMBER_DISPLAY_TYPE,
    //     totalMana
    //   );
    return NftMetadataUtils.delimit(components);
  }

  function getStatefulManaAttributes(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    uint256 numDecimals = mergeMana.numDecimals();

    string memory totalMana = DecimalUtils.toDecimalString(
      mergeMana.getTotalManaWithNoPenalties(tokenId),
      numDecimals
    );

    string[] memory components = new string[](1);
    components[0] = NftMetadataUtils
      .getAttributeObjectWithMaxValue(
        'Usable Mana',
        DecimalUtils.toDecimalString(
          mergeMana.getTotalMana(tokenId),
          numDecimals
        ),
        totalMana
      );

    // components[1] = NftMetadataUtils
    //   .getAttributeObjectWithDisplayTypeAndMaxValue(
    //     'Channelabe Mana',
    //     DecimalUtils.toDecimalString(
    //       mergeMana.getBoostedMana(tokenId) + mergeMana.getInherentMana(tokenId),
    //       numDecimals
    //     ),
    //     NftMetadataUtils.BOOST_NUMBER_DISPLAY_TYPE,
    //     totalMana
    //   );

    return NftMetadataUtils.delimit(components);
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