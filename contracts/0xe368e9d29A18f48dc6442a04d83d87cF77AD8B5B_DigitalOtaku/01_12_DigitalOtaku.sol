// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";

contract DigitalOtaku is ERC721A, Pausable, Ownable, DefaultOperatorFilterer {
  enum SaleStates {
    CLOSED,
    OPEN
  }

  SaleStates public saleState;

  bytes32 public whitelistMerkleRoot;

  uint256 public maxSupply = 777;
  uint256 public maxWhitelistTokens = 555;
  uint256 public maxPublicTokens = 222;

  uint256 public whitelistedMinted;
  uint256 public publicMinted;

  uint256 public publicSalePrice = 0.0088 ether;
  uint256 public whitelistSalePrice = 0.0066 ether;

  uint64 public maxTokensPerWallet = 3;

  string public baseURL;
  string public unRevealedURL;
  bool public isRevealed = false;

  constructor() ERC721A("DigitalOtaku", "DO") {
    _mint(msg.sender, 1);
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

  modifier canMint(uint256 numberOfTokens) {
    require(
      _totalMinted() + numberOfTokens <= maxSupply,
      "Not enough tokens remaining to mint"
    );
    _;
  }

  modifier checkState(SaleStates _saleState) {
    require(saleState == _saleState, "Sale is not active");
    _;
  }

  function whitelistMint(
    bytes32[] calldata merkleProof,
    uint64 numberOfTokens
  )
    external
    payable
    whenNotPaused
    isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    canMint(numberOfTokens)
    checkState(SaleStates.OPEN)
  {
    require(
      whitelistedMinted + numberOfTokens <= maxWhitelistTokens,
      "Minted the maximum no of public tokens"
    );

    require(
      _numberMinted(msg.sender) + numberOfTokens <= maxTokensPerWallet,
      "Maximum minting limit exceeded"
    );

    require(msg.value >= whitelistSalePrice * numberOfTokens, "Not enough ETH");

    _mint(msg.sender, numberOfTokens);
    whitelistedMinted++;
  }

  function publicMint(
    uint64 numberOfTokens
  )
    external
    payable
    whenNotPaused
    canMint(numberOfTokens)
    checkState(SaleStates.OPEN)
  {
    require(
      publicMinted + numberOfTokens <= maxPublicTokens,
      "Minted the maximum no of public tokens"
    );
    require(
      _numberMinted(msg.sender) + numberOfTokens <= maxTokensPerWallet,
      "Maximum minting limit exceeded"
    );

    require(msg.value >= publicSalePrice * numberOfTokens, "Not enough ETH");

    _mint(msg.sender, numberOfTokens);
    publicMinted++;
  }

  function mintTo(
    address to,
    uint256 numberOfTokens
  ) external canMint(numberOfTokens) onlyOwner {
    _mint(to, numberOfTokens);
  }

  function tokenURI(
    uint256 _tokenId
  ) public view override returns (string memory) {
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
          abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), ".json")
        )
        : "";
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURL;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function numberMinted(address _account) external view returns (uint256) {
    return _numberMinted(_account);
  }

  // Metadata
  function setBaseURL(string memory _baseURL) external onlyOwner {
    baseURL = _baseURL;
  }

  function setUnRevealedURL(string memory _unRevealedURL) external onlyOwner {
    unRevealedURL = _unRevealedURL;
  }

  function toggleRevealed() external onlyOwner {
    isRevealed = !isRevealed;
  }

  // Sale Price
  function setPublicSalePrice(uint256 _price) external onlyOwner {
    publicSalePrice = _price;
  }

  function setWhitelistSalePrice(uint256 _price) external onlyOwner {
    whitelistSalePrice = _price;
  }

  // CLOSED = 0, OPEN = 1
  function setSaleState(uint256 newSaleState) external onlyOwner {
    require(newSaleState <= uint256(SaleStates.OPEN), "sale state not valid");
    saleState = SaleStates(newSaleState);
  }

  // Max Tokens Per Wallet
  function setMaxTokensPerWallet(
    uint64 _maxTokensPerWallet
  ) external onlyOwner {
    maxTokensPerWallet = _maxTokensPerWallet;
  }

  function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    whitelistMerkleRoot = merkleRoot;
  }

  function setMaxWhitelistTokens(
    uint256 _maxWhitelistTokens
  ) external onlyOwner {
    maxWhitelistTokens = _maxWhitelistTokens;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function withdraw() external onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}