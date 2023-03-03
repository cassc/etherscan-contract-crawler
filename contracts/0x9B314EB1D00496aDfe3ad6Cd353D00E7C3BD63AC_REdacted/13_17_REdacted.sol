// SPDX-License-Identifier: MIT

//  _______   ________       __                        __                      __
// |       \ |        \     |  \                      |  \                    |  \
// | $$$$$$$\| $$$$$$$$ ____| $$  ______    _______  _| $$_     ______    ____| $$
// | $$__| $$| $$__    /      $$ |      \  /       \|   $$ \   /      \  /      $$
// | $$    $$| $$  \  |  $$$$$$$  \$$$$$$\|  $$$$$$$ \$$$$$$  |  $$$$$$\|  $$$$$$$
// | $$$$$$$\| $$$$$  | $$  | $$ /      $$| $$        | $$ __ | $$    $$| $$  | $$
// | $$  | $$| $$_____| $$__| $$|  $$$$$$$| $$_____   | $$|  \| $$$$$$$$| $$__| $$
// | $$  | $$| $$     \\$$    $$ \$$    $$ \$$     \   \$$  $$ \$$     \ \$$    $$
//  \$$   \$$ \$$$$$$$$ \$$$$$$$  \$$$$$$$  \$$$$$$$    \$$$$   \$$$$$$$  \$$$$$$$

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract REdacted is ERC721AQueryable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  event MintSuccessfully(address indexed minter, uint256 totalSupply);
  event MintEnabled(string mintType, bool enabled);
  event MintPaused(bool paused);

  bytes32 public ogMerkleRoot;
  bytes32 public whitelistMerkleRoot;
  bytes32 public waitlistMerkleRoot;

  mapping(address => bool) public ogClaimed;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public waitlistClaimed;

  string private _baseTokenURI;
  string public hiddenMetadataUri;

  uint256 public maxSupply;
  uint256 public reserved;
  uint256 public ogMintPrice;
  uint256 public whitelistMintPrice;
  uint256 public waitlistMintPrice;
  uint256 public publicMintPrice;

  bool public paused = true;
  bool public revealed = false;
  bool public ogMintEnabled = false;
  bool public whitelistMintEnabled = false;
  bool public waitlistMintEnabled = false;
  bool public publicMintEnabled = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _ogMintPrice,
    uint256 _whitelistMintPrice,
    uint256 _waitlistMintPrice,
    uint256 _publicMintPrice,
    uint256 _maxSupply,
    uint256 _reserved,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    reserved = _reserved;
    ogMintPrice = _ogMintPrice;
    whitelistMintPrice = _whitelistMintPrice;
    waitlistMintPrice = _waitlistMintPrice;
    publicMintPrice = _publicMintPrice;
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  // Mint methods
  modifier mintCompliance {
    require(!paused, "The mint is paused!");
    uint256 availableSupply = maxSupply - reserved;
    require(totalSupply() + 1 <= availableSupply, "Max supply exceeded!");
    _;
  }

  function mintPriceCompliance (uint256 _mintPrice) internal view {
    require(msg.value >= _mintPrice, "Insufficient funds!");
  }

  function ogMint(bytes32[] calldata _ogMerkleRoot) public payable mintCompliance {
    require(ogMintEnabled, "OG mint is not enabled!");
    require(!ogClaimed[_msgSender()], "You have already minted!");

    mintPriceCompliance(ogMintPrice);

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_ogMerkleRoot, ogMerkleRoot, leaf), "You are not OG!");

    ogClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), 1);

    emit MintSuccessfully(msg.sender, totalSupply());
  }

  function whitelistMint(bytes32[] calldata _whitelistMerkleRoot) public payable mintCompliance {
    require(whitelistMintEnabled, "Whitelist mint is not enabled!");
    require(!whitelistClaimed[_msgSender()], "You have already minted!");

    mintPriceCompliance(whitelistMintPrice);

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_whitelistMerkleRoot, whitelistMerkleRoot, leaf), "You are not whitelisted!");

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), 1);

    emit MintSuccessfully(msg.sender, totalSupply());
  }

  function waitlistMint(bytes32[] calldata _waitlistMerkleRoot) public payable mintCompliance {
    require(waitlistMintEnabled, "Waitlist mint is not enabled!");
    require(!waitlistClaimed[_msgSender()], "You have already minted!");

    mintPriceCompliance(waitlistMintPrice);

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_waitlistMerkleRoot, waitlistMerkleRoot, leaf), "You are not waitlisted!");

    waitlistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), 1);

    emit MintSuccessfully(msg.sender, totalSupply());
  }

  function publicMint() public payable mintCompliance {
    require(publicMintEnabled, "Public mint is not enabled!");

    mintPriceCompliance(publicMintPrice);

    _safeMint(_msgSender(), 1);

    emit MintSuccessfully(msg.sender, totalSupply());
  }

  function reservedMint() public onlyOwner() {
    _safeMint(owner(), reserved);
    reserved = 0;

    emit MintSuccessfully(msg.sender, totalSupply());
  }

  function devMint() public payable onlyOwner() mintCompliance {
    require(reserved > 0, "Exceed reserved supply!");
    mintPriceCompliance(publicMintPrice);

    _safeMint(owner(), 1);
    reserved = reserved - 1;

    emit MintSuccessfully(msg.sender, totalSupply());
  }

  // Setters
  function setOgMintPrice(uint256 _ogMintPrice) public onlyOwner {
    ogMintPrice = _ogMintPrice;
  }

  function setWhitelistMintPrice(uint256 _whitelistMintPrice) public onlyOwner {
    whitelistMintPrice = _whitelistMintPrice;
  }

  function setWaitlistMintPrice(uint256 _waitlistMintPrice) public onlyOwner {
    waitlistMintPrice = _waitlistMintPrice;
  }

  function setPublicMintPrice(uint256 _publicMintPrice) public onlyOwner {
    publicMintPrice = _publicMintPrice;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
    emit MintPaused(_state);
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setOgMintEnabled(bool _state) public onlyOwner {
    ogMintEnabled = _state;
    emit MintEnabled("OG", _state);
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
    emit MintEnabled("WHITELIST", _state);
  }

  function setWaitlistMintEnabled(bool _state) public onlyOwner {
    waitlistMintEnabled = _state;
    emit MintEnabled("WAITLIST", _state);
  }

  function setPublicMintEnabled(bool _state) public onlyOwner {
    publicMintEnabled = _state;
    emit MintEnabled("PUBLIC", _state);
  }

  function setOgMerkleRoot(bytes32 _ogMerkleRoot) public onlyOwner {
    ogMerkleRoot = _ogMerkleRoot;
  }

  function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) public onlyOwner {
    whitelistMerkleRoot = _whitelistMerkleRoot;
  }

  function setWaitlistMerkleRoot(bytes32 _waitlistMerkleRoot) public onlyOwner {
    waitlistMerkleRoot = _waitlistMerkleRoot;
  }

  // Token metadata
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString())) : "";
  }

  // Only owner methods
  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}