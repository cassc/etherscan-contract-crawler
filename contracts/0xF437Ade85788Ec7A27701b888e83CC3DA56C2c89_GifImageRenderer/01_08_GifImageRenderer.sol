// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "../interfaces/IRenderer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract GifImageRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  bytes public constant GRAPHIC_CONTROL_EXTENSION = hex"21F9040100000000";
  bytes public constant IMAGE_DESCRIPTOR = hex"2C00000000800080000007";

  uint public IMAGE_DATA_CHUNK_SIZE = 126;

  uint public WIDTH_INDEX = 0;
  uint public HEIGHT_INDEX = 1;
  uint public NUM_COLORS_INDEX = 2;

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
    return "ipfs://bafkreid63nuzy5wy4l42mevl73dvknxpxq35dwarj47gnmms754inbngra";
  }

  function renderAttributeKey() external override pure returns (string memory) {
    return "image";
  }

  function name() public override pure returns (string memory) {
    return 'Single frame gif';
  }

  function getBestColorTableSize(uint8 numColors) internal pure returns (uint) {
    if (numColors > 64) {
      return 128;
    }
    if (numColors > 32) {
      return 64;
    }
    if (numColors > 16) {
      return 32;
    }
    if (numColors > 8) {
      return 16;
    }
    if (numColors > 4) {
      return 8;
    }
    if (numColors > 2) {
      return 4;
    }
    return 2;
  }

  function logicalScreenDescriptor(uint8 numColors) internal pure returns (bytes1) {
    require(numColors < 128, "Only a maximum of 127 colors allowed");
    if (numColors > 64) {
      return hex"F6";
    }
    if (numColors > 32) {
      return hex"F5";
    }
    if (numColors > 16) {
      return hex"F4";
    }
    if (numColors > 8) {
      return hex"F3";
    }
    if (numColors > 4) {
      return hex"F2";
    }
    if (numColors > 2) {
      return hex"F1";
    }
    return hex"F0";
  }

  function gifHeader(bytes calldata props) internal view returns (bytes memory) {
    return abi.encodePacked(hex"474946383961", props[WIDTH_INDEX], hex"00", props[HEIGHT_INDEX], hex"00", logicalScreenDescriptor(uint8(props[NUM_COLORS_INDEX]) + 1), hex"0000");
  } 

  function colorTable(bytes calldata props) internal view returns (bytes memory) {
    uint8 numColors = uint8(props[NUM_COLORS_INDEX]);
    bytes memory paddedZeros = new bytes((getBestColorTableSize(numColors + 1) - numColors) * 3);
    return abi.encodePacked(props[3:3 + (numColors * 3)], paddedZeros);
  }

  function imageDescriptor(bytes calldata props) internal view returns (bytes memory) {
    return abi.encodePacked(
      hex"2C00000000", props[WIDTH_INDEX], hex"00", props[HEIGHT_INDEX], hex"000007"
    );
  }

  function renderRaw(bytes calldata props) public override view returns (bytes memory) {
    bytes memory imageData = "";
    for (uint i = (3 + uint8(props[NUM_COLORS_INDEX]) * 3); i < props.length; i+=IMAGE_DATA_CHUNK_SIZE) {
      uint end = i + IMAGE_DATA_CHUNK_SIZE;
      bytes memory chunk = props[i:(end > props.length ? props.length : end)];
      imageData = abi.encodePacked(imageData, uint8(chunk.length + (end > props.length ? 2 : 1)), hex"80", chunk);
    }
    return abi.encodePacked(gifHeader(props), colorTable(props), GRAPHIC_CONTROL_EXTENSION, imageDescriptor(props), imageData, hex"81003B"); 
  }

  function render(bytes calldata props) external override view returns (string memory) {
    return string(
      abi.encodePacked(
        'data:image/gif;base64,',
        Base64.encode(renderRaw(props))
      )
    );
  }

  function attributes(bytes calldata props) external override pure returns (string memory) {
    uint i = 0;
    while(props[i] != 0x00) {
      i++;
    }
      return string(
            abi.encodePacked(
              '{"trait_type": "Data Length", "value":', i.toString(), '}'
            )
          );
  }
}