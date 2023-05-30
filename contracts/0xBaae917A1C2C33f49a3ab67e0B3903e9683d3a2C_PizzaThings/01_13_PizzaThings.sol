// SPDX-License-Identifier: MIT

//  ________  ___  ________  ________  ________          _________  ___  ___  ___  ________   ________  ________      
// |\   __  \|\  \|\_____  \|\_____  \|\   __  \        |\___   ___\\  \|\  \|\  \|\   ___  \|\   ____\|\   ____\     
// \ \  \|\  \ \  \\|___/  /|\|___/  /\ \  \|\  \       \|___ \  \_\ \  \\\  \ \  \ \  \\ \  \ \  \___|\ \  \___|_    
//  \ \   ____\ \  \   /  / /    /  / /\ \   __  \           \ \  \ \ \   __  \ \  \ \  \\ \  \ \  \  __\ \_____  \   
//   \ \  \___|\ \  \ /  /_/__  /  /_/__\ \  \ \  \           \ \  \ \ \  \ \  \ \  \ \  \\ \  \ \  \|\  \|____|\  \  
//    \ \__\    \ \__\\________\\________\ \__\ \__\           \ \__\ \ \__\ \__\ \__\ \__\\ \__\ \_______\____\_\  \ 
//     \|__|     \|__|\|_______|\|_______|\|__|\|__|            \|__|  \|__|\|__|\|__|\|__| \|__|\|_______|\_________\
                                                                                                 
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract PizzaThings is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerWallet = 1;
  mapping (address => uint256) public ownerTokenMapping;

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
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, 'Invalid mint amount!');
    require(_mintAmount <= maxMintAmountPerTx, "Don't be greedy, only 1 slice per person...");

    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');

    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function reservedSlice(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(ownerTokenMapping[msg.sender] + _mintAmount <= maxMintAmountPerWallet, "Don't be greedy, only 1 slice per person...");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    _safeMint(_msgSender(), _mintAmount);
    ownerTokenMapping[msg.sender] += _mintAmount;
  }

  function orderNow(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(ownerTokenMapping[msg.sender] + _mintAmount <= maxMintAmountPerWallet, "Don't be greedy, only 1 slice per person...");
    _safeMint(_msgSender(), _mintAmount);
    ownerTokenMapping[msg.sender] += _mintAmount;
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      if (_exists(currentTokenId)) {
        TokenOwnership memory ownership = _ownerships[currentTokenId];

        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}