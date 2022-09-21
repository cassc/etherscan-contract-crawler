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
contract TapTapRevSI is 
  Ownable,
  ReentrancyGuard, 
  ERC721AQueryable 
{
  using SafeMath for uint256;

  uint256 public collectionSize = 8481;
  uint256 public reserveAmount = 150;

  uint256 public publicMintPrice = 0.065 ether;
  uint256 public addressMintMax = 8;

  uint256 public publicMintStartTime = 0; // Must be EPOCH
  uint256 public publicMintDuration = 365 days;

  /*
  * Once mint ends this will only be able to be updated to false, closing mint forever.
  * Supply can never be diluted.
  */
  bool public mintOpen = true;

  /*
  * Token.
  */
  string private _baseTokenURI;
  uint256 private constant _startingTokenId = 407;

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
    uint256 _initpublicMintStartTime
  ) ERC721A(_initName, _initSymbol) {
    _baseTokenURI = _initBaseURI;
    publicMintStartTime = _initpublicMintStartTime;
  }

  /*
  * Connect and override base URI.
  */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /*
  * Connect and override base startTokenId.
  */
  function _startTokenId() internal view virtual override returns (uint256) {
    return _startingTokenId;
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
  * Update collection size if necessary.
  */
  function setCollectionSize(uint256 _size) external onlyOwner nonReentrant {
    collectionSize = _size;
  }

  /*
  * Update reserve amount if necessary.
  */
  function setReserveAmount(uint256 _amount) external onlyOwner nonReentrant {
    reserveAmount = _amount;
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
  * Update Public Mint price if necessary.
  */
  function setPublicMintPrice(uint256 _price) external onlyOwner nonReentrant {
    publicMintPrice = _price; 
  }

  /*
  * Update max mints allowed if necessary.
  */
  function setAddressMintMax(uint256 _number) external onlyOwner nonReentrant {
    addressMintMax = _number; 
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
      totalSupply() + quantity <= collectionSize - reserveAmount, 
      "Purchase would exceed max supply"
    );

    uint256 totalCost = publicMintPrice * quantity;

    _safeMint(msg.sender, quantity);
    _validatePayment(totalCost);
  }
}