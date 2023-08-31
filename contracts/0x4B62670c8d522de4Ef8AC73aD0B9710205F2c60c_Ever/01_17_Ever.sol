// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Ever is ERC721URIStorage, ERC2981, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  uint256 price = 0.025 ether;
  address _trustedSigner = 0x2Eb5A3d5960D474B15747E7f901D4723b74747df;
  mapping(bytes32 => bool) _mintedTokenURIHashes;

  constructor() ERC721("Ever", "E") {
    _setDefaultRoyalty(msg.sender, 1000);
  }

  event NFTMinted(uint256 tokenId);

  function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC721, ERC2981)
    returns (bool) {
      return super.supportsInterface(interfaceId);
  }

  function _baseURI() internal pure override returns (string memory) {
    return "ipfs://";
  }

  function _burn(uint256 tokenId) internal virtual override {
    super._burn(tokenId);
    _resetTokenRoyalty(tokenId);
  }

  function burnNFT(uint256 tokenId)
    public onlyOwner {
      require(ownerOf(tokenId) == msg.sender, "You are not the owner of the token.");
      _burn(tokenId);
  }

  function setPrice(uint256 _price)
    public onlyOwner {
      price = _price;
  }

  function mintNFTForAnyone(address recipient, string memory tokenURI, bytes memory signature)
    payable
    public
    returns (uint256) {
      require(msg.value >= price, "You need to pay some ETH, please use the getter to check the price");
      require(ECDSA.recover(ECDSA.toEthSignedMessageHash(bytes(tokenURI)), signature) == _trustedSigner, "Invalid signature");
      payable(owner()).transfer(msg.value);

      uint256 tokenId = mintNFTWithRoyalty(recipient, tokenURI);

      return tokenId;
  }

  function mintNFTForOwner(address recipient, string memory tokenURI)
    public onlyOwner
    returns (uint256) {
      uint256 tokenId = mintNFTWithRoyalty(recipient, tokenURI);

      return tokenId;
  } 

  function mintNFT(address recipient, string memory tokenURI)
    internal
    returns (uint256) {
      _tokenIds.increment();

      bytes32 tokenURIHash = keccak256(abi.encode(tokenURI));
      require(!_mintedTokenURIHashes[tokenURIHash], "tokenURI already exists");
      _mintedTokenURIHashes[tokenURIHash] = true;
      uint256 newItemId = _tokenIds.current();
      _safeMint(recipient, newItemId);
      _setTokenURI(newItemId, tokenURI);

      return newItemId;
  }

  function mintNFTWithRoyalty(address recipient, string memory tokenURI)
    internal
    returns (uint256) {
      uint256 tokenId = mintNFT(recipient, tokenURI);
      emit NFTMinted(tokenId);

      return tokenId;
  }
}