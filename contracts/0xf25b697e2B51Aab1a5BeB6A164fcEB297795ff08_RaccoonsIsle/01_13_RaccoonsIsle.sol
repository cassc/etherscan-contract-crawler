// SPDX-License-Identifier: MIT

// ______  ___  _____  _____ _____  _____ _   _  _____   _____ _____ _      _____
// | ___ \/ _ \/  __ \/  __ \  _  ||  _  | \ | |/  ___| |_   _/  ___| |    |  ___|
// | |_/ / /_\ \ /  \/| /  \/ | | || | | |  \| |\ `--.    | | \ `--.| |    | |__
// |    /|  _  | |    | |   | | | || | | | . ` | `--. \   | |  `--. \ |    |  __|
// | |\ \| | | | \__/\| \__/\ \_/ /\ \_/ / |\  |/\__/ /  _| |_/\__/ / |____| |___
// \_| \_\_| |_/\____/ \____/\___/  \___/\_| \_/\____/   \___/\____/\_____/\____/

pragma solidity 0.8.13;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract RaccoonsIsle is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  event MintSuccessfully(address indexed _from);

  bytes32 public ogMerkleRoot;
  bytes32 public wlMerkleRoot;
  mapping(address => uint256) public whitelistClaimed;
  mapping(address => uint256) public ogClaimed;

  string private _baseTokenURI;
  string public hiddenMetadataUri;

  uint256 public mintPrice;
  uint256 public ogMintAmount;
  uint256 public wlMintAmount;
  uint256 public maxSupply = 6500;
  uint256 public reserved = 150;
  uint256 public maxPerTransaction = 6;

  bool public paused = true;
  bool public presaleEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _mintPrice,
    uint256 _ogMintAmount,
    uint256 _wlMintAmount,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setMintPrice(_mintPrice);
    setOGMintAmount(_ogMintAmount);
    setWLMintAmount(_wlMintAmount);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    uint256 availableSupply = maxSupply - reserved;
    require(totalSupply() + _mintAmount <= availableSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= mintPrice * _mintAmount, 'Insufficient funds!');
    _;
  }

  // Mint
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _wlMerkleRoot) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(presaleEnabled, 'The presale is not enabled!');

    uint256 mintNumber =  whitelistClaimed[_msgSender()] + _mintAmount;
    require(wlMintAmount >= mintNumber, 'Exceed whitelist mint amount');

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_wlMerkleRoot, wlMerkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = whitelistClaimed[_msgSender()] + _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
    emit MintSuccessfully(msg.sender);
  }

  function ogMint(uint256 _mintAmount, bytes32[] calldata _ogMerkleRoot) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(presaleEnabled, 'The presale is not enabled!');

    uint256 mintNumber =  ogClaimed[_msgSender()] + _mintAmount;
    require(ogMintAmount >= mintNumber, 'Exceed OG mint amount');

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_ogMerkleRoot, ogMerkleRoot, leaf), 'Invalid proof!');

    ogClaimed[_msgSender()] = ogClaimed[_msgSender()] + _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
    emit MintSuccessfully(msg.sender);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The sale is paused!');

    _safeMint(_msgSender(), _mintAmount);
    emit MintSuccessfully(msg.sender);
  }

  function reservedMint() public onlyOwner() {
    _safeMint(owner(), reserved);
    reserved = 0;
  }

  /**
    * @dev It is for the dev team to test the mint function.
    */
  function devMint() public payable onlyOwner() mintCompliance(1) {
    require(reserved > 0, 'Exceed reserved amount');
    require(msg.value > 0, 'Insufficient funds!');

    _safeMint(_msgSender(), 1);
    reserved = reserved - 1;
  }

  function giveAway(address _to, uint256 _amount) external onlyOwner() mintCompliance(_amount) {
    _safeMint(_to, _amount);
  }

  // Setter
  function setMintPrice(uint256 _mintPrice) public onlyOwner {
    mintPrice = _mintPrice;
  }

  function setOGMintAmount(uint256 _ogMintAmount) public onlyOwner {
    ogMintAmount = _ogMintAmount;
  }

  function setWLMintAmount(uint256 _wlMintAmount) public onlyOwner {
    wlMintAmount = _wlMintAmount;
  }

  function setOGMerkleRoot(bytes32 _ogMerkleRoot) public onlyOwner {
    ogMerkleRoot = _ogMerkleRoot;
  }

  function setWLMerkleRoot(bytes32 _wlMerkleRoot) public onlyOwner {
    wlMerkleRoot = _wlMerkleRoot;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setPresaleEnabled(bool _state) public onlyOwner {
    presaleEnabled = _state;
  }

  function setMaxPerTransaction(uint256 _amount) public onlyOwner {
    maxPerTransaction = _amount;
  }

  function remainingOgMintAmount() public view returns (uint256) {
    uint256 remaining = ogMintAmount - ogClaimed[_msgSender()];
    return remaining;
  }

  function remainingWlMintAmount() public view returns (uint256) {
    uint256 remaining = wlMintAmount - whitelistClaimed[_msgSender()];
    return remaining;
  }

  // Token
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
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString())) : '';
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success, "Transfer failed.");
  }
}