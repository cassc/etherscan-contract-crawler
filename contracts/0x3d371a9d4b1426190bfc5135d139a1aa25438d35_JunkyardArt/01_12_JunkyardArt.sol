// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract JunkyardArt is ERC721, Ownable {
  string internal uri = "https://api.junkyarddogs.io/art?tokenId=";
  string internal contractURI = "https://api.junkyarddogs.io/contract/";
  uint256 public totalSupply = 0;

  constructor() ERC721("Junkyard Art", "JYA") {}

  function mint(bytes memory signature, uint256 tokenId) public {
    require(!_exists(tokenId), "Already minted");
    bytes32 messageHash = keccak256(abi.encodePacked('junkyard marketplace', address(this), msg.sender, tokenId));
    bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);

    address signer = ECDSA.recover(digest, signature);
    require(signer == owner(), "Invalid signature");
    totalSupply += 1;

    _mint(msg.sender, tokenId);
  }

  function setUri(string memory u) public onlyOwner {
    uri = u;
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return uri;
  }
}