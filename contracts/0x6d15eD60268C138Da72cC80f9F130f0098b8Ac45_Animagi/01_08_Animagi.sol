/* 
╭━━━┳━╮╱╭┳━━┳━╮╭━┳━━━┳━━━┳━━╮
┃╭━╮┃┃╰╮┃┣┫┣┫┃╰╯┃┃╭━╮┃╭━╮┣┫┣╯
┃┃╱┃┃╭╮╰╯┃┃┃┃╭╮╭╮┃┃╱┃┃┃╱╰╯┃┃
┃╰━╯┃┃╰╮┃┃┃┃┃┃┃┃┃┃╰━╯┃┃╭━╮┃┃
┃╭━╮┃┃╱┃┃┣┫┣┫┃┃┃┃┃╭━╮┃╰┻━┣┫┣╮
╰╯╱╰┻╯╱╰━┻━━┻╯╰╯╰┻╯╱╰┻━━━┻━━╯ 
*/


// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Animagi is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint public cost = 0.003 ether;
  uint public MAXSUPPLY = 999;
  uint public freeSupply = 333;
  uint public MAXPerWallet = 5;
  uint public MAXMintAmountPerTx = 5;

  bool public paused = true;
  bool public revealed = true;

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
    require(_mintAmount > 0 && _mintAmount <= MAXMintAmountPerTx, 'Invalid mint amount!');
    require(_mintAmount + balanceOf(_msgSender()) <= MAXPerWallet, 'Only 5 allowed per wallet!');
    require(totalSupply() + _mintAmount <= MAXSUPPLY, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint _mintAmount) {
    if (freeMintClaimed[_msgSender()] || totalSupply() >= freeSupply) {
      require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    }
    _;
  }

  // ~~~~~~~~~~~~~~~~~~~~ Mint Functions ~~~~~~~~~~~~~~~~~~~~
  function Transfigure(uint _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    freeMintClaimed[_msgSender()] = true;

    _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(uint _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
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
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint _cost) public onlyOwner {
    cost = _cost;
  }

  function setMAXMintAmountPerTx(uint _MAXMintAmountPerTx) public onlyOwner {
    MAXMintAmountPerTx = _MAXMintAmountPerTx;
  }
  
  function setMAXPerWallet(uint _MAXPerWallet) public onlyOwner {
    MAXPerWallet = _MAXPerWallet;
  }

 function ownerMint(uint _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  
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