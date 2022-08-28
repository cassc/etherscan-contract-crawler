//SPDX-License-Identifier: CC-BY-SA-4.0

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './Base64.sol';

interface IOldColors {
  function getCOLORData(uint256 tokenId)
    external
    view
    returns (
      uint32,
      uint32,
      uint32,
      uint32,
      uint32,
      address
    );

  function MAX_COLORS() external view returns (uint256);

  function ownerOf(uint256 tokenId) external view returns (address);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ISecrets {
  function setSecret(
    uint256 tokenId,
    string memory secret,
    string memory trait
  ) external view;

  function renderSecret(uint256 tokenId) external view returns (string memory);

  function renderSecretsData(uint256 tokenId)
    external
    view
    returns (string memory);
}

contract ColorParser is Ownable {
  using Strings for uint256;

  IOldColors colorsContract;
  ISecrets secretsContract;
  string description;

  constructor(address _oldColors, address _secrets) Ownable() {
    colorsContract = IOldColors(_oldColors);
    secretsContract = ISecrets(_secrets);
  }

  function buildColorString(
    uint32 colorR,
    uint32 colorG,
    uint32 colorB
  ) internal pure returns (string memory) {
    // GREY Adjust contrast
    if (
      colorR < 140 &&
      colorR >= 100 &&
      colorG < 140 &&
      colorG >= 100 &&
      colorB < 140 &&
      colorB >= 100
    ) {
      colorR = colorR / 3;
      colorG = colorG / 3;
      colorB = colorB / 3;
    }

    return
      string(
        abi.encodePacked(
          'rgb(',
          Strings.toString(colorR),
          ',',
          Strings.toString(colorG),
          ',',
          Strings.toString(colorB),
          ')'
        )
      );
  }

  function buildXTextPosition(uint32 positionX, uint32 positionY)
    internal
    pure
    returns (string memory)
  {
    return
      positionX > 65 && positionY > 70
        ? Strings.toString(96)
        : Strings.toString(96);
  }

  function buildYTextPosition(uint32 positionX, uint32 positionY)
    internal
    pure
    returns (string memory)
  {
    return
      positionX > 65 && positionY > 70
        ? Strings.toString(8)
        : Strings.toString(94);
  }

  function buildSVG(
    uint32 colorR,
    uint32 colorG,
    uint32 colorB,
    uint32 positionX,
    uint32 positionY,
    uint256 tokenId
  ) internal view returns (string memory) {
    string memory result = string(
      abi.encodePacked(
        '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" viewBox="0 0 100 100"><rect x="0" y="0" width="100" height="100" fill="',
        buildColorString(colorR, colorG, colorB),
        '"/><circle cx="',
        Strings.toString(positionX),
        '.5" cy="',
        Strings.toString(positionY),
        '.5" r="4" fill="',
        buildColorString(255 - colorR, 255 - colorG, 255 - colorB),
        '"/><rect x="',
        Strings.toString(positionX),
        '" y="',
        Strings.toString(positionY),
        '" width="1" height="1" fill="',
        buildColorString(colorR, colorG, colorB),
        '"/>',
        secretsContract.renderSecret(tokenId)
      )
    );

    result = string(
      abi.encodePacked(
        result,
        '<text id="coordsText" text-anchor="end" font-family="Arial Black" dominant-baseline="middle" transform="matrix(0.5 0 0 0.5 ',
        buildXTextPosition(positionX, positionY),
        ' ',
        buildYTextPosition(positionX, positionY),
        ')" fill="',
        buildColorString(255 - colorR, 255 - colorG, 255 - colorB),
        '">',
        Strings.toString(positionX),
        ':',
        Strings.toString(positionY),
        '</text>',
        '</svg>'
      )
    );

    return result;
  }

  function buildTraits(uint256 tokenId) internal view returns (string memory) {
    (
      uint32 colorR,
      uint32 colorG,
      uint32 colorB,
      uint32 positionX,
      uint32 positionY,
      address owner
    ) = colorsContract.getCOLORData(tokenId);

    return
      string(
        abi.encodePacked(
          '[{"trait_type": "Position", "value": "',
          Strings.toString(positionX),
          ':',
          Strings.toString(positionY),
          '"},',
          '{"trait_type": "Color: RGB", "value": "',
          Strings.toString(colorR),
          ',',
          Strings.toString(colorG),
          ',',
          Strings.toString(colorB),
          '"}',
          secretsContract.renderSecretsData(tokenId),
          '],'
        )
      );
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(tokenId >= 0 && tokenId < colorsContract.MAX_COLORS());

    (
      uint32 colorR,
      uint32 colorG,
      uint32 colorB,
      uint32 positionX,
      uint32 positionY,
      address owner
    ) = colorsContract.getCOLORData(tokenId);

    string memory output = buildSVG(
      colorR,
      colorG,
      colorB,
      positionX,
      positionY,
      tokenId
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name":',
            buildTitle(tokenId),
            ',"description":"',
            description,
            '","attributes": ',
            buildTraits(tokenId),
            '"image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '"}'
          )
        )
      )
    );

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function buildTitle(uint256 tokenId) internal view returns (string memory) {
    (
      uint32 colorR,
      uint32 colorG,
      uint32 colorB,
      uint32 positionX,
      uint32 positionY,
      address owner
    ) = colorsContract.getCOLORData(tokenId);
    return
      string(
        abi.encodePacked(
          '"COLOR X',
          Strings.toString(positionX),
          ':',
          Strings.toString(positionY),
          'Y"'
        )
      );
  }

  /* 
    OWNER FUNCTIONS
     */

  function setDescription(string memory _description) public onlyOwner {
    description = _description;
  }
}

/* G */