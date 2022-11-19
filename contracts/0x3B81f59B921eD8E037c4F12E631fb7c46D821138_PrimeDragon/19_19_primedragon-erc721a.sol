// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
Prime Dragon
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
//import "erc721a/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "./ofr/DefaultOperatorFilterer.sol";

abstract contract NftStaking {
  struct UserNFTStake {
    address nftContract;
    uint256 tokenId;
    PlanId planId;
    uint64 stakedAt;
    uint64 unstakedAt;
    uint256 rewardClaimed;
  }

  enum PlanId {
    plan0monthsLock,
    plan1monthsLock,
    plan3monthsLock,
    plan6monthsLock
  }

  function getUserStakes(address user) external view virtual returns (UserNFTStake[] memory nftStakes);
}

contract PrimeDragon is ERC721Enumerable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  using MerkleProof for bytes32[];
  bytes32 merkleRoot;

  uint256 public MAX_SUPPLY = 500;
  string private baseURI;

  uint256 public publicMintPrice = 0.22 ether;
  uint256 public whitelistMintPrice = 0.18 ether;
  uint256 public primelistMintPrice = 0.12 ether;

  bool public publicMintEnabled = false;
  bool public whitelistMintEnabled = false;
  bool public primelistMintEnabled = false;

  address public NFT_STAKING_CONTRACT = 0x9D1D148193C296DBCb7056C4Ec0BC1445e3fADFb;
  address public PRIME_APE_CONTRACT = 0x6632a9d63E142F17a668064D41A21193b49B41a0;
  address public PRIME_KONG_CONTRACT = 0x5845E5F0571427D0ce33550587961262CA8CDF5C;
  address public PRIME_INFECTED_CONTRACT = 0xFD8917a36f76c4DA9550F26DB2faaaA242d6AE2c;

  uint256 public PRIME_APE_MIN_COUNT = 1;
  uint256 public PRIME_KONG_MIN_COUNT = 1;
  uint256 public PRIME_INFECTED_MIN_COUNT = 2;

  uint256 public public_MaxMintPerAddress = 2;
  uint256 public whitelist_MaxMintPerAddress = 3;
  uint256 public primelist_MaxMintPerAddress = 2;

  mapping(address => uint256) public publicMinted;
  mapping(address => uint256) public whitelistMinted;
  mapping(address => uint256) public primelistMinted;

  event publicMintActive(bool active);
  event whitelistMintActive(bool active);
  event primelistMintActive(bool active);

  constructor(string memory uri) ERC721("PrimeDragon", "PrimeDragon") {
    baseURI = uri;
  }

  function setMerkleRoot(bytes32 root) external onlyOwner {
    merkleRoot = root;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
    require(newMaxSupply != MAX_SUPPLY, "Same value as current max supply");
    require(newMaxSupply >= totalSupply(), "Value lower than total supply");
    MAX_SUPPLY = newMaxSupply;
  }

  function setPublicMintPrice(uint256 newPrice) external onlyOwner {
    publicMintPrice = newPrice;
  }

  function setWhitelistMintPrice(uint256 newPrice) external onlyOwner {
    whitelistMintPrice = newPrice;
  }

  function setPrimelistMintPrice(uint256 newPrice) external onlyOwner {
    primelistMintPrice = newPrice;
  }

  function togglePublicMint() external onlyOwner {
    publicMintEnabled = !publicMintEnabled;
    emit publicMintActive(publicMintEnabled);
  }

  function toggleWhitelistMint() external onlyOwner {
    whitelistMintEnabled = !whitelistMintEnabled;
    emit whitelistMintActive(whitelistMintEnabled);
  }

  function togglePrimelistMint() external onlyOwner {
    primelistMintEnabled = !primelistMintEnabled;
    emit primelistMintActive(primelistMintEnabled);
  }

  function activatePublicMint(uint256 newMaxSupply) external onlyOwner {
    setMaxSupply(newMaxSupply);

    publicMintEnabled = true;
    whitelistMintEnabled = false;
    primelistMintEnabled = false;

    emit publicMintActive(true);
  }

  function activateWhitelistMint(uint256 newMaxSupply) external onlyOwner {
    setMaxSupply(newMaxSupply);

    publicMintEnabled = false;
    whitelistMintEnabled = true;
    primelistMintEnabled = false;

    emit whitelistMintActive(true);
  }

  function activatePrimelistMint(uint256 newMaxSupply) external onlyOwner {
    setMaxSupply(newMaxSupply);

    publicMintEnabled = false;
    whitelistMintEnabled = false;
    primelistMintEnabled = true;

    emit primelistMintActive(true);
  }

  function setPublicMaxMintPerAddress(uint256 newMaxMintPerAddress) external onlyOwner {
    require(newMaxMintPerAddress > 0, "Value lower then 1");
    public_MaxMintPerAddress = newMaxMintPerAddress;
  }

  function setWhitelistMaxMintPerAddress(uint256 newMaxMintPerAddress) external onlyOwner {
    require(newMaxMintPerAddress > 0, "Value lower then 1");
    whitelist_MaxMintPerAddress = newMaxMintPerAddress;
  }

  function setPrimelistMaxMintPerAddress(uint256 newMaxMintPerAddress) external onlyOwner {
    require(newMaxMintPerAddress > 0, "Value lower then 1");
    primelist_MaxMintPerAddress = newMaxMintPerAddress;
  }

  function setPrimeNFTStaking(address newStakingAddress) external onlyOwner {
    NFT_STAKING_CONTRACT = newStakingAddress;
  }

  function setPrimeContractAddress(address primeApeAddress, address primeKongAddress, address primeInfectedAddress) external onlyOwner {
    PRIME_APE_CONTRACT = primeApeAddress;
    PRIME_KONG_CONTRACT = primeKongAddress;
    PRIME_INFECTED_CONTRACT = primeInfectedAddress;
  }

  function setPrimeConstraintCount(uint256 primeApeCount, uint256 primeKongCount, uint256 primeInfectedCount) external onlyOwner {
    PRIME_APE_MIN_COUNT = primeApeCount;
    PRIME_KONG_MIN_COUNT = primeKongCount;
    PRIME_INFECTED_MIN_COUNT = primeInfectedCount;
  }

  function getTokenIDs(address addr) external view returns (uint256[] memory) {
    uint256 total = totalSupply();
    uint256 count = balanceOf(addr);
    uint256[] memory tokens = new uint256[](count);
    uint256 tokenIndex = 0;
    for (uint256 i; i < total; i++) {
      if (addr == ownerOf(i)) {
        tokens[tokenIndex] = i;
        tokenIndex++;
      }
    }
    return tokens;
  }

  //Check if have 1 prime ape, 1 prime kong, 2 prime infected
  function checkPrimeNFTOwned(address user) public view returns (bool) {
    uint256 primeApeUserCount = 0;
    uint256 primeKongUserCount = 0;
    uint256 primeInfectedUserCount = 0;

    NftStaking NftStakingContract = NftStaking(NFT_STAKING_CONTRACT);
    NftStaking.UserNFTStake[] memory nftStakes = NftStakingContract.getUserStakes(user);
    for (uint256 index = 0; index < nftStakes.length; index++) {
      address stakedContract = nftStakes[index].nftContract;
      if (stakedContract == PRIME_APE_CONTRACT) {
        primeApeUserCount += 1;
      } else if (stakedContract == PRIME_KONG_CONTRACT) {
        primeKongUserCount += 1;
      } else if (stakedContract == PRIME_INFECTED_CONTRACT) {
        primeInfectedUserCount += 1;
      }
    }

    uint256 primeApePlanet_Balance = IERC721(PRIME_APE_CONTRACT).balanceOf(user);
    uint256 primeKongPlanet_Balance = IERC721(PRIME_KONG_CONTRACT).balanceOf(user);
    uint256 primeInfectedPlanet_Balance = IERC721(PRIME_INFECTED_CONTRACT).balanceOf(user);

    primeApeUserCount += primeApePlanet_Balance;
    primeKongUserCount += primeKongPlanet_Balance;
    primeInfectedUserCount += primeInfectedPlanet_Balance;

    if (primeApeUserCount >= PRIME_APE_MIN_COUNT && primeKongUserCount >= PRIME_KONG_MIN_COUNT && primeInfectedUserCount >= PRIME_INFECTED_MIN_COUNT) {
      return true;
    }

    return false;
  }

  function checkWhitelist(address user, bytes32[] memory proof) public view returns (bool) {
    return proof.verify(merkleRoot, keccak256(abi.encodePacked(user)));
  }

  function airDrop(address[] calldata recipient, uint256[] calldata quantity) external onlyOwner {
    require(quantity.length == recipient.length, "Please provide equal quantities and recipients");

    uint256 totalQuantity = 0;
    uint256 supply = totalSupply();
    for (uint256 i = 0; i < quantity.length; ++i) {
      totalQuantity += quantity[i];
    }
    require(supply + totalQuantity <= MAX_SUPPLY, "Not enough supply");
    delete totalQuantity;

    for (uint256 i = 0; i < recipient.length; ++i) {
      for (uint256 j = 0; j < quantity[i]; ++j) {
        _safeMint(recipient[i], supply++);
      }
    }
  }

  function publicMint(uint256 amount) public payable nonReentrant {
    uint256 totalMinted = totalSupply();

    require(msg.sender == tx.origin);
    require(publicMintEnabled, "Public mint not enabled");
    require(amount * publicMintPrice <= msg.value, "More ETH please");
    require(amount + totalMinted <= MAX_SUPPLY, "Please try minting with less, not enough supply!");
    require(amount + publicMinted[msg.sender] <= public_MaxMintPerAddress, "Exceeded max mint per address, try minting with less");

    bulkMint(msg.sender, amount);
    publicMinted[msg.sender] += amount;
  }

  function whitelistMint(uint256 amount, bytes32[] memory proof) public payable nonReentrant {
    uint256 totalMinted = totalSupply();

    require(msg.sender == tx.origin);
    require(whitelistMintEnabled, "Whitelist mint not enabled");
    require(amount * whitelistMintPrice <= msg.value, "More ETH please");
    require(amount + totalMinted <= MAX_SUPPLY, "Please try minting with less, not enough supply!");
    require(amount + whitelistMinted[msg.sender] <= whitelist_MaxMintPerAddress, "Exceeded max mint per address for whitelist, try minting with less");
    require(checkWhitelist(msg.sender, proof), "You are not on the whitelist");

    bulkMint(msg.sender, amount);
    whitelistMinted[msg.sender] += amount;
  }

  function primelistMint(uint256 amount) public payable nonReentrant {
    uint256 totalMinted = totalSupply();

    require(msg.sender == tx.origin);
    require(primelistMintEnabled, "Primelist mint not enabled");
    require(amount * primelistMintPrice <= msg.value, "More ETH please");
    require(amount + totalMinted <= MAX_SUPPLY, "Please try minting with less, not enough supply!");
    require(amount + primelistMinted[msg.sender] <= primelist_MaxMintPerAddress, "Exceeded max mint per address, try minting with less");
    require(checkPrimeNFTOwned(msg.sender), "You do not meet NFT requirements for Primelist");

    bulkMint(msg.sender, amount);
    primelistMinted[msg.sender] += amount;
  }

  function bulkMint(address creator, uint batchSize) internal returns (bool) {
    require(batchSize > 0, "MintZeroQuantity()");
    uint256 totalMinted = totalSupply();
    for (uint i = 0; i < batchSize; i++) {
      _safeMint(creator, totalMinted + i);
    }
    return true;
  }

  function withdrawAll() external onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}