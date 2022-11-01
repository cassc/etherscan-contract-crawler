// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "../libraries/SSTORE2Map.sol";
import "../libraries/BytesUtils.sol";
import "../interfaces/IRenderer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ConfiguredGifImageRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  IRenderer gifImageRenderer;

  uint public maxConfigurationIndex = 1;

  uint public constant MAX_NUM_CONFIGURATIONS = 0xFFFFFFFF;

  struct Configuration {
    uint8 width; 
    uint8 height;
    bytes colors;
  }

    event AddedConfiguration(
      uint index
    );

  constructor(address _gifImageRenderer) {
    gifImageRenderer = IRenderer(_gifImageRenderer);
  }

  function owner() public override(Ownable, IRenderer) view returns (address) {
    return super.owner();
  }

  function addConfiguration(Configuration memory config) public returns (uint) {
    require (config.colors.length % 3 == 0, "colors must come in r,g,b tuples");
    SSTORE2Map.write(bytes32(maxConfigurationIndex), abi.encodePacked(config.width, config.height, uint8(config.colors.length / 3), config.colors));
    emit AddedConfiguration(maxConfigurationIndex);
    maxConfigurationIndex++;
    require(maxConfigurationIndex <= MAX_NUM_CONFIGURATIONS, "Max number of configurations allowed.");
    return maxConfigurationIndex;
  }

  function batchAddConfiguration(Configuration[] memory configs) public returns (uint) {
    for (uint i = 0; i < configs.length; ++i) {
      Configuration memory config = configs[i];
      require (config.colors.length % 3 == 0, "colors must come in r,g,b tuples");
      SSTORE2Map.write(bytes32(maxConfigurationIndex), abi.encodePacked(config.width, config.height, uint8(config.colors.length / 3), config.colors));
      emit AddedConfiguration(maxConfigurationIndex);
      maxConfigurationIndex++;
      require(maxConfigurationIndex <= MAX_NUM_CONFIGURATIONS, "Max number of configurations allowed.");
    }
    return maxConfigurationIndex;
  }

  function getConfiguration(uint index) public view returns (bytes memory) {
    return SSTORE2Map.read(bytes32(index));
  }

  function name() public override pure returns (string memory) {
    return 'Configured Single Frame Gif';
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IRenderer).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function propsSize() external override pure returns (uint256) {
    return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  }
  
  function additionalMetadataURI() external override pure returns (string memory) {
    return "ipfs://bafkreihcz67yvvlotbn4x3p35wdbpde27rldihlzoqg2klbme7u6lehxna";
  }
  
  function renderAttributeKey() external override pure returns (string memory) {
    return "image";
  }

  function renderRaw(bytes calldata props) public override view returns (bytes memory) {
    return gifImageRenderer.renderRaw(abi.encodePacked(SSTORE2Map.read(bytes32(uint(BytesUtils.toUint32(props, 0)))), props[4: props.length]));
  }

  function render(bytes calldata props) external override view returns (string memory) {
    return gifImageRenderer.render(abi.encodePacked(SSTORE2Map.read(bytes32(uint(BytesUtils.toUint32(props, 0)))), props[4: props.length]));
  }

  function attributes(bytes calldata props) external override pure returns (string memory) {
    return string(
            abi.encodePacked(
              '{"trait_type": "Data Length", "value":', props.length.toString(), '}'
            )
          );
  }
}