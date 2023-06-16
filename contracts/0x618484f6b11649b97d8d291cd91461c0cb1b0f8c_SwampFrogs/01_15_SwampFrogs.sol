// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwampFrogs is ERC721Enumerable, ReentrancyGuard, Ownable {
  using ECDSA for bytes32;

  // Minting values
  uint256 public constant MAX_SUPPLY = 9999;
  uint256 public constant MAX_PRESALE_AMOUNT = 1;
  uint256 public constant MAX_MINT_AMOUNT = 10;

  address payable constant CASHOUT_WALLET = payable(0x8672b0EBC3Ec7525e3a973BE338298E28C273FC2);

  // Reservation values
  bool public reserveClaimed = false;
  uint256 public constant RESERVE_AMOUNT = 99;
  uint16 public constant PRESALE_ID = 10085;
  address public constant PRESALE_SIGNER = 0x95223bA4Dd076588aC34546367839D06720D682b;

  // Mint cost = 0.05 eth
  uint256 public constant MINT_COST = 50000000000000000;

  // Sale values
  bool private _presaleActive = false;
  bool private _publicSaleActive = false;
  bool private _isActive = false;

  string private _name = "Swamp Frogs";
  string private _sybmol = "FROGS";

  // Presale claim mapping
  mapping (address => bool) private _claimedPresale;

  // URI
  string private _uri = "https://api.swampfrogs.io/token/";

  constructor() ERC721("Swamp Frogs", "FROGS") {}

  // Private mint
  function presaleMint(uint16 _tokenCount, uint16 _purchaseLimit, bytes memory _signature) external nonReentrant payable {
    require(_isActive, "Sale must be active");
    require(_presaleActive, "Presale must be active");
    require(_tokenCount > 0, "Token count must be at least 0");
    require(_tokenCount <= MAX_PRESALE_AMOUNT, "Token count exceeds purchase limit");
    require((MINT_COST * _tokenCount) == msg.value, "Incorrect ETH value sent");
    require(!_claimedPresale[msg.sender], "User has already claimed from presale");

    bytes32 message = keccak256(abi.encodePacked(msg.sender, _tokenCount, _purchaseLimit, PRESALE_ID));
    require(message.toEthSignedMessageHash().recover(_signature) == PRESALE_SIGNER, "whitelist is not signed");

    _claimedPresale[msg.sender] = true;

    _mintFrogs(_tokenCount, msg.sender);
  }

  // Public mint
  function publicMint(uint256 _tokenCount) external nonReentrant payable {
    require(_isActive, "Sale must be active");
    require(_publicSaleActive, "Public sale must be active");
    require(_tokenCount > 0, "Token count must be at least 1");
    require(_tokenCount <= MAX_MINT_AMOUNT, "Token count is greather than the max allowed");
    require((MINT_COST * _tokenCount) == msg.value, "Incorrect ETH value sent");

    _mintFrogs(_tokenCount, msg.sender);
  }

  // Reserve
  function claimReserved() external onlyOwner {
    require(!reserveClaimed, "The reserved frogs have already been claimed");

    reserveClaimed = true;
    _mintFrogs(RESERVE_AMOUNT, msg.sender);
  }

  // Mints a specified number of frogs to a given address
  function _mintFrogs(uint256 _tokenCount, address _to) private {
    uint256 _totalSupply = totalSupply();

    require(_totalSupply + _tokenCount <= MAX_SUPPLY, "Mint exceeds max token supply");

    for (uint i = 0; i < _tokenCount; i++) {
      uint256 tokenId = _totalSupply + i;

      _safeMint(_to, tokenId + 1);
    }
  }

  // Admin Functions
  function toggleSale() external onlyOwner {
    _isActive = !_isActive;
  }

  function togglePublicSale() external onlyOwner {
    _publicSaleActive = !_publicSaleActive;
  }

  function togglePresale() external onlyOwner {
    _presaleActive = !_presaleActive;
  }

  function setBaseURI(string memory uri) external onlyOwner {
    _uri = uri;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    CASHOUT_WALLET.transfer(balance);
  }

  function _baseURI() 
    internal view override returns (string memory) {
        return _uri;
    }
}