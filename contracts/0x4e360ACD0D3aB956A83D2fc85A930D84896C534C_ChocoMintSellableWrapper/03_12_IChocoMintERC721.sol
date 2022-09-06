// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/MintERC721Lib.sol";
import "../utils/SignatureLib.sol";

interface IChocoMintERC721 {
  event Minted(bytes32 indexed mintERC721Hash);

  function mint(MintERC721Lib.MintERC721Data memory mintERC721Data, SignatureLib.SignatureData memory signatureData)
    external;

  function isMinted(uint256 tokenId) external view returns (bool);
}