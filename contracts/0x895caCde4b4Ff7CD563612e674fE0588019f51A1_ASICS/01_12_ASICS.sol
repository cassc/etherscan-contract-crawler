// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./external/ERC721A.sol";

// @author rollauver.eth

contract ASICS is ERC721A, Ownable {
  string public _baseTokenURI;
  uint256 public _maxSupply;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    uint256 maxSupply
  ) ERC721A(name, symbol, maxSupply) {
    _baseTokenURI = baseTokenURI;
    _maxSupply = maxSupply;
  }

  function setBaseUri(
    string memory baseUri
  ) external onlyOwner {
    _baseTokenURI = baseUri;
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return string(
      abi.encodePacked(
        _baseTokenURI,
        Strings.toHexString(uint256(uint160(address(this))), 20),
        '/'
      )
    );
  }

  function mintBatch(address[] memory toAddresses, uint256[] memory counts) external payable onlyOwner {
    require(toAddresses.length == counts.length, "toAddresses and counts length mismatch");

    for (uint256 i = 0; i < toAddresses.length; i++) {
      require(totalSupply() + counts[i] <= _maxSupply, "Exceeds max supply");

      _safeMint(toAddresses[i], counts[i]);
    }
  }
}