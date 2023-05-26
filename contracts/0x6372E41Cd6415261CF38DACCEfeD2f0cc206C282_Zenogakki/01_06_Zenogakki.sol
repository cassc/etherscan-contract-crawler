// Project Zenogakki
// Contract developed by Culture Cubs Venture Labs

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract Zenogakki is Ownable, ERC721A, ReentrancyGuard {
  uint256 public constant PRESALE_PRICE = 0.24 ether;
  uint256 public constant MINT_PRICE = 0.28 ether;
  uint256 public constant MAX_COLLECTION_SIZE = 10000;
  uint256 public constant MAX_PUBLIC_SIZE = 7500;
  uint256 public constant MAX_PER_WALLET = 5;
  uint256 public constant MAX_CUT = 6.75 ether;

  uint256 public constant OG_MAX_MINT = 4; // includes 1 free NFT offered on first mint
  uint256 public constant WL_MAX_MINT = 2;

  uint256 public maxPerWallet;
  uint256 public maxCollectionSize;
  uint256 public maxPublicSize;

  uint256 public phase1Start = 1657209600; // Thursday, July 7, 2022 4:00:00 PM GMT
  uint256 public phase2Start = 1657213200; // Thursday, July 7, 2022 5:00:00 PM GMT
  uint256 public publicStart = 1657220400; // Thursday, July 7, 2022 7:00:00 PM GMT
  uint256 public publicEnd   = 1657245600; // Friday, July 8, 2022 2:00:00 AM GMT

  mapping(address => bool) public og;
  mapping(address => bool) public wl1;
  mapping(address => bool) public wl2;

  mapping(address => bool) public ogHasClaimed;

  uint256 revenueCut;
  address cutAddress = 0xAc047cF33CBAcEd70E77Efb41Cff705A31031d26;

  constructor(uint256 toTreasury) ERC721A("Zenogakki", "ZENO") {
    maxCollectionSize = MAX_COLLECTION_SIZE;
    maxPublicSize = MAX_PUBLIC_SIZE;
    maxPerWallet = MAX_PER_WALLET;
    _mintERC2309(msg.sender, toTreasury);
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function mint(uint256 quantity) external payable callerIsUser {
    require(block.timestamp > phase1Start, "Mint has not yet started");
    require(block.timestamp < publicEnd, "Mint is over");
    require(quantity > 0, "Buy at least 1 NFT");
    uint256 maxMint = allowanceForCurrentPhase(msg.sender);

    // any OG minting gets a free NFT.
    uint256 mintQty = quantity;
    if (og[msg.sender] && !ogHasClaimed[msg.sender]) {
      ++mintQty;
      ogHasClaimed[msg.sender] = true;
    }

    require(_totalMinted() + mintQty <= maxPublicSize, "Reached max public supply");
    require(_numberMinted(msg.sender) + mintQty <= maxMint, "cannot mint this quantity");

    uint256 price = PRESALE_PRICE;
    if (block.timestamp > publicStart) {
      price = MINT_PRICE;
    }

    require(msg.value >= price * quantity, "Need to send more ETH.");

    _mint(msg.sender, mintQty);
    refundIfOver(price * quantity);
  }

  function allowanceForCurrentPhase(address minter) internal view returns (uint256) {
    if (block.timestamp > publicStart) {
      return maxPerWallet;
    } else if (og[minter]) {
      return OG_MAX_MINT;
    } else if (wl1[minter] || (block.timestamp > phase2Start && wl2[minter])) {
      return WL_MAX_MINT;
    } else {
      return 0;
    }
  }

  function devMint(address to, uint256 quantity) external onlyOwner {
    require(_totalMinted() + quantity <= maxCollectionSize, "reached max supply");
    _mint(to, quantity);
  }

  function refundIfOver(uint256 price) private {
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  // allows to add or remove addresses from the list.
  function seedOg(address[] calldata addresses, bool allow)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; ++i) {
      og[addresses[i]] = allow;
    }
  }

  function seedWl1(address[] calldata addresses, bool allow)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; ++i) {
      wl1[addresses[i]] = allow;
    }
  }

  function seedWl2(address[] calldata addresses, bool allow)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; ++i) {
      wl2[addresses[i]] = allow;
    }
  }

  // metadata URI
  string private _baseTokenURI = "ipfs://bafybeibnnksw3ugblhjdqjjnbjty7m6hfkzdjt5yl3y6ujes7g25rovkem/";

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setMaxCollectionSize(uint256 maxCollectionSize_) external onlyOwner {
    // Can only be decreased
    require(maxCollectionSize_ < maxCollectionSize);
    maxCollectionSize = maxCollectionSize_;
  }

  function setMaxPublicSize(uint256 maxPublicSize_) external onlyOwner {
    // Can only be decreased
    require(maxPublicSize_ < maxPublicSize);
    maxPublicSize = maxPublicSize_;
  }

  function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
    maxPerWallet = maxPerWallet_;
  }  

  function setPhase1Start(uint256 phase1Start_) external onlyOwner {
    phase1Start = phase1Start_;
  }

  function setPhase2Start(uint256 phase2Start_) external onlyOwner {
    phase2Start = phase2Start_;
  }

  function setPublicStart(uint256 publicStart_) external onlyOwner {
    publicStart = publicStart_;
  }

  function setPublicEnd(uint256 publicEnd_) external onlyOwner {
    publicEnd = publicEnd_;
  }

  function setCutAddress(address cutAddress_) external onlyOwner {
    cutAddress = cutAddress_;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function withdrawCut() external nonReentrant {
    require(msg.sender == cutAddress || msg.sender == owner(), 'You cannot call this function');
    if (revenueCut < MAX_CUT) {
        uint256 cut = MAX_CUT - revenueCut;
        if (cut > address(this).balance) {
            cut = address(this).balance;
        }
        revenueCut += cut;
        (bool cutSuccess, ) = cutAddress.call{value: cut}("");
        require(cutSuccess, "Cut transfer failed.");
    }
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
}