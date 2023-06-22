// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Auction is Ownable, Pausable {
  using SafeERC20 for IERC20;

  uint256 public immutable minimumUnitPrice;
  uint256 public immutable minimumBidIncrement;
  uint256 public immutable unitPriceStepSize;
  uint256 public immutable minimumQuantity;
  uint256 public immutable maximumQuantity;
  uint256 public immutable numberOfAuctions;
  uint256 public immutable itemsPerAuction;
  address payable public immutable beneficiaryAddress;

  // Total auction length - including the last X hours inside which it can randomly end
  uint256 public auctionLengthInHours = 24;
  // The target number for the random end's random number generator.
  // MUST be < endWindows to have an even chance of ending each window
  uint256 constant randomEnd = 7;
  // Auction randomly ends within last auctionEndThresholdHrs
  uint256 public constant auctionEndThresholdHrs = 3;
  // Number of time windows inside the threshold in which the auction can randomly end
  uint256 public constant endWindows = 18;
  // block timestamp of when auction starts
  uint256 public auctionStart;
  // Merkle root of those addresses owed a refund
  bytes32 public refundMerkleRoot;

  AuctionStatus private _auctionStatus;
  uint256 private _bidIndex;

  event AuctionStarted();
  event AuctionEnded();
  event BidPlaced(
    bytes32 indexed bidHash,
    uint256 indexed auctionIndex,
    address indexed bidder,
    uint256 bidIndex,
    uint256 unitPrice,
    uint256 quantity,
    uint256 balance
  );
  event RefundIssued(address indexed refundRecipient, uint256 refundAmount);

  struct Bid {
    uint128 unitPrice;
    uint128 quantity;
  }

  struct AuctionStatus {
    bool started;
    bool ended;
  }

  // keccak256(auctionIndex, bidder address) => current bid
  mapping(bytes32 => Bid) private _bids;
  // Refunds address => excessRefunded
  mapping(address => bool) private _excessRefunded;
  // Auction end checks windowIndex => windowChecked
  mapping(uint256 => bool) private _windowChecked;

  // Beneficiary address cannot be changed after deployment.
  constructor(
    address payable beneficiaryAddress_,
    uint256 minimumUnitPrice_,
    uint256 minimumBidIncrement_,
    uint256 unitPriceStepSize_,
    uint256 maximumQuantity_,
    uint256 numberOfAuctions_,
    uint256 itemsPerAuction_
  ) {
    beneficiaryAddress = beneficiaryAddress_;
    minimumUnitPrice = minimumUnitPrice_;
    minimumBidIncrement = minimumBidIncrement_;
    unitPriceStepSize = unitPriceStepSize_;
    minimumQuantity = 1;
    maximumQuantity = maximumQuantity_;
    numberOfAuctions = numberOfAuctions_;
    itemsPerAuction = itemsPerAuction_;
    pause();
  }

  modifier whenRefundsActive() {
    require(refundMerkleRoot != 0, "Refund merkle root not set");
    _;
  }

  modifier whenAuctionActive() {
    require(!_auctionStatus.ended, "Auction has already ended");
    require(_auctionStatus.started, "Auction hasn't started yet");
    _;
  }

  modifier whenPreAuction() {
    require(!_auctionStatus.ended, "Auction has already ended");
    require(!_auctionStatus.started, "Auction has already started");
    _;
  }

  modifier whenAuctionEnded() {
    require(_auctionStatus.ended, "Auction hasn't ended yet");
    require(_auctionStatus.started, "Auction hasn't started yet");
    _;
  }

  function auctionStatus() public view returns (AuctionStatus memory) {
    return _auctionStatus;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function startAuction() external onlyOwner whenPreAuction {
    _auctionStatus.started = true;
    auctionStart = block.timestamp;

    if (paused()) {
      unpause();
    }
    emit AuctionStarted();
  }

  function getAuctionEnd() internal view returns (uint256) {
    return auctionStart + (auctionLengthInHours * 1 hours);
  }

  function endAuction() external whenAuctionActive {
    require(
      block.timestamp >= getAuctionEnd(),
      "Auction can't be stopped until due"
    );
    _endAuction();
  }

  function _endAuction() internal whenAuctionActive {
    _auctionStatus.ended = true;
    if (!paused()) {
      _pause();
    }
    emit AuctionEnded();
  }

  function numberOfBidsPlaced() external view returns (uint256) {
    return _bidIndex;
  }

  function getBid(uint256 auctionIndex_, address bidder_)
    external
    view
    returns (Bid memory)
  {
    return _bids[_bidHash(auctionIndex_, bidder_)];
  }

  function _bidHash(uint256 auctionIndex_, address bidder_)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(auctionIndex_, bidder_));
  }

  function _refundHash(uint256 refundAmount_, address bidder_)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(refundAmount_, bidder_));
  }

  // When a bidder places a bid or updates their existing bid, they will use this function.
  // - total value can never be lowered
  // - unit price can never be lowered
  // - quantity can be raised or lowered, but only if unit price is raised to meet or exceed previous total price
  function placeBid(
    uint256 auctionIndex_,
    uint256 quantity_,
    uint256 unitPrice_
  ) external payable whenNotPaused whenAuctionActive {
    // If the bidder is increasing their bid, the amount being added must be greater than or equal to the minimum bid increment.
    // A msg.value of 0 can be valid if the bidder is updating their bid but no new ether is required.
    if (msg.value > 0 && msg.value < minimumBidIncrement) {
      revert("Bid lower than minimum bid increment.");
    }

    // Ensure auctionIndex is within valid range.
    // For a multi-phase auction like loomlock, this would be insuffucient. You would need to store a state var for the current auction index and require that the auctionIndex_ param == that index.
    require(auctionIndex_ < numberOfAuctions, "Invalid auctionIndex");

    // Cache initial bid values.
    bytes32 bidHash = _bidHash(auctionIndex_, msg.sender);
    uint256 initialUnitPrice = _bids[bidHash].unitPrice;
    uint256 initialQuantity = _bids[bidHash].quantity;
    uint256 initialBalance = initialUnitPrice * initialQuantity;

    // Cache final bid values.
    uint256 finalUnitPrice = unitPrice_;
    uint256 finalQuantity = quantity_;
    uint256 finalBalance = initialBalance + msg.value;

    // Don't allow bids with a unit price scale smaller than unitPriceStepSize.
    // For example, allow 1.01 or 111.01 but don't allow 1.011.
    require(
      finalUnitPrice % unitPriceStepSize == 0,
      "Unit price step too small"
    );

    // Reject bids that don't have a quantity within the valid range.
    require(finalQuantity >= minimumQuantity, "Quantity too low");
    require(finalQuantity <= maximumQuantity, "Quantity too high");

    // Balance can never be lowered. This can't really ever happen because of the way finalBalance is defined.
    require(finalBalance >= initialBalance, "Balance can't be lowered");

    // Unit price can never be lowered.
    // Quantity can be raised or lowered, but it can only be lowered if the unit price is raised to meet or exceed the initial total value. Ensuring the the unit price is never lowered takes care of this.
    require(finalUnitPrice >= initialUnitPrice, "Unit price can't be lowered");

    // Ensure the new finalBalance equals quantity * the unit price that was given in this txn exactly. This is important to prevent rounding errors later when returning ether.
    require(
      finalQuantity * finalUnitPrice == finalBalance,
      "Quantity * Unit Price != Total Value"
    );

    // Unit price must be greater than or equal to the minimumUnitPrice.
    require(finalUnitPrice >= minimumUnitPrice, "Bid unit price too low");

    // Something must be changing from the initial bid for this new bid to be valid.
    if (
      initialUnitPrice == finalUnitPrice && initialQuantity == finalQuantity
    ) {
      revert("This bid doesn't change anything");
    }

    // Update the bidder's bid.
    _bids[bidHash].unitPrice = uint128(finalUnitPrice);
    _bids[bidHash].quantity = uint128(finalQuantity);

    emit BidPlaced(
      bidHash,
      auctionIndex_,
      msg.sender,
      _bidIndex,
      finalUnitPrice,
      finalQuantity,
      finalBalance
    );

    // Increment after emitting the BidPlaced event because counter is 0-indexed.
    _bidIndex += 1;

    // After the bid has been placed, check to see whether the auction is ended
    _checkAuctionEnd();
  }

  function withdrawContractBalance() external onlyOwner {
    (bool success, ) = beneficiaryAddress.call{value: address(this).balance}(
      ""
    );
    require(success, "Transfer failed");
  }

  // A withdraw function to avoid locking ERC20 tokens in the contract forever.
  // Tokens can only be withdrawn by the owner, to the owner.
  function transferERC20Token(IERC20 token, uint256 amount) external onlyOwner {
    token.safeTransfer(owner(), amount);
  }

  // Handles receiving ether to the contract.
  // Reject all direct payments to the contract except from beneficiary and owner.
  // Bids must be placed using the placeBid function.
  receive() external payable {
    require(msg.value > 0, "No ether was sent");
    require(
      msg.sender == beneficiaryAddress || msg.sender == owner(),
      "Only owner or beneficiary can fund contract"
    );
  }

  function setRefundMerkleRoot(bytes32 refundMerkleRoot_)
    external
    onlyOwner
    whenAuctionEnded
  {
    refundMerkleRoot = refundMerkleRoot_;
  }

  function claimRefund(uint256 refundAmount_, bytes32[] calldata proof_)
    external
    whenNotPaused
    whenAuctionEnded
    whenRefundsActive
  {
    // Can only refund if we haven't already refunded this address:
    require(!_excessRefunded[msg.sender], "Refund already issued");

    bytes32 leaf = _refundHash(refundAmount_, msg.sender);
    require(
      MerkleProof.verify(proof_, refundMerkleRoot, leaf),
      "Refund proof invalid"
    );

    // Safety check - we shouldn't be refunding more than this address has bid across all auctions. This will also
    // catch data collision exploits using other address and refund amount combinations, if
    // such are possible:
    uint256 totalBalance;
    for (
      uint256 auctionIndex = 0;
      auctionIndex < numberOfAuctions;
      auctionIndex++
    ) {
      bytes32 bidHash = _bidHash(auctionIndex, msg.sender);
      totalBalance += _bids[bidHash].unitPrice * _bids[bidHash].quantity;
    }

    require(refundAmount_ <= totalBalance, "Refund request exceeds balance");

    // Set state - we are issuing a refund to this address now, therefore
    // this logic path cannot be entered again for this address:
    _excessRefunded[msg.sender] = true;

    // State has been set, we can now send the refund:
    (bool success, ) = msg.sender.call{value: refundAmount_}("");
    require(success, "Refund failed");

    emit RefundIssued(msg.sender, refundAmount_);
  }

  function _checkAuctionEnd() internal {
    // (1) If we are at or past the end time it's the end of the action:
    if (block.timestamp >= getAuctionEnd()) {
      _endAuction();
    } else {
      // (2) Still going? See if we are in the threshold:
      uint256 auctionEndThreshold = getAuctionEnd() -
        (auctionEndThresholdHrs * 1 hours);
      if (block.timestamp >= auctionEndThreshold) {
        uint256 windowSize = (auctionEndThresholdHrs * 1 hours) / endWindows;
        uint256 windowIndex = (block.timestamp - auctionEndThreshold) /
          windowSize;
        if (!_windowChecked[windowIndex]) {
          _windowChecked[windowIndex] = true;
          // End logic is simple, we do a modulo on the random number using the number of
          // windows. We check the value (something that must be < endWindows to sure even probability each window).
          // Auction ends if they match.
          if (_getRandomNumber() % endWindows == randomEnd) {
            _endAuction();
          }
        }
      }
    }
  }

  function _getRandomNumber() internal view returns (uint256) {
    return
      uint256(keccak256(abi.encode(_bidIndex, blockhash(block.number - 1))));
  }
}