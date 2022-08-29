// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "../interfaces/IRenderer.sol";
import "../libraries/BytesUtils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract CompactMiddlewareRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  function owner() public override(Ownable, IRenderer) view returns (address) {
    return super.owner();
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
    return "ipfs://bafkreifio7i4ixmw4dpvhn3xpvinmgne4hgyuze53aa3hss3padz3qawui";
  }
  
  function renderAttributeKey() external override pure returns (string memory) {
    return "image";
  }
  
  function name() public override pure returns (string memory) {
    return 'Compact Data Middleware';
  }

  function convertProps(bytes calldata props) public pure returns (bytes memory output) {
    uint8 numBytesPrefix = uint8(props[20]);
    uint16 totalSize = BytesUtils.toUint16(props, 21);
    uint16 skipValues = BytesUtils.toUint16(props, 23);

    output = new bytes(totalSize);

    uint idx = 25;
    for (uint i = 0; i < numBytesPrefix; ++i) {
      output[i] = props[idx + i];
    }
    idx += numBytesPrefix;
    uint acc = skipValues + numBytesPrefix;
    while (idx < props.length) {
      uint8 qt = uint8(props[idx]);
      bytes1 val = props[idx + 1];
      if (val != 0) {
        for (uint8 ct = 0; ct < qt; ct++) {
          output[acc + ct] = val;
        }
      }
      acc += uint(qt);
      idx += 2;
    }
  }

  function renderRaw(bytes calldata props) public override view returns (bytes memory) {
    IRenderer destinationRenderer = IRenderer(BytesUtils.toAddress(props, 0));
    return destinationRenderer.renderRaw(convertProps(props));
  }

  function render(bytes calldata props) external override view returns (string memory) {
    IRenderer destinationRenderer = IRenderer(BytesUtils.toAddress(props, 0));
    return destinationRenderer.render(convertProps(props));
  }

  function attributes(bytes calldata props) external override view returns (string memory) {
    IRenderer destinationRenderer = IRenderer(BytesUtils.toAddress(props, 0));
    return destinationRenderer.attributes(convertProps(props));
  }
}