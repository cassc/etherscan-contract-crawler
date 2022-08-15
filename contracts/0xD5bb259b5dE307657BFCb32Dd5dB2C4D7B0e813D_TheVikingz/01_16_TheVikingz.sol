// SPDX-License-Identifier: MIT
//_______________________v____________________________
//_______________________$q___________________________
//______________________3¶¶v__________________________
//______________________¶¶¶¶__________________________
//_____________________¶¶¶¶¶o_______qqv_______________
//____________________$¶¶¶¶¶¶¶_______¶¶¶¶¶¶3__________
//___________________¶¶¶¶¶¶¶¶¶q______o¶¶¶¶¶¶¶¶________
//__________________3¶¶¶¶¶¶¶¶¶¶q_____v¶¶¶¶¶¶¶¶¶¶______
//___________________$¶¶¶¶¶¶¶¶_______3¶¶¶¶¶¶¶¶¶¶¶$____
//____________________¶¶¶¶¶¶¶3_______¶¶¶¶¶¶¶¶¶¶¶¶¶¶___
//_________¶¶v_________$¶¶¶¶o_____v¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶__
//_________q¶¶¶¶¶o_____¶¶¶¶¶____o¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶__
//_____o¶$¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶o_
//oq$¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶q_
//_________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶v_
//_________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶__
//_________¶¶3o_______¶¶¶¶¶¶¶¶____¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶o__
//____________________¶¶¶¶¶¶¶¶______3¶¶¶¶¶¶¶¶¶¶¶¶¶v___
//____________________¶¶¶¶¶¶¶¶_______¶¶¶¶¶¶¶¶¶¶¶¶_____
//____________________¶¶¶¶¶¶¶¶________¶¶¶¶¶¶¶¶$_______
//____________________¶¶¶¶¶¶¶¶________¶¶¶¶¶$__________
//____________________¶¶¶¶¶¶¶¶________________________
//____________________¶¶¶¶¶¶¶¶________________________
//____________________¶¶¶¶¶¶¶¶________________________
//____________________¶¶¶¶¶¶¶¶________________________
//____________________¶¶¶¶¶¶¶¶________________________
//____________________¶¶¶¶¶¶¶¶________________________
//____________________¶¶¶¶¶¶¶¶________________________
//____________________¶¶¶¶¶¶¶¶________________________
//____________________¶¶¶¶¶¶¶¶________________________
//____________________¶¶¶¶¶¶¶¶________________________
//____________________¶¶¶¶¶¶¶¶________________________
//____________________¶¶¶¶¶¶¶¶________________________
//___________________v¶¶¶¶¶¶¶¶________________________
//___________________v¶¶¶¶¶¶¶¶________________________
//___________________v¶¶¶¶¶¶¶¶________________________
//___________________v¶¶¶¶¶¶¶¶________________________
//___________________o¶¶¶¶¶¶¶¶________________________
//___________________o¶¶¶¶¶¶¶¶v_______________________
//___________________o¶¶¶¶¶¶¶¶v_______________________
//___________________q¶¶¶¶¶¶¶¶v_______________________
//___________________q¶¶¶¶¶¶¶¶v_______________________
//___________________q¶¶¶¶¶¶¶¶v_______________________
//___________________q¶¶¶¶¶¶¶¶o_______________________
//___________________3¶¶¶¶¶¶¶¶o_______________________
//___________________q¶¶¶¶¶¶¶¶o_______________________

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract TheVikingz is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public raidCollection = false;
  bool public raidParty = false;
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
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
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
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
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

  function setRaidCollection(bool _state) public onlyOwner {
    raidCollection = _state;
  }
   
  function setRaidParty(bool _state) public onlyOwner {
    raidParty = _state;
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
   
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
 
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}