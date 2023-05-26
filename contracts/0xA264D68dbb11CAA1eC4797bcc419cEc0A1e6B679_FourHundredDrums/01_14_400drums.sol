// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FourHundredDrums is ERC721A, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public alMerkleRoot;
    bytes32 public devMerkleRoot;

    string public baseURI;
    string public revealURI;

    uint256 public mintPrice = 0.12 ether;
    uint256 public alMintPrice = 0.1 ether;
    uint256 public maxSupply;
    uint256 public reserveSupply;

    uint256 public maxPublicMint;
    uint256 public maxAlMint;

    bool public isPublicMint;
    bool public isAlMint;
    bool public isDevMint;
    bool public revealed = false;

    mapping(address => uint256) private _mintedWallets;
    mapping(address => uint256) private _alWallets;

    constructor() payable ERC721A("400DRUMS", "DRUMS") {
      maxSupply = 444;
      maxPublicMint = 5;
      maxAlMint = 3;
      reserveSupply = 5;
    }

    // Minting - public, allow list
    function publicMint(uint256 _quantity) external payable {
      require(isPublicMint, "Public minting is not live.");
      require(_mintedWallets[msg.sender] + _quantity <= maxPublicMint, "You reached max per wallet.");
      require(_quantity > 0, "You need to mint at least 1 NFT.");
      require(msg.value >= mintPrice * _quantity, "Insufficient ETH");
      require(maxSupply - reserveSupply >= _tokenIds.current() + _quantity, "Sold out or Exceeds max tokens");

      for (uint256 i = 0; i < _quantity; i++) {
        _mintedWallets[msg.sender]++;
        _tokenIds.current() + i;
      }
      _safeMint(msg.sender, _quantity);
    }

    function alMint(bytes32[] calldata _merkleProof, uint256 _quantity) external payable {
      require(isAlMint, "Allow list minting is not live.");
      require(MerkleProof.verify(_merkleProof, alMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on the allow list.");
      require(_alWallets[msg.sender] + _quantity <= maxAlMint, "You reached max per wallet.");
      require(_quantity > 0, "You need to mint at least 1 NFT.");
      require(msg.value >= alMintPrice * _quantity, "Insufficient ETH");
      require(maxSupply - reserveSupply >= _tokenIds.current() + _quantity, "Sold out or Exceeds max tokens");

      for (uint256 i = 0; i < _quantity; i++) {
        _alWallets[msg.sender]++;
        _tokenIds.increment();
      }
      _safeMint(msg.sender, _quantity);
    }

    function devMint(bytes32[] calldata _merkleProof, uint256 _quantity) external {
      require(isDevMint, "Dev mint is not live.");
      require(MerkleProof.verify(_merkleProof, devMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on the dev list.");
      require(maxSupply >= _tokenIds.current() + _quantity, "Sold out or Exceeds max tokens");

      for (uint256 i = 0; i < _quantity; i++) {
        _tokenIds.increment();
      }

      _safeMint(msg.sender, _quantity);
    }

    // onlyOwner -- set al merkle root
    function setAlMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
      alMerkleRoot = _merkleRoot;
    }

    // onlyOwner -- set dev merkle root
    function setDevMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
      devMerkleRoot = _merkleRoot;
    }

    // onlyOwner Token / Reveal URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721A Metadata: URI query for nonexistent token");

      if (revealed == false) {
        return revealURI;
      }

      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json")) : "";
    }

    function setRevealURI(string memory _revealURI) external onlyOwner() {
      revealURI = _revealURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner() {
      baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }

    // onlyOwner Admin functions

    function reveal() external onlyOwner {
      revealed = !revealed;
    }

    function togglePublicMint() external onlyOwner {
      isPublicMint = !isPublicMint;
      isAlMint = false;
      isDevMint = false;
    }

    function toggleAlMint() external onlyOwner {
      isAlMint = !isAlMint;
      isPublicMint = false;
      isDevMint = false;
    }

    function toggleDevMint() external onlyOwner {
      isAlMint = false;
      isPublicMint = false;
      isDevMint = !isDevMint;
    }

    function disableMint() external onlyOwner {
      isPublicMint = false;
      isAlMint = false;
      isDevMint = false;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
      maxSupply = _maxSupply;
    }

    function setReserveSupply(uint256 _reserveSupply) external onlyOwner {
      reserveSupply = _reserveSupply;
    }

    function setMaxPublicMint(uint256 _maxPublicMint) external onlyOwner {
      maxPublicMint = _maxPublicMint;
    }

    function setMaxAlMint(uint256 _maxAlMint) external onlyOwner {
      maxAlMint = _maxAlMint;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
      mintPrice = _mintPrice;
    }

    function setAlMintPrice(uint256 _alMintPrice) external onlyOwner {
      alMintPrice = _alMintPrice;
    }

    // onlyOwner - withdrawl

    function withdrawSplit() public onlyOwner {
      uint256 balance = address(this).balance;
      (bool wallet1, ) = payable(0x23A3f45bD7961B968970D6A69ebE1B5d6513b8Bf).call{value: balance * 20 / 100}("");
      (bool wallet2, ) = payable(0xe9D99C29B2872784b7d28f10ED37347374Fb084B).call{value: address(this).balance}("");
      require(wallet1, "Withdraw 1 failed");
      require(wallet2, "Withdraw 2 failed");
    }

    function withdraw() public onlyOwner {
      (bool wallet1, ) = payable(msg.sender).call{value: address(this).balance}("");
      require(wallet1, "Withdraw 1 failed");
    }
}