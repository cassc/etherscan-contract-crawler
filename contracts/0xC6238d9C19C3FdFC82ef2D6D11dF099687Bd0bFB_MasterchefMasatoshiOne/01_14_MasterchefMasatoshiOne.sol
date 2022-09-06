// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IReverseRegistrar.sol";
import "./ERC721.sol";

contract MasterchefMasatoshiOne is ERC721, Ownable {
  address public immutable ENSReverseRegistrar = 0x084b1c3C81545d370f3634392De611CaaBFf8148;
  address payable public immutable omakasea = payable(0x9A88d47EBb4038e9d8479A9535FCCa0d3F8Ba73B);

  uint256 public immutable rakePercentage = 1;
  uint256 public minBidIncrementPercentage = 1;
  uint256 public startingBid = 0;
  uint256 public currentAuctionID = 0;

  bool public biddingActive = false;

  string public currentTokenURI;
  address payable public highestBidAddress;
  // first uint256 represents the current auction ID
  mapping(uint256 => mapping(address => uint256)) public bidPerAddress;
  mapping(uint256 => string) tokenURIs;

  constructor(
      string memory _name,
      string memory _symbol
  ) ERC721(_name, _symbol, 1) {}

  function tokenURI(uint256 tokenID) public view override returns (string memory) {
      require(_exists(tokenID), "z");
      return tokenURIs[tokenID];
  }

  function addReverseENSRecord(string memory name) external onlyOwner{
    IReverseRegistrar(ENSReverseRegistrar).setName(name);
  }

  function execMint(uint amount, address recipient) public onlyOwner {
    _safeMint(recipient, amount);
  }

  function setMinBidIncrementPercentage(uint256 percentage) public onlyOwner {
    minBidIncrementPercentage = percentage;
  }  

  function openBidding(uint256 _startingBid, string calldata _tokenURI) public onlyOwner {
    require(!biddingActive, "Bidding is already active!");
    biddingActive = true;
    // input starting bid in ETH
    startingBid = _startingBid * 10 ** 18;
    currentTokenURI = _tokenURI;
  }

  function acceptBid() public onlyOwner {
    require(biddingActive, "Bidding is inactive!");
    uint256 winningBid = bidPerAddress[currentAuctionID][highestBidAddress];
    bidPerAddress[currentAuctionID][highestBidAddress] = 0;

    payable(owner()).transfer(winningBid);
    _safeMint(highestBidAddress, 1);

    tokenURIs[totalSupply() - 1] = currentTokenURI;
     biddingActive = false;
     highestBidAddress = payable(address(0));
     currentAuctionID += 1;
  }

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
    require(biddingActive, "Bidding is inactive!");
    if (msg.sender == owner()) {
      acceptBid();
      return;
    }
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

  // emergency use only
  function withdraw() external onlyOwner() {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}

// The High Table