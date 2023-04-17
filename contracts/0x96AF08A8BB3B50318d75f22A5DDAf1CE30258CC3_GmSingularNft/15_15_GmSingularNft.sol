// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "openzeppelin/contracts/token/ERC721/ERC721.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";
import "openzeppelin/contracts/utils/Counters.sol";
import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GmSingularNft is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  struct ScoringHoldersAllowance {
    uint8 free;
    uint8 whitelist;
  }

  mapping(address => ScoringHoldersAllowance) public scoringHolderAllowances;
  mapping(address => uint8) public whitelistMints;

  bytes32 public tierOneMerkleRoot;
  bytes32 public tierTwoMerkleRoot;

  
  struct PhaseMetadata {
    uint256 totalSupply;
    uint256 maxSupply;
    bool saleIsActive;
    bool tierTwoSaleIsActive;
    bool tierOneSaleIsActive;
    bool scoringHoldersSaleIsActive;
    uint256 currentTimestamp;
  }

  /* MINT CONFIGURATION */
  uint256 public constant MAX_SUPPLY = 10000;

  uint256 public constant PUBLIC_MAX_MULTIMINT = 10;

  uint256 public constant PUBLIC_PRICE = 0.05 ether;

  uint256 public constant TIER_ONE_PRICE = 0.027 ether;
  uint256 public constant TIER_TWO_PRICE = 0.034 ether;

  uint256 public constant TIER_LIMIT = 5;

  uint256 public TREASURY_ALLOCATION = 500;
  address public TREASURY_ADDRESS = address(0x40BC1382001aC8570fa2D4D122Ea0Cc598FF2e1c);

  constructor(string memory customBaseURI_) ERC721("GMSINGULAR", "GMSINGULAR") {
    customBaseURI = customBaseURI_;

    for (uint256 i = 0; i < TREASURY_ALLOCATION; i++) {
      _safeMintInternal(TREASURY_ADDRESS);
    }
  }

  function setHoldersAllowances(address[] memory addresses, uint8[] memory free, uint8[] memory whitelist) external onlyOwner {
    require(addresses.length == free.length, "Addresses and free arrays must be the same length");
    require(addresses.length == whitelist.length, "Addresses and whitelist arrays must be the same length");

    for (uint256 i = 0; i < addresses.length; i++) {
      scoringHolderAllowances[addresses[i]] = ScoringHoldersAllowance(free[i], whitelist[i]);
    }
  }

  /** MINTING **/
  Counters.Counter private supplyCounter;

  function publicMint(uint256 count) payable public nonReentrant {
    require(saleIsActive, "Sale not active");

    require(count <= PUBLIC_MAX_MULTIMINT, "Mint at most 10 at a time");

    require(msg.value >= PUBLIC_PRICE * count, "Insufficient ETH");

    _mintInternal(count);
  }

   function scoringHoldersFreeMint(uint8 count) public nonReentrant {
    require(scoringHoldersSaleIsActive, "Sale not active");

    require(scoringHolderAllowances[msg.sender].free >= count, "Address not allowed to mint");
    scoringHolderAllowances[msg.sender].free -= count;

    _mintInternal(count);
  }

  function scoringHoldersWhitelistMint(uint8 count) payable public nonReentrant {
    require(scoringHoldersSaleIsActive, "Sale not active");

    require(scoringHolderAllowances[msg.sender].whitelist >= count, "Address not allowed to mint");
    scoringHolderAllowances[msg.sender].whitelist -= count;

    require(msg.value >= TIER_ONE_PRICE * count, "Insufficient ETH");

    _mintInternal(count);
  }

  function tierOneMint(uint8 count, bytes32[] calldata proof) payable public nonReentrant {
    require(tierOneSaleIsActive, "Sale not active");

    bytes32 leaf = keccak256(abi.encode(msg.sender));
    require(MerkleProof.verifyCalldata(proof, tierOneMerkleRoot, leaf), "Invalid proof");

    _mintWhitelist(count, TIER_ONE_PRICE);
  }

  function tierTwoMint(uint8 count, bytes32[] calldata proof) payable public nonReentrant {
    require(tierTwoSaleIsActive, "Sale not active");

    bytes32 leaf = keccak256(abi.encode(msg.sender));
    require(MerkleProof.verifyCalldata(proof, tierTwoMerkleRoot, leaf), "Invalid proof");

    _mintWhitelist(count, TIER_TWO_PRICE);
  }

  function _mintWhitelist(uint8 count, uint256 pricePerToken) internal {
    require(msg.value >= pricePerToken * count, "Insufficient ETH");

    require(whitelistMints[msg.sender] + count <= TIER_LIMIT, "Mint limit reached");
    whitelistMints[msg.sender] += count;

    _mintInternal(count);
  }


  function _mintInternal(uint256 count) internal {
    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    for (uint256 i = 0; i < count; i++) {
        _safeMintInternal(msg.sender);
    }
  }

    function _safeMintInternal(address receiver) internal {
      _safeMint(receiver, totalSupply());

      supplyCounter.increment();
    }


  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  bool public scoringHoldersSaleIsActive = false;

  function setScoringHoldersSaleIsActive(bool saleIsActive_) external onlyOwner {
    scoringHoldersSaleIsActive = saleIsActive_;
  }

  bool public tierOneSaleIsActive = false;

  function setTierOneSaleIsActive(bool saleIsActive_) external onlyOwner {
    tierOneSaleIsActive = saleIsActive_;
  }

  function setTierOneMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    tierOneMerkleRoot = merkleRoot;
  }

  bool public tierTwoSaleIsActive = false;

  function setTierTwoSaleIsActive(bool saleIsActive_) external onlyOwner {
    tierTwoSaleIsActive = saleIsActive_;
  }

  function setTierTwoMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    tierTwoMerkleRoot = merkleRoot;
  }


function getPhaseMetadata() public view returns (PhaseMetadata memory) {
  PhaseMetadata memory metadata = PhaseMetadata({
      totalSupply: totalSupply(),
      maxSupply: MAX_SUPPLY,
      saleIsActive: saleIsActive,
      tierTwoSaleIsActive: tierTwoSaleIsActive,
      tierOneSaleIsActive: tierOneSaleIsActive,
      scoringHoldersSaleIsActive: scoringHoldersSaleIsActive,
      currentTimestamp: block.timestamp
  });

  return metadata;
}

function getHoldersAllowance(address wallet) public view returns (ScoringHoldersAllowance memory) {
  return scoringHolderAllowances[wallet];
}

function getTierMints(address wallet) public view returns (uint8) {
  return whitelistMints[wallet];
}

  /** URI HANDLING **/

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  /** WITHDRAW **/
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
  
}