// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SecurityLib.sol";
import "./SignatureLib.sol";

library MintERC721Lib {
  struct MintERC721Data {
    SecurityLib.SecurityData securityData;
    address minter;
    address to;
    uint256 tokenId;
    bytes data;
  }

  bytes32 private constant _MINT_ERC721_TYPEHASH =
    keccak256(
      bytes(
        "MintERC721Data(SecurityData securityData,address minter,address to,uint256 tokenId,bytes data)SecurityData(uint256 validFrom,uint256 validTo,uint256 salt)"
      )
    );

  function hashStruct(MintERC721Data memory mintERC721Data) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          _MINT_ERC721_TYPEHASH,
          SecurityLib.hashStruct(mintERC721Data.securityData),
          mintERC721Data.minter,
          mintERC721Data.to,
          mintERC721Data.tokenId,
          keccak256(mintERC721Data.data)
        )
      );
  }
}