// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";



//  ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗██╗    ██╗ █████╗ ██╗     ██╗  ██╗███████╗██████╗ ███████╗
//  ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██║    ██║██╔══██╗██║     ██║ ██╔╝██╔════╝██╔══██╗██╔════╝
//  ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║██║ █╗ ██║███████║██║     █████╔╝ █████╗  ██████╔╝███████╗
//  ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║██║███╗██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗╚════██║
//  ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║╚███╔███╔╝██║  ██║███████╗██║  ██╗███████╗██║  ██║███████║
//  ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝



/// @title The Moonwalkers NFT Smart Contract.
/// @author The Moonwalkers NFT project.
/// @notice This contract allows users to mint and transfer the Moonwalkers NFTs.
/// @dev The contract inherits from the ERC721A contract.
contract Moonwalkers is ERC721A, Pausable, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using SafeMath for uint256;

  /// @dev Sale configuration struct.
  struct SaleConfig {
    uint256 publicSaleMintPrice;
    uint256 presaleMintPrice;
    uint256 maxPublicMintPerWallet;
    uint256 maxWhitelistMintPerWallet;
    uint256 maxAlphaMintPerWallet;
    uint256 publicSaleStartTime;
    uint256 presaleStartTime;
  }

  /// @dev Sale configuration instance.
  SaleConfig public saleConfig;

  /// @dev Sale State.
  bool private saleState;

  /// @dev Sale Revealed.
  bool private isRevealed;

  /// @dev Maximum supply.
  uint256 private maxSupply;

  /// @dev Merke root that contains all the whitelisted addresses.
  bytes32 private merkleRootWhitelist;

  /// @dev Merke root that contains all the alpha addresses.
  bytes32 private merkleRootAlpha;

  /// @dev Mapping of the amount of NFT minted by a whitelisted/alpha address during the presale.
  mapping(address => uint256) private amountMintedWhitelist;

  /// @dev Mapping of the amount of NFT minted by an address during the public sale.
  mapping(address => uint256) private amountMintedPublic;

  /// @dev Base token URI used as a prefix by tokenURI().
  string private baseTokenURI;

  /// @dev Base token URI used as a suffix by tokenURI().
  string private extensionTokenURI;

  /// @dev Unrevealed toke URI.
  string private unrevealedTokenURI;

  /// @dev Constructor.
  constructor(uint256 _maxSupply) ERC721A("Moonwalkers", "MW") {
    baseTokenURI = "";
    extensionTokenURI = ".json";
    unrevealedTokenURI = "";
    saleConfig.publicSaleMintPrice = 0.1 ether;
    saleConfig.presaleMintPrice = 0.08 ether;
    saleConfig.presaleStartTime = 1652635800;
    saleConfig.publicSaleStartTime = 1652643000;
    saleConfig.maxWhitelistMintPerWallet = 2;
    saleConfig.maxAlphaMintPerWallet = 4;
    saleConfig.maxPublicMintPerWallet = 4;
    maxSupply = _maxSupply;
    isRevealed = false;
    saleState = true;
  }

  /// @dev Modifier used in the mint functions in order to stop/unstop the mint.
  modifier whenNotLocked() {
      require(saleState, "Sale is locked.");
      _;
  }

  /// @dev Modifier used in the mint functions in order to avoid contract calls.
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract.");
    _;
  }

  /// @dev Pause the contract.
  function pause() external onlyOwner {
    _pause();
  }

  /// @dev Unpause the contract.
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @dev Making the token transfer pausable.
  function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal whenNotPaused override {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  /// @dev Public sale mint function.
  function publicSaleMint(uint256 _mintAmount) external payable whenNotLocked callerIsUser {
    SaleConfig memory config = saleConfig;
    require(block.timestamp > config.publicSaleStartTime, "Public sale has not started yet.");
    require(_totalMinted().add(_mintAmount) < maxSupply.add(1), "Max supply reached.");
    require(msg.value == config.publicSaleMintPrice.mul(_mintAmount), "Tr. value did not equal the mint price.");
    require(amountMintedPublic[msg.sender].add(_mintAmount) < config.maxPublicMintPerWallet.add(1), "You cannot mint that much.");

    amountMintedPublic[msg.sender] += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

  /// @dev Presale mint function. Only the whitelisted and alpha addresses are able to mint during the presale.
  function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable whenNotLocked callerIsUser {
    SaleConfig memory config = saleConfig;
    require(block.timestamp > config.presaleStartTime && block.timestamp < config.publicSaleStartTime, "Presale is closed.");
    require(_totalMinted().add(_mintAmount) < maxSupply.add(1), "Max supply reached.");
    require(msg.value == config.presaleMintPrice.mul(_mintAmount), "Tr. value did not equal the mint price.");
    require(amountMintedWhitelist[msg.sender].add(_mintAmount) < config.maxWhitelistMintPerWallet.add(1), "You cannot mint that much.");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRootWhitelist, leaf), "Invalid Merkle Proof.");

    amountMintedWhitelist[msg.sender] += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

  /// @dev Presale mint function for alpha addresses. Only the whitelisted and alpha addresses are able to mint during the presale.
  function alphaMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable whenNotLocked callerIsUser {
    SaleConfig memory config = saleConfig;
    require(block.timestamp > config.presaleStartTime && block.timestamp < config.publicSaleStartTime, "Presale is closed.");
    require(_totalMinted().add(_mintAmount) < maxSupply.add(1), "Max supply reached.");
    require(msg.value == config.presaleMintPrice.mul(_mintAmount), "Tr. value did not equal the mint price.");
    require(amountMintedWhitelist[msg.sender].add(_mintAmount) < config.maxAlphaMintPerWallet.add(1), "Max presale mint per address exceeded.");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRootAlpha, leaf), "Invalid Merkle Proof.");

    amountMintedWhitelist[msg.sender] += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

  /// @dev Dev mint function for admin.
  function devMint(uint256 _mintAmount) external onlyOwner {
    require(totalSupply().add(_mintAmount) < maxSupply.add(1), "Max supply reached.");

    amountMintedPublic[msg.sender] += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

  /// @dev Override the tokenURI to add our a custom base prefix and suffix.
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token.");

    if(!isRevealed) {
      return unrevealedTokenURI;
    }

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), extensionTokenURI)) : "";
  }

  /// @dev Returns an URI for a given token ID.
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  /// @dev Sets the base token URI suffix.
  function setExtensionTokenURI(string memory _extensionTokenURI) external onlyOwner {
    extensionTokenURI = _extensionTokenURI;
  }

  /// @dev Sets the unrevealed token URI.
  function setUnrevealedTokenURI(string memory _unrevealedTokenURI) external onlyOwner {
    unrevealedTokenURI = _unrevealedTokenURI;
  }

  /// @dev Sets the isRevealed state.
  function setRevealed(bool _revealState) external onlyOwner {
    isRevealed = _revealState;
  }

  /// @dev Sets the public sale mint price.
  function setPublicSaleMintPrice(uint64 _publicSaleMintPrice) external onlyOwner {
    saleConfig.publicSaleMintPrice = _publicSaleMintPrice;
  }

  /// @dev Sets the presale mint price.
  function setPresaleMintPrice(uint64 _presaleMintPrice) external onlyOwner {
    saleConfig.presaleMintPrice = _presaleMintPrice;
  }

  /// @dev Sets the presale date.
  function setPresaleStartTime(uint256 _presaleStartTime) external onlyOwner {
    saleConfig.presaleStartTime = _presaleStartTime;
  }

  /// @dev Sets the public sale date.
  function setPublicSaleStartTime(uint256 _publicSaleStartTime) external onlyOwner {
    saleConfig.publicSaleStartTime = _publicSaleStartTime;
  }

  /// @dev Sets the max public mint per wallet allowed.
  function setMaxPublicMintPerWallet(uint256 _maxPublicMintPerWallet) external onlyOwner {
    saleConfig.maxPublicMintPerWallet = _maxPublicMintPerWallet;
  }

  /// @dev Sets the max presale mint per whitelisted wallet allowed.
  function setMaxWhitelistMintPerWallet(uint256 _maxWhitelistMintPerWallet) external onlyOwner {
    saleConfig.maxWhitelistMintPerWallet = _maxWhitelistMintPerWallet;
  }

  /// @dev Sets the max presale mint per alpha wallet allowed.
  function setMaxAlphaMintPerWallet(uint256 _maxAlphaMintPerWallet) external onlyOwner {
    saleConfig.maxAlphaMintPerWallet = _maxAlphaMintPerWallet;
  }

  /// @dev Set sale state.
  function setSaleState(bool _saleState) external onlyOwner {
    saleState = _saleState;
  }

  /// @dev Set the merkle root for whitelisted addresses.
  function setMerkleRootWhitelist(bytes32 _merkleRootWhitelist) external onlyOwner {
    merkleRootWhitelist = _merkleRootWhitelist;
  }

  /// @dev Set the merkle root for alpha addresses.
  function setMerkleRootAlpha(bytes32 _merkleRootAlpha) external onlyOwner {
    merkleRootAlpha = _merkleRootAlpha;
  }

  /// @dev Set the max supply (in case we need to cut the supply).
  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  /// @dev Get the total number of NFT minted by an address (presale and public sale both included).
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  /// @dev Get the ownership data.
  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return _ownershipOf(tokenId);
  }

  /// @dev Withdraw the contract funds to the contract owner. The nonReentrant guard is useless but...safety first !
  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}