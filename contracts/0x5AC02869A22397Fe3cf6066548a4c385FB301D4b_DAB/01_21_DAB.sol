// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DAB is
  ERC721,
  PaymentSplitter,
  Pausable,
  Ownable,
  ReentrancyGuard
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenSupply;
  uint64 public constant MAX_SUPPLY = 222;
  uint64 public constant WHITELIST_FREEMINT = 22;
  uint64 public constant WHITELIST = 200;
  uint64 public publicRedeemedCount;
  uint64 public privateRedeemedCount;
  uint256 public PRICE = 0.01 ether;

  mapping(address => uint256) public privateRedeemed;
  mapping(address => uint256) public publicRedeemed;

  WorkflowStatus public workflow;

  event PrivateMint(address indexed _minter, uint256 _amount, uint256 _price);
  event PublicMint(address indexed _minter, uint256 _amount, uint256 _price);

  uint256[] private teamShares_ = [7,31,31,31];

  address[] private team_ = [
    0xD7E39C749A9c34bff1Dac37b4681B9636F87Ff9A,
    0x5763C71681569850035c4a58B474E65De4d35F11,
    0xae8ac7aA9F611A5F0ed157f8D8bA09CBFfC6aBaD,
    0xd52F8F05F6C719Edfe632e35095d47dC1453Ed7c
  ];

  enum WorkflowStatus {
    Before,
    Private,
    Sale,
    SoldOut
  }

  bool public revealed;
  string public baseURI;
  string public notRevealedUri;

  bytes32 public privateWhitelist;

  constructor(
    string memory _initNotRevealedUri,
    bytes32 _privateWhitelist
  ) ERC721("Bad dog", "BAD") PaymentSplitter(team_, teamShares_) {
    transferOwnership(msg.sender);
    workflow = WorkflowStatus.Before;
    setNotRevealedURI(_initNotRevealedUri);
    privateWhitelist = _privateWhitelist;
  }

  function redeem(uint64 amount, bytes32[] calldata proof)
    external
    payable
    whenNotPaused
  {
    require(workflow == WorkflowStatus.Private, "Private sale has ended");

    bool isOnWhitelist = _verifyRaffle(_leaf(msg.sender, 1), proof);
    require(
      isOnWhitelist,
      "address not verified on the private whitelist"
    );
    require(
      WHITELIST_FREEMINT >= privateRedeemedCount + amount,
      "cannot mint tokens. will go over private supply limit"
    );

    uint256 price = PRICE;
    uint256 max = MAX_SUPPLY;
    uint256 maxAmount = 2;
    uint256 currentSupply = _tokenSupply.current();
    uint256 alreadyRedeemed = privateRedeemed[msg.sender];
    uint256 supply = currentSupply + amount;

    require(supply <= max, "Sold out !");
    require(
      alreadyRedeemed + amount <= maxAmount,
      "tokens minted will go over user limit"
    );
    require(price * amount <= msg.value, "Insuficient funds");

    emit PrivateMint(msg.sender, amount, price);

    privateRedeemed[msg.sender] = privateRedeemed[msg.sender] + amount;
    for (uint256 i = 0; i < amount; i++) {
      privateRedeemedCount = privateRedeemedCount++;
      _tokenSupply.increment();
      _safeMint(msg.sender, _tokenSupply.current());
    }
  }


  function publicSaleMint(uint64 amount)
    external
    payable
    nonReentrant
    whenNotPaused
  {
    require(amount > 0, "need to mint at least one token");
    require(workflow != WorkflowStatus.SoldOut, " SOLD OUT!");
    require(
      workflow == WorkflowStatus.Sale,
      "Public sale is not started yet"
    );

    uint256 price = PRICE;
    uint256 maxAmount = 2;
    uint256 alreadyRedeemed = publicRedeemed[msg.sender];
    uint256 currentSupply = _tokenSupply.current();
    uint256 supply = currentSupply + amount;
    require(
      alreadyRedeemed + amount <= maxAmount,
      "You can't mint more than 2 tokens!"
    );
    require(supply <= MAX_SUPPLY, "Sold out !");
    require(price * amount <= msg.value, "Insuficient funds");

    publicRedeemedCount = publicRedeemedCount + amount;
    emit PublicMint(msg.sender, amount, price);

    uint256 initial = 1;
    uint256 condition = amount;
    if (currentSupply + amount == MAX_SUPPLY) {
      workflow = WorkflowStatus.SoldOut;
    }
    publicRedeemed[msg.sender] = publicRedeemed[msg.sender] + condition;
    for (uint256 i = initial; i <= condition; i++) {
      _tokenSupply.increment();
      _safeMint(msg.sender, _tokenSupply.current());
    }
  }

  function gift(uint64 _mintAmount) public onlyOwner {
    require(_mintAmount > 0, "Need to mint at least 1 NFT");

    uint256 currentSupply = _tokenSupply.current();
    uint256 supply = currentSupply + _mintAmount;
    require(supply <= MAX_SUPPLY, "Sold out !");

    uint256 condition = _mintAmount;
    if (currentSupply + _mintAmount == MAX_SUPPLY) {
      workflow = WorkflowStatus.SoldOut;
    }

    for (uint256 i = 1; i <= condition; i++) {
      _tokenSupply.increment();
      _safeMint(msg.sender, _tokenSupply.current());
    }
  }

  function giveaway(address[] memory giveawayAddressTable) public onlyOwner {
    uint256 _mintAmount = giveawayAddressTable.length;

    uint256 currentSupply = _tokenSupply.current();
    uint256 supply = currentSupply + _mintAmount;
    require(supply <= MAX_SUPPLY, "Sold out !");

    if (currentSupply + _mintAmount == MAX_SUPPLY) {
      workflow = WorkflowStatus.SoldOut;
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _tokenSupply.increment();
      _safeMint(giveawayAddressTable[i], _tokenSupply.current());
    }
  }

  /***************************
   * Owner Protected Functions
   ***************************/

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function totalSupply() external view returns (uint256) {
    uint256 supply = _tokenSupply.current();
    return supply;
  }

  function setprivateWhitelist(bytes32 whitelist_) public onlyOwner {
    privateWhitelist = whitelist_;
  }


  function setPrivateSaleEnabled() public onlyOwner {
    workflow = WorkflowStatus.Private;
  }


  function setPublicSaleEnabled() public onlyOwner {
    workflow = WorkflowStatus.Sale;
  }

  function getWorkflowStatus() public view returns (WorkflowStatus) {
    return workflow;
  }

  function _leaf(address account, uint256 amount)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(account, amount));
  }

  function _verifyRaffle(bytes32 leaf, bytes32[] memory proof)
    internal
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, privateWhitelist, leaf);
  }

  function _verifyPrivate(bytes32 leaf, bytes32[] memory proof)
    internal
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, privateWhitelist, leaf);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /*************************************************************
   * The following functions are overrides required by Solidity.
   *************************************************************/

  function _toString(uint256 v) internal pure returns (string memory str) {
    if (v == 0) {
      return "0";
    }
    uint256 maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint256 i = 0;
    while (v != 0) {
      uint256 remainder = v % 10;
      v = v / 10;
      reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory s = new bytes(i);
    for (uint256 j = 0; j < i; j++) {
      s[j] = reversed[i - 1 - j];
    }
    str = string(s);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    if (revealed == false) {
      return notRevealedUri;
    }

    string memory currentBaseURI = baseURI;
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId)))
        : "";
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setPrice(uint256 _price) public onlyOwner {
    PRICE = _price;
  }


  function reveal(string memory revealedBaseURI) public onlyOwner {
    baseURI = revealedBaseURI;
    revealed = true;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
}