// SPDX-License-Identifier: MIT

 // _____                           _____                
 //|  __ \                         |  __ \               
 //| |__) |__ _ __  _ __   ___ _ __| |__) |__ _ __   ___ 
 //|  ___/ _ \ '_ \| '_ \ / _ \ '__|  ___/ _ \ '_ \ / _ \
 //| |  |  __/ |_) | |_) |  __/ |  | |  |  __/ |_) |  __/
 //|_|   \___| .__/| .__/ \___|_|  |_|   \___| .__/ \___|
 //          | |   | |                       | |         
  //         |_|   |_|                       |_|         

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract PepperPepe is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  
  
  uint public maxFreeSupply = 1111;
  uint public maxSupply = 2222;
  uint public maxPerTx = 2;
  uint public maxPerWallet = 2;
  uint public price = 0.0055 ether;


  bool public paused = true;
  bool public revealed = false;

  mapping(address => bool) public freeMintClaimed;


  constructor() ERC721A("PepperPepe", "PRP") {
  }

  modifier onlyOwnerAndPaused() {
    require(msg.sender == owner() && paused, "Only owner can perform this action when paused");
    _;
    }

  modifier mintPriceCompliance(uint _mintAmount) {
    if (freeMintClaimed[_msgSender()] || totalSupply() >= maxFreeSupply) {
      require(msg.value >= price * _mintAmount, 'Insufficient funds!');
    }
    _;
  }

    function Mint(uint256 amount) external payable {
    require(!paused, "Mint is not live yet!");
    require(msg.sender == tx.origin, "Cannot mint from contract");

    require(totalSupply() + 2 <= maxSupply, "Max supply would be exceeded");
    uint minted = _numberMinted(msg.sender);

    require(minted + 2 <= maxPerWallet, "Max mint per wallet would be exceeded");

    require(amount >= 1 && amount <= 2, "Invalid amount");
    require(msg.value >= price * 1, "Incorrect value");

    _safeMint(msg.sender, 2);
    }

  
    function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
    }

    function mintToOwner(uint256 amount) external onlyOwnerAndPaused {
    require(totalSupply() + amount <= maxSupply, "Max supply would be exceeded");

    _safeMint(owner(), amount);
    }
    
    function airdrop(uint256 _mintAmount, address[] memory _receivers) external onlyOwner {
    require(totalSupply() + (_mintAmount * _receivers.length) <= maxSupply, "Max supply exceeded!");

    for(uint256 i = 0; i < _receivers.length; i++) {
        _safeMint(_receivers[i], _mintAmount);
    }
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setMaxPerTx(uint _maxPerTx) public onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setmaxPerWallet(uint _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxFreeSupply(uint _freeQty) public onlyOwner {
        maxFreeSupply = _freeQty;
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

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function cutMaxSupply(uint256 _amount) public onlyOwner {
        require(
            maxSupply - _amount >= totalSupply(),
            "Supply can't fall below minted tokens."
        );
        maxSupply -= _amount;
    }
    }