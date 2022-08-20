// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./vendor/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./vendor/@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./vendor/@openzeppelin/contracts/access/Ownable.sol";
import "./vendor/@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract PaniniMegaCracksNFT is ERC721Enumerable, Ownable {

  using ECDSA for bytes32;

  mapping(uint256 => string) idToCode;

  string currentBaseURI;

  constructor(string memory _baseURI) ERC721("PaniniMegaCracksNFT", "MGK") {
    currentBaseURI = _baseURI;
  }

  function changeBaseURI(string memory _newBaseURI) external onlyOwner {
    currentBaseURI = _newBaseURI;
  }

  function exists(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  /**
   * Mints tokens with specified code ids to specified addresses.
   * The generated tokenIds are mapped to the token codes.
   */
  function mint(address[] memory _receivers, string[] memory _codes) external onlyOwner {
    for (uint256 i = 0; i < _receivers.length; i++) {
      string memory tokenCode = _codes[i];
      uint256 tokenId = codeToId(tokenCode);
      _safeMint(_receivers[i], tokenId);
      idToCode[tokenId] = tokenCode;
    }
  }

  /**
   * Creates the URI for the specified token.
   */
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "Requesting URI for nonexistent token");
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, idToCode[_tokenId], ".json")) : "";
  }

  /* INTERNAL FUNCTIONS */

  /**
   * Creates an uint256 tokenId for the specified token code.
   */
  function codeToId(string memory _code) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_code)));
  }

  /**
   * Recovers the signer of the specified signature.
   */
  function getSigner(bytes memory message, bytes memory _signature) internal pure returns (address) {
    bytes32 messageHash = keccak256(message);
    bytes32 signedHash = messageHash.toEthSignedMessageHash();
    return signedHash.recover(_signature);
  }
}