// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/ERC2981/ERC2981Base.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AFTERLIF3 ERC721 Token
 * Built with ♥ by the ProductShop team
 * @author ahm3d, Thierry, RyadMM
 */

contract AFTERLIF3 is ERC721A, ERC2981Base, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public constant BASE_EXTENSION = ".json";

  uint256 internal _cost = 0.088 ether;
  uint256 internal _maxSupply = 8888;
  uint256 internal _maxMintBatchQuantity = 2;
  bytes32 internal _merkleRootHash;
  string internal _baseTokenURI;
  RoyaltyInfo internal _royalties;

  bool public _paused = true;
  bool public _allowedListRestricted = true;

  constructor(
    string memory name,
    string memory symbol,
    string memory initBaseURI
  ) ERC721A(name, symbol) {
    setBaseTokenURI(initBaseURI);
  }

  // modifiers
  modifier noContractCaller() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier isNotPaused() {
    require(!_paused, "The contract is paused");
    _;
  }

  modifier isMintQuantityCompliant(uint256 mintQuantity) {
    require(mintQuantity > 0, "Need to mint at least 1 NFT");

    if (msg.sender != owner()) {
      require(
        mintQuantity <= _maxMintBatchQuantity,
        "Max mint amount per session exceeded"
      );
    }

    require(
      totalSupply() + mintQuantity <= _maxSupply,
      "Max NFT limit exceeded"
    );
    _;
  }

  modifier isMintPaymentCompliant(uint256 mintQuantity) {
    require(msg.value >= _cost * mintQuantity, "Insufficient funds");
    _;
  }

  modifier isAllowedListCompliant(
    uint256 mintQuantity,
    bytes32[] calldata proof
  ) {
    require(_getAux(msg.sender) == 0, "Mint allocation already claimed");

    require(
      _validateTransaction(proof, msg.sender),
      "Invalid proof, transaction not valid"
    );
    _;
  }

  // Mint functions
  function mint(uint256 mintQuantity)
    external
    payable
    isNotPaused
    nonReentrant
    noContractCaller
    isMintQuantityCompliant(mintQuantity)
    isMintPaymentCompliant(mintQuantity)
  {
    require(
      !_allowedListRestricted,
      "Minting is resctricted to the allowed list"
    );
    _safeMint(msg.sender, mintQuantity);
  }

  function allowedListMint(uint256 mintQuantity, bytes32[] calldata proof)
    external
    payable
    isNotPaused
    nonReentrant
    noContractCaller
    isMintQuantityCompliant(mintQuantity)
    isMintPaymentCompliant(mintQuantity)
    isAllowedListCompliant(mintQuantity, proof)
  {
    _setAux(msg.sender, uint64(mintQuantity));
    _safeMint(msg.sender, mintQuantity);
  }

  function mintOnBehalf(address beneficiary, uint256 mintQuantity)
    external
    nonReentrant
    onlyOwner
    isMintQuantityCompliant(mintQuantity)
  {
    _safeMint(beneficiary, mintQuantity);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), BASE_EXTENSION)
        )
        : "";
  }

  // external functions

  function royaltyInfo(uint256, uint256 value)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    RoyaltyInfo memory royalties = _royalties;
    receiver = royalties.recipient;
    royaltyAmount = (value * royalties.amount) / 10000;
  }

  // internal functions

  function _startTokenId()
    internal
    view
    virtual
    override(ERC721A)
    returns (uint256)
  {
    return 1;
  }

  function _validateTransaction(bytes32[] memory proof, address user)
    internal
    view
    returns (bool)
  {
    return
      MerkleProof.processProof(proof, keccak256(abi.encodePacked(user))) ==
      _merkleRootHash;
  }

  function _baseURI() internal view override(ERC721A) returns (string memory) {
    return _baseTokenURI;
  }

  // setters - Owner only

  /// @dev Sets token royalties
  /// @param recipient recipient of the royalties
  /// @param value percentage (using 2 decimals : 10000 = 100%, 0 = 0%)
  function setRoyalties(address recipient, uint256 value) external onlyOwner {
    require(value <= 10000, "ERC2981Royalties: Too high");
    _royalties = RoyaltyInfo(recipient, uint24(value));
  }

  function setBaseTokenURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setPaused(bool paused) external onlyOwner {
    _paused = paused;
  }

  function setMaxMintBatchQuantity(uint256 maxMintBatchQuantity)
    external
    onlyOwner
  {
    _maxMintBatchQuantity = maxMintBatchQuantity;
  }

  function setAllowedListRestricted(bool restricted) external onlyOwner {
    _allowedListRestricted = restricted;
  }

  function setMaxSupply(uint256 maxSupply) external onlyOwner {
    _maxSupply = maxSupply;
  }

  function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner {
    _merkleRootHash = merkleRootHash;
  }

  function setClaimedAmountForAddress(address user, uint64 claimedAmount)
    external
    onlyOwner
  {
    _setAux(user, claimedAmount);
  }

  function setCost(uint256 cost) external onlyOwner {
    _cost = cost;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981Base)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function withdraw() external nonReentrant onlyOwner {
    (bool os, ) = (owner()).call{value: address(this).balance}("");
    require(os);
  }
}