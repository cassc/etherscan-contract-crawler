// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

struct TokenMetadata {
  string name;
  string description;
  string image;
  string external_url;
  string background_color;
  Attribute[] attributes;
}

struct Attribute {
  string trait_type;
  string value;
}

library MetadataUtils {
  function tokenMetadataToString(
    TokenMetadata memory metadata
  ) internal pure returns (string memory) {
    bytes memory output = abi.encodePacked(
      "{",
      '"name": "',
      metadata.name,
      '",',
      '"description": "',
      metadata.description,
      '",',
      '"image": "',
      metadata.image,
      '",'
    );

    output = abi.encodePacked(
      output,
      '"external_url": "',
      metadata.external_url,
      '",',
      '"background_color": "',
      metadata.background_color,
      '",',
      '"attributes": ['
    );

    return string(abi.encodePacked(output, attributesToString(metadata.attributes), "]", "}"));
  }

  function attributesToString(Attribute[] memory attributes) internal pure returns (string memory) {
    string memory output = "";
    for (uint256 i = 0; i < attributes.length; i++) {
      output = string(
        abi.encodePacked(
          output,
          "{",
          '"trait_type": "',
          attributes[i].trait_type,
          '",',
          '"value": "',
          attributes[i].value,
          '"',
          "}"
        )
      );
      if (i != attributes.length - 1) {
        output = string(abi.encodePacked(output, ","));
      }
    }
    return output;
  }
}