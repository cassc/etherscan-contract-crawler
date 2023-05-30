// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

/**
 * @title TapTapRev contract
 * @dev Extends ERC721A Non-Fungible Token Standard implementation
 */
contract TapTapRev is 
  Ownable,
  ReentrancyGuard, 
  ERC721AQueryable 
{
  using SafeMath for uint256;

  uint256 public immutable collectionSize = 8888;
  uint256 public reserveAmount = 300; // 100 for OG airdrops

  uint256 public ogMaxSupply = 250;
  uint256 public ogMaxTotalSupply = ogMaxSupply + reserveAmount;

  uint256 public constant ogPrice = 0.15 ether;
  uint256 public constant allowlistPrice = 0.2 ether;
  uint256 public constant publicMintPrice = 0.25 ether;

  uint256 public constant addressMintMax = 8;

  uint256 public ogMintDuration = 48 hours;
  uint256 public ogMintStartTime = 0; // Must be EPOCH

  uint256 public allowlistMintDuration = 48 hours;
  uint256 public allowlistMintStartTime = 0; // Must be EPOCH

  uint256 public publicMintDuration = 30 days;
  uint256 public publicMintStartTime = 0; // Must be EPOCH

  /*
  * Once mint ends this will only be able to be updated to false, closing mint forever.
  * Supply can never be diluted.
  */
  bool public mintOpen = true;

  /*
  * Token.
  */
  string private _baseTokenURI;

  /*
  * Phase 1 and 2 allow list mappings.
  */
  mapping(address => uint256) public oglist;
  mapping(address => uint256) public allowlist;

  /*
  * Make sure origin is sender.
  */
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  /*
  * Make sure were open for business.
  */
  modifier onlyMintOpen() {
    require(mintOpen, "Season 1 mint has closed.");
    _;
  }

  constructor(
    string memory _initName, 
    string memory _initSymbol, 
    string memory _initBaseURI,
    uint256 _initOgMintStartTime,
    uint256 _initAllowlistMintStartTime,
    uint256 _initpublicMintStartTime
  ) ERC721A(_initName, _initSymbol) {
    _baseTokenURI = _initBaseURI;
    ogMintStartTime = _initOgMintStartTime;
    allowlistMintStartTime = _initAllowlistMintStartTime;
    publicMintStartTime = _initpublicMintStartTime;
  }

  /*
  * Connect and override base URI.
  */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /*
  * Set base URI for meta data.
  */
  function setBaseURI(string calldata baseURI) external onlyOwner nonReentrant {
    _baseTokenURI = baseURI;
  }

  /*
  * Set base URI for meta data.
  */
  function _validatePayment(uint256 price) private {
    require(msg.value >= price, "Send more ETH.");
  }

  /*
  * Withdraw Ether from contract.
  */
  function withdrawFunds() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  /*
  * Seed Allow List for OG mint.
  */
  function seedOGList(
    address[] memory addresses, 
    uint256[] memory numAllowedBySlot
  )
    external
    onlyOwner
    nonReentrant
  {
    require(
      addresses.length == numAllowedBySlot.length,
      "addresses amd numAllowedBySlot length need to be equal"
    );

    for (uint256 i = 0; i < addresses.length; i++) {
      oglist[addresses[i]] = numAllowedBySlot[i];
    }
  }

  /*
  * Seed Allow List for OG mint.
  */
  function seedAllowlist(
    address[] memory addresses, 
    uint256[] memory numAllowedBySlot
  )
    external
    onlyOwner
    nonReentrant
  {
    require(
      addresses.length == numAllowedBySlot.length,
      "addresses amd numAllowedBySlot length need to be equal"
    );

    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numAllowedBySlot[i];
    }
  }

  /*
  * Reverse look up tokenId to owner address.
  */
  function getTokenOwnerAddress(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(tokenId);
  }

  /*
  * Get number of tokens a user has minted.
  */
  function getNumberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  /*
  * Update OG Mint duration if necessary.
  */
  function setOgMintDuration(uint256 _duration) external onlyOwner nonReentrant {
    ogMintDuration = _duration;
  }

  /*
  * Update OG Mint start time if necessary.
  */
  function setOgMintStartTime(uint256 _startTime) external onlyOwner nonReentrant {
    ogMintStartTime = _startTime;
  }

  /*
  * Update allowlist Mint duration if necessary.
  */
  function setAllowlistMintDuration(uint256 _duration) external onlyOwner nonReentrant {
    allowlistMintDuration = _duration;
  }

  /*
  * Update allowlist Mint start time if necessary.
  */
  function setAllowlistMintStartTime(uint256 _startTime) external onlyOwner nonReentrant {
    allowlistMintStartTime = _startTime;
  }

  /*
  * Update Public Mint duration if necessary.
  */
  function setPublicMintDuration(uint256 _duration) external onlyOwner nonReentrant {
    publicMintDuration = _duration;
  }

  /*
  * Update Public Mint start time if necessary.
  */
  function setPublicMintStartTime(uint256 _startTime) external onlyOwner nonReentrant {
    publicMintStartTime = _startTime;
  }

  /*
  * Close Minting.
  */
  function closeMint() external onlyOwner nonReentrant {
    mintOpen = false; // close mint forever.
  }

  /*
  * Set some TTRs aside for marketing etc.
  */
  function mintDevAndMarketingReserve() external onlyOwner nonReentrant onlyMintOpen {
    _safeMint(msg.sender, reserveAmount);
  }

  /*
  * Mint function to handle OG minting.
  */
  function ogMint() external payable callerIsUser onlyMintOpen {
    require(block.timestamp >= ogMintStartTime, "OG Mint not yet started.");
    require(block.timestamp < ogMintStartTime + ogMintDuration, "Mint is over.");
    require(oglist[msg.sender] > 0, "Not on the OG list!");
    require(totalSupply() + 1 <= ogMaxTotalSupply, "Max OG TTR's Minted");
    require(
      totalSupply() + 1 <= collectionSize, 
      "Purchase would exceed max supply"
    );

    oglist[msg.sender]--;

    _safeMint(msg.sender, 1);
    _validatePayment(ogPrice);
  }

  /*
  * Mint function to handle allowlist minting.
  */
  function allowListMint(uint256 quantity) external payable callerIsUser onlyMintOpen {
    require(block.timestamp >= allowlistMintStartTime, "Allowlist Mint not yet started.");
    require(block.timestamp < allowlistMintStartTime + allowlistMintDuration, "Mint is over.");
    require(allowlist[msg.sender] > 0, "Not on the allowlist or max reached!");
    require(allowlist[msg.sender] >= quantity, "Cannot Mint that many TTR's.");
    require(
      totalSupply() + quantity <= collectionSize, 
      "Purchase would exceed max supply"
    );

    allowlist[msg.sender] = allowlist[msg.sender] - quantity;

    uint256 totalCost = allowlistPrice * quantity;

    _safeMint(msg.sender, quantity);
    _validatePayment(totalCost);
  }

  /*
  * Mint function to handle public auction.
  */
  function publicMint(uint256 quantity) external payable callerIsUser onlyMintOpen {
    require(block.timestamp >= publicMintStartTime, "Public Mint not yet started.");
    require(block.timestamp < publicMintStartTime + publicMintDuration, "Public is over.");
    require(
      getNumberMinted(msg.sender) + quantity <= addressMintMax,
      "Cannot Mint that many TTR's."
    );
    require(
      totalSupply() + quantity <= collectionSize, 
      "Purchase would exceed max supply"
    );

    uint256 totalCost = publicMintPrice * quantity;

    _safeMint(msg.sender, quantity);
    _validatePayment(totalCost);
  }
}