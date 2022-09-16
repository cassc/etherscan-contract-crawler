// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// @title: Historical Moments: The Merge
// @author: @todo fill this out
// @see Ethereum Logo originally sourced from https://commons.wikimedia.org/wiki/File:Ethereum_logo_2014.svg
//      by Ethereum Foundation is licensed under CC BY 3.0

//
// ,-----.      .--.    .----.  ,-----.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.      .-.   
// |   ___)   /  _  \  (___  |  |   ___)   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \   /    \  
// |  |      . .' `. ;     | |  |  |      |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; |  .-. ; 
// |  '-.    | \   | |     | |  |  '-.    | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | 
// '---.  .   \ `.(_.'     | |  '---.  .  | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | 
//  ___ `  \  /`'. '.      | |   ___ `  \ | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | | |  | | 
// (   ) | | | |  `\ |     | |  (   ) | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | | '  | | 
//  ; `-'  / ; '._,' '     | |   ; `-'  / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / '  `-' / 
//   '.__.'   '.___.'     (___)   '.__.'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'   `.__,'  
//                                                                                                                                                                                                           

// Note from Author:
// Will likely just open it via Etherscan minting until a frontend can be built
// Wanna watch the countdown live too and not code and test this rn...
//
// But here's the gist:
// Have wanted to explore generative art (like many of you) for a while, but no time
// Had time during BM this year, many were on the Playa, while these contracts were getting buitl
// Celebrating the TDD in style with some fun SVG motions, colors, randomization and generative metadata traits
//
// 100 free mints (max 1 per addy, plz dont sybil attack this)  =)
// Max 487 @ 0.05875 ETH
//
// Then the exciting bits (if anyone cares)...
// Once (if) the first 587 sell out, then a waitlist forms
// Waitlist is 0.069 ETH
// BUT... existing Collectors are the only ones that get to decide whether to let waitlisters join
// There's a cost to call this method, so the contract will keep its base fee (0.05875 ETH) and the rest (the tip)
// Goes to the Collector that let the waitlister(s) in by calling `mintFromWaitlist(1)`
// Tip should cover gas cost, plus a little more as a thank you from those waitlisted and let in
// 
// If you're on the waitlist, you may exit and get back your mint fee (less gas)
// any time until an existing Collector let's you in
//
// Thank you to all the devs and larger community for getting us this far!!!
// <3

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./ArtCreator.sol";

contract HistoricalMoments_Merge is ERC721, Ownable, ReentrancyGuard, ArtCreator {
    using SafeMath for uint8;
    using SafeMath for uint16;
    using SafeMath for uint128;
    using SafeMath for uint256;

    uint16 public constant MAX_TOKENS = 5875;
    uint16 public constant MAX_TOKENS_INITIAL = 587;
    uint8 public constant FREE_MINT_LIMIT = 100;
    uint256 public constant MAX_BLOCK = 15750000;
    uint128 private _mintFeeWei = 58750000000000000; // .05875 ETH
    uint128 private _mintWaitlistFeeWei = 69000000000000000; // .069 ETH

    // Need quick lookup for user to withdraw
    mapping(address => bool) public waitlistMap;

    // FIFO queue for getting minted from waitlist
    address[] public waitlist;
    uint16 private _nextWaitlistPos = 0;

    // to keep track of unspent bal
    uint256 private _pendingWaitlist = 0;

    // Keep track of the total number of NFTs minted.
    // Each NFT will have an unique Id.
    uint256 private _nextTokenId = 1;

    // Allow for starting/pausing sale
    bool public mintActive = true;

    modifier onlyCollector() {
        require(balanceOf(msg.sender) > 0, "Caller is not a collector");
        _;
    }

    modifier onlyWaitlist() {
        require(isWaitlist(msg.sender));
        _;
    }

    constructor() ERC721("Historical Moments: The Merge", "HMMERGE") {}

    /***************
     * Public Mint *
     ***************/

    function mint() external payable nonReentrant {
        require(totalSupply() < MAX_TOKENS_INITIAL, "All minted, try waitlist");
        uint256 mintPrice = getMintPrice();
        require(msg.value >= mintPrice, "Mint fee too low");

        _safeMint(msg.sender, _nextTokenId++);
    }

    function getMintPrice() public view returns (uint256) {
        require(mintActive, "Sale hasn't started");

        // limit free mint to 1 per address
        if (totalSupply() < FREE_MINT_LIMIT && balanceOf(msg.sender) == 0) {
            return 0;
        } else if (totalSupply() < MAX_TOKENS_INITIAL) {
            return _mintFeeWei;
        } else {
            return _mintWaitlistFeeWei;
        }
    }

    /**********************
     * Waitlist post-mint *
     **********************/

    function joinWaitlist() external payable nonReentrant {
        require(totalSupply() >= MAX_TOKENS_INITIAL, "Waitlist not started, use mint");
        require(totalSupply() < MAX_TOKENS, "All art in collection was minted");
        require(block.number <= MAX_BLOCK, "Waitlist period ended");
        require(msg.value >= _mintWaitlistFeeWei, "Mint fee too low");
        require(isWaitlist(msg.sender) == false, "Already on waitlist");

        // address is active waitlist (again)
        waitlistMap[msg.sender] = true;

        // pushes address, even if existed before and minted
        waitlist.push(msg.sender);

        _pendingWaitlist++;
    }

    function mintFromWaitlist(uint256 _quantity) external onlyCollector {
        // bound by arr size
        require(_quantity > 0, "Quantity cannot be zero");
        uint256 quantity = Math.min(_quantity, waitlist.length - _nextWaitlistPos);
        require(quantity > 0, "No one in queue");
        uint256 end = _nextWaitlistPos.add(quantity);

        while (_nextWaitlistPos < end) {
            address account = waitlist[_nextWaitlistPos];
            if (isWaitlist(account)) {
                waitlistMap[account] = false;
                _safeMint(account, _nextTokenId++);
            }
            _nextWaitlistPos++;
        }
        _pendingWaitlist -= quantity;

        // send tips to caller
        uint256 tipPerMint = _mintWaitlistFeeWei.sub(_mintFeeWei);
        uint256 amount = tipPerMint.mul(quantity);
        payable(msg.sender).transfer(amount);
    }

    function isWaitlist(address account) public view returns (bool) {
        if (waitlistMap[account]) {
            return true;
        }
        return false;
    }

    /************
     * Metadata *
     ************/

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return generateMetadata(tokenId, MAX_TOKENS);
    }

    /****************
     * Mint Helpers *
     ****************/

    function totalSupply() public view virtual returns (uint256) {
        return _nextTokenId - 1;
    }

    function setMintActive(bool _active) public onlyOwner {
        mintActive = _active;
    }

    /**************
     * Withdrawal *
     **************/

    // for waitlist
    function exitWaitlist() public payable nonReentrant {
        require(isWaitlist(msg.sender), "Not on waitlist");
        waitlistMap[msg.sender] = false;
        _pendingWaitlist--;
        payable(msg.sender).transfer(_mintWaitlistFeeWei);
    }

    function withdrawAll() public payable onlyOwner {
        // dont allow transfer of un-minted waitlist
        uint256 reserved = _mintWaitlistFeeWei.mul(_pendingWaitlist);
        uint256 amount = address(this).balance.sub(reserved);
        payable(msg.sender).transfer(amount);
    }

    function withdrawAllLost() public payable onlyOwner {
        // only enable withdrawal of waitlist eth if left here for ~5 yrs
        require(block.number > MAX_BLOCK.add(10**7), "Period not started");
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }
}