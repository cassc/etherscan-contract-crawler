// SPDX-License-Identifier: MIT

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&######&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BP55YY55555555PGB#&@@@###&@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@&#GPPPPGGGGGGGGPPPPP5555G#&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@&BGGBBBBBBGGGGGGGGGPPPPPPPP5P55G#&@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@#GB#####[email protected]@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@#GB####BGGP55PPGPPPGGGGPPGGPPP5PP5Y555#@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@&GB####BGP55PGGP5PPGGGP5PGP5PP5PGPYYP55Y&@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@#B####[email protected]@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@#G###BGPPGGGP5GBGGP55GBGPPGPPBGPY5GGGPP5J&@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@&BB##BPGGGGP5GBG5YJJPBPGBG55BG5JYGGGPPPY?&@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@#B##[email protected]@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@##B?!~^^~!^:::^^~~~~::::::[email protected]@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@&#BBJ^^^^!??7!^^~!!7~^^~77~!^:::~5P5Y&@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@&BBBJ^^~~^~~!7~^^~^^^!!~^^^^^::5P5Y#@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@&&#BG?~~:. :??!~:::::^~.~?!:.:^:[email protected]@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@P7!~!JJ~!. [email protected]@#7~:^::~^P#@@5. :^:!~:[email protected]@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@P~^~!^^~^~^..!G##5!^:^::^^YBBP7..~^:::^7~:[email protected]@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@Y~^~?7^^^^^~~~!!!^:^:~::::~!7!~~^!!::^??^::^&@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@B?~~!~^^^:~~!~!^::^!~~^^:::^~^^::::::::^:::[email protected]@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@BJ!~~^^!~^~~~!^:^^^^^^^^::::~:::::^::::^[email protected]@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@&G5JJJ5G?~^^^~~^^:.. .:::.:^::.~PPYY5G&@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G?~^^^^^^~~~^:::::..~5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BY7~^^:::::::::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PJJJYP7?7YJ?!7Y#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P?!~7???!?7JJ?^^^^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GYJ??7?!. . :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PYGPPGJYYYY5YJ7J5YYY!Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@&GJ!~~!!5----------J77~:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@ 
//@@@@@@@@@@@@@@@@@@@@@@@@&5YYJ^^55PG----------PYYY^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@&#GYGPJY?7777YJJ777777?J5JJP#@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract TheDropoutznftERC is ERC721AQueryable, Ownable, ReentrancyGuard {

   using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => uint256) public numberOfWLMintsOnAddress;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerAddress;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxMintAmountPerAddress,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    maxMintAmountPerAddress = _maxMintAmountPerAddress;
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

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(numberOfWLMintsOnAddress[msg.sender] + _mintAmount <= maxMintAmountPerAddress, "Sender is trying to mint more than their whitelist amount");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    numberOfWLMintsOnAddress[msg.sender] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
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

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return string(abi.encodePacked(hiddenMetadataUri, _tokenId.toString(), uriSuffix));
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

  function setMaxMintAmountPerAddress(uint256 _maxMintAmountPerAddress) public onlyOwner {
    maxMintAmountPerAddress = _maxMintAmountPerAddress;
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