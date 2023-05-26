// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Whitelisted.sol";

contract SwampverseERC721 is ERC721, Ownable, ReentrancyGuard, Whitelisted, VRFConsumerBase {
  using Address for address;

  bytes32 internal _LINK_KEY_HASH;
  uint256 internal _LINK_FEE;
  uint256 internal _tokenIds;
  uint256 internal _reserved;
  uint256 internal _presaleMinted;
  uint256 internal _tokenOffset;
  string internal _baseTokenURI;
  address internal _team;

  uint256 constant public MAX_MINT = 10;
  uint256 constant public PRESALE_MAX_MINT = 3;
  uint256 constant public MINT_PRICE = 0.06 ether;
  uint256 constant public MAX_SUPPLY = 9600;
  uint256 constant public MAX_RESERVED = 100;
  string constant public PROVENANCE_HASH = "8016b8eee30dcaf2c61321cee08ccd0ae08657e3d150cbd49315e353b161cd6e"; // sha256
  bool public revealed;
  bool public presaleActive;
  bool public saleActive;
  string public metadataURI;
  mapping(address => uint256) public presaleMints;

  constructor(
    address team,
    address signer,
    string memory baseTokenURI,
    address vrfCoordinator,
    address linkToken,
    bytes32 keyHash,
    uint256 linkFee
  )
    ERC721("Swampverse", "SWAMPER")
    Whitelisted(signer)
    VRFConsumerBase(vrfCoordinator, linkToken)
  {
    _team = team;
    _baseTokenURI = baseTokenURI;
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

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseTokenURI(string memory URI) public onlyOwner {
    _baseTokenURI = URI;
  }

  function setMetadataURI(string memory URI) public onlyOwner {
    metadataURI = URI;
  }

  function flipPresaleActive() public onlyOwner {
    presaleActive = !presaleActive;
  }

  function flipSaleActive() public onlyOwner {
    saleActive = !saleActive;
  }

  function flipRevealed() public onlyOwner {
    require(_tokenOffset != 0, "Offset has not been generated");

    revealed = !revealed;
  }

  function setTokenOffset() public onlyOwner {
    require(_tokenOffset == 0, "Offset is already set");

    requestRandomness(_LINK_KEY_HASH, _LINK_FEE);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    _tokenOffset = randomness % MAX_SUPPLY;
  }

  function reserve(uint256 amount, address to) public onlyOwner {
    require(_reserved + amount <= MAX_RESERVED, "Exceeds maximum number of reserved tokens");

    _mintAmount(amount, to);
    _reserved += amount;
  }

  function presaleMint(bytes memory signature, uint256 amount)
    public
    payable
    nonReentrant
    isValidWhitelistSignature(signature)
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
    require(_tokenIds + amount < MAX_SUPPLY,  "Exceeds maximum number of tokens");

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _tokenIds);
      _tokenIds += 1;
    }
  }

  function withdraw() nonReentrant public {
    require(msg.sender == _team || msg.sender == owner(), "Caller cannot withdraw");

    Address.sendValue(payable(_team), address(this).balance / 5);
    Address.sendValue(payable(owner()), address(this).balance);
  }

  function withdrawLINK(address to, uint256 amount) external onlyOwner {
    require(LINK.balanceOf(address(this)) >= amount, "Insufficient LINK balance");
    LINK.transfer(to, amount);
  }
}