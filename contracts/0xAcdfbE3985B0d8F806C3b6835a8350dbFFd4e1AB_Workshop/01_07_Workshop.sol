// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './interfaces/IShared.sol';

contract Workshop is IShared, Ownable, ReentrancyGuard {
  // Endpoint where images are generated
  string public endpoint;

  // Collection description
  string public description;

  // List of available trait categories
  string[14] public categories = [
    'accessory',
    'animation',
    'background',
    'body',
    'bottom',
    'ears',
    'eyes',
    'face',
    'fx',
    'head',
    'mouth',
    'overlay',
    'shoes',
    'top'
  ];

  constructor(string memory baseEndpoint) Ownable() {
    endpoint = baseEndpoint;
  }

  function setEndpoint(string calldata newEndpoint)
    public
    onlyOwner
    nonReentrant
  {
    endpoint = newEndpoint;
  }

  function setDescription(string calldata newDescription)
    public
    onlyOwner
    nonReentrant
  {
    description = newDescription;
  }

  function stringifyAttributes(Attributes calldata attributes)
    internal
    pure
    returns (string[14] memory)
  {
    return [
      Strings.toString(attributes.accessory),
      Strings.toString(attributes.animation),
      Strings.toString(attributes.background),
      Strings.toString(attributes.body),
      Strings.toString(attributes.bottom),
      Strings.toString(attributes.ears),
      Strings.toString(attributes.eyes),
      Strings.toString(attributes.face),
      Strings.toString(attributes.fx),
      Strings.toString(attributes.head),
      Strings.toString(attributes.mouth),
      Strings.toString(attributes.overlay),
      Strings.toString(attributes.shoes),
      Strings.toString(attributes.top)
    ];
  }

  function getBaseUrl() internal view returns (string memory) {
    return string(abi.encodePacked(endpoint, '/render'));
  }

  function getImageUrl(Attributes calldata attributes)
    internal
    view
    returns (string memory)
  {
    string[14] memory attributesArray = stringifyAttributes(attributes);
    string memory url = getBaseUrl();

    for (uint256 i; i <= 13; i++) {
      url = string(
        abi.encodePacked(
          url,
          i == 0 ? '?' : '&',
          categories[i],
          '=',
          attributesArray[i]
        )
      );
    }

    return url;
  }

  function render(
    uint256 tokenId,
    address owner,
    string calldata name,
    uint256 birthdate,
    Attributes calldata attributes
  ) public view returns (string memory) {
    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                name,
                '", "id":',
                Strings.toString(tokenId),
                ', "soul":"',
                Strings.toHexString(owner),
                '", "birthdate":"',
                Strings.toString(birthdate),
                '", "description":"',
                description,
                '", "image": "',
                getImageUrl(attributes),
                '"}'
              )
            )
          )
        )
      );
  }
}