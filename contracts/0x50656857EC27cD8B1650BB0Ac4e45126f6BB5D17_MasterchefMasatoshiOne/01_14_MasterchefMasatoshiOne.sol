// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IReverseRegistrar.sol";
import "./ERC721.sol";

/// @title Omakasea 1of1 Auction & Fixed Sale Contract
/// @author @TheChadDevET
/// @notice Use this contract to auction or sell 1of1 art pieces. Omakasea takes a 1% rake on each sale.

contract MasterchefMasatoshiOne is ERC721, Ownable {
  address public immutable ENSReverseRegistrar = 0x084b1c3C81545d370f3634392De611CaaBFf8148;
  address payable public immutable omakasea = payable(0xa179c4533CB519a9b8C08c6bAF95223c1Af19A6b);

  uint256 public immutable rakePercentage = 1;
  uint256 public minBidIncrementPercentage = 1;
  uint256 public startingBid;
  uint256 public currentAuctionID = 0;
  uint256 public fixedSalePrice;

  bool public biddingActive;
  bool public fixedSaleActive;

  string public currentTokenURI;
  address payable public highestBidAddress;
  // first uint256 represents the current auction ID
  mapping(uint256 => mapping(address => uint256)) public bidPerAddress;
  mapping(uint256 => string) tokenURIs;

  constructor(
      string memory _name,
      string memory _symbol
  ) ERC721(_name, _symbol, 1) {}

  /// @notice Retrieve token URI for token
  /// @dev Reads from a mapping set every time an NFT is minted
  /// @param tokenID The token ID of the NFT
  /// @return tokenURI The URI of the NFT
  function tokenURI(uint256 tokenID) public view override returns (string memory) {
      require(_exists(tokenID), "z");
      return tokenURIs[tokenID];
  }

  /// @notice Add reverse ENS records pointing from the specified name to this contract
  /// @dev The contract must be the controller of the ENS name
  /// @param name The ENS name provided
  function addReverseENSRecord(string memory name) external onlyOwner{
    IReverseRegistrar(ENSReverseRegistrar).setName(name);
  }

  /// @notice Sets minimum bid increment percentage for auctions
  /// @param percentage Percentage to set the minimum bid increment
  function setMinBidIncrementPercentage(uint256 percentage) public onlyOwner {
    minBidIncrementPercentage = percentage;
  }

  /// @notice Creates a new fixed sale NFT
  /// @dev Fixed sale and auction must both not be active. Only One fixed sale or auction may occur at a time
  /// @param _price The price in WEI the purchaser will pay
  /// @param _tokenURI The URI of the NFT
  function newFixedSale(uint256 _price, string calldata _tokenURI) external onlyOwner {
    require(!fixedSaleActive, "Fixed sale must not be active!");
    require(!biddingActive, "Bidding must not be active!");

    fixedSaleActive = true;
    fixedSalePrice = _price;
    currentTokenURI = _tokenURI;
  }

  /// @notice Buyer purchases the fixed sale NFT
  /// @dev Must send enough ETH to cover the fixedSalePrice. Mints the NFT to the buyer's wallet
  function purchaseFixedSale() payable public {
    require(fixedSaleActive, "Fixed sale must be active!");
    require(msg.value == fixedSalePrice, "Invalid amount sent!");

    tokenURIs[totalSupply() - 1] = currentTokenURI;
    payable(owner()).transfer(msg.value);
    fixedSaleActive = false;
    _safeMint(msg.sender, 1);
  }

  /// @notice Opens a new auction
  /// @dev Fixed sale and auction must both not be active. Only One fixed sale or auction may occur at a time
  /// @param _startingBid The starting bid
  /// @param _tokenURI The URI of the NFT
  function openBidding(uint256 _startingBid, string calldata _tokenURI) external onlyOwner {
    require(!biddingActive, "Bidding must not be active!");
    require(!fixedSaleActive, "Fixed sale must not be active!");

    biddingActive = true;
    // input starting bid in WEI
    startingBid = _startingBid;
    currentTokenURI = _tokenURI;
  }

  /// @notice Places a bid on the current auctioned NFT
  /// @dev Bidders may call this function repeatedly to top up their bids. ETH sent represents the bid amount
  function placeBid() public payable {
    uint256 rake = msg.value * rakePercentage / 100;
    uint256 currentBidAfterRake = msg.value - rake;
    uint256 existingBid = bidPerAddress[currentAuctionID][msg.sender];
    uint256 totalBid = existingBid + currentBidAfterRake;
    uint256 highestBid = bidPerAddress[currentAuctionID][highestBidAddress];

    require(totalBid > startingBid, "Total bid must exceed starting bid");
    require(totalBid >= highestBid + highestBid * minBidIncrementPercentage / 100, "Total bid must exceed or equal highest bid + min bid increment!");

    // adds to existing bid
    bidPerAddress[currentAuctionID][msg.sender] = existingBid + currentBidAfterRake;
    omakasea.transfer(rake);
    highestBidAddress = payable(msg.sender);
  }

  /// @notice Accepts highest bid and closes out auction
  /// @dev Mints the NFT directly to the highest bidder's wallet, resets state
  function acceptBid() public onlyOwner {
    require(biddingActive, "Bidding must be active!");
    uint256 winningBid = bidPerAddress[currentAuctionID][highestBidAddress];
    bidPerAddress[currentAuctionID][highestBidAddress] = 0;

    payable(owner()).transfer(winningBid);
    _safeMint(highestBidAddress, 1);

    tokenURIs[totalSupply() - 1] = currentTokenURI;
    biddingActive = false;
    highestBidAddress = payable(address(0));
    currentAuctionID += 1;
  }

  /// @notice Closes out the auction if nobody has participated
  /// @dev Resets the state and increments the auction ID
  function closeBid() external onlyOwner {
    require(biddingActive, "Bidding must be active!");
    require(highestBidAddress == address(0), "Auction must not have any bidders!");

    biddingActive = false;
    currentAuctionID += 1;    
  }

  /// @notice Bidders withdraw their existing bid per auction ID
  /// @dev Resets the state and increments the auction ID
  /// @param auctionID The auction ID to withdraw from
  function withdrawBid(uint256 auctionID) external {
    require(msg.sender != highestBidAddress, "Cannot withdraw bid as highest bidder!");
    uint256 bidAmount = bidPerAddress[auctionID][msg.sender];
    bidPerAddress[auctionID][msg.sender] = 0;
    uint thisBalance = address(this).balance;

    // safe transfer mechanism, if there is some rounding error and there isn't enought ETH on "paper" to cover a withdraw
    if (bidAmount >= thisBalance) {
      payable(msg.sender).transfer(thisBalance);
    } else {
      payable(msg.sender).transfer(bidAmount);
    }
  }

  receive() external payable {
    if (biddingActive) {
      if (msg.sender == owner()) {
        acceptBid();
        return;
      }
      placeBid();
    } else if (fixedSaleActive) {
      purchaseFixedSale();
    } else {
      revert("No active sale!");
    }
  }

  // emergency use only
  function withdraw() external onlyOwner() {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);

    //reset state if needed
    if (biddingActive) {
      highestBidAddress = payable(address(0));
      biddingActive = false;
      currentAuctionID += 1;
    }
  }
}

// The High Table