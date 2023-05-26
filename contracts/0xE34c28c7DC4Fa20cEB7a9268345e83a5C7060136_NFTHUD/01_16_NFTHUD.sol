// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTHUD is ERC721, Pausable, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;

  string _baseTokenURI = "https://nfthud-api-lklfn.ondigitalocean.app/api/token/";

  // Initial token price
  uint256 private _price = 0.3 ether;

  uint256 DEVELOPER_TOKENS = 10;
  uint256 MARKETING_TOKENS = 90;
  uint256 TOTAL_SUPPLY = 3000;

  // Whitelist
  bytes32 public _merkleRoot;
  mapping(address => bool) public hasClaimedWhitelist;

  // Sale control
  enum MintStatus {
    CLOSED,
    PRESALE,
    PUBLIC
  }
  MintStatus public mintStatus = MintStatus.CLOSED;

  address private _developerWallet = 0x27eD0592EbcC59De91c55F88aCb53872443A33f3;
  address private _marketingWallet = 0x692f3113395d0778C2762c1d9895171d800069f3;

  Counters.Counter private _tokenIdCounter;

  event Mint(address indexed _address, uint256 tokenId);

  constructor(bytes32 merkleRoot) ERC721("NFTHUD Membership Token", "NFTHUD") {
    // Assogm merkleRoot on deployment
    _merkleRoot = merkleRoot;

    // Minting tokens for marketing
    for (uint256 i = 0; i < MARKETING_TOKENS; i++) {
      _mintPrivate(_marketingWallet);
    }

    // Minting tokens for developers
    for (uint256 i = 0; i < DEVELOPER_TOKENS; i++) {
      _mintPrivate(_developerWallet);
    }
  }

  // Creating the membership NFT is a simply minting function
  function mint(uint256 amount, bytes32[] calldata proof)
    public
    payable
    whenNotPaused
    nonReentrant
  {
    require(mintStatus != MintStatus.CLOSED, "Sale inactive");
    if (mintStatus == MintStatus.PUBLIC) {
      _mintPublic(amount);
    } else if (mintStatus == MintStatus.PRESALE) {
      _mintPresale(proof);
    }
  }

  // Public mint can mint as much as it wants
  function _mintPublic(uint256 amount) private {
    require(mintStatus == MintStatus.PUBLIC, "Public Sale inactive");
    require(
      _tokenIdCounter.current() + amount < TOTAL_SUPPLY,
      "Can't mint over supply limit"
    );
    require(msg.value >= _price * amount, "Not enough ether");
    for (uint256 i = 0; i < amount; i++) {
      _mintPrivate(msg.sender);
    }

    emit Mint(msg.sender, _tokenIdCounter.current());
  }

  // Whitelisted wallet can only mint 1 during whitelist
  function _mintPresale(bytes32[] calldata proof) private {
    require(mintStatus == MintStatus.PRESALE, "Pre-sale inactive");
    require(
      _tokenIdCounter.current() < TOTAL_SUPPLY,
      "Can't mint over supply limit"
    );
    require(
      MerkleProof.verify(
        proof,
        _merkleRoot,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Proof not valid"
    );
    require(!hasClaimedWhitelist[msg.sender], "Already claimed");
    require(msg.value == _price, "Not enough ether");

    hasClaimedWhitelist[msg.sender] = true;
    _mintPrivate(msg.sender);
    emit Mint(msg.sender, _tokenIdCounter.current());
  }

  function _mintPrivate(address to) private {
    _tokenIdCounter.increment();
    _safeMint(to, _tokenIdCounter.current());
  }

  function getBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function getPrice() external view returns (uint256) {
    return _price;
  }

  function setPrice(uint256 price) public onlyOwner {
    _price = price;
  }

  function withdraw() public {
    require(
      msg.sender == _developerWallet || msg.sender == _marketingWallet,
      "Wrong wallet address"
    );
    uint256 balance = address(this).balance;
    uint256 marketingBalance = balance / 3;
    uint256 developmentBalance = balance - marketingBalance;
    payable(_developerWallet).transfer(developmentBalance);
    payable(_marketingWallet).transfer(marketingBalance);
  }

  // Changes developer wallet, only developer wallet can change it
  // Do we want to transfer tokens also?
  function changeDeveloperWallet(address _address) public {
    require(msg.sender == _developerWallet, "Wrong wallet address");
    _developerWallet = _address;
  }

  // Changes marketing wallet, only marketing wallet can change it
  // Do we want to transfer tokens also?
  function changeMarketingWallet(address _address) public {
    require(msg.sender == _marketingWallet, "Wrong wallet address");
    _marketingWallet = _address;
  }

  // Update sale status
  function setStatus(uint8 _status) external onlyOwner {
    mintStatus = MintStatus(_status);
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function updateMerkleRoot(bytes32 merkleRoot) public onlyOwner {
    _merkleRoot = merkleRoot;
  }

  function pause() public onlyOwner whenNotPaused {
    _pause();
  }

  function unpause() public onlyOwner whenPaused {
    _unpause();
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function hasFoundingMemberToken(address wallet) public view returns (bool) {
    // To know if a user holds an NFT, we simply check the balance of the wallet
    // to count how many tokens the wallet has.
    return balanceOf(wallet) > 0;
  }


  function tokensSold() public view returns (uint256) {
    return _tokenIdCounter.current();
  }
}