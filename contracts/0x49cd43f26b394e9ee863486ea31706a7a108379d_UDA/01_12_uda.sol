//  Hello, you...
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

abstract contract EscapeRoomGameManager {
    mapping(uint => uint) public ActiveGames;
    mapping(address => uint) public Players;
    function StartNewGame(uint _seed, uint difficulty) public virtual;
    function DistributeRewardsToWinners(uint _activeGame) public virtual;
    function JoinGame(uint gameId) public virtual;
    function CompleteGame(uint gameId, string calldata _hash, uint _seed) public virtual;
}

contract UDA is ERC721AQueryable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  mapping(address => uint) public mintedByOwner;
  bytes32 public merkleRoot;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  
  uint256 public cost = 0.00666 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 10;
  bool public allowFreeMint = true;

  bool public paused = true;

  EscapeRoomGameManager gameManager;

  constructor() ERC721A("UNDEAD", "UNDEAD") {}

  
// ~~~~~~~~~~~~~~~~~~~~ GameManager Proxy ~~~~~~~~~~~~~~~~~~~~
  function setGameManager(address addr) public onlyOwner {
    gameManager = EscapeRoomGameManager(addr);
  }

  function JoinGame(uint id) public {
    require(balanceOf(_msgSender()) > 0,  'No Detective found.');
      gameManager.JoinGame(id);
  }


// ~~~~~~~~~~~~~~~~~~~~ Modifiers ~~~~~~~~~~~~~~~~~~~~
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,  'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint free = canFreeMint() ? 1 : 0;
    require(msg.value >= cost * (_mintAmount - free),'Insufficient funds!');
    _;
  }

// ~~~~~~~~~~~~~~~~~~~~ Mint Functions ~~~~~~~~~~~~~~~~~~~~
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    mintedByOwner[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');

    mintedByOwner[_msgSender()] += 1;
    _safeMint(_receiver, _mintAmount);
  }

  function mintWhitelist(bytes32[] calldata _merkleProof) public mintCompliance(1) {
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    mintedByOwner[_msgSender()] += 1;
    _safeMint(_msgSender(), 1);
  }

  function canFreeMint() public view returns (bool) {
    return mintedByOwner[_msgSender()] == 0 && allowFreeMint == true;
  }
 
// ~~~~~~~~~~~~~~~~~~~~ Various Checks ~~~~~~~~~~~~~~~~~~~~
  function _startTokenId() internal view virtual override returns (uint256) {
    return 0;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

// ~~~~~~~~~~~~~~~~~~~~ onlyOwner Functions ~~~~~~~~~~~~~~~~~~~~
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setFreeMint(bool _free) public onlyOwner {
    allowFreeMint = _free;
  }

   function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  } 

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

// ~~~~~~~~~~~~~~~~~~~~ Withdraw Functions ~~~~~~~~~~~~~~~~~~~~
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
}