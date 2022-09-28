//   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄               ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄            ▄▄▄▄▄▄▄▄▄▄▄
//  ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌             ▐░▌▐░░░░░░░░░░░▌▐░▌          ▐░░░░░░░░░░░▌
//  ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌ ▀▀▀▀█░█▀▀▀▀  ▐░▌           ▐░▌ ▐░█▀▀▀▀▀▀▀█░▌▐░▌          ▐░█▀▀▀▀▀▀▀▀▀
//  ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌       ▐░▌         ▐░▌  ▐░▌       ▐░▌▐░▌          ▐░▌
//  ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌     ▐░▌        ▐░▌       ▐░▌   ▐░█▄▄▄▄▄▄▄█░▌▐░▌          ▐░█▄▄▄▄▄▄▄▄▄
//  ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌         ▐░▌     ▐░▌    ▐░░░░░░░░░░░▌▐░▌          ▐░░░░░░░░░░░▌
//  ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀█░█▀▀ ▐░█▀▀▀▀█░█▀▀      ▐░▌          ▐░▌   ▐░▌     ▐░█▀▀▀▀▀▀▀█░▌▐░▌           ▀▀▀▀▀▀▀▀▀█░▌
//  ▐░▌       ▐░▌▐░▌     ▐░▌  ▐░▌     ▐░▌       ▐░▌           ▐░▌ ▐░▌      ▐░▌       ▐░▌▐░▌                    ▐░▌
//  ▐░▌       ▐░▌▐░▌      ▐░▌ ▐░▌      ▐░▌  ▄▄▄▄█░█▄▄▄▄        ▐░▐░▌       ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄█░▌
//  ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌        ▐░▌        ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Arrivals is ERC721A, Pausable, Ownable {
  uint256 public maxSupply = 1452;

  bytes32 public whitelistMerkleRoot;

  bytes32 public OGMerkleRoot;
  uint256 public OGMinted;
  uint256 public maxOGTokens = 100;

  bool public isOG = false;
  bool public isWhitelist = false;
  bool public isPublic = false;

  uint256 public cost = 0.015 ether;
  uint256 public maxPerWallet = 1;

  string public baseURL;
  string public baseExtension = ".json";

  string public unRevealedURL;
  bool public isRevealed = false;

  constructor() ERC721A("Arrivals", "ARVLS") {
    _mintERC2309(msg.sender, 50);
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
    require(
      MerkleProof.verify(
        merkleProof,
        root,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Address does not exist in list"
    );
    _;
  }

  modifier canMint() {
    require(totalSupply() < maxSupply, "Not enough tokens remaining to mint");
    require(
      _numberMinted(msg.sender) < maxPerWallet,
      "Maximum Minting Limit Exceeded"
    );
    _;
  }

  modifier isCorrectPayment() {
    require(msg.value >= cost, "Not Enough ETH");
    _;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function OGMint(bytes32[] calldata merkleProof)
    external
    payable
    whenNotPaused
    isValidMerkleProof(merkleProof, OGMerkleRoot)
    isCorrectPayment
    canMint
  {
    require(isOG, "OG sale is closed");
    require(OGMinted < maxOGTokens, "Max OG Limit Exceeded");

    _mint(msg.sender, 1);
    OGMinted++;
  }

  function whitelistMint(bytes32[] calldata merkleProof)
    external
    payable
    whenNotPaused
    isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    isCorrectPayment
    canMint
  {
    require(isWhitelist, "Whitelist sale is closed");

    _mint(msg.sender, 1);
  }

  function publicMint()
    external
    payable
    whenNotPaused
    isCorrectPayment
    canMint
  {
    require(isPublic, "Public sale is closed");

    _mint(msg.sender, 1);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (!isRevealed) {
      return unRevealedURL;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(
            currentBaseURI,
            Strings.toString(_tokenId),
            baseExtension
          )
        )
        : "";
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURL;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setBaseURL(string memory _baseURL) external onlyOwner {
    baseURL = _baseURL;
  }

  function setBaseExtension(string memory _baseExtension) external onlyOwner {
    baseExtension = _baseExtension;
  }

  function setUnRevealedURL(string memory _unRevealedURL) external onlyOwner {
    unRevealedURL = _unRevealedURL;
  }

  function toggleRevealed() external onlyOwner {
    isRevealed = !isRevealed;
  }

  // Sale Price

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  // Max Tokens Per Wallet

  function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  // Merkle Roots

  function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    whitelistMerkleRoot = merkleRoot;
  }

  function setOGMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    OGMerkleRoot = merkleRoot;
  }

  // Sale Status

  function setOG(bool _isOG) external onlyOwner {
    isOG = _isOG;
  }

  function setWhitelist(bool _isWhitelist) external onlyOwner {
    isWhitelist = _isWhitelist;
  }

  function setPublic(bool _isPublic) external onlyOwner {
    isPublic = _isPublic;
  }

  function withdraw() external onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}