/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//                                      ████████╗██╗  ██╗███████╗
//                                      ╚══██╔══╝██║  ██║██╔════╝
//                                         ██║   ███████║█████╗
//                                         ██║   ██╔══██║██╔══╝
//                                         ██║   ██║  ██║███████╗
//                                         ╚═╝   ╚═╝  ╚═╝╚══════╝
//
//  ██████╗ ██╗ ██████╗██╗  ██╗██╗  ██╗███████╗ █████╗ ██████╗ ███████╗     ██████╗██╗     ██╗   ██╗██████╗
//  ██╔══██╗██║██╔════╝██║ ██╔╝██║  ██║██╔════╝██╔══██╗██╔══██╗██╔════╝    ██╔════╝██║     ██║   ██║██╔══██╗
//  ██║  ██║██║██║     █████╔╝ ███████║█████╗  ███████║██║  ██║███████╗    ██║     ██║     ██║   ██║██████╔╝
//  ██║  ██║██║██║     ██╔═██╗ ██╔══██║██╔══╝  ██╔══██║██║  ██║╚════██║    ██║     ██║     ██║   ██║██╔══██╗
//  ██████╔╝██║╚██████╗██║  ██╗██║  ██║███████╗██║  ██║██████╔╝███████║    ╚██████╗███████╗╚██████╔╝██████╔╝
//  ╚═════╝ ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝     ╚═════╝╚══════╝ ╚═════╝ ╚═════╝
//
//
///////////////////////////     Made with love in Belgium by 0x Odyssey Studio     //////////////////////////
///////////////////////////                 https://0xOdyssey.com                  //////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DickheadsClub is ERC721A, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  mapping(address => uint256) public claimed;

  address proxyRegistryAddress;

  // Define starting contract state
  bytes32 public merkleRoot;
  string public notRevealedUri = 'ipfs://QmPcfXW3FZyZUT32fYsbxkYDUCUeztEB8LYeTErKj8kbis';
  string public _contractURI = 'ipfs://QmeP1hEj9ZcmCdU8z7oYxFGsL2ZYQKsj4fBN2XAajGzmv8';
	string public baseURI = ''; // First Proxy then ipfs://CID/

  uint256 public wlSalePrice = 0.007 ether;
  uint256 public salePrice = 0.01 ether;
  uint256 public maxSupply = 2222;

  uint256 public constant RESERVED_TOKENS = 49; // 50 with genesis token
  uint256 public constant MAX_MINTS_ON_WL = 20;
  uint256 public constant INITIAL_TOKEN_ID = 1;

  bool public mintingIsActive = false;
  bool public whiteListIsActive = false;
  bool public reservedTokensMinted = false;
  bool public genesisTokenMinted = false;
  bool public revealed = false;
  bool public supplyLocked = false;

  constructor() ERC721A("Dickheads Club", "DICKHEADS") {
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return INITIAL_TOKEN_ID;
  }

  function toggleWhiteList() external onlyOwner {
    whiteListIsActive = !whiteListIsActive;

    if (whiteListIsActive) {
      mintingIsActive = false;
    }
  }

  function toggleMinting() external onlyOwner {
    mintingIsActive = !mintingIsActive;
    if (mintingIsActive) {
      whiteListIsActive = false;
    }
  }

  function toggleReveal() public onlyOwner {
    revealed = !revealed;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setBaseURI(string memory _newURI) external onlyOwner {
    baseURI = _newURI;
  }

  function setNotRevealedURI(string memory _newURI) public onlyOwner {
    notRevealedUri = _newURI;
  }

  function setContractURI(string memory _newURI) public onlyOwner {
    _contractURI = _newURI;
  }

  function setSalePrice(uint256 _newPrice) external onlyOwner {
    salePrice = _newPrice;
  }

  function setWlSalePrice(uint256 _newPrice) external onlyOwner {
    wlSalePrice = _newPrice;
  }

  // Update maxSupply if needed
  function setMaxSupply(uint256 _newSupply) external onlyOwner {
    require(supplyLocked == false, "Supply is locked and cannot be updated");
    maxSupply = _newSupply;
  }

  // Lock the possibility to update maxSupply
  function lockSupply() external onlyOwner {
    supplyLocked = true;
  }

  // Reserve the first token
  function reserveGenesisToken(address toAddress) external onlyOwner {
    // Only allow one-time reservation of genesis token
    require(genesisTokenMinted == false, "Genesis token already minted");
    if (!genesisTokenMinted) {
      _mintTokens(1, toAddress);
      genesisTokenMinted = true;
    }
  }

  // Reserve some tokens for the team
  function reserveTokens(address toAddress) external onlyOwner {
    // Only allow one-time reservation of tokens
    require(genesisTokenMinted == true, "Genesis token must be minted first");
    require(reservedTokensMinted == false, "Reserved tokens already minted");

    if (!reservedTokensMinted) {
      _mintTokens(RESERVED_TOKENS, toAddress);
      reservedTokensMinted = true;
    }
  }

  // Internal mint function (default buyer)
  function _mintTokens(uint256 numberOfTokens) private {
    require(numberOfTokens > 0, "Must mint at least 1 token");
    // Mint number of tokens requested
    _safeMint(msg.sender, numberOfTokens);

    // Disable minting if max supply of tokens is reached
    if (totalSupply() == maxSupply) {
      mintingIsActive = false;
    }
  }

	// Internal mint function WITH specific destination address
  function _mintTokens(uint256 numberOfTokens, address toAddress) private {
    require(numberOfTokens > 0, "Must mint at least 1 token");
    _safeMint(toAddress, numberOfTokens);

    // Disable minting if max supply of tokens is reached
    if (totalSupply() == maxSupply) {
      mintingIsActive = false;
    }
  }

  // Public mint functions
  function mintTokens(uint256 numberOfTokens) external payable nonReentrant {
    require(mintingIsActive, "Minting is not active");
    require(msg.value == numberOfTokens.mul(salePrice), "Incorrect Ether supplied");
    require(totalSupply().add(numberOfTokens) <= maxSupply, "Minting would exceed max supply");
    _mintTokens(numberOfTokens);
  }

  function mintTokenWL(bytes32[] calldata merkleProof, uint256 numberOfTokens) external payable nonReentrant {
    require(whiteListIsActive, "Whitelist minting is not active");
    require(merkleRoot != "", "Whitelist minting is not active (merckle root not set)");
    require((claimed[msg.sender] + numberOfTokens) <= MAX_MINTS_ON_WL, "Minting would exceed max minting for this address");
    require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "invalid merkle proof");
    require(msg.value == numberOfTokens.mul(wlSalePrice), "Incorrect Ether supplied");
    require(totalSupply().add(numberOfTokens) <= maxSupply, "Minting would exceed max supply");

    claimed[msg.sender] += numberOfTokens;
    _mintTokens(numberOfTokens);
  }

  // Override the below functions from parent contracts
  function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (!revealed) {
      return notRevealedUri;
    }

  	return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}