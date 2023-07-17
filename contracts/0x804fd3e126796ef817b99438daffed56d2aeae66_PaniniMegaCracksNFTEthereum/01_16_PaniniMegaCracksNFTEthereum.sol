// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PaniniMegaCracksNFT.sol";

contract PaniniMegaCracksNFTEthereum is PaniniMegaCracksNFT {
  event MoveDone(uint256 tokenId, string code, address owner);

  constructor(string memory _baseURI) PaniniMegaCracksNFT(_baseURI) {}

  /**
   * Verifies user's authorisation to mint the token on this contract and mints it as the final stage of
   * the bridging process.
   */
  function moveToChain(uint256 _tokenId, string memory _code, address _tokenOwner, bytes memory _sig) external {
    require(!_exists(_tokenId), "Token already exists on this chain!");
    
    bytes memory message = abi.encode(_tokenId, _code, _tokenOwner);
    
    address signer = getSigner(message, _sig);

    require(owner() == signer, "Signer is not contract owner!");

    _safeMint(_tokenOwner, _tokenId);
    idToCode[_tokenId] = _code;
    emit MoveDone(_tokenId, _code, _tokenOwner);
  }
}