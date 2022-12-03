// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import { Attribute, Royalty } from '@gm2/blockchain/src/structs/DynamicMetadataStructs.sol';
import { Metadata as MetadataV1 } from '../structs/DynamicMetadataStructs.sol';

library DynamicMetadata {
  using Strings for uint16;

  // Returns a copy of the concated attributes
  function concatDynamicAttributes(Attribute[] calldata baseAttributes, Attribute[] calldata dynamicAttributes)
    public
    pure
    returns (Attribute[] memory)
  {
    uint256 countOfAttributes = baseAttributes.length + dynamicAttributes.length;
    Attribute[] memory allAttributes = new Attribute[](countOfAttributes);
    for (uint256 i = 0; i < baseAttributes.length; i++) {
      allAttributes[i] = baseAttributes[i];
    }

    for (uint256 i = 0; i < dynamicAttributes.length; i++) {
      allAttributes[baseAttributes.length + i] = dynamicAttributes[i];
    }

    return allAttributes;
  }

  //
  function appendBaseAttributes(Attribute[] storage baseAttributes, Attribute[] calldata newBaseAttributes) public {
    for (uint256 i = 0; i < newBaseAttributes.length; i++) {
      baseAttributes.push(newBaseAttributes[i]);
    }
  }

  function toBytes(Attribute memory attribute) public pure returns (bytes memory) {
    bytes memory attributesInByte = '{';
    if (bytes(attribute.displayType).length > 0) {
      attributesInByte = bytes.concat(
        attributesInByte,
        abi.encodePacked('"display_type":"', attribute.displayType, '",')
      );
    }

    attributesInByte = bytes.concat(
      attributesInByte,
      //TODO: ver como hacemos con el manejo de las comillas para los numeros
      abi.encodePacked('"trait_type":"', attribute.traitType, '",', '"value":"', attribute.value, '"')
    );

    return bytes.concat(attributesInByte, '}');
  }

  //INFO: This method assumes that attributesToMap has a length greather than 0
  function mapToBytes(Attribute[] calldata attributesToMap) public pure returns (bytes memory) {
    bytes memory attributesInBytes = '"attributes":[';

    for (uint32 i = 0; i < attributesToMap.length - 1; i++) {
      attributesInBytes = bytes.concat(attributesInBytes, toBytes(attributesToMap[i]), ',');
    }
    attributesInBytes = bytes.concat(attributesInBytes, toBytes(attributesToMap[attributesToMap.length - 1]), ']');

    return attributesInBytes;
  }

  //INFO: This method assumes that metadata.attributes has a length greather than 0
  function toBase64URI(MetadataV1 calldata metadata) public pure returns (string memory) {
    bytes memory descriptionInBytes = keyValueToJsonInBytes('description', metadata.description);
    bytes memory imageInBytes = keyValueToJsonInBytes('image', metadata.image);
    bytes memory nameInBytes = keyValueToJsonInBytes('name', metadata.name);
    bytes memory attributesInBytes = mapToBytes(metadata.attributes);
    bytes memory jsonInBytes = bytes.concat(
      '{',
      descriptionInBytes,
      ',',
      imageInBytes,
      ',',
      nameInBytes,
      ',',
      attributesInBytes
    );
    // INFO: If has royalties set
    if (metadata.royalty.feePercentage != 0) {
      bytes memory royaltyFeeInBytes = keyValueToJsonInBytes(
        'seller_fee_basis_points', // INFO: Open see key for royalties
        metadata.royalty.feePercentage.toString()
      );
      bytes memory royaltyRecipientInBytes = keyValueToJsonInBytes(
        'fee_recipient', // INFO: Open see key for royalties
        Strings.toHexString(uint256(uint160(metadata.royalty.recipientAddress)), 20)
      );
      jsonInBytes = bytes.concat(jsonInBytes, ',', royaltyFeeInBytes, ',', royaltyRecipientInBytes);
    }

    jsonInBytes = bytes.concat(jsonInBytes, '}');

    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(jsonInBytes)));
  }

  function keyValueToJsonInBytes(string memory key, string memory value) public pure returns (bytes memory) {
    return bytes.concat('"', bytes(key), '":"', bytes(value), '"');
  }
}