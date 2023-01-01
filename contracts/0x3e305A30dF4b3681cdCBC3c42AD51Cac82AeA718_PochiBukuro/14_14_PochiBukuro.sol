// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PochiBukuro is ERC721, Ownable {
  using Counters for Counters.Counter;

  address immutable public designer;
  address immutable public programmer;
  uint256 private constant _FEE = 0.0005 ether;
  Counters.Counter private _tokenIdCounter;

  constructor(
    address _designer,
    address _programmer
  ) ERC721("Pochi Bukuro", "PB") {
    designer = _designer;
    programmer = _programmer;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "Non-existent Token ID");

    uint8 pattern = (_tokenId % 20) == 0 ? 9 : uint8(_tokenId % 4);

    return string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{"name":"', tokenName(_tokenId),
                '","description":"Otoshidama in Pochi Bukuro',
                '","attributes":[{"trait_type":"Pattern","value":"', Strings.toString(pattern), '"}',
                '],"image":"https://june29.github.io/pochibukuro/', Strings.toString(pattern), '.png',
              '"}'
            )
          )
        )
      )
    );
  }

  function tokenName(uint256 _tokenId) internal pure returns(string memory) {
    return string(abi.encodePacked("Pochi Bukuro #", Strings.toString(_tokenId)));
  }

  function otoshidama(address _destination) payable external {
    require(msg.value >= _FEE * 4, "More ether required");

    address payable designerAddress = payable(designer);
    address payable programmerAddress = payable(programmer);
    designerAddress.transfer(_FEE);
    programmerAddress.transfer(_FEE);

    address payable destination = payable(_destination);
    destination.transfer(msg.value - _FEE * 2);

    uint256 tokenId = _tokenIdCounter.current();
    _safeMint(_destination, tokenId);
    _tokenIdCounter.increment();
  }
}