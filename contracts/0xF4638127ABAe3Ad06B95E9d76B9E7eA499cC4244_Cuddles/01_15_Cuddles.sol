pragma solidity ^0.8.4;

// ♫♪ Cuddles

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import { MerkleProofUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract Cuddles is ERC721EnumerableUpgradeable, OwnableUpgradeable {
  using MerkleProofUpgradeable for bytes32[];

  bool public partyIsActive;
  bool public whitelistSaleIsActive;
  bool public publicSaleIsActive;

  uint256 public PARTY_PRICE;
  uint256 public WHITELIST_PRICE;
  uint256 public PUBLIC_PRICE;

  uint256 public MAX_CUDDLES;
  address internal payee;
  string internal baseURI;
  mapping(uint256 => uint256) private timesAbandoned;
  bytes32 public merkleRoot;

  function flipPartySaleState() external onlyOwner {
    partyIsActive = !partyIsActive;
  }

  function flipWhitelistSaleState() external onlyOwner {
    whitelistSaleIsActive = !whitelistSaleIsActive;
  }
  
  function flipPublicSaleState() external onlyOwner {
    publicSaleIsActive = !publicSaleIsActive;
  }

  function hogCuddles(uint numberOfTokens) external onlyOwner {
    for(uint i = 0; i < numberOfTokens; i++) {
      _adoptCuddles();
    }
  }

  function fullfillAddresses(address[] memory addresses, uint8 numberOfTokens) external onlyOwner {
    for (uint8 i=0; i<addresses.length; i++) {
      for(uint j = 0; j < numberOfTokens; j++) {
        _safeMint(addresses[i], totalSupply());
      }
    }
  }

  receive() external payable {
    require(partyIsActive, "The party has not started");
    uint256 numberOfTokens = msg.value / PARTY_PRICE;
    require(numberOfTokens <= 20, "Can only mint 20 tokens at a time");
    require(totalSupply() + numberOfTokens <= MAX_CUDDLES, "Purchase would exceed max supply of Cuddles");

    // ♪ You can dance if you want to...
    for(uint i = 0; i < numberOfTokens; i++) {
      _adoptCuddles();
    }
  }

  function whitelistSale(    
    uint numberOfTokens,    
    bytes32[] calldata proof,
    bytes32 megalodon
  ) external payable {
    require(whitelistSaleIsActive, "Whitelist sale is not active");
    require(proof.verify(merkleRoot, keccak256(abi.encodePacked(megalodon))), "You are not eligible for whitelist");
    require(numberOfTokens <= 20, "Can only mint 20 tokens at a time");
    require(totalSupply() + numberOfTokens <= MAX_CUDDLES, "Purchase would exceed max supply of Cuddles");
    require(WHITELIST_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");

    for(uint i = 0; i < numberOfTokens; i++) {
      _adoptCuddles();
    }
  }

  function publicSale(uint numberOfTokens) external payable {
    require(publicSaleIsActive, "Public sale is not active");
    require(numberOfTokens <= 20, "Can only mint 20 tokens at a time");
    require(totalSupply() + numberOfTokens <= MAX_CUDDLES, "Purchase would exceed max supply of Cuddles");
    require(PUBLIC_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");

    for(uint i = 0; i < numberOfTokens; i++) {
      _adoptCuddles();
    }
  }

  function _adoptCuddles () internal {
    // By minting this NFT you are promising to never
    // abandon your Cuddles for all of eternity
    _safeMint(_msgSender(), totalSupply());
  }

  function _abandonCuddles (uint256 tokenId) internal {
    // You promised :(
    timesAbandoned[tokenId] = timesAbandoned[tokenId] + 1;
  }

  function withdraw() external onlyOwner {
    uint balance = address(this).balance;
    payable(payee).transfer(balance);
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
    baseURI = newBaseURI;
  }

  function setPayeeAddress(address _payee) external onlyOwner {
    payee = _payee;
  }

  function setWhitelistPrice(uint256 newWhitelistPrice) external onlyOwner {
    WHITELIST_PRICE = newWhitelistPrice;
  }

  function setPublicPrice(uint256 newPublicPrice) external onlyOwner {
    PUBLIC_PRICE = newPublicPrice;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setRoot(bytes32 _root) external onlyOwner {
    merkleRoot = _root;
  }

  function isEligibleForWhitelist(        
    bytes32[] calldata proof,
    bytes32 megalodon,
    uint amount,
    address account
  ) external view returns (bool) {
    return (keccak256(abi.encodePacked(account, amount)) == megalodon && proof.verify(merkleRoot, keccak256(abi.encodePacked(megalodon))));
  }

  function getTimesAbandoned(uint256 tokenId) external view returns (uint256) {
    return timesAbandoned[tokenId];
  }

  /**
    * @dev See {IERC721Enumerable-transferFrom}.
  */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
    _abandonCuddles(tokenId);
  }

  /**
    * @dev See {IERC721Enumerable-safeTransferFrom}.
  */
  function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    safeTransferFrom(from, to, tokenId, "");
    _abandonCuddles(tokenId);
  }

  /**
    * @dev See {IERC721Enumerable-safeTransferFrom}.
  */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
    _abandonCuddles(tokenId);
  }

  function initialize() initializer public {
    __ERC721_init("Cuddles", "CUD");
    __ERC721Enumerable_init();
    __Ownable_init();

    partyIsActive = false;
    whitelistSaleIsActive = false;
    publicSaleIsActive = false;
    PARTY_PRICE = 10000000000000000; // 0.01 ETH
    WHITELIST_PRICE = 20000000000000000; // 0.02 ETH
    PUBLIC_PRICE = 30000000000000000; // 0.03 ETH
    MAX_CUDDLES = 5432;

    payee = 0x54358aceFdf75d1d30f9BAf577590BC36762db6B;
  }
}