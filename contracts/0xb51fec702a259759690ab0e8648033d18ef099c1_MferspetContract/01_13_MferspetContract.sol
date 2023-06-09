// SPDX-License-Identifier: MIT
/*

███    ███ ███████ ███████ ██████  ███████ ██████  ███████ ████████ 
████  ████ ██      ██      ██   ██ ██      ██   ██ ██         ██    
██ ████ ██ █████   █████   ██████  ███████ ██████  █████      ██    
██  ██  ██ ██      ██      ██   ██      ██ ██      ██         ██    
██      ██ ██      ███████ ██   ██ ███████ ██      ███████    ██  

*/

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract MferspetContract is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public publicUriPrefix;
  string public uriSuffix = '.json';
  string public hiddenMetadataPrefix;
  string public hiddenUriCatSuffix = 'cat.json';
  string public hiddenUriDogSuffix = 'dog.json';
  string public publicHiddenUriSuffix = 'public.json';

  uint256 public publicMintCost = 0.0069 ether;
  uint256 public personalizedMintCost = 0.0169 ether;
  uint256 public maxSupply;
  uint256 public maxMferHolderFreeMintAmount = 1;
  uint256 public maxPublicMintAmount = 5;
  uint256 private maxTeamAmount = 20;
  uint256 private currentTeamAmount = 0;

  bool public paused = true;
  bool public publicMintPaused = false;
  bool public personalizedMintPaused = false;
  bool public revealed = false;

  IERC721Enumerable mferContract;

  // public mint balance
  mapping(address => uint256) public holderAddressPublicMintBalance;

  // public free mint balance
  mapping(address => uint256) public holderAddressFreeMintBalance;

  // mfer id -> bool
  mapping(uint256 => bool) public personalizedMinted;

  // mferpet id => mfer id (only for peronsalized)
  mapping(uint256 => uint256) public mferIdFromMferpetId;

  // pet token id -> if cat (true)
  mapping(uint256 => bool) public isCat;

  // pet token id -> if personalized (true)
  mapping(uint256 => bool) internal isPersonalized;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    string memory _hiddenMetadataUri,
    address _mfersContract
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    setHiddenMetadataUri(_hiddenMetadataUri);
    mferContract = IERC721Enumerable(_mfersContract);
  }

  function personalizedMint(uint256[] memory _mferIds, uint8[] memory _petTypes)
    public
    payable
  {
    require(!paused, 'The contract is paused!');
    require(!personalizedMintPaused, 'Personalied mint not open yet');
    require(
      _mferIds.length == _petTypes.length,
      'Size of mfer id must equal to size of pet types'
    );
    require(isOwnedNft(_mferIds), 'Personlized mint only for this nft holder');
    uint256 _numberOfTokens = 0;
    for (uint256 i = 0; i < _mferIds.length; i++) {
      require(
        !personalizedMinted[_mferIds[i]],
        'There exist a mfer which has been minted!'
      );
      require(
        _petTypes[i] == 1 || _petTypes[i] == 2 || _petTypes[i] == 3,
        'Invalid pet type'
      );
      // cat or dog
      if (_petTypes[i] == 1 || _petTypes[i] == 2) {
        _numberOfTokens += 1;
      }
      // both cat and dog
      else {
        _numberOfTokens += 2;
      }
    }
    require(_numberOfTokens > 0, 'Need to mint at least 1 NFT');
    uint256 supply = totalSupply();
    require(supply + _numberOfTokens <= maxSupply, 'Max supply exceeded!');
    require(
      msg.value >= _numberOfTokens * personalizedMintCost,
      'insufficient funds'
    );

    // start mint process
    uint256 tokenId = supply + 1;
    for (uint256 i = 0; i < _mferIds.length; i++) {
      // check if cat:1, dog:2, both:3
      uint256 currMferId = _mferIds[i];
      if (_petTypes[i] == 1 || _petTypes[i] == 2) {
        isPersonalized[tokenId] = true;
        mferIdFromMferpetId[tokenId] = currMferId;
        isCat[tokenId++] = _petTypes[i] == 1;
      }
      // mint both cat and dog
      else {
        // mint cat
        isPersonalized[tokenId] = true;
        mferIdFromMferpetId[tokenId] = currMferId;
        isCat[tokenId++] = true;
        // mint dog
        isPersonalized[tokenId] = true;
        mferIdFromMferpetId[tokenId] = currMferId;
        isCat[tokenId++] = false;
      }
      // mark the mfer id to avoid mint twice
      personalizedMinted[_mferIds[i]] = true;
    }
    uint256 _mintAmount = tokenId - supply - 1;
    _safeMint(_msgSender(), _mintAmount);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(
      _mintAmount > 0 && _mintAmount <= maxPublicMintAmount,
      'Invalid mint amount!'
    );
    uint256 ownerMintedCount = holderAddressPublicMintBalance[msg.sender];
    require(
      _mintAmount + ownerMintedCount <= maxPublicMintAmount,
      'Max public NFT limit exceeded'
    );
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier freeMintCompliance(uint256 _mintAmount) {
    require(
      _mintAmount > 0 && _mintAmount <= maxMferHolderFreeMintAmount,
      'Invalid free mint amount!'
    );
    uint256 ownerMintedCount = holderAddressFreeMintBalance[msg.sender];
    require(
      _mintAmount + ownerMintedCount <= maxMferHolderFreeMintAmount,
      'Max public free NFT limit exceeded'
    );
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier publicMintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= publicMintCost * _mintAmount, 'Insufficient funds!');
    _;
  }

  // personalization mint check:
  // (1) minter hold the mfer nft
  // (2) all of the mfer nft ids belong to this minter
  function isOwnedNft(uint256[] memory _mferIds) internal view returns (bool) {
    uint256 count = mferContract.balanceOf(msg.sender);
    if (count < _mferIds.length) {
      return false;
    }

    for (uint256 i = 0; i < _mferIds.length; i++) {
      if (mferContract.ownerOf(_mferIds[i]) != msg.sender) return false;
    }
    return true;
  }

  function publicFreeMint(uint256 _mintAmount)
    public
    payable
    freeMintCompliance(_mintAmount)
  {
    require(!paused && !publicMintPaused, 'Public mint not start');
    holderAddressFreeMintBalance[msg.sender] =
      _mintAmount +
      holderAddressFreeMintBalance[msg.sender];
    _safeMint(_msgSender(), _mintAmount);
  }

  function publicMint(uint256 _mintAmount)
    public
    payable
    mintCompliance(_mintAmount)
    publicMintPriceCompliance(_mintAmount)
  {
    require(!paused && !publicMintPaused, 'Public mint not start');
    holderAddressPublicMintBalance[msg.sender] =
      _mintAmount +
      holderAddressPublicMintBalance[msg.sender];
    _safeMint(_msgSender(), _mintAmount);
  }

  // This is for airdrop awarded users with personalized pet
  function mintForAddressForPersonalization(
    address _receiver,
    uint256[] memory _mferIds,
    uint8[] memory _petTypes
  ) public onlyOwner {
    uint256 _numberOfTokens = 0;
    for (uint256 i = 0; i < _mferIds.length; i++) {
      require(
        !personalizedMinted[_mferIds[i]],
        'There exist a mfer which has been minted!'
      );
      require(
        _petTypes[i] == 1 || _petTypes[i] == 2 || _petTypes[i] == 3,
        'Invalid pet type'
      );
      // cat or dog
      if (_petTypes[i] == 1 || _petTypes[i] == 2) {
        _numberOfTokens += 1;
      }
      // both cat and dog
      else {
        _numberOfTokens += 2;
      }
    }
    require(_numberOfTokens > 0, 'Need to mint at least 1 NFT');
    uint256 supply = totalSupply();
    require(supply + _numberOfTokens <= maxSupply, 'Max supply exceeded!');
    // start mint process
    uint256 tokenId = supply + 1;
    for (uint256 i = 0; i < _mferIds.length; i++) {
      // check if cat:1, dog:2, both:3
      uint256 currMferId = _mferIds[i];
      if (_petTypes[i] == 1 || _petTypes[i] == 2) {
        isPersonalized[tokenId] = true;
        mferIdFromMferpetId[tokenId] = currMferId;
        isCat[tokenId++] = _petTypes[i] == 1;
      }
      // mint both cat and dog
      else {
        // mint cat
        isPersonalized[tokenId] = true;
        mferIdFromMferpetId[tokenId] = currMferId;
        isCat[tokenId++] = true;
        // mint dog
        isPersonalized[tokenId] = true;
        mferIdFromMferpetId[tokenId] = currMferId;
        isCat[tokenId++] = false;
      }
      // mark the mfer id to avoid mint twice
      personalizedMinted[_mferIds[i]] = true;
    }
    uint256 _mintAmount = tokenId - supply - 1;
    _safeMint(_receiver, _mintAmount);
  }

  // This is for airdrop awarded users with public random pet
  function mintForAddress(uint256 _mintAmount, address _receiver)
    public
    mintCompliance(_mintAmount)
    onlyOwner
  {
    _safeMint(_receiver, _mintAmount);
  }

  function mintForTeam(uint256 _mintAmount, address _receiver)
    public
    onlyOwner
  {
    require(
      currentTeamAmount <= maxTeamAmount,
      'Max supply exceeded for team members!'
    );
    currentTeamAmount += _mintAmount;
    _safeMint(_receiver, _mintAmount);
  }

  function checkPersonalizedStatus(uint256 _tokenId)
    public
    view
    returns (bool)
  {
    require(_tokenId >= 0 && _tokenId <= 10020, 'Not valid mfer id');
    return personalizedMinted[_tokenId];
  }

  function isPersonalizedTokenId(uint256 _tokenId) public view returns (bool) {
    require(_exists(_tokenId), 'ERC721Metadata: nonexistent token');
    return isPersonalized[_tokenId];
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
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

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );

    if (revealed == false) {
      return
        isPersonalized[_tokenId]
          ? isCat[_tokenId]
            ? string(abi.encodePacked(hiddenMetadataPrefix, hiddenUriCatSuffix))
            : string(abi.encodePacked(hiddenMetadataPrefix, hiddenUriDogSuffix))
          : string(
            abi.encodePacked(hiddenMetadataPrefix, publicHiddenUriSuffix)
          );
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)
        )
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setPublicMintCost(uint256 _cost) public onlyOwner {
    publicMintCost = _cost;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataPrefix)
    public
    onlyOwner
  {
    hiddenMetadataPrefix = _hiddenMetadataPrefix;
  }

  function setPublicUriPrefix(string memory _publicUriPrefix) public onlyOwner {
    publicUriPrefix = _publicUriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setPublicMintPaused(bool _state) public onlyOwner {
    publicMintPaused = _state;
  }

  function setPersonalizedMintPaused(bool _state) public onlyOwner {
    personalizedMintPaused = _state;
  }

  function setHiddenUriCatSuffix(string memory _suffix) public onlyOwner {
    hiddenUriCatSuffix = _suffix;
  }

  function setHiddenUriDogSuffix(string memory _suffix) public onlyOwner {
    hiddenUriDogSuffix = _suffix;
  }

  function setHiddenPublicSuffix(string memory _suffix) public onlyOwner {
    publicHiddenUriSuffix = _suffix;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return publicUriPrefix;
  }
}