// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '../libraries/NftMetadataUtils.sol';
import '../rces/LiveServiceRarityCompositingEngine.sol';
import '../rces/RarityCompositingEngine.sol';

import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';
import '@abf-monorepo/protocol/contracts/interfaces/IRenderer.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

contract BaseMergeAttributesRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  LiveServiceRarityCompositingEngine public liveRce;

  constructor(address _liveRce) {
    liveRce = LiveServiceRarityCompositingEngine(_liveRce);
  }

  function setLiveRCE(address _liveRce) public onlyOwner {
    liveRce = LiveServiceRarityCompositingEngine(_liveRce);
  }

  function owner() public view override(Ownable, IRenderer) returns (address) {
    return super.owner();
  }

  function name() public pure override returns (string memory) {
    return 'Base Merge Attributes';
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
    (, uint16[] memory rceAttributeIndexes) = liveRce
      .decodeAttributeIndexesWithLiveServiceData(encodedAttributeIndexes);

    RarityCompositingEngine rce = liveRce.rce();

    bytes memory attributesJSON = bytes(
      rce.getAttributesJSON(rceAttributeIndexes)
    );

    return (BytesUtils.slice(attributesJSON, 1, attributesJSON.length - 2));
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