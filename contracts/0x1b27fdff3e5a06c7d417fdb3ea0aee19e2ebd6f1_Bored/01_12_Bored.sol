// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

contract Bored is ERC721, Ownable {
  string private _title = 'Bored in the Distrikt';
  string private _description = 'Prize NFT for Bored in the District game beat masters - Made with <3 by coin artist, illestrater, & curtis roach.';
  string private _presetBaseURI = 'https://arweave.net/';
  string private _assetHash;
  bool public mintingFinalized;

  uint256 private tokenIndex = 1;

  constructor(
    string memory name,
    string memory symbol,
    string memory assetHash
  ) ERC721(name, symbol) {
    _assetHash = assetHash;
    mintingFinalized = false;
  }

  function mintPrize(address winner) public onlyOwner {
    require(tokenIndex < 100, 'Minting has concluded');
    _safeMint(winner, tokenIndex);
    tokenIndex++;
  }

  function updateAsset(string memory asset) public onlyOwner {
    _assetHash = asset;
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
    require(ownerOf(tokenId) != address(0));

    string memory encoded = string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{"name":"',
              _title,
              ' #',
              Strings.toString(tokenId),
              '", "description":"',
              _description,
              '", "image": "',
              _presetBaseURI,
              _assetHash,
              '" }'
            )
          )
        )
      )
    );

    return encoded;
  }

  bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;
  bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || super.supportsInterface(interfaceId);
  }

  function getFeeRecipients(uint256 tokenId) public view returns (address payable[] memory) {
    address payable[] memory recipients = new address payable[](2);
    recipients[0] = payable(0xeEE5Eb24E7A0EA53B75a1b9aD72e7D20562f4283);
    recipients[1] = payable(0x148e2ED011A9EAAa200795F62889D68153EEacdE);
    return recipients;
  }

  function getFeeBps(uint256 tokenId) public view returns (uint[] memory) {
    uint[] memory fees = new uint[](2);
    fees[0] = 500;
    fees[1] = 500;
    return fees;
  }

  function royaltyInfo(uint256 tokenId, uint256 value) public view returns (address recipient, uint256 amount){
    return (0x148e2ED011A9EAAa200795F62889D68153EEacdE, 500 * value / 10000);
  }
}