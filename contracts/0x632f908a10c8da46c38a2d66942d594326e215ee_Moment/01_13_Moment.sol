//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Moment is ERC721, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;

  address public neortAddress;
  address public vesselAddress;
  bool private _isOnSale;
  uint256 public startDate;
  uint256 public endDate;
  uint256 public nftPrice = 0.05 ether;
  string private _baseTokenURI;
  mapping(uint256 => bool) private _neortMintedTokens;
  mapping(uint256 => bool) private _vesselMintedTokens;

  Counters.Counter private _tokenIdTracker;

  constructor(
    string memory baseTokenURI,
    address neort,
    address vessel,
    uint256 start,
    uint256 end
  ) ERC721("Moment", "MOMENT") {
    _baseTokenURI = baseTokenURI;
    startDate = start;
    endDate = end;
    neortAddress = neort;
    vesselAddress = vessel;
  }

  modifier checkMintable(uint256 quantity) {
    require(_tokenIdTracker.current() + quantity <= 1000, "Moment: Sold out");
    _;
  }

  function setIsOnSale(bool isOnSale) external onlyOwner {
    _isOnSale = isOnSale;
  }

  function _incrementalMint(address to) internal {
    uint256 tokenId = _tokenIdTracker.current();
    _safeMint(to, tokenId);
    _tokenIdTracker.increment();
  }

  function mint() external payable nonReentrant checkMintable(1) {
    require(_isOnSale, "Moment: Currently unavailable");
    require(msg.value == nftPrice, "Moment: Invalid msg.value");
    _incrementalMint(msg.sender);
  }

  function bulkMint(uint256 quantity)
    external
    payable
    nonReentrant
    checkMintable(quantity)
  {
    require(_isOnSale, "Moment: Currently unavailable");
    require(msg.value == nftPrice * quantity, "Moment: Invalid msg.value");
    for (uint256 i = 0; i < quantity; i++) {
      _incrementalMint(msg.sender);
    }
  }

  function giveaway(address to) external onlyOwner checkMintable(1) {
    _incrementalMint(to);
  }

  function giveawayForNEORTHolder(uint256 neortTokenId)
    external
    nonReentrant
    checkMintable(1)
  {
    require(
      IERC721(neortAddress).ownerOf(neortTokenId) == msg.sender,
      "Moment: You must have NEORT or Vessel token"
    );
    require(!_neortMintedTokens[neortTokenId], "Moment: Already claimed");
    _neortMintedTokens[neortTokenId] = true;
    _incrementalMint(msg.sender);
  }

  function giveawayForVesselHolder(uint256 vesselTokenId)
    external
    nonReentrant
    checkMintable(1)
  {
    require(
      IERC721(vesselAddress).ownerOf(vesselTokenId) == msg.sender,
      "Moment: You must have NEORT or Vessel token"
    );
    require(!_vesselMintedTokens[vesselTokenId], "Moment: Already claimed");
    _vesselMintedTokens[vesselTokenId] = true;
    _incrementalMint(msg.sender);
  }

  function withdraw() external nonReentrant onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function totalSupply() external view returns (uint256) {
    return _tokenIdTracker.current();
  }

  function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
    _baseTokenURI = baseTokenURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    require(_exists(tokenId), "Moment: URI query for nonexistent token");
    return
      string(
        bytes.concat(
          bytes(_baseTokenURI),
          bytes(Strings.toString(tokenId)),
          bytes(".json")
        )
      );
  }
}