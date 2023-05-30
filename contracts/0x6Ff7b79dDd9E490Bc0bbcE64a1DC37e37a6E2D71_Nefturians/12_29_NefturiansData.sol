// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ECDSALibrary.sol";
import "../libraries/StringsLibrary.sol";
import "../interfaces/INefturiansData.sol";
import "../interfaces/INefturians.sol";

/**********************************************************************************************************************/
/*                                                                                                                    */
/*                                                  Nefturians Data                                                   */
/*                                                                                                                    */
/*                     NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                  NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                  */
/*                NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                */
/*              NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN              */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNN...............NNNNNNNNNNNN............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN.................NNNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN...................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN.....................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN.......................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..........................NNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............................NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNN............NNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN............NNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNNNN............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN...............NNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN...............NNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN............................NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN..........................NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN........................NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN.....................NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN..................NNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN................NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*               NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN               */
/*                 NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                 */
/*                    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                                                                                                                    */
/*                                                                                                                    */
/*                                                                                                                    */
/**********************************************************************************************************************/


contract NefturiansData is Ownable, INefturiansData {

  /**
   * Roles for the access control
   * these roles are only checked against the parent contract's settings
   */
  bytes32 internal constant DAO_ROLE = keccak256("DAO_ROLE");
  bytes32 internal constant METADATA_ROLE = keccak256("METADATA_ROLE");
  bytes32 internal constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

  /**
   * Metadata and Attributes
   */
  uint256 internal metadataKeysCounter;
  mapping(uint256 => string) internal metadataKeys;
  mapping(uint256 => mapping(uint256 => uint256)) internal attributes;
  mapping(uint256 => mapping(uint256 => string)) internal metadata;

  /**
   * Parent contract: The Nefturians collection
   */
  INefturians private collection;

  constructor() {
    metadataKeys[0] = "name";
    metadataKeys[1] = "strength";
    metadataKeysCounter = 2;
    collection = INefturians(msg.sender);
  }

  /**
   * Get the metadata of a token in an easily parseable format (dotenv-style)
   * @param tokenId: id of the token for which we want the metadata
   */
  function getMetadata(uint256 tokenId) public view returns (string memory) {
    string memory metadataString;
    for (uint256 index = 0; index < metadataKeysCounter; index++) {
      if (bytes(metadata[tokenId][index]).length != 0){
        metadataString = string(abi.encodePacked(metadataString, metadataKeys[index], "=", metadata[tokenId][index], "\n"));
      }
      else if (attributes[tokenId][index] != 0) {
        metadataString = string(abi.encodePacked(metadataString, metadataKeys[index], "=", StringsLibrary.toString(attributes[tokenId][index]), "\n"));
      }
    }
    return metadataString;
  }

  /**
   * Add new metadatakey
   * @param keyName: name of the new metadata key
   *
   * Error messages:
   *  - ND1: "Unauthorized to add key"
   */
  function addKey(string calldata keyName) public onlyOwner {
    metadataKeys[metadataKeysCounter + 1] = keyName;
    metadataKeysCounter += 1;
  }

  /**
   * Set a string metadata for a given token with specific key
   * @param tokenId: token id for which to set metadata
   * @param key: metadata key id
   * @param value: on chain metadata value
   * @param signature to authorize the transaction:
   *      - SIGNER_ROLE signed metadata if the update is performed by the owner
   *      - Token owner's signed metadata if the update is performed by the DAO and signed by the owner
   *
   * Error messages:
   *  - ND2: "Not authorized to update metadata"
   */
  function setMetadata(uint256 tokenId, uint256 key, string calldata value, bytes calldata signature) public {
    address owner = collection.ownerOf(tokenId);
    uint256 nonce = collection.getNonce(owner);
    address signer = ECDSALibrary.recover(abi.encodePacked(
        owner,
        nonce,
        tokenId,
        key,
        value
      ), signature);
    require(
      (msg.sender == owner && collection.hasRole(SIGNER_ROLE, signer)) ||
      (signer == owner && collection.hasRole(DAO_ROLE, msg.sender)), "ND2"
    );
    collection.incrementNonce(owner);
    metadata[tokenId][key] = value;
    emit MetadataUpdated(tokenId, key, value);
  }

  /**
   * Set the numeric metadata (attributes) of a token
   * @param tokenId: id of the token for which to set new attributes
   * @param keys: array of keys from attributes to be updated
   * @param values: values for each key of the new attributes
   * @param signature:
   *      - SIGNER_ROLE or DAO_ROLE signature to authorize on chain metadata update
   *      - SIGNER_ROLE signed metadata if the update is performed by the owner
   *      - DAO_ROLE caller if the update is performed by the DAO and signed by the owner
   *
   * Error messages:
   *  - ND0: "Array lengths do not match"
   *  - ND2: "Not authorized to update metadata"
   */
  function setAttributes(uint256 tokenId, uint256[] calldata keys, uint256[] calldata values, bytes calldata signature) public {
    require(keys.length == values.length, "ND0");
    address owner = collection.ownerOf(tokenId);
    uint256 nonce = collection.getNonce(owner);
    address signer = ECDSALibrary.recover(abi.encodePacked(
        owner,
        nonce,
        tokenId,
        keys,
        values
      ), signature);
    require(
      (msg.sender == owner && collection.hasRole(SIGNER_ROLE, signer)) ||
      (signer == owner && collection.hasRole(DAO_ROLE, msg.sender)), "ND2"
    );
    for (uint256 i = 0; i < keys.length; i++) {
      attributes[tokenId][keys[i]] = values[i];
      emit AttributeUpdated(tokenId, keys[i], values[i]);
    }
    collection.incrementNonce(owner);
  }
}