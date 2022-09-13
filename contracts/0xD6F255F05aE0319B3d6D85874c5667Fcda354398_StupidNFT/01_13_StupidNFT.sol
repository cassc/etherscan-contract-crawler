// SPDX-License-Identifier: MIT

/*
.'''''''''''''''''''''''',:clc:,''',,,;;;::::::::,,,;,',''';:;,'''''''''''''''''''''
..'''''''''''''''''''',;oOKK0KKkl,:dkkkOO0KKKKKK0o;o0d,''',oKk;'''''''''''''''''''''
...'''''''''''''''''',cONKdc;cxXKl;cccc:cxOxc::::,;xKo,''',xNO:''''''''''''''.......
'....'''''''''''''''':ONOc'''',xXa,''''',dOo,.....;dx:'...'oOd,'''''..............''
'''...'''''''''''''''lKNd,','''cdl,''''';kNk;.....;dx:....'lxl'..............'''''''
''''....''''''''''''':ON0ol::;,',''''''';kW0:''''':xx:....'lxc'.........''''''''''''
'''''.....'''''''','',cx0KXKK0x:,''''''';kW0:'''''lKKl'''',d0o''''''''''''''''''''''
'''''''.....''''''''''',;:cloON0l,'''''';kW0:'''''lKXo,''':ONx,'''''''''''''''''''''
''''''''......'''''','',,,''':kN0c,''''';kW0:'''''cKNd,','c0Nd,'''''''''''''''''''''
''''''''''......'''''',okc,'''lXNo,'','';kW0:''''':0Nk;',:kN0c''''''''''''''''''''''
''''''''''''......'''',oKKd:;:xNXl,'','';xN0c''''',oKXkdx0XOc,''''''''''''''''''''..
''''''''''''''.......'',l0XK0KX0o;''','',lOx:'''''',cxO0Oxl;,''''''''''''''''.......
.'''''''''''''''........';codol:,'''''''',,,,''''','',,,,''''''''''''''''...........
..'''''''''''''''''.......'''''''''''''''''''''''',;:ccc:;,''''''''''.............''
 ..''''''''''''''''''.',clooool:,'''''',cdc,'''':dO0KKKKKKOo;''''...............''''
  .''''''''''''''''''''ckxl:cldxo;...'''o0x;''''lKXklc:ccoxkd:'..............'''''''
  .''''''''''''''''''',oK0c'..,okl'....'lkl'....;xkc'.....'lkd;............'''''''''
  .''''''''''''''''''',oXXo,';lxkc'....'lkl'....;dkc'......:xx:........'''''''''''''
  .''''''''''''''''''',lXN0kOKX0o,''...,okl'....,okl'.....'cxd;...''''''''''''''''''
  .''''''''''''''''''''lKWKkxdl;,,''''';x0o'....,oOo,....';x0d;'''''''''''''''''''''
  .''''''''''''''''''''c0Nx;'''''''''''c0Nd,'''';kXk;'',;o0NOc,'''''''''''''''''''''
  .'''''''''''''''''''':OWO;'''''''''''c0Nd,'''';kW0lcokKX0d;,''''''''''''''''''''''
  ..''''''''''''''''''',xN0c''''''''''':OXd,'''',oKXKKK0kl;,''''''''''''''''''''''''
  ..''''''''''''''''''',l0Oc''''''''''',:c;'''''',:clc:;,''''''''''''''''''''''''''.
  ....''''''''''''''''',,::,,,,,,,,,,,,,,,,,,,,,,;,,,,,,,,,,,,,,,'''''''''''''''''..
  .....''''''''''''''',:ccllllllllllllllllllllllllllllllllllllll:,'''''''
*/

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract StupidNFT is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public whitelistCost = 0;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _whitelistCost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    whitelistCost = _whitelistCost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

    modifier whitelistMintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= whitelistCost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) whitelistMintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Address not whitelisted!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'Public sale is not enabled!');

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

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
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
    // Do not remove this otherwise will not be able to withdraw.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }
}