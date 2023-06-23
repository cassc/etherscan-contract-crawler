// SPDX-License-Identifier: MIT

// .____                        .__      _________ __                 
// |    |    ____   ____ _____  |  |    /   _____//  |______ _______  
// |    |   /  _ \_/ ___\\__  \ |  |    \_____  \\   __\__  \\_  __ \ 
// |    |__(  <_> )  \___ / __ \|  |__  /        \|  |  / __ \|  | \/ 
// |_______ \____/ \___  >____  /____/ /_______  /|__| (____  /__|    
//         \/          \/     \/               \/           \/        
// 
//    ⋆｡ We will have a continuation here. ｡⋆
//  For more information check our official website: thelocalstar.xyz         
//
//
//    ___    ___       ________      
//  _|\  \__|\  \     |\   ____\     
// |\   ____\ \  \    \ \  \___|_    
// \ \  \___|\ \  \    \ \_____  \   
//  \ \_____  \ \  \____\|____|\  \  
//   \|____|\  \ \_______\____\_\  \ 
//     ____\_\  \|_______|\_________\
//    |\___    __\       \|_________|
//    \|___|\__\_|                   
//         \|__|                     

// //

pragma solidity 0.8.17;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './DefaultOperatorFilterer.sol';

contract LocalStar is ERC721AQueryable, DefaultOperatorFilterer, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;


  mapping(address => uint) public publicSaleClaimedCounter;
  mapping(address => bool) public isFreeMintClaimed;
  mapping(address => bool) public isWhitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public publicCost;
  uint256 public wlCost;

  
  uint public wlCounter;
  uint public publicSaleLimit;
  uint public wlSupplyLimit = 1111;

  bool public paused = false;
  bool public whitelistMintEnabled = true;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  
    publicSaleLimit = 6;
    wlCost = 0.003 ether;
    publicCost = 0.005 ether;
  }


    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount)  {
    require(!paused, 'The contract is paused!');


          require(msg.value >= publicCost * _mintAmount, 'Insufficient funds!');
          require(publicSaleClaimedCounter[tx.origin] + _mintAmount <= publicSaleLimit, "you're out of publicSale limit");
          publicSaleClaimedCounter[tx.origin] += _mintAmount;
          _safeMint(tx.origin, _mintAmount);

  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }
  
  
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require (wlCounter + _mintAmount <= wlSupplyLimit, "all wl tokens have been minted");
    require(!isWhitelistClaimed[tx.origin], "you're already mint in wl phase");

    
    
    bytes32 leaf = keccak256(abi.encodePacked(tx.origin));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    if(_mintAmount == 1) {
      isWhitelistClaimed[tx.origin] = true;
      _safeMint(tx.origin, _mintAmount);
      

    } else {
          require(_mintAmount <= 3, "too much for wl");
          require(msg.value >= wlCost * _mintAmount, 'Insufficient funds!');
   
           isWhitelistClaimed[tx.origin] = true;

          _safeMint(tx.origin, _mintAmount);


    }

    wlCounter += _mintAmount;

  }

  function freeMint() public mintCompliance(1) {
    require(!isFreeMintClaimed[tx.origin], "you're already minted free token");

      uint counter;

      for (uint256 index = 0; index < 555 ; index++) {
        counter ++;
      }

              _safeMint(tx.origin, 1);


  }
  
  function setPublicSaleLimit(uint _value) public onlyOwner {
    publicSaleLimit = _value;
  }

  function setWlSupplyLimit(uint _value) public onlyOwner {
    wlSupplyLimit = _value;
  }

  function setPublicCost(uint _value) public onlyOwner {
    publicCost = _value;
  }

  
  function setWlCost(uint _value) public onlyOwner {
    wlCost = _value;
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

   function AirDrop(address[] calldata _to) public onlyOwner() {
    
    for (uint256 i = 0; i < _to.length; i++) {
         _safeMint(_to[i], 1);

    }
  }

  function burn(uint256 _tokenId) public {
    require(ownerOf(_tokenId) == tx.origin, "not owner of token");
    _burn(_tokenId);

  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
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

    (bool os, ) = payable(0xe43ebaD53e5A179E54836eBf4169276539b0a19D).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}