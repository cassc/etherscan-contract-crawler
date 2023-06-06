// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "base64-sol/base64.sol";
import "./Strings.sol";

interface CryptopunksData {
  function punkImageSvg(uint16 index) external view returns (string memory svg);
  function punkAttributes(uint16 index) external view returns (string memory attributes);
}

contract Cryptopunks is ERC721, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private tokenIdCounter;
  using strings for *;

  address punksDataAddress;

  mapping (uint256 => address) internal _tokenOwner;

  event Mint(address owner, uint256 tokenId);

  constructor() ERC721("on-chain-cryptopunks", "OCCP") {}

  function setPunksDataAddress(address _punksDataAddress) external onlyOwner {
    punksDataAddress = _punksDataAddress;
  }

  function mint() external payable returns (uint256) {
    require(tokenIdCounter.current() <= 10000, "Maximum value reached.");
    uint256 _tokenId = tokenIdCounter.current();
    _safeMint(msg.sender, _tokenId);
    tokenIdCounter.increment();
    emit Mint(msg.sender, _tokenId);
    return _tokenId;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(ownerOf(tokenId) != address(0), "Non-existent tokens.");
    CryptopunksData punksDataContract = CryptopunksData(punksDataAddress);
    string memory svg = punksDataContract.punkImageSvg(uint16(tokenId));
    string memory attributes = punksDataContract.punkAttributes(uint16(tokenId));
    strings.slice memory sliceSvg = svg.toSlice().beyond('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">'.toSlice());
    svg = sliceSvg.toString();
    strings.slice memory sliceAttributes = attributes.toSlice();
    strings.slice memory delim = ",".toSlice();
    string[] memory parts = new string[](sliceAttributes.count(delim) + 1);
    for (uint i = 0; i < parts.length; i++) {
      parts[i] = sliceAttributes.split(delim).beyond(" ".toSlice()).toString();
    }
    string memory attr;
    for (uint i = 0; i < parts.length; i++) {
      attr = string(abi.encodePacked(attr, '{'));
      if (i == 0) {
        attr = string(abi.encodePacked(attr, '"trait_type": "Type",'));
      } else {
        attr = string(abi.encodePacked(attr, '"trait_type": "Accessory",'));
      }
      attr = string(abi.encodePacked(attr, '"value": "', parts[i], '"'));
      if (i == parts.length - 1) {
        attr = string(abi.encodePacked(attr, '}'));
      } else {
        attr = string(abi.encodePacked(attr, '},'));
      }
    }
    string memory svgString = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24" style="background-color: #648595;">', svg));
    string memory output;
    output = string(abi.encodePacked(output, '{"name": "On-chain Cryptopunks #', toString(tokenId), '", "description": "On-chain CryptoPunks.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svgString)), '", "attributes": [', attr, ']}'));
    output = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(output))));
    return output;
  }

  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

}