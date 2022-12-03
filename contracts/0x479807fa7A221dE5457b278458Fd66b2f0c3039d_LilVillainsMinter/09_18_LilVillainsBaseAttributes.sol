// SPDX-License-Identifier: CC-BY-NC-ND-4.0
// By interacting with this smart contract you agree to the terms located at https://lilheroes.io/tos, https://lilheroes.io/privacy).

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import { Attribute } from '@gm2/blockchain/src/structs/DynamicMetadataStructs.sol';
import './interfaces/ILilCollection.sol';
import { NFTBaseAttributes, NFTBaseAttributesRequest } from './structs/LilVillainsStructs.sol';

abstract contract LilVillainsBaseAttributes is EIP712, Ownable {
  address internal _lilVillainsAddress;

  constructor(string memory _SIGNING_DOMAIN, string memory _SIGNATURE_VERSION)
    EIP712(_SIGNING_DOMAIN, _SIGNATURE_VERSION)
  {}

  function setBaseAttributesOfNfts(NFTBaseAttributesRequest calldata nFTBaseAttributesRequest, bytes calldata signature)
    external
  {
    require(
      ECDSA.recover(_hashTypedDataV4(hashNFTBaseAttributesRequest(nFTBaseAttributesRequest)), signature) == owner(),
      'Invalid signature'
    );
    ILilCollection(_lilVillainsAddress).setBaseAttributes(nFTBaseAttributesRequest.nFTsBaseAttributes);
  }

  function setBaseAttributesOfNftsByOwner(NFTBaseAttributesRequest calldata nFTBaseAttributesRequest)
    external
    onlyOwner
  {
    ILilCollection(_lilVillainsAddress).setBaseAttributes(nFTBaseAttributesRequest.nFTsBaseAttributes);
  }

  function hashStringArray(string[] calldata stringArray) internal pure returns (bytes32) {
    bytes32[] memory hashedItems = new bytes32[](stringArray.length);
    for (uint256 i = 0; i < stringArray.length; i++) {
      hashedItems[i] = keccak256(bytes(stringArray[i]));
    }
    return keccak256(abi.encodePacked(hashedItems));
  }

  function hashNFTBaseAttributes(NFTBaseAttributes calldata nFTsBaseAttributes) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256('NFTBaseAttributes(uint256 id,string[] values)'),
          nFTsBaseAttributes.id,
          hashStringArray(nFTsBaseAttributes.values)
        )
      );
  }

  function hashNFTBaseAttributesRequest(NFTBaseAttributesRequest calldata nFTBaseAttributesRequest)
    internal
    pure
    returns (bytes32)
  {
    bytes32[] memory nFTsBaseAttributesHashes = new bytes32[](nFTBaseAttributesRequest.nFTsBaseAttributes.length);
    for (uint256 i = 0; i < nFTBaseAttributesRequest.nFTsBaseAttributes.length; i++) {
      nFTsBaseAttributesHashes[i] = hashNFTBaseAttributes(nFTBaseAttributesRequest.nFTsBaseAttributes[i]);
    }
    return
      keccak256(
        abi.encode(
          keccak256(
            abi.encodePacked(
              'NFTBaseAttributesRequest(NFTBaseAttributes[] nFTsBaseAttributes)',
              'NFTBaseAttributes(uint256 id,string[] values)'
            )
          ),
          keccak256(abi.encodePacked(nFTsBaseAttributesHashes))
        )
      );
  }
}