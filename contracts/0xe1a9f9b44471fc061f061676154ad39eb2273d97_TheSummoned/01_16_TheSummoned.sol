// SPDX-License-Identifier: MIT
/*
████████╗██╗░░██╗███████╗░░░░███████╗██╗░░░██╗███╗░░░███╗███╗░░░███╗░██████╗░███╗░░░██╗███████╗██████╗ 
╚══██╔══╝██║░░██║██╔════╝░░░░██╔════╝██║░░░██║████╗░████║████╗░████║██╔═══██╗████╗░░██║██╔════╝██╔══██╗
░░░██║░░░███████║█████╗░░░░░░███████╗██║░░░██║██╔████╔██║██╔████╔██║██║░░░██║██╔██╗░██║█████╗░░██║░░██║
░░░██║░░░██╔══██║██╔══╝░░░░░░╚════██║██║░░░██║██║╚██╔╝██║██║╚██╔╝██║██║░░░██║██║╚██╗██║██╔══╝░░██║░░██║
░░░██║░░░██║░░██║███████╗░░░░███████║╚██████╔╝██║░╚═╝░██║██║░╚═╝░██║╚██████╔╝██║░╚████║███████╗██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝╚══════╝░░░░╚══════╝░╚═════╝ ╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝░╚═════╝░╚═╝░░╚═══╝╚══════╝╚═════╝
*/

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract TheSummoned is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => uint) public summonsClaimed;
  mapping(address => uint) public burntBones;
  mapping(uint => bool) private specialTokens;

  string public uriPrefix = '';
  string public specialUri = '';
  string public uriSuffix = '.json';
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _uriPrefix,
    string memory _specialUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setUriPrefix(_uriPrefix);
    setSpecialUri(_specialUri);
    _safeMint(_msgSender(), 10);
  }

// ~~~~~~~~~~~~~~~~~~~~ Modifiers ~~~~~~~~~~~~~~~~~~~~
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

// ~~~~~~~~~~~~~~~~~~~~ Mint Functions ~~~~~~~~~~~~~~~~~~~~
  function whitelistMint(uint256 _mintAmount, uint256 _burntAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    //Verify eligible address
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Address is not eligible. If you have burnt tokens, please contact team!');
    // increment burnt amount in contract
    if (_burntAmount > burntBones[_msgSender()]) {
      burntBones[_msgSender()] = _burntAmount;
    }
    

    uint256 _burnt = burntBones[_msgSender()] / 2;
    require(_burnt > 0 && _burnt > summonsClaimed[_msgSender()], 'Not enough burnt to claim more!');
    require(_mintAmount <= _burnt - summonsClaimed[_msgSender()], 'Exceeded maximum claim amount for # of tokens burnt!');
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');

    summonsClaimed[_msgSender()] += _mintAmount;

    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }



// ~~~~~~~~~~~~~~~~~~~~ Various Checks ~~~~~~~~~~~~~~~~~~~~
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = '';

    if (specialTokens[_tokenId] == true) {
      currentBaseURI = specialUri;
    } else {
      currentBaseURI = _baseURI();
    }
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

// ~~~~~~~~~~~~~~~~~~~~ onlyOwner Functions ~~~~~~~~~~~~~~~~~~~~
  function setBurntBones(uint _burnAmount, address _address) public onlyOwner {
      burntBones[_address] = _burnAmount;
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

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setSpecialUri(string memory _specialUri) public onlyOwner {
    specialUri = _specialUri;
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

  function setSpecialTokens(uint[] memory _tokens, bool _status) public onlyOwner {
      for (uint256 i = 0; i < _tokens.length; i++) {
          specialTokens[i] = _status;
    }
  }

// ~~~~~~~~~~~~~~~~~~~~ Withdraw Functions ~~~~~~~~~~~~~~~~~~~~
  function withdraw() public onlyOwner nonReentrant {
    (bool db, ) = payable(0x0755acA0cF9212A3D20F6d728a9B846BE67f07C9).call{value: address(this).balance * 25 / 1000}('');
    require(db);
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
/*
  __            __    __                     
 /\ \          /\ \__/\ \              __    
 \_\ \     __  \ \ ,_\ \ \____    ___ /\_\   
 /'_` \  /'__`\ \ \ \/\ \ '__`\  / __`\/\ \  
/\ \L\ \/\ \L\.\_\ \ \_\ \ \L\ \/\ \L\ \ \ \ 
\ \___,_\ \__/.\_\\ \__\\ \_,__/\ \____/\ \_\
 \/__,_ /\/__/\/_/ \/__/ \/___/  \/___/  \/_/
*/
}