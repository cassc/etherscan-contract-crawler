// SPDX-License-Identifier: MIT
//
// 
//          .88b  d88.  .d8b.  db    db d8888b. d88888b d8888b. d88888b 
//   db db  88'YbdP`88 d8' `8b `8b  d8' 88  `8D 88'     88  `8D 88'     
//  C88888D 88  88  88 88ooo88  `8bd8'  88oodD' 88ooooo 88oodD' 88ooooo 
//   88 88  88  88  88 88~~~88  .dPYb.  88~~~   88~~~~~ 88~~~   88~~~~~ 
//  C88888D 88  88  88 88   88 .8P  Y8. 88      88.     88      88.     
//   YP YP  YP  YP  YP YP   YP YP    YP 88      Y88888P 88      Y88888P 
//                                                                    
//                                                               
//
//
// d88888b db    db  .o88b. db   dD       d888b   .d88b.  d8888b. db      d888888b d8b   db d888888b  .d88b.  db   d8b   db d8b   db 
// 88'     88    88 d8P  Y8 88 ,8P'      88' Y8b .8P  Y8. 88  `8D 88        `88'   888o  88 `~~88~~' .8P  Y8. 88   I8I   88 888o  88 
// 88ooo   88    88 8P      88,8P        88      88    88 88oooY' 88         88    88V8o 88    88    88    88 88   I8I   88 88V8o 88 
// 88~~~   88    88 8b      88`8b        88  ooo 88    88 88~~~b. 88         88    88 V8o88    88    88    88 Y8   I8I   88 88 V8o88 
// 88      88b  d88 Y8b  d8 88 `88.      88. ~8~ `8b  d8' 88   8D 88booo.   .88.   88  V888    88    `8b  d8' `8b d8'8b d8' 88  V888 
// YP      ~Y8888P'  `Y88P' YP   YD       Y888P   `Y88P'  Y8888P' Y88888P Y888888P VP   V8P    YP     `Y88P'   `8b8' `8d8'  VP   V8P 
//

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract PixelPepeWTF is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public MAX_FREE_SUPPLY = '888';
  string public MAX_TOTAL_SUPPLY = '3333';
  string public MAX_PER_WALLET = '20';
  string public PRICE_AFTER_FREE = '0.0005 EASY DOUBLE YA CHEAP BASTARD';
  string public isPepe = 'TRUE';
  string public isPixel = 'TRUE';
  string public isHorny = 'TRUE';
  string public pepe1ETH = 'TRUE';

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

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
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'PEPES SOLD OUT MAH BOI');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'YA TOO BROKE FOR DIS MINT BOIII');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
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
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}