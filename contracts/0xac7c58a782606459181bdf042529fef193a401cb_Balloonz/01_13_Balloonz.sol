// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;


//      ,-""""-.
//    ,'        `.
//   /       (_)  \
//  :              :
//  \              /
//   \            /
//    `.        ,'
//      `.    ,'
//        `.,'
//         /\`.   ,-._ Hi, there!
//             `-'     


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract Balloonz is Ownable, ERC721A, ReentrancyGuard {
  uint256 public constant MAX_SUPPLY = 7777;

  uint256 private constant MAX_MINTS_PER_TX_PUBLIC = 10;
  uint256 private PRICE = 0.077 ether;

  string private _baseTokenURI;

  bool public IS_PUBLIC_ACTIVE = false;
  bool public IS_PRESALE_ACTIVE = false;


  mapping(address => uint256) private whitelist;

  constructor() ERC721A("Balloonz", "BALLOONZ") {}

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function whitelistMint(uint256 quantity) external payable {
    require(totalSupply() + quantity <= MAX_SUPPLY, "reached max supply");
    require(IS_PRESALE_ACTIVE, "whitelist sale has not begun yet");
    require(msg.value >= PRICE * quantity, "not enough funds.");
    require(whitelist[msg.sender] - quantity >= 0, "not eligible for whitelist mint");
    whitelist[msg.sender] -= quantity;
    _safeMint(msg.sender, quantity);
  }

  function mint(uint256 quantity) external payable callerIsUser() {
    require(totalSupply() + quantity <= MAX_SUPPLY, "reached max supply");
    require(IS_PUBLIC_ACTIVE, "public sale has not begun yet");
    require(msg.value >= PRICE * quantity, "not enough funds.");
    require(quantity <= MAX_MINTS_PER_TX_PUBLIC, "you can only mint 10 per transaction");
    _safeMint(msg.sender, quantity);
  }

  function seedWhitelist(address[] memory addresses) external onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelist[addresses[i]] = 2;
    }
  }

  function getWhitelistSpotFor(address _address) external view returns (uint256) {
    return whitelist[_address];
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function reserve(uint256 n) public onlyOwner {
    _safeMint(msg.sender, n);
  }

  function setSalePrice(uint256 _price) external onlyOwner {
    PRICE = _price;
  }

  function setPublicSaleState(bool _state) external onlyOwner {
    IS_PUBLIC_ACTIVE = _state;
  }
  
  function setPresaleState(bool _state) external onlyOwner {
    IS_PRESALE_ACTIVE = _state;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return ownershipOf(tokenId);
  }
}