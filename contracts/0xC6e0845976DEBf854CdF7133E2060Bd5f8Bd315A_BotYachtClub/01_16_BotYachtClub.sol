// SPDX-License-Identifier: MIT

/*______               __   __      __                   __          __       ______   __            __       
/       \             /  | /  \    /  |                 /  |        /  |     /      \ /  |          /  |      
$$$$$$$  |  ______   _$$ |_$$  \  /$$/______    _______ $$ |____   _$$ |_   /$$$$$$  |$$ | __    __ $$ |____  
$$ |__$$ | /      \ / $$   |$$  \/$$//      \  /       |$$      \ / $$   |  $$ |  $$/ $$ |/  |  /  |$$      \ 
$$    $$< /$$$$$$  |$$$$$$/  $$  $$/ $$$$$$  |/$$$$$$$/ $$$$$$$  |$$$$$$/   $$ |      $$ |$$ |  $$ |$$$$$$$  |
$$$$$$$  |$$ |  $$ |  $$ | __ $$$$/  /    $$ |$$ |      $$ |  $$ |  $$ | __ $$ |   __ $$ |$$ |  $$ |$$ |  $$ |
$$ |__$$ |$$ \__$$ |  $$ |/  | $$ | /$$$$$$$ |$$ \_____ $$ |  $$ |  $$ |/  |$$ \__/  |$$ |$$ \__$$ |$$ |__$$ |
$$    $$/ $$    $$/   $$  $$/  $$ | $$    $$ |$$       |$$ |  $$ |  $$  $$/ $$    $$/ $$ |$$    $$/ $$    $$/ 
$$$$$$$/   $$$$$$/     $$$$/   $$/   $$$$$$$/  $$$$$$$/ $$/   $$/    $$$$/   $$$$$$/  $$/  $$$$$$/  $$$$$$*/

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract BotYachtClub is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;

  mapping(address => uint) public whitelistClaimed;
  mapping(address => bool) private controllers; 

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxWhitelistPerWallet = 4;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    addController(_msgSender());
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

// ~~~~~~~~~~~~~~~~~~~~ Modifiers ~~~~~~~~~~~~~~~~~~~~
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  modifier onlyController() {
    require(controllers[_msgSender()], "This wallet is not authorized to call this function");
    _;
  }

// ~~~~~~~~~~~~~~~~~~~~ Mint functions ~~~~~~~~~~~~~~~~~~~~
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    require(whitelistClaimed[_msgSender()] + _mintAmount <= maxWhitelistPerWallet, "Exceeds whitelist claim amount!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

// ~~~~~~~~~~~~~~~~~~~~ Various checks ~~~~~~~~~~~~~~~~~~~~
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

// ~~~~~~~~~~~~~~~~~~~~ onlyController functions ~~~~~~~~~~~~~~~~~~~~
  function setRevealed(bool _state) public onlyController {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyController {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyController {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyController {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyController {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyController {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyController {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyController {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyController {
    whitelistMintEnabled = _state;
  }

// ~~~~~~~~~~~~~~~~~~~~ onlyOwner functions ~~~~~~~~~~~~~~~~~~~~
  function addController(address _address) public onlyOwner {
    controllers[_address] = true;
  }

  function removeController(address _address) public onlyOwner {
    require(_address != owner(), "Can not remove owner, or else owner would lose control over onlyController functions");
    controllers[_address] = false;
  }

// ~~~~~~~~~~~~~~~~~~~~ Withdraw functions ~~~~~~~~~~~~~~~~~~~~
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
}