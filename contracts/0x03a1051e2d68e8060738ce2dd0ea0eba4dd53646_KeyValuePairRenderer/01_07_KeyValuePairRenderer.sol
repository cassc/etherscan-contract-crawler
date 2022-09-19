// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '@abf-monorepo/protocol/contracts/interfaces/IRenderer.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract KeyValuePairRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  string public key;
  string public value;

  constructor(string memory _key, string memory _value) {
    key = _key;
    value = _value;
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

  function renderAttributeKey() external view override returns (string memory) {
    return key;
  }

  function renderRaw(bytes calldata props)
    public
    view
    override
    returns (bytes memory)
  {
    return bytes(value);
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