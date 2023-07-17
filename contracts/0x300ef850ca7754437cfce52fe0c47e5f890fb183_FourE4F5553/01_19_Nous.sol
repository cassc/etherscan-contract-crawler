// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//        ██    ████████        ██    ████████  ████████  ████████  ████████    ████
//      ████    ██            ████    ██        ██        ██        ██        ██    ██
//    ██  ██    ██          ██  ██    ██        ██        ██        ██              ██
//  ██    ██    ██████    ██    ██    ██████    ████████  ████████  ████████    ████
//  ██████████  ██        ██████████  ██              ██        ██        ██        ██
//        ██    ██              ██    ██        ██    ██  ██    ██  ██    ██  ██    ██
//        ██    ████████        ██    ██          ████      ████      ████      ████

contract FourE4F5553 is ERC721, ERC721Enumerable, ERC721Burnable, PaymentSplitter, Ownable, VRFConsumerBase {
  using Address for address;

  uint256 internal LINK_FEE;
  bytes32 internal LINK_KEY_HASH;
  uint256 internal _tokenIds;
  uint256 internal _reserved;
  address[] internal _payees;
  bool internal _saleActive;
  uint256 internal _tokenOffset;
  string internal _baseTokenURI;
  string internal _contractURI;
  string internal _keysURI;

  uint256 public MAX_MINT = 10;
  uint256 public MINT_PRICE = 0.03333 ether;
  uint256 public MAX_SUPPLY = 3333;
  uint256 public MAX_RESERVED = 66;
  string public PROVENANCE_HASH; // Keccak-256

  constructor(
    string memory provenanceHash,
    string memory baseTokenURI,
    address vrfCoordinator,
    address linkToken,
    bytes32 keyHash,
    uint256 linkFee,
    address[] memory payees,
    uint256[] memory shares
  )
    ERC721("4E4F5553", "4E4F")
    PaymentSplitter(payees, shares)
    VRFConsumerBase(vrfCoordinator, linkToken)
  {
    PROVENANCE_HASH = provenanceHash;
    LINK_KEY_HASH = keyHash;
    LINK_FEE = linkFee;
    _baseTokenURI = baseTokenURI;
    _payees = payees;
  }

  function saleActive() public view returns (bool) {
    return _saleActive;
  }

  function tokenOffset() public view returns (uint256) {
    require(_tokenOffset != 0, "Offset has not been generated");

    return _tokenOffset;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseTokenURI(string memory URI) public onlyOwner {
    _baseTokenURI = URI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory URI) public onlyOwner {
    _baseTokenURI = URI;
  }

  function keysURI() public view returns (string memory) {
    return _keysURI;
  }

  function setKeysURI(string memory URI) public onlyOwner {
    _keysURI = URI;
  }

  function keyId(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "Query for nonexistent token");

    return (tokenId + tokenOffset()) % MAX_SUPPLY;
  }

  function flipSaleActive() public onlyOwner {
    _saleActive = !_saleActive;
  }

  function initializeSale() public onlyOwner {
    require(_tokenOffset == 0 && !_saleActive, "Sale is already initialized");

    requestRandomness(LINK_KEY_HASH, LINK_FEE);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    _saleActive = true;
    _tokenOffset = randomness % MAX_SUPPLY;
  }

  function reserve(uint256 amount, address to) public onlyOwner {
    require(_reserved + amount < MAX_RESERVED, "Exceeds maximum number of reserved tokens");

    _mintAmount(amount, to);
    _reserved += amount;
  }

  function mint(uint256 amount) public payable {
    require(amount <= MAX_MINT,               "Exceeds the maximum amount to mint at once");
    require(msg.value >= MINT_PRICE * amount, "Invalid Ether amount sent");
    require(_tokenOffset != 0,                "Offset has not been generated");
    require(_saleActive,                      "Sale is not active");

    _mintAmount(amount, msg.sender);
  }

  function _mintAmount(uint256 amount, address to) internal {
    require(_tokenIds + amount < MAX_SUPPLY, "Exceeds maximum number of tokens");

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _tokenIds);
      _tokenIds += 1;
    }
  }

  function withdrawLINK(address to, uint256 amount) external onlyOwner {
    require(LINK.balanceOf(address(this)) >= amount, "Insufficient LINK balance");
    LINK.transfer(to, amount);
  }

  function withdrawAll() external onlyOwner {
    for (uint256 i = 0; i < _payees.length; i++) {
      release(payable(_payees[i]));
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}