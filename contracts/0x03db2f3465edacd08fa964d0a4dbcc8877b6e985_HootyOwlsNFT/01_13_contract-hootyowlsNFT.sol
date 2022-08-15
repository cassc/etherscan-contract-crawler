// SPDX-License-Identifier: MIT
// ------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------
// [email protected]@[email protected]@@@[email protected]@@@[email protected]@@@@@@[email protected]@[email protected]@@@[email protected]@[email protected]@@@@@@@----
// [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]
// [email protected]@@@@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@@@@@----
// [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@----
// [email protected]@[email protected]@@@[email protected]@@@[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@@@@[email protected]@@@@@@----
// ------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract HootyOwlsNFT is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRootFreeMint;
  bytes32 public merkleRootWL;
  mapping(address => uint256) public numberOfMintsOnAddress;
  mapping(address => uint256) public numberOfFreeMintsOnAddress;

  string public baseURI = '';
  string public uriSuffix = '.json';
  string public preRevealBaseURI;
  
  uint256 public standardCost;
  uint256 public freeMintAddonCost;
  uint256 public whitelistCost;
  uint256 public maxSupply;
  uint256 public maxMintQuantityPerTx;
  uint256 public maxFreeMintQuantityPerTx;
  uint256 public maxMintQuantityPerAddress;
  uint256 public maxFreeMintQuantityPerAddress;

  bool public paused = true;
  bool public promoPaused = true;
  bool public whitelistPaused = true;
  bool public revealed = false;

  //bundles for mint
  uint256 public zSmallQty;
  uint256 public zSmallCost;
  uint256 public zMediumQty;
  uint256 public zMediumCost;
  uint256 public zLargeQty;
  uint256 public zLargeCost;
  uint256 public zXLargeQty;
  uint256 public zXLargeCost;
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _standardCost,
    uint256 _freeMintAddonCost,
    uint256 _whitelistCost,
    uint256 _maxSupply,
    uint256 _maxFreeMintQuantityPerTx,
    uint256 _maxMintQuantityPerTx,
    uint256 _maxFreeMintQuantityPerAddress,
    uint256 _maxMintQuantityPerAddress,
    string memory _preRevealBaseURI
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCosts(_standardCost, _freeMintAddonCost, _whitelistCost);
    setMaxSupply(_maxSupply);
    setmaxMintQuantitiesPerTx(_maxFreeMintQuantityPerTx, _maxMintQuantityPerTx);
    setmaxMintQuantitiesPerAddress(_maxFreeMintQuantityPerAddress, _maxMintQuantityPerAddress);
    setPreRevealBaseURI(_preRevealBaseURI);
  }

  modifier mintQuantityCheck(uint256 _mintQuantity) {
    require(_mintQuantity > 0 && _mintQuantity <= maxMintQuantityPerTx, 'Invalid mint quantity!');
    require(totalSupply() + _mintQuantity <= maxSupply, 'Max supply exceeded!');
    require(numberOfMintsOnAddress[msg.sender] + _mintQuantity <= maxMintQuantityPerAddress, "Sender is trying to mint more than allowed");
    _;
  }

  modifier mintPriceCheck(uint256 _mintQuantity) {
    if(_mintQuantity==zSmallQty || _mintQuantity==zMediumQty || _mintQuantity==zLargeQty || _mintQuantity==zXLargeQty){
        if(_mintQuantity == zSmallQty){
            require(msg.value >= zSmallCost, 'Insufficient funds for bundle!');
        }
        if(_mintQuantity == zMediumQty){
            require(msg.value >= zMediumCost, 'Insufficient funds for bundle!');
        }
        if(_mintQuantity == zLargeQty){
            require(msg.value >= zLargeCost, 'Insufficient funds for bundle!');
        }
        if(_mintQuantity == zXLargeQty){
            require(msg.value >= zXLargeCost, 'Insufficient funds for bundle!');
        }
    }
    else{
        require(msg.value >= standardCost * _mintQuantity, 'Insufficient funds!');
    }
    _;
  }

  modifier mintPaused(){
    require(!paused, 'The contract is paused!');
    _;
  }

  function mint(uint256 _mintQuantity) public payable mintPaused mintQuantityCheck(_mintQuantity) mintPriceCheck(_mintQuantity) nonReentrant {
    numberOfMintsOnAddress[msg.sender] += _mintQuantity;
    _safeMint(_msgSender(), _mintQuantity);
  }

  function promoMint(uint256 _mintQuantity, bytes32[] calldata _merkleProofFreeMint) public payable mintQuantityCheck(_mintQuantity) nonReentrant {
    require(!promoPaused, 'The promotion mints are paused!');
    uint256 freeMintQuantity;
    uint256 freeMintAddonQuantity;

    //get free mint quantity from cost
    if(msg.value == 0) freeMintQuantity = _mintQuantity;
    if(msg.value > 0) {
        freeMintAddonQuantity =  msg.value / freeMintAddonCost;
        freeMintQuantity = _mintQuantity - freeMintAddonQuantity;
    }

    require(freeMintQuantity <= maxFreeMintQuantityPerTx, 'Sender trying to avail too much free mints in transation!');
    require(numberOfFreeMintsOnAddress[msg.sender] + freeMintQuantity <= maxFreeMintQuantityPerAddress, "Sender cannot avail more than allowed free mints!");
    require(msg.value >= freeMintAddonCost * freeMintAddonQuantity, 'Insufficient funds!');

    //merkle check
    bytes32 leafFreeMint = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProofFreeMint, merkleRootFreeMint, leafFreeMint), 'Invalid proof!');

    numberOfMintsOnAddress[msg.sender] += _mintQuantity;
    numberOfFreeMintsOnAddress[msg.sender] += freeMintQuantity;
    _safeMint(_msgSender(), _mintQuantity);
  }

  function whitelistMint(uint256 _mintQuantity, bytes32[] calldata _merkleProofWL) public payable mintQuantityCheck(_mintQuantity) nonReentrant {
    require(!whitelistPaused, 'The whitelist mints are paused!');
    require(msg.value >= whitelistCost * _mintQuantity, 'Insufficient funds!');

    bytes32 leafWL = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProofWL, merkleRootWL, leafWL), 'Invalid proof!');

    numberOfMintsOnAddress[msg.sender] += _mintQuantity;
    _safeMint(_msgSender(), _mintQuantity);
  }

  function mintForAddress(uint256 _mintQuantity, address _receiver) public onlyOwner {
    numberOfMintsOnAddress[_receiver] += _mintQuantity;
    _safeMint(_receiver, _mintQuantity);
  }

  function getWalletTokens(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 0;
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return string(abi.encodePacked(preRevealBaseURI, _tokenId.toString(), uriSuffix));
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCosts(uint256 _standardCost, uint256 _freeMintAddonCost, uint256 _whitelistCost) public onlyOwner {
    standardCost = _standardCost;
    freeMintAddonCost = _freeMintAddonCost;
    whitelistCost = _whitelistCost;
  }

  function setmaxMintQuantitiesPerTx(uint256 _maxFreeMintQuantityPerTx, uint256 _maxMintQuantityPerTx) public onlyOwner {
    maxFreeMintQuantityPerTx = _maxFreeMintQuantityPerTx;
    maxMintQuantityPerTx = _maxMintQuantityPerTx;
  }

  function setmaxMintQuantitiesPerAddress(uint256 _maxFreeMintQuantityPerAddress, uint256 _maxMintQuantityPerAddress) public onlyOwner {
    maxFreeMintQuantityPerAddress = _maxFreeMintQuantityPerAddress;
    maxMintQuantityPerAddress = _maxMintQuantityPerAddress;
  }

  function setPreRevealBaseURI(string memory _preRevealBaseURI) public onlyOwner {
    preRevealBaseURI = _preRevealBaseURI;
  }

  function setBaseURI(string memory __baseURI) public onlyOwner {
    baseURI = __baseURI;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state, bool _promoState, bool _whitelistState) public onlyOwner {
    paused = _state;
    promoPaused = _promoState;
    whitelistPaused = _whitelistState;
  }

  function setMerkleRoot(bytes32 _merkleRootFreeMint, bytes32 _merkleRootWL) public onlyOwner {
    merkleRootFreeMint = _merkleRootFreeMint;
    merkleRootWL = _merkleRootWL;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setMintBundles(uint256 _zSmallQty,uint256 _zSmallCost,uint256 _zMediumQty,uint256 _zMediumCost,uint256 _zLargeQty,uint256 _zLargeCost,uint256 _zXLargeQty,uint256 _zXLargeCost) public onlyOwner {
    zSmallQty = _zSmallQty;
    zSmallCost = _zSmallCost;
    zMediumQty = _zMediumQty;
    zMediumCost = _zMediumCost;
    zLargeQty = _zLargeQty;
    zLargeCost = _zLargeCost;
    zXLargeQty = _zXLargeQty;
    zXLargeCost = _zXLargeCost;
  }

}