// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import '../../interfaces/IJBDirectory.sol';
import '../../interfaces/IJBPaymentTerminal.sol';
import '../../libraries/JBTokens.sol';

import './interfaces/INFTAuctionMint.sol';

interface IDutchAuctionMachine {
  function initialize(
    uint256 _maxAuctions,
    uint256 _auctionDuration,
    uint256 _periodDuration,
    uint256 _maxPriceMultiplier,
    uint256 _projectId,
    IJBDirectory _jbxDirectory,
    address _token,
    address _owner
  ) external;

  function bid() external payable;

  function settle() external;

  function timeLeft() external view returns (uint256);

  function currentPrice() external view returns (uint256 price);

  function recoverToken(address _account, uint256 _tokenId) external;
}

/**
 * @notice This contract allows for simple perpetual NFT Dutch auctions on ERC721 tokens. The target token must allow this contract to mint new tokens to itself via `mintFor(address)`. AuctionMachine will call this function to grab a token to put on sale. An example of a compatible token is available in this repo. It also requires `unitPrice()` to set starting and ending prices for the auction.
 *
 * @dev This contract is `Ownable` but it also mimics `Initializable` without actually implementing it. It's meant to be deployed by a clone factory contract. While the source contract storage is not inherited by clones, it is neater to have it be controlled by a known party rather than float without a pre-set admin. Once a clone is crated the factory contract will call `initialize` to set the contract admin on the new instance.
 */
contract DutchAuctionMachine is IDutchAuctionMachine, IERC165, Ownable, ReentrancyGuard {
  error INVALID_DURATION();
  error INVALID_BID();
  error AUCTION_ENDED();
  error SUPPLY_EXHAUSTED();
  error AUCTION_ACTIVE();
  error INVALID_OPERATION();

  // TODO: consider packing maxAuctions, auctionDuration, periodDuration and maxPriceMultiplier
  uint256 public maxAuctions; // TODO: consider allowing modification of this parameter

  /** @notice Duration of auctions in seconds. */
  uint256 public auctionDuration;

  /** @notice Price drop period duration.  */
  uint256 public periodDuration;

  /** @notice Price multiplier to determine the starting (high) price. */
  uint256 public maxPriceMultiplier;

  /** @notice Juicebox project id that will receive auction proceeds */
  uint256 public jbxProjectId;

  /** @notice Juicebox terminal for send proceeds to */
  IJBDirectory public jbxDirectory;

  INFTAuctionMint public token;

  uint256 public completedAuctions;

  /** @notice Current auction ending time. */
  uint256 public auctionExpiration;

  uint256 public currentTokenId;

  /** @notice Current highest bid. */
  uint256 public currentBid;

  /** @notice Current highest bidder. */
  address public currentBidder;

  uint256 public startingPrice;
  uint256 public endingPrice;

  event Bid(address indexed bidder, uint256 amount, address token, uint256 tokenId);
  event AuctionStarted(uint256 expiration, address token, uint256 tokenId);
  event AuctionEnded(address winner, uint256 price, address token, uint256 tokenId);

  /**
   * @notice Create an "Auction Machine" which is expected to be able to mint new NFTs against the supplied token. The operation is as follows:
   * - Mint a new token.
   * - Create a new Dutch auction for the token that was just minted using the provided price multiplier along with `unitPrice` from the nft contract as the starting price and `unitPrice` as the ending (lowest) price.
   * - Accept bids until auction duration is reached.
   * - Transfer the token to the auction winner.
   * - Repeat until maxAuctions are run.
   *
   * An auction doesn't need to result in a sale for it to be counted as completed for `maxAuctions`. Unsold tokens are retained by the contract and can be moved by the admin with `recoverToken(address,uint256)`
   *
   * @dev The provided token must have the following functions: `mintFor(address) => uint256`, `transferFrom(address, address, uint256)` (standard ERC721/1155 function), `unitPrice() => uint256`. `mintFor` will be called with `address(this)` to mint a new token to this contract in order to start a new auction. unitPrice() will be called to set the auction starting price. `transferFrom` will be called to transfer the token to the auction winner if any.
   *
   * @dev This contract is meant to be used via the `Deployer` contract which makes `Clone`s. This means that there is a known-good initial deployment of by the platform admin which is then given to the deployer as the clone source. To make sure that the mother instance is not orphaned and taken over by a malicious actor this contract is Ownable which gives ownership to the original deployer. Then when a clone is made it is unowned but the Deployer contract will call initialize which will assign ownership as intended.
   *
   * @param _maxAuctions Maximum number of auctions to perform automatically, 0 for no limit.
   * @param _auctionDuration Auction duration in seconds.
   * @param _periodDuration Price reduction period in seconds.
   * @param _maxPriceMultiplier Starting price multiplier. Token unit price is multiplied by this value to become the auction starting price.
   * @param _projectId Juicebox project id, used to transfer auction proceeds.
   * @param _jbxDirectory Juicebox directory, used to transfer auction proceeds to the correct terminal.
   * @param _token Token contract to operate on.
   * @param _owner Auction admin address.
   */
  function initialize(
    uint256 _maxAuctions,
    uint256 _auctionDuration,
    uint256 _periodDuration,
    uint256 _maxPriceMultiplier,
    uint256 _projectId,
    IJBDirectory _jbxDirectory,
    address _token,
    address _owner
  ) external {
    if (address(token) != address(0)) {
      revert INVALID_OPERATION();
    }

    if (owner() != address(0)) {
      if (msg.sender != owner()) {
        revert INVALID_OPERATION();
      }
    } else {
      _transferOwnership(_owner);
    }

    maxAuctions = _maxAuctions;
    auctionDuration = _auctionDuration;
    periodDuration = _periodDuration;
    maxPriceMultiplier = _maxPriceMultiplier;
    jbxProjectId = _projectId;
    jbxDirectory = _jbxDirectory;
    token = INFTAuctionMint(_token);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  function bid() external payable nonReentrant {
    if (currentBidder == address(0) && currentBid == 0 && currentTokenId == 0) {
      // no auction, create new

      startNewAuction();
    } else if (currentBid >= msg.value || msg.value < token.unitPrice()) {
      revert INVALID_BID();
    } else if (auctionExpiration > block.timestamp && currentBid < msg.value) {
      // new high bid

      payable(currentBidder).transfer(currentBid);
      currentBidder = msg.sender;
      currentBid = msg.value;

      emit Bid(msg.sender, msg.value, address(token), currentTokenId);
    } else {
      revert AUCTION_ENDED();
    }
  }

  function settle() external nonReentrant {
    if (auctionExpiration > block.timestamp && currentPrice() > currentBid) {
      revert AUCTION_ACTIVE();
    }

    if (currentBid >= currentPrice()) {
      // auction reached a valid bid, settle
      IJBPaymentTerminal terminal = jbxDirectory.primaryTerminalOf(jbxProjectId, JBTokens.ETH);
      terminal.pay(jbxProjectId, currentBid, JBTokens.ETH, currentBidder, 0, false, '', ''); // TODO: send relevant memo to terminal

      token.transferFrom(address(this), currentBidder, currentTokenId);

      emit AuctionEnded(currentBidder, currentBid, address(token), currentTokenId);
    }
    //  else if (auctionExpiration < block.timestamp) {
    // auction concluded without a valid bid
    // }

    unchecked {
      ++completedAuctions;
    }

    currentBidder = address(0);
    currentBid = 0;
    currentTokenId = 0;
    auctionExpiration = 0;

    if (maxAuctions == 0 || completedAuctions + 1 <= maxAuctions) {
      startNewAuction();
    }
  }

  function timeLeft() public view returns (uint256) {
    if (block.timestamp > auctionExpiration) {
      return 0;
    }

    return auctionExpiration - block.timestamp;
  }

  function currentPrice() public view returns (uint256 price) {
    if (currentTokenId != 0) {
      if (auctionExpiration < block.timestamp) {
        return endingPrice;
      }
    }

    uint256 startTime = auctionExpiration - auctionDuration;
    uint256 periods = auctionDuration / periodDuration;
    uint256 periodPrice = (startingPrice - endingPrice) / periods;
    uint256 elapsedPeriods = (block.timestamp - startTime) / periodDuration;
    price = startingPrice - elapsedPeriods * periodPrice;
  }

  function supportsInterface(bytes4 _interfaceId) public pure override returns (bool) {
    return _interfaceId == type(IDutchAuctionMachine).interfaceId;
  }

  //*********************************************************************//
  // --------------------- privileged transactions --------------------- //
  //*********************************************************************//

  /**
   * @notice Sends tokens owned by this contract, from failed auctions, to the given address.
   *
   * @param _account Address to transfer the token to.
   * @param _tokenId Token id of NFT to transfer.
   */
  function recoverToken(address _account, uint256 _tokenId) external onlyOwner {
    if (_tokenId == currentTokenId) {
      revert AUCTION_ACTIVE();
    }

    token.transferFrom(address(this), _account, _tokenId);
  }

  //*********************************************************************//
  // ---------------------- private transactions ----------------------- //
  //*********************************************************************//

  function startNewAuction() private {
    if (maxAuctions != 0 && completedAuctions == maxAuctions) {
      revert SUPPLY_EXHAUSTED();
    }

    currentTokenId = token.mintFor(address(this));
    endingPrice = token.unitPrice();
    startingPrice = endingPrice * maxPriceMultiplier;

    if (msg.value >= endingPrice) {
      currentBidder = msg.sender;
      currentBid = msg.value;
      emit Bid(msg.sender, msg.value, address(token), currentTokenId);
    } else {
      currentBidder = address(0);
      currentBid = 0;
    }
    auctionExpiration = block.timestamp + auctionDuration;

    emit AuctionStarted(auctionExpiration, address(token), currentTokenId);
  }
}