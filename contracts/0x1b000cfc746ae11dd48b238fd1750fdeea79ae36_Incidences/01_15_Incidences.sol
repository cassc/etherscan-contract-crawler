/// SPDX-License-Identifier CC0-1.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {Incidental} from "./Incidental.sol";

contract Incidences is Incidental, ERC721, ReentrancyGuard {

  uint256 private constant _MAX_SUPPLY = 10_000;

  mapping(bytes32 => bool) private _hashes;
  mapping(address => bool) private _minters;

  bytes private _preamble;

  uint256 private _tokenId;

  constructor() ERC721("Incidentals", "INCI") {
    _preamble = abi.encodePacked("Sybil to ", Strings.toHexString(address(this)), " to mint an incidental. Just don't forget the ", unicode"🧂", ".");
  }

  function ethsGEGzXlymji3hvTyjQnpYo() external override(Incidental) nonReentrant {
    bytes32 hash = keccak256(msg.data);

    require(_tokenId < _MAX_SUPPLY);

    require(msg.data.length >= _preamble.length + 6); // data,{preamble}
    require(msg.data[4] == 0x3a);
    require(msg.data[5] == 0x2c);

    require(_minters[msg.sender] == false);
    require(_hashes[hash] == false);

    for (uint i = 0; i < _preamble.length; i += 1)
      require(msg.data[6 + i] == _preamble[i]);

    _minters[msg.sender] = true;
    _hashes[hash] = true;

    _safeMint(msg.sender, ++_tokenId);
  }

  function preamble() public view returns (string memory) {
    return string(_preamble);
  }

  function _tokenURIImage() private pure returns (bytes memory) {
    bytes memory result = "";

    result = abi.encodePacked(result, '<svg xmlns="http://www.w3.org/2000/svg">');
    result = abi.encodePacked(result, '<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-size="75px">');
    result = abi.encodePacked(result, unicode"🧂");
    result = abi.encodePacked(result, '</text></svg>');

    return result;
  }

  function _tokenURISkeleton(
    bytes memory name
  ) private pure returns (string memory) {
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{',
              '"name":"', name, '",',
              '"description":', '"', "Incidences demonstrate the concept of incidentals - smart contract invocations that originate from Ethscriptions.", '",',
              '"image":"data:image/svg+xml;base64,', Base64.encode(_tokenURIImage()), '",',
              '"attributes": [',
                '{"trait_type": "Source", "value": "ipfs://QmSwPbPgUmH9EPkDXgwe9Mz343Naq6XuYgPeoyeF1A22KU"},',
                '{"trait_type": "License", "value": "CC0-1.0"}',
              ']',
              '}'
            )
          )
        )
      )
    );
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(tokenId > 0 && tokenId <= _MAX_SUPPLY);
    return _tokenURISkeleton(abi.encodePacked("Incidence #", Strings.toString(tokenId)));
  }

}