// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFT is ERC721, Ownable, ReentrancyGuard  {
  using SafeMath for uint;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  enum SaleStatus {
		PAUSED,
		PRESALE,
		PUBLIC
	}

  // Constants
  uint public constant TOTAL_SUPPLY = 1000;
  uint public constant PRESALE_MINT_PRICE = 0.05 ether;
  uint public constant PUBLIC_MINT_PRICE = 0.08 ether;
  uint public constant MAX_PER_MINT = 5;
  uint public constant PRESALE_MINT_MAX = 5;
  uint public constant PUBLIC_MINT_MAX = 25;

  // Variables
  string public baseTokenURI;
  bytes32 public merkleRoot;
  SaleStatus public saleStatus = SaleStatus.PAUSED;
  mapping(address => uint8) private _mintCount;
  mapping(address => uint8) private _whitelistmintCount;

  /// @dev Constructor
  constructor() ERC721("Shell Rebels", "SR") {
    baseTokenURI = "https://bafybeibcg3dors4hpvywxmcws4gx5gsjel6neuwycjlwn4wqdw4kep24pm.ipfs.nftstorage.link/json/";
  }

  /// @dev Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix
  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  /// @dev Sets the sale status
  function setSaleStatus(SaleStatus status) public onlyOwner {
		saleStatus = status;
	}

  /// @dev Sets the Merkle Tree root
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

  /// @dev Mint NFTs via airdrop to address
  function airdropShellRebels(address to, uint8 amount) public onlyOwner {
    uint256 tokenId = _tokenIds.current();
    require(tokenId.add(amount) < TOTAL_SUPPLY, "Number of requested tokens will exceed collection size");

    _mintShellRebelsTo(to, amount);
  }

  /// @dev Mint NFTs without paying the price (only for the owner)
  function reserveShellRebels(uint8 amount) public onlyOwner {
    uint256 tokenId = _tokenIds.current();
    require(tokenId.add(amount) < TOTAL_SUPPLY, "Max supply reached");

    _mintShellRebelsTo(msg.sender, amount);
  }

  /// @dev Mint multiple NFTs for different sale phases
  function mintShellRebels(uint8 amount, bytes32[] calldata _merkleProof) public payable {
    uint256 tokenId = _tokenIds.current();
    require(saleStatus != SaleStatus.PAUSED, "Sale is not active");
    require(tokenId.add(amount) < TOTAL_SUPPLY, "Number of requested tokens will exceed collection size");
    require(amount > 0 && amount <= MAX_PER_MINT, "Number of requested tokens exceeds minimum or maximum per transaction");

    if(saleStatus == SaleStatus.PRESALE) {
      require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on the whitelist");
      require(msg.value >= PRESALE_MINT_PRICE.mul(amount), "Not enough ether to purchase NFTs");
      require(amount + _whitelistmintCount[msg.sender] <= PRESALE_MINT_MAX, "Number of requested tokens exceeds max per whitelisted address");
      _whitelistmintCount[msg.sender] += amount;
    } else {
      require(msg.value >= PUBLIC_MINT_PRICE.mul(amount), "Not enough ether to purchase NFTs");
      require(amount + _mintCount[msg.sender] <= PUBLIC_MINT_MAX, "Number of requested tokens exceeds max per address");
      _mintCount[msg.sender] += amount;
    }

    _mintShellRebelsTo(msg.sender, amount);
  }

  /// @dev Mint multiple NFTs to address
  function _mintShellRebelsTo(address to, uint amount) private {
    for (uint256 i = 0; i < amount; i++) {
      _tokenIds.increment();
      uint256 newItemId = _tokenIds.current();
      _safeMint(to, newItemId);
    }
  }

  /// @dev Withdraw all payments to the owner
  function withdrawPayments() public onlyOwner nonReentrant  {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Withdrawal failed");
  }  
}