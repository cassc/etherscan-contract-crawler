// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./PresaleApproval.sol";

contract GlizzyGangERC721 is ERC721, Ownable, ReentrancyGuard, PresaleApproval, VRFConsumerBase {
  using Address for address;

  uint256 constant public PRE_MINTED = 251; // migrated from OpenSea
  uint256 constant public MAX_MINT = 10;
  uint256 constant public PRESALE_MAX_MINT = 5;
  uint256 constant public MINT_PRICE = 0.0555 ether;
  uint256 constant public MAX_SUPPLY = 5555;

  string public PROVENANCE_HASH; // sha256
  bool public revealed;
  bool public presaleActive;
  bool public saleActive;
  string public metadataURI;
  mapping(address => uint256) public presaleMints;

  uint256 internal _tokenIds = PRE_MINTED;
  uint256 internal _reserved;
  uint256 internal _presaleMinted;
  uint256 internal _tokenOffset;
  string internal _baseTokenURI;
  string internal _placeholderURI;
  bytes32 internal _LINK_KEY_HASH;
  uint256 internal _LINK_FEE;

  constructor(
    address signer,
    string memory placeholderURI,
    address vrfCoordinator,
    address linkToken,
    bytes32 keyHash,
    uint256 linkFee
  )
    ERC721("GlizzyGang", "GLIZZY")
    PresaleApproval(signer)
    VRFConsumerBase(vrfCoordinator, linkToken)
  {
    _placeholderURI = placeholderURI;
    _LINK_KEY_HASH = keyHash;
    _LINK_FEE = linkFee;
  }

  function totalSupply() external view returns (uint256) {
    return _tokenIds;
  }

  function tokenOffset() public view returns (uint256) {
    require(_tokenOffset != 0, "Offset has not been generated");

    return _tokenOffset;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return revealed ? ERC721.tokenURI(tokenId) : _placeholderURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseTokenURI(string memory URI) public onlyOwner {
    _baseTokenURI = URI;
  }

  function setMetadataURI(string memory URI) public onlyOwner {
    metadataURI = URI;
  }

  function setPlaceholderURI(string memory URI) public onlyOwner {
    _placeholderURI = URI;
  }

  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    require(bytes(PROVENANCE_HASH).length == 0, "Provenance hash has already been set");

    PROVENANCE_HASH = provenanceHash;
  }

  function flipPresaleActive() public onlyOwner {
    presaleActive = !presaleActive;
  }

  function flipSaleActive() public onlyOwner {
    saleActive = !saleActive;
  }

  function flipRevealed() public onlyOwner {
    require(_tokenOffset != 0, "Offset has not been generated");
    require(bytes(_baseTokenURI).length > 0, "Base URI has not been set");

    revealed = !revealed;
  }

  function setTokenOffset() public onlyOwner {
    require(_tokenOffset == 0, "Offset is already set");

    requestRandomness(_LINK_KEY_HASH, _LINK_FEE);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    // offset is not applied to pre-minted tokens
    _tokenOffset = randomness % (MAX_SUPPLY - PRE_MINTED);
  }

  function presaleMint(bytes memory signature, uint256 amount)
    public
    payable
    nonReentrant
    isValidPresaleSignature(signature)
  {
    require(presaleActive,                                         "Presale has not started");
    require(msg.value == MINT_PRICE * amount,                      "Invalid Ether amount sent");
    require(presaleMints[msg.sender] + amount <= PRESALE_MAX_MINT, "Exceeds remaining presale balance");

    _mintAmount(amount, msg.sender);

    presaleMints[msg.sender] += amount;
    _presaleMinted += amount;
  }

  function mint(uint256 amount) public payable nonReentrant {
    require(saleActive,                       "Public sale has not started");
    require(msg.value == MINT_PRICE * amount, "Invalid Ether amount sent");
    require(amount <= MAX_MINT,               "Exceeds the maximum amount to mint at once");

    _mintAmount(amount, msg.sender);
  }

  function _mintAmount(uint256 amount, address to) internal {
    require(_tokenIds + amount <= MAX_SUPPLY, "Exceeds maximum number of tokens");

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _tokenIds);
      _tokenIds += 1;
    }
  }

  function withdraw() nonReentrant onlyOwner public {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function withdrawLINK(address to, uint256 amount) external onlyOwner {
    require(LINK.balanceOf(address(this)) >= amount, "Insufficient LINK balance");
    LINK.transfer(to, amount);
  }
}