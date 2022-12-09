// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./interfaces/INFB.sol";
import "./interfaces/INFBTokenURIGetter.sol";

contract NFBImageTokenURIGetter is INFBTokenURIGetter {
  using Strings for uint8;
  using Strings for uint16;
  using Strings for uint256;

  INFB public nfb;
  string public name;
  string public imageURI;

  constructor(
    INFB _nfb,
    string memory _name,
    string memory _imageURI
  ) {
    nfb = _nfb;
    name = _name;
    imageURI = _imageURI;
  }

  function tokenURI(
    uint256 tokenId,
    uint16 seriesId,
    uint8 editionId
  ) external view returns (string memory) {
    (string memory seriesName, string memory seriesDescription) = nfb.series(
      seriesId
    );
    string memory birthTime = nfb.getBirthTime(tokenId).toString();
    string memory tokenIdStr = tokenId.toString();
    string memory metadata = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            "{",
            '"id":"',
            tokenIdStr,
            '","name":"',
            name,
            " #",
            tokenIdStr,
            '","description":"',
            seriesDescription,
            '","image":"',
            imageURI,
            '","attributes":[{"trait_type":"Series","value":"',
            seriesName,
            // lets also add the series id as an attribute
            '"},{"trait_type":"Series ID","display_type":"number","value":',
            seriesId.toString(),
            '},{"trait_type":"Edition","display_type":"number","value":',
            editionId.toString(),
            '},{"trait_type":"NFB Number","display_type":"number","value":',
            tokenIdStr,
            '},{"trait_type":"Birthday","display_type":"date","value":',
            birthTime,
            "}]}"
          )
        )
      )
    );

    return string(abi.encodePacked("data:application/json;base64,", metadata));
  }
}