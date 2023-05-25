// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "erc721a/contracts/ERC721A.sol";
import "./INFTW_Whitelist.sol";

contract NFTW_Genesis_Avatars is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  /**
   * @dev @iamarkdev was here
   * */

  INFTW_Whitelist private whitelist;
  uint256 private whitelistPassTypeId = 1;

  uint256 public MAX_AVATARS;
  uint256 public MAX_AVATARS_PER_PURCHASE;
  uint256 public constant RESERVED_AVATARS = 100;

  uint256 public constant STARTING_PRICE = 1 ether;
  uint256 public constant ENDING_PRICE = 0.4 ether;

  uint256 public publicSaleDuration;
  uint256 public publicSaleStartTime;

  string public tokenBaseURI;
  string public unrevealedURI;

  bool public presaleActive = false;
  bool public mintActive = false;
  bool public reservesMinted = false;

  /**
   * @dev Contract Methods
   */

  constructor(
    address _nftwWhitelist,
    uint256 _maxAvatars,
    uint256 _maxAvatarsPerPurchase
  ) ERC721A("NFT Worlds Genesis Avatars", "AVATARS") {
    whitelist = INFTW_Whitelist(_nftwWhitelist);
    MAX_AVATARS = _maxAvatars;
    MAX_AVATARS_PER_PURCHASE = _maxAvatarsPerPurchase;
  }

  /************
   * Metadata *
   ************/

  function setTokenBaseURI(string memory _baseURI) external onlyOwner {
    tokenBaseURI = _baseURI;
  }

  function setUnrevealedURI(string memory _unrevealedUri) external onlyOwner {
    unrevealedURI = _unrevealedUri;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    bool revealed = bytes(tokenBaseURI).length > 0;

    if (!revealed) {
      return unrevealedURI;
    }

    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
  }

  /****************
   * Presale Mint *
   ****************/

  function presaleMint(uint256 _quantity) external payable nonReentrant {
    require(presaleActive, "Presale is not active");
    require(msg.value >= ENDING_PRICE * _quantity, "The ether value sent is not correct");

    whitelist.burnTypeForOwnerAddress(whitelistPassTypeId, _quantity, msg.sender);

    _safeMintAvatars(_quantity);
  }

  /***************
   * Public Mint *
   ***************/

  function publicMint(uint256 _quantity) external payable nonReentrant {
    require(mintActive, "Public sale is not active.");
    require(tx.origin == msg.sender, "The caller is another contract");

    uint256 mintCost = getMintPrice() * _quantity;
    require(msg.value >= mintCost, "The ether value sent is not correct");

    _safeMintAvatars(_quantity);

    if (msg.value > mintCost) {
      Address.sendValue(payable(msg.sender), msg.value - mintCost);
    }
  }

  function getMintPrice() public view returns (uint256) {
    require(mintActive, "Public sale is not active");
    uint256 elapsed = _getElapsedSaleTime();

    if (elapsed >= publicSaleDuration) {
      return ENDING_PRICE;
    } else {
      uint256 currentPrice = STARTING_PRICE - ((STARTING_PRICE - ENDING_PRICE) * elapsed) / publicSaleDuration;
      return currentPrice > ENDING_PRICE ? currentPrice : ENDING_PRICE;
    }
  }

  /****************
   * Mint Helpers *
   ****************/

  function _getElapsedSaleTime() internal view returns (uint256) {
    return publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0;
  }

  function _safeMintAvatars(uint256 _quantity) internal {
    require(_quantity > 0, "You must mint at least 1 Genesis Avatar");
    require(_quantity <= MAX_AVATARS_PER_PURCHASE, "Quantity is more than allowed per transaction.");
    require(_totalMinted() + _quantity <= MAX_AVATARS, "This purchase would exceed max supply of Genesis Avatars");

    _safeMint(msg.sender, _quantity);
  }

  /*
   * Note: Reserved avatars will be minted immediately after the presale ends
   * but before the public sale begins.
   */

  function mintReservedAvatars(address _toAddress) external onlyOwner {
    require(!reservesMinted, "Reserves have already been minted.");
    require(_totalMinted() + RESERVED_AVATARS <= MAX_AVATARS, "This mint would exceed max supply of Genesis Avatars");

    _safeMint(_toAddress, RESERVED_AVATARS);

    reservesMinted = true;
  }

  function setWhitelistContract(address _whitelist) external onlyOwner {
    whitelist = INFTW_Whitelist(_whitelist);
  }

  function setWhitelistPassTypeId(uint256 _whitelistPassTypeId) external onlyOwner {
    whitelistPassTypeId = _whitelistPassTypeId;
  }

  function setPresaleActive(bool _active) external onlyOwner {
    presaleActive = _active;
  }

  function setPublicSaleActive(bool _active, uint256 _publicSaleDuration) external onlyOwner {
    presaleActive = false;
    mintActive = _active;

    if (_publicSaleDuration > 0) {
      publicSaleDuration = _publicSaleDuration;
      publicSaleStartTime = block.timestamp;
    }
  }

  /**************
   * Withdrawal *
   **************/

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}