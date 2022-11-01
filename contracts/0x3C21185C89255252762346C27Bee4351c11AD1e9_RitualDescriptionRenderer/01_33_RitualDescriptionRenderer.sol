// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '@abf-monorepo/protocol/contracts/interfaces/IRenderer.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../rituals/TransmutationRitual.sol';

contract RitualDescriptionRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  string public delimeter = ', \\n';

  string public defaultValue;
  TransmutationRitual public ritual;

  constructor(address _ritual, string memory _defaultValue) {
    ritual = TransmutationRitual(_ritual);
    defaultValue = _defaultValue;
  }

  function setDelimeter(string memory _delimeter) public onlyOwner {
    delimeter = _delimeter;
  }

  function owner() public view override(Ownable, IRenderer) returns (address) {
    return super.owner();
  }

  function name() public pure override returns (string memory) {
    return 'RitualDescription';
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
    return 'ipfs://TODO';
  }

  function renderAttributeKey() external pure override returns (string memory) {
    return 'description';
  }

  function renderRaw(bytes calldata props)
    public
    view
    override
    returns (bytes memory)
  {
    uint16[] memory encodedAttributeIndexes = abi.decode(props, (uint16[]));
    uint256 tokenId = uint256(encodedAttributeIndexes[0]);
    bytes32 spell = ritual.getSpell(tokenId);

    if (uint256(spell) == 0) {
      return bytes(defaultValue);
    }

    string[] memory words = ritual.getSpellInWords(spell);

    bytes memory description;

    for (uint256 i = 0; i < words.length; ++i) {
      description = abi.encodePacked(
        description,
        (i == 0 || bytes(words[i]).length == 0) ? '' : delimeter,
        words[i]
      );
    }
    return abi.encodePacked('"', description, '"');
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