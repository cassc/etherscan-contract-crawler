// SPDX-License-Identifier: MIT

/*
                                   ___
                                 [|   |=|{)__
                                  |___| \/   )
                                   /|\      /|
Cocoshop™️ by Hubabu aka FotoGuru  / | \    | \
*/

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Cocoshop is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uri = '';
  string public uriSuffix = '.json';
  string public unrevealedUri;
  
  uint256 public supplyLimit;
  uint256 public cost1;
  uint256 public cost2;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public revealed = false;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _supplyLimit,
    uint256 _maxMintAmountPerTx,
    string memory _unrevealedUri
  ) ERC721A(_name, _symbol) {
    supplyLimit = _supplyLimit;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setunrevealedUri(_unrevealedUri);
  }

  function UpdateCost(uint256 _supply) internal view returns  (uint256 _cost) {

      if (_supply < 1000) {
          return cost1;
        } else {
          return cost2;
        }
  }

  modifier photoMintAction(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Not enough left.');
    _;
  }

  modifier costAction(uint256 _mintAmount) {
  // Dynamic Price
    uint256 supply = totalSupply();
  // Normal requirements 
    require(msg.value >= UpdateCost(supply) * _mintAmount, 'Insufficient funds!');
    _;
  }

  function mint(uint256 _mintAmount) public payable photoMintAction(_mintAmount) costAction(_mintAmount) {
    require(!paused, 'The contract is in pause mode!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function Airdrop(uint256 _mintAmount, address _receiver) public photoMintAction(_mintAmount) onlyOwner {
   
    _safeMint(_receiver, _mintAmount);
  }

// ================== Mint Functions End =======================  

// Saving Cocoshop for Portfolio

  function saveCocoshop() public onlyOwner {  
      uint supply = _startTokenId();
      uint i;
      for (i = 1; i < 20; i++) {
          _safeMint(msg.sender, supply + i);
      }
  }

// ================== Set Functions Start =======================

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

// Max per tx

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

// Uri

  function setunrevealedUri(string memory _unrevealedUri) public onlyOwner {
    unrevealedUri = _unrevealedUri;
  }

  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

// Sales toggle

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

// Price

  function setcost1(uint256 _cost1) public onlyOwner {
    cost1 = _cost1;
  }  

  function setcost2(uint256 _cost2) public onlyOwner {
    cost2 = _cost2;
  }  

// Supply limit
  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

  // ================== Set Functions End =======================

// ================== Withdraw Function Start =======================

  function withdraw() public onlyOwner {
    (bool os,) = payable(owner()).call{value:address(this).balance}("");
    require(os);
  }

// ================== Withdraw Function End=======================  

// ================== Read Functions Start =======================

  function price() public view returns (uint256){
         if (totalSupply() < 1000) {
          return cost1;
          } else {
               return cost2;
          }
  }

  function balanceOfOwner(address _owner) public view returns (uint256[] memory) {

    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
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
      return unrevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

// ================== Read Functions End ======================= 

}