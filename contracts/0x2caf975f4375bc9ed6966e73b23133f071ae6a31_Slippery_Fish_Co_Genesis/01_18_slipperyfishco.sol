// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "erc721a/contracts/ERC721A.sol";

contract Slippery_Fish_Co_Genesis is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using SafeMath for uint256;
  using ECDSA for bytes32;

  uint256 public MAX_SlipperyFishCo;
  uint256 public MAX_SlipperyFishCo_PER_PURCHASE;
  uint256 public MAX_SlipperyFishCo_OG_CAP;
  uint256 public MAX_SlipperyFishCo_FL_CAP;

  uint256 public SlipperyFishCo_OG_PRICE = 0.04 ether;
  uint256 public SlipperyFishCo_FL_PRICE = 0.045 ether;
  uint256 public SlipperyFishCo_PUB_PRICE = 0.055 ether;

  string public tokenBaseURI;
  string public unrevealedURI;

  bool public presaleActive = false;
  bool public mintActive = false;
  bool public giftActive = false;
  bool public passActive = false;

  mapping(address => uint256) private OGAddressMintCount;
  mapping(address => uint256) private FLAddressMintCount;

  constructor(
    uint256 _maxSlipperyFishCo,
    uint256 _maxSlipperyFishCoPerPurchase,
    uint256 _maxSlipperyFishCoOGCap,
    uint256 _maxSlipperyFishCoFLCap
  ) ERC721A("Slippery Fish Co Genesis", "SFC") {
    MAX_SlipperyFishCo = _maxSlipperyFishCo;
    MAX_SlipperyFishCo_PER_PURCHASE = _maxSlipperyFishCoPerPurchase;
    MAX_SlipperyFishCo_OG_CAP = _maxSlipperyFishCoOGCap;
    MAX_SlipperyFishCo_FL_CAP = _maxSlipperyFishCoFLCap;
  }

  function setOGPrice(uint256 _newPrice) external onlyOwner {
    SlipperyFishCo_OG_PRICE = _newPrice;
  }

  function setFLPrice(uint256 _newPrice) external onlyOwner {
    SlipperyFishCo_FL_PRICE = _newPrice;
  }

  function setPUBPrice(uint256 _newPrice) external onlyOwner {
    SlipperyFishCo_PUB_PRICE = _newPrice;
  }

  function setOGCap(uint256 _newPresaleCap) external onlyOwner {
    MAX_SlipperyFishCo_OG_CAP = _newPresaleCap;
  }

  function setFLCap(uint256 _newPresaleCap) external onlyOwner {
    MAX_SlipperyFishCo_FL_CAP = _newPresaleCap;
  }

  function setMaxPerPurchase(uint256 _newMaxPerPurchase) external onlyOwner {
    MAX_SlipperyFishCo_PER_PURCHASE = _newMaxPerPurchase;
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

  function passHolderMint(uint256 _quantity) external payable nonReentrant {
    require(passActive, "Pass holder mint is not active");
    require(getPassBalance(msg.sender) > 0, "no pass held");
    require(_quantity <= MAX_SlipperyFishCo_OG_CAP, "This would exceed the maximum SlipperyFishCo you are allowed to mint in presale");
    require(msg.value >= SlipperyFishCo_OG_PRICE * _quantity, "The ether value sent is not correct");
    require(OGAddressMintCount[msg.sender].add(_quantity) <= MAX_SlipperyFishCo_OG_CAP, "This purchase would exceed the maximum SlipperyFishCo you are allowed to mint in the presale");
    OGAddressMintCount[msg.sender] += _quantity;
    _safeMintSlipperyFishCo(_quantity);
  }

  function giftMint(uint256 _quantity, address _giftAddress) external onlyOwner {
    require(giftActive, "Gift is not active");

    _giftMintSlipperyFishCo(_quantity, _giftAddress);
  }

  function _giftMintSlipperyFishCo(uint256 _quantity, address _giftAddress) internal {
    require(_quantity > 0, "You must mint at least 1 SlipperyFishCo");
    require(_totalMinted() + _quantity <= MAX_SlipperyFishCo, "This gift would exceed max supply of SlipperyFishCo");
    require(_quantity <= MAX_SlipperyFishCo_PER_PURCHASE, "Quantity is more than allowed per transaction.");

    _safeMint(_giftAddress, _quantity);
  }

  function presaleMint(uint256 _quantity, bytes calldata _presaleSignature) external payable nonReentrant {
    require(presaleActive, "Presale is not active");
    require(verifyOwnerSignature(keccak256(abi.encode(msg.sender)), _presaleSignature), "Invalid presale signature");
    require(_quantity <= MAX_SlipperyFishCo_FL_CAP, "This would exceed the maximum SlipperyFishCo you are allowed to mint in presale");
    require(msg.value >= SlipperyFishCo_FL_PRICE * _quantity, "The ether value sent is not correct");
    require(FLAddressMintCount[msg.sender].add(_quantity) <= MAX_SlipperyFishCo_FL_CAP, "This purchase would exceed the maximum SlipperyFishCo you are allowed to mint in the presale");

    FLAddressMintCount[msg.sender] += _quantity;
    _safeMintSlipperyFishCo(_quantity);
  }

  function publicMint(uint256 _quantity) external payable nonReentrant {
    require(mintActive, "Public sale is not active.");
    require(tx.origin == msg.sender, "The caller is another contract");
    require(msg.value >= SlipperyFishCo_PUB_PRICE * _quantity, "The ether value sent is not correct");

    _safeMintSlipperyFishCo(_quantity);
  }

  function _safeMintSlipperyFishCo(uint256 _quantity) internal {
    require(_quantity > 0, "You must mint at least 1 SlipperyFishCo");
    require(_quantity <= MAX_SlipperyFishCo_PER_PURCHASE, "Quantity is more than allowed per transaction.");
    require(_totalMinted() + _quantity <= MAX_SlipperyFishCo, "This purchase would exceed max supply of SlipperyFishCo");

    _safeMint(msg.sender, _quantity);
  }

  function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
    require(recipients.length > 0, "No recipients");
    require(recipients.length == amounts.length, "amounts argument size mismatched");

    for (uint256 i = 0; i < recipients.length; i++) {
      transferFrom(msg.sender, recipients[i], amounts[i]);
    }
  }

  function getPassBalance(address _user) public view
      returns (uint256 _passBalance)
  {
      uint256 passBalance = IERC721Enumerable(
          0x21F59d850b00866375B0d914Cb3Ce6A01ce54701
      ).balanceOf(_user);
      return passBalance;
  }

  function setPassActive(bool _active) external onlyOwner {
    passActive = _active;
  }

  function setPresaleActive(bool _active) external onlyOwner {
    presaleActive = _active;
  }

  function setGiftActive(bool _active) external onlyOwner {
    giftActive = _active;
  }

  function setMintActive(bool _active) external onlyOwner {
    mintActive = _active;
  }

  function withdraw() public onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    payable(0x7A3b398dbE5429bA809ccfb73F5Df4eD82eB1C87).transfer((balance*5)/100);
    payable(0x82416fA9D2a26267836A06773e8C3F4Be792BEbe).transfer((balance*17)/100);
    payable(0xC11778679A4B7be52f63be6b152643549db2C246).transfer((balance*25)/100);
    payable(0x4aC4A6D11553196E55325BaB5b38Dc9A77581825).transfer((balance*5)/100);
    payable(0x33779Ae970773A76ED5799fF4B6417275CCaBA29).transfer((balance*10)/100);
    payable(0xE2Dd85b41bF052800034Dff54f2FD80973efF942).transfer((balance*10)/100);
    payable(0x9B8AF273FB41a2a8893591c88F142977b80e4E77).transfer((balance*5)/100);
    payable(0x721c60038f6Da862c8F686bCFA89CA8fad9B7677).transfer((balance*23)/100);
  }

  function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
    return hash.toEthSignedMessageHash().recover(signature) == owner();
  }
}