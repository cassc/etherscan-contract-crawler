// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import {HotSteppable} from "./HotSteppable.sol";

contract SteppableNFT is
  ERC721,
  Pausable,
  Ownable,
  ERC721Burnable,
  HotSteppable
{
  address constant BLACK_HOLE_ADDRESS =
    0x0000000000000000000000000000000000000000;
  address payable private beneficiary;
  address private developer;
  bool private mintingClosed;
  uint256 private _tokenIdCounter;
  uint256 private developerAllocation;
  uint256 private developerAllocated;

  constructor(
    uint256 _basePrice,
    uint256 _maxPrice,
    uint256 _priceIncrementToSet,
    uint256 _startPriceToSet,
    uint256 _bufferInSecondsToSet,
    uint256 _maxBatchMintToSet,
    uint256 _startPreviousBucketCountToSet,
    address payable _beneficiary,
    address _developer
  ) ERC721("Interleave Genesis", "INTER") {
    _setBasePrice(_basePrice);
    _setMaxPrice(_maxPrice);
    _setPriceIncrement(_priceIncrementToSet);
    _setStartPrice(_startPriceToSet);
    _setPriceBufferInSeconds(_bufferInSecondsToSet);
    _setMaxBatchMint(_maxBatchMintToSet);
    // we start with the previous price and current price the same:
    _setStartPreviousPrice(_startPriceToSet);
    _setStartPreviousBucketCount(_startPreviousBucketCountToSet);
    beneficiary = _beneficiary;
    developer = _developer;
    // start in minting mode:
    mintingClosed = false;
    // and in surge mode, not openmint mode:
    _setSurgeModeOn();
    // start paused using the inherited function, as we don't
    // want to set any zero point reference here:
    _pause();
  }

  modifier whenMintingOpen() {
    require(!mintingClosed, "Minting must be open");
    _;
  }

  modifier whenMintingClosed(address from) {
    require(
      (mintingClosed || from == BLACK_HOLE_ADDRESS),
      "Minting must be closed"
    );
    _;
  }

  event ethWithdrawn(uint256 indexed withdrawal, uint256 effectiveDate);
  event mintingStarted(uint256 mintStartTime);
  event mintingEnded(uint256 mintEndTime);

  function pause() external onlyOwner {
    _pause();
    _handleZeroPointReference();
  }

  function unpause() external onlyOwner {
    _unpause();
    _updateZeroPoint();
    if (_pausedAt == 0) {
      // This is the start of minting. Say so:
      emit mintingStarted(block.timestamp);
    }
  }

  function closeMinting() external onlyOwner {
    performMintingClose();
  }

  function performMintingClose() internal {
    mintingClosed = true;
    emit mintingEnded(block.timestamp);
  }

  function setBasePrice(uint256 _basePriceToSet) external onlyOwner {
    _setBasePrice(_basePriceToSet);
  }

  function setMaxBatchMint(uint256 _maxBatchMintToSet) external onlyOwner {
    _setMaxBatchMint(_maxBatchMintToSet);
  }

  function setPriceIncrement(uint256 _priceIncrementToSet) external onlyOwner {
    _setPriceIncrement(_priceIncrementToSet);
  }

  function setPriceBufferInSeconds(uint256 _BufferInSecondsToSet)
    external
    onlyOwner
  {
    _setPriceBufferInSeconds(_BufferInSecondsToSet);
  }

  function setSurgeModeOff() external onlyOwner {
    _setSurgeModeOff();
  }

  function setSurgeModeOn() external onlyOwner {
    _setSurgeModeOn();
  }

  function getEndTimeStamp() external view returns (uint256) {
    return (_endTimeStamp);
  }

  // The fallback function is executed on a call to the contract if
  // none of the other functions match the given function signature.
  fallback() external payable {
    revert();
  }

  receive() external payable {
    revert();
  }

  // Ensure that the beneficiary can receive deposited ETH:
  function withdraw(uint256 _withdrawal) external onlyOwner returns (bool) {
    (bool success, ) = beneficiary.call{value: _withdrawal}("");
    require(success, "Transfer failed.");
    emit ethWithdrawn(_withdrawal, block.timestamp);
    return true;
  }

  function getPrice()
    public
    view
    whenNotPaused
    whenMintingOpen
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (_getPrice());
  }

  function steppableMint(uint256 quantity)
    external
    payable
    whenNotPaused
    whenMintingOpen
  {
    // Don't want to try and mint 0 NFTs for 0 ETH:
    require(
      (quantity > 0) && (quantity <= _maxBatchMint),
      "Quantity must be greater than 0 and less than or equal to maximum"
    );

    // Get the price
    uint256 NFTPrice;
    uint256 bucketNumberToAdd;
    uint256 OldNFTPrice;
    (NFTPrice, bucketNumberToAdd, OldNFTPrice) = _getPrice();

    // We need the surge price * quantity to have been paid in:
    if (msg.value < (quantity * NFTPrice)) {
      // Check the buffer
      require(
        _withinBuffer(bucketNumberToAdd) &&
          (msg.value >= (quantity * OldNFTPrice)),
        "Insufficient ETH for surge adjusted price"
      );
    }

    // Update the bucket details IF we need to:
    if (bucketNumberToAdd > 0) {
      _updateBuckets(bucketNumberToAdd, NFTPrice, OldNFTPrice, quantity);
    } else {
      _recordMinting(quantity);
    }

    // Mint required qantity:
    performMinting(quantity, msg.sender);

    // Check if this is the end:
    if (block.timestamp > _endTimeStamp) {
      performMintingClose();
    }

    emit _steppableMinting(msg.sender, quantity, msg.value, block.timestamp);
  }

  function performMinting(uint256 quantityToMint, address to) internal {
    uint256 tokenIdToMint = _tokenIdCounter;
    for (uint256 i = 0; i < quantityToMint; i++) {
      _safeMint(to, tokenIdToMint);
      tokenIdToMint += 1;
    }
    _tokenIdCounter = tokenIdToMint;
  }

  function getDeveloperAllocationDetails()
    external
    view
    onlyOwner
    returns (uint256, uint256)
  {
    return (developerAllocation, developerAllocated);
  }

  function mintDeveloperAllocation(uint256 quantity)
    external
    onlyOwner
    whenMintingClosed(msg.sender)
  {
    if (developerAllocation == 0) {
      developerAllocation = (((_tokenIdCounter * 204) / 10000) + 1);
    }

    uint256 remainingDeveloperAllocation = (developerAllocation -
      developerAllocated);
    require(remainingDeveloperAllocation > 0, "Developer allocation exhausted");

    if (remainingDeveloperAllocation < quantity) {
      quantity = remainingDeveloperAllocation;
    }

    developerAllocated += quantity;

    // Mint required qantity:
    performMinting(quantity, developer);

    emit _developerAllocationMinting(
      developer,
      quantity,
      remainingDeveloperAllocation - quantity,
      block.timestamp
    );
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) whenNotPaused whenMintingClosed(from) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _baseURI() internal pure override returns (string memory) {
    return "https://arweave.net/u7QmmY8LhngU50EqUjjhdB6h8tnqK-9opSGmYVI8-v8";
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return _baseURI();
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}