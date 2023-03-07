/*
█▀ ▀█▀ █▀█ █▀▀ █▀▀ ▀█▀   █▀ █▀▄▀█ ▄▀█ █▀█ ▀█▀   █▀ █▄▀ █░█ █░░ █░░ █ █▀▀ █▀
▄█ ░█░ █▀▄ ██▄ ██▄ ░█░   ▄█ █░▀░█ █▀█ █▀▄ ░█░   ▄█ █░█ █▄█ █▄▄ █▄▄ █ ██▄ ▄█
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract StreetSmartSkullies is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint;

  string public uriPrefix = '';
  string public hiddenMetadataUri;
  string public uriSuffix = '.json';
  
  
  uint public maxSupply = 8888;
  uint public freeSupply = 8888;
  uint public cost = 0.004 ether;
  uint public maxMintAmountPerTx = 10;
  uint public maxPerWallet = 20;

  bool public paused = true;
  bool public revealed = false;

  mapping(address => bool) public freeMintClaimed;


  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  // ~~~~~~~~~~~~~~~~~~~~ Modifiers ~~~~~~~~~~~~~~~~~~~~
  modifier mintCompliance(uint _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(_mintAmount + balanceOf(_msgSender()) <= maxPerWallet, 'Only 10 allowed per wallet!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint _mintAmount) {
    if (freeMintClaimed[_msgSender()] || totalSupply() >= freeSupply) {
      require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    }
    _;
  }

  // ~~~~~~~~~~~~~~~~~~~~ Mint Functions ~~~~~~~~~~~~~~~~~~~~

     function DrawGraffiti(uint256 amount) external payable {
        require(!paused, "contract is paused");
        require(msg.sender == tx.origin, "Cannot mint from contract");

        require(totalSupply() + amount <= maxSupply, "max supply would be exceeded");
        uint minted = _numberMinted(msg.sender);

        require(minted + amount <= maxPerWallet, "max mint per wallet would be exceeded");

        uint chargeableCount;

        if (minted == 0) {
            chargeableCount = amount - 1;
            require(amount > 0, "amount must be greater than 0");
            require(msg.value >= cost * chargeableCount, "value not met");
        } else {
            chargeableCount = amount;
            require(amount > 0, "amount must be greater than 0");
            require(msg.value >= cost * chargeableCount, "value not met");
        }
        _safeMint(msg.sender, amount);
    }
  
  // ~~~~~~~~~~~~~~~~~~~~ Various Checks ~~~~~~~~~~~~~~~~~~~~
    function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  // ~~~~~~~~~~~~~~~~~~~~ onlyOwner Functions ~~~~~~~~~~~~~~~~~~~~

      function mintForAddress(uint256 _mintAmount, address _receiver) external onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _safeMint(_receiver, _mintAmount);
    }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

     function setmaxPerWallet(uint _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
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

  function setFreeSupply(uint _freeQty) public onlyOwner {
    freeSupply = _freeQty;
  }

  // ~~~~~~~~~~~~~~~~~~~~ Withdraw Functions ~~~~~~~~~~~~~~~~~~~~
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
/*

*/
}