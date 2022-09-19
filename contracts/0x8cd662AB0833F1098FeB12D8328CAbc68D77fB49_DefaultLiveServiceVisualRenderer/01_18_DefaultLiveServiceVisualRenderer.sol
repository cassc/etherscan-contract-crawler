// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '@abf-monorepo/protocol/contracts/interfaces/IRenderer.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';
import '../rces/RarityCompositingEngine.sol';

contract DefaultLiveServiceVisualRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  RarityCompositingEngine public rce;
  IRenderer public compactMiddlewareRenderer;

  constructor(address _compactMiddlewareRenderer, address _rce) {
    compactMiddlewareRenderer = IRenderer(_compactMiddlewareRenderer);
    rce = RarityCompositingEngine(_rce);
  }

  function owner() public view override(Ownable, IRenderer) returns (address) {
    return super.owner();
  }

  function name() public pure override returns (string memory) {
    return 'Default live service visual renderer';
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

  function renderRaw(bytes calldata props)
    public
    view
    override
    returns (bytes memory)
  {
    uint256 attributeIndex = BytesUtils.toUint256(props, 64);
    RarityCompositingEngine.AttributeData memory ad = rce.decodeAttributeData(
      rce.attributeStorage().indexToData(attributeIndex)
    );

    return
      compactMiddlewareRenderer.renderRaw(
        abi.encodePacked(
          rce.GLOBAL_ATTRIBUTE_PREFIX(),
          ad.prefix,
          rce.rendererPropsStorage().indexToRendererProps(ad.rendererDataIndex)
        )
      );
  }

  function render(bytes calldata props)
    external
    view
    override
    returns (string memory)
  {
    uint256 attributeIndex = BytesUtils.toUint256(props, 64);
    RarityCompositingEngine.AttributeData memory ad = rce.decodeAttributeData(
      rce.attributeStorage().indexToData(attributeIndex)
    );

    return
      compactMiddlewareRenderer.render(
        abi.encodePacked(
          rce.GLOBAL_ATTRIBUTE_PREFIX(),
          ad.prefix,
          rce.rendererPropsStorage().indexToRendererProps(ad.rendererDataIndex)
        )
      );
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