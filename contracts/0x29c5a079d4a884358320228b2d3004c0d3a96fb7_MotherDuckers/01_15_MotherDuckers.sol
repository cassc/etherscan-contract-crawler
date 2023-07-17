// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MotherDuckers is ERC721, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using ECDSA for bytes32;
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 public MAX_Mother_Duckers;
  uint256 public MAX_Mother_Duckers_PER_PURCHASE;
  uint256 public MAX_Mother_Duckers_WHITELIST_CAP;
  uint256 public Mother_Duckers_PRICE = 0.025 ether;
  uint256 public constant RESERVED_Mother_Duckers = 50;

  string public tokenBaseURI;
  string public unrevealedURI;
  bool public presaleActive = false;
  bool public mintActive = false;
  bool public reservesMinted = false;

  mapping(address => uint256) private whitelistAddressMintCount;

  Counters.Counter public tokenSupply;

  constructor(
    uint256 _maxMotherDuckers,
    uint256 _maxMotherDuckersPerPurchase,
    uint256 _maxMotherDuckersWhitelistCap
  ) ERC721("MotherDuckers", "MDKR") {
    MAX_Mother_Duckers = _maxMotherDuckers;
    MAX_Mother_Duckers_PER_PURCHASE = _maxMotherDuckersPerPurchase;
    MAX_Mother_Duckers_WHITELIST_CAP = _maxMotherDuckersWhitelistCap;
  }

  function setPrice(uint256 _newPrice) external onlyOwner {
    Mother_Duckers_PRICE = _newPrice;
  }

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
  function presaleMint(uint256 _quantity, bytes calldata _whitelistSignature) external payable nonReentrant {
    require(presaleActive, "Presale is not active");
    require(verifyOwnerSignature(keccak256(abi.encode(msg.sender)), _whitelistSignature), "Invalid whitelist signature");
    require(_quantity <= MAX_Mother_Duckers_WHITELIST_CAP, "You can only mint a maximum of 3 for presale");
    require(whitelistAddressMintCount[msg.sender].add(_quantity) <= MAX_Mother_Duckers_WHITELIST_CAP, "This purchase would exceed the maximum Mother Duckers you are allowed to mint in the presale");

    whitelistAddressMintCount[msg.sender] += _quantity;
    _safeMintMotherDuckers(_quantity);
  }

  function publicMint(uint256 _quantity) external payable nonReentrant {
    require(mintActive, "Sale is not active.");
    require(_quantity <= MAX_Mother_Duckers_PER_PURCHASE, "Quantity is more than allowed per transaction.");

    _safeMintMotherDuckers(_quantity);
  }

  function _safeMintMotherDuckers(uint256 _quantity) internal {
    require(_quantity > 0, "You must mint at least 1 Mother Duckers");
    require(tokenSupply.current().add(_quantity) <= MAX_Mother_Duckers, "This purchase would exceed max supply of Mother Duckers");
    require(msg.value >= Mother_Duckers_PRICE.mul(_quantity), "The ether value sent is not correct");

    for (uint256 i = 0; i < _quantity; i++) {
      uint256 mintIndex = tokenSupply.current();

      if (mintIndex < MAX_Mother_Duckers) {
        tokenSupply.increment();
        _safeMint(msg.sender, mintIndex);
      }
    }
  }

  function mintReservedMotherDuckers() external onlyOwner {
    require(!reservesMinted, "Reserves have already been minted.");
    require(tokenSupply.current().add(RESERVED_Mother_Duckers) <= MAX_Mother_Duckers, "This mint would exceed max supply of Mother Duckers");

    for (uint256 i = 0; i < RESERVED_Mother_Duckers; i++) {
      uint256 mintIndex = tokenSupply.current();

      if (mintIndex < MAX_Mother_Duckers) {
        tokenSupply.increment();
        _safeMint(msg.sender, mintIndex);
      }
    }

    reservesMinted = true;
  }

  function setPresaleActive(bool _active) external onlyOwner {
    presaleActive = _active;
  }

  function setMintActive(bool _active) external onlyOwner {
    mintActive = _active;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
    return hash.toEthSignedMessageHash().recover(signature) == owner();
  }
}