// SPDX-License-Identifier: MIT

/**
777777777777777777777777777777777777777777777777777777777777??77777?77777777!77777777777777777777777
77777777777777777?????77!77?77????77777777777777777777777777GP7777JBJ7PPYY5??G55Y5J77777777777777777
77777777777777777JYBYJJG??5G7PPYYJ77777777777777777777!!7777GP7777JBJ7BPYYY7J#5YYY77777777777!!77777
77777777777777777!?B?7JBYYPB7GPYY?77777777777777777777777777GGJJJ?J#J7B5?JJ7J#YJJJ7777777!7777777777
7777777777777777!7?P?7?P7!JP7PPY5Y77777777777777777777777777Y5555J?Y?7PJ!777JP5555J77777777777777777
7777777777777777777777777777777???77777!77777777777777777!7777777777777777YYJY7Y5YJ77777777777777777
777777777777777777777777777777!77777777!77777777777777777!7777777777777777G?75J55J?77777777777777777
77777777777777777!!7777777777777777777777777777777777777777777777777777777?J?J7??7777777777777777777
777777777777JYYYYYYJJ?77777777?JJJ?77777777?????????77777777???7777777777777??77777777777777777777JJ
777?77777777P##BGGBGBBGP?77777G###BJ777777?BBBBBBBBBBG5J777?BBB?777777777!JBBG77?GBBBBBBBBBB57777Y##
77??77777!77P##G7777?P##B7777P#BPB#BJ77777?B##Y?????5B#B?77?BBBJ7777777777Y#BB?775555G#BG555?777J#BB
???777777777G##P77777P##B7775##G7Y##B?7777?B##Y?????5BBP?77?BBBJ7777777777Y#BB?777!7!P#BP7!7777?B#BJ
?????7777777P##BGGGBB##BJ77JBBB?77P##G7777?B##BBBBBB##GJ777?BBBJ7777777777Y#BB?777777P#BP777777G#BY7
?????7777777P##B5555YYJ777?BB#BPPPG#B#5777?BBBJ7????JBB#577?BB#J7!!77!7777Y#BB?777777P##G777775#B#PP
7????7??7777G##G7777777777G#BG5PPPP5BBBY77?BBB?77777JB##P77?BBBJ777777?777Y#BB?777777P#BG7777YB#BPPP
7?7??7777777P##P777777777P##G?!777!75#BB?7?B##BGGGGBBBBP777?BBBBGBBBBBB577YBBB?777777PBBG777?BBBY777
**/

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Pablitaslol is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = 'ipfs://QmfFtK1DGXPnLGseiKpgu8HKvD1wWEpDZJ2vgVcKHJvhbU/';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public reservedSupply = 100;


  bool public paused = false;
  bool public whitelistMintEnabled = false;
  bool public revealed = true;

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
    require((totalSupply() + _mintAmount) <= (maxSupply - reservedSupply), 'Max supply exceeded!');
    _;
  }

  modifier mintComplianceOwner(uint256 _mintAmount) {
  require(_mintAmount > 0 && _mintAmount <= 100, 'Invalid mint amount!');
  require((totalSupply() + _mintAmount) <= maxSupply, 'Max supply exceeded!');
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

  function mintOwner(uint256 _mintAmount) public mintComplianceOwner(_mintAmount) onlyOwner {
  
  _safeMint(_msgSender(), _mintAmount);
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