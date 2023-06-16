// SPDX-License-Identifier: MIT

/*

  ░█████╗░░█████╗░    ░█████╗░██████╗░██╗░██████╗░██╗███╗░░██╗░█████╗░██╗░░░░░░██████╗
  ██╔══██╗██╔══██╗    ██╔══██╗██╔══██╗██║██╔════╝░██║████╗░██║██╔══██╗██║░░░░░██╔════╝
  ╚██████║╚██████║    ██║░░██║██████╔╝██║██║░░██╗░██║██╔██╗██║███████║██║░░░░░╚█████╗░
  ░╚═══██║░╚═══██║    ██║░░██║██╔══██╗██║██║░░╚██╗██║██║╚████║██╔══██║██║░░░░░░╚═══██╗
  ░█████╔╝░█████╔╝    ╚█████╔╝██║░░██║██║╚██████╔╝██║██║░╚███║██║░░██║███████╗██████╔╝
  ░╚════╝░░╚════╝░    ░╚════╝░╚═╝░░╚═╝╚═╝░╚═════╝░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚══════╝╚═════╝░

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract Originals99 is ERC721Royalty, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // ============ Constants ============

    uint256 private constant DURATION = 24 hours;
    uint256 private constant DURATION_EXTENSION = 15 minutes;
    uint256 private constant DURATION_EXTENSION_ALLOWED_BEFORE_END = 15 minutes;
    uint256 private constant TOTAL_SUPPLY = 99;
    uint256 private constant PRICE_INITIAL = 0.1 ether;
    uint256 private constant MAX_BPS = 10_000; // = 100%
    uint256 private constant MIN_BID_INCREASE_BPS = 1000; // = 10%
    uint96 private constant ROYALTIES_BPS = 700; // = 7%

    address private constant ROYALTIES_RECEIVER = 0xdC62Bd9feF08B47094Fd4b0AE9cBFDF05272f63B;

    // withdrawal accounts
    address private constant FUNDS_RECEIVER_50 = 0xD50c2a4Faa066763127cAc3Ba46fE4817906a9c0; // DAO wallet
    address private constant FUNDS_RECEIVER_45 = 0xc938C5f20aa151ccc854B7C0438e387394Ed4Cb2;
    address private constant FUNDS_RECEIVER_5 = 0x1ABC492f34839d3204D9f1d1078528Ad4611962A;

    // ============ Variables ============

    mapping(uint256 => bool) private soldTokenIds;
    address private winningBidder = address(0);
    uint256 private auctionedTokenId = 0;
    uint256 private currentPrice = 0;
    mapping(uint256 => string) private tokenURIs;
    uint256 private auctionEndTime;

    // ============ Modifiers ============

    modifier onlyActiveAuction() {
        require(auctionedTokenId != 0, "Auction not active");
        _;
    }

    // ============ Events ============

    event AuctionStarted(uint256 tokenId, uint256 endTime);
    event AuctionBidPlaced(uint256 tokenId, address bidder, uint256 bid, uint256 endTime);
    event AuctionFinalized(uint256 tokenId, address winner);

    // ============ Methods ============

    constructor() ERC721("99 Originals", "99ORIG") {
        _setDefaultRoyalty(ROYALTIES_RECEIVER, ROYALTIES_BPS);
    }

    function getAuctionEndTime() public view onlyActiveAuction returns (uint256) {
        return auctionEndTime;
    }

    function getSmallestAllowedBid() public view onlyActiveAuction returns (uint256) {
        if (winningBidder == address(0)) {
            return PRICE_INITIAL;
        }

        return currentPrice + ((currentPrice * MIN_BID_INCREASE_BPS) / MAX_BPS);
    }

    function getInitialPrice() public view onlyActiveAuction returns (uint256) {
        return PRICE_INITIAL;
    }

    function getCurrentPrice() public view onlyActiveAuction returns (uint256) {
        return currentPrice;
    }

    function getWinningBidder() public view onlyActiveAuction returns (address) {
        return winningBidder;
    }

    function getAuctionedTokenId() public view returns (uint256) {
        return auctionedTokenId;
    }

    function isSold(uint256 tokenId) public view returns (bool) {
        return soldTokenIds[tokenId];
    }

    function isAuctionEnd() public view onlyActiveAuction returns (bool) {
        return auctionEndTime <= block.timestamp;
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI_) public onlyOwner {
        require(bytes(tokenURI_).length > 0, "Token URI is mandatory");
        require(tokenId > 0 && tokenId <= TOTAL_SUPPLY, "Invalid token ID");

        tokenURIs[tokenId] = tokenURI_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return tokenURIs[tokenId];
    }

    function isTokenURISetUp(uint256 tokenId) public view returns (bool) {
        require(tokenId > 0 && tokenId <= TOTAL_SUPPLY, "Invalid token ID");

        return bytes(tokenURIs[tokenId]).length != 0;
    }

    function mint(uint256 tokenId, address to) external onlyOwner {
        require(auctionedTokenId == 0, "Current auction is not finalized");
        require(tokenId > 0 && tokenId <= TOTAL_SUPPLY, "Invalid token ID");
        require(!soldTokenIds[tokenId], "Token ID already sold");
        require(bytes(tokenURIs[tokenId]).length > 0, "Token URI not set up");

        soldTokenIds[tokenId] = true;

        _safeMint(to, tokenId);
    }

    function startAuction(uint256 tokenId) external onlyOwner {
        require(auctionedTokenId == 0, "Current auction is not finalized");
        require(tokenId > 0 && tokenId <= TOTAL_SUPPLY, "Invalid token ID");
        require(!soldTokenIds[tokenId], "Token ID already sold");
        require(bytes(tokenURIs[tokenId]).length > 0, "Token URI not set up");

        auctionedTokenId = tokenId;
        auctionEndTime = block.timestamp + DURATION;
        currentPrice = PRICE_INITIAL;

        emit AuctionStarted(tokenId, auctionEndTime);
    }

    function placeBid() external payable onlyActiveAuction nonReentrant {
        require(tx.origin == msg.sender, "Caller cannot be contract");
        require(msg.value >= getSmallestAllowedBid(), "Too small bid");
        require(!isAuctionEnd(), "Auction ended");

        if (block.timestamp + DURATION_EXTENSION_ALLOWED_BEFORE_END >= auctionEndTime) {
            auctionEndTime = block.timestamp + DURATION_EXTENSION;
        }

        if (winningBidder != address(0)) {
            (bool success, ) = winningBidder.call{value: currentPrice}("");
            require(success, "Returning escrowed funds failed");
        }

        currentPrice = msg.value;
        winningBidder = _msgSender();

        emit AuctionBidPlaced(auctionedTokenId, _msgSender(), msg.value, auctionEndTime);
    }

    function finalizeAuction() external onlyActiveAuction onlyOwner {
        require(isAuctionEnd(), "Auction not ended");

        if (winningBidder != address(0)) {
            soldTokenIds[auctionedTokenId] = true;
            _safeMint(winningBidder, auctionedTokenId);
        }

        emit AuctionFinalized(auctionedTokenId, winningBidder);

        currentPrice = 0;
        auctionedTokenId = 0;
        winningBidder = address(0);
    }

    function withdraw() external onlyOwner {
        require(auctionedTokenId == 0, "Withdraw during active auction not allowed");
        require(address(this).balance > 0, "No funds");

        uint256 balance = address(this).balance;

        // 50%
        uint256 split1 = (balance / 100) * 50;
        (bool success1, ) = FUNDS_RECEIVER_50.call{value: split1}("");
        require(success1, "Withdraw transaction #1 failed");

        // 45%
        uint256 split2 = (balance / 100) * 45;
        (bool success2, ) = FUNDS_RECEIVER_45.call{value: split2}("");
        require(success2, "Withdraw transaction #2 failed");

        // 5%
        uint256 split3 = address(this).balance;
        (bool success3, ) = FUNDS_RECEIVER_5.call{value: split3}("");
        require(success3, "Withdraw transaction #3 failed");
    }
}