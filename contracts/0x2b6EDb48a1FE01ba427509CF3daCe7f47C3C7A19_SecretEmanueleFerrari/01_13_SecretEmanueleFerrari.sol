// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

//           _____ ________________  ____________
//         / ___// ____/ ____/ __ \/ ____/_  __/
//         \__ \/ __/ / /   / /_/ / __/   / /   
//        ___/ / /___/ /___/ _, _/ /___  / /    
//       /____/_____/\____/_/ |_/_____/ /_/     
                                       
contract SecretEmanueleFerrari is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  
  uint256 public cost;
  uint256 public maxSupply = 0;
  mapping(address => uint256) public mintedCount;

  bool public paused = true;
  bool public closed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    string memory _unrevealedUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    setUriPrefix(_unrevealedUri);
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function mintPublic(uint256 _mintAmount) public payable mintPriceCompliance(_mintAmount) {
    require(!closed, 'The contract is closed!');
    require(!paused, 'The contract is paused!');
    require(_mintAmount > 0 && _mintAmount <= 10, 'Invalid mint amount!');
    require(mintedCount[_msgSender()] + _mintAmount <= 10, 'Minted amount exceeds maximum (10)!');
    mintedCount[_msgSender()] = mintedCount[_msgSender()] + _mintAmount;
    maxSupply = maxSupply + _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(!closed, 'The contract is closed!');
    maxSupply = maxSupply + _mintAmount;
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
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function closeEdition() public onlyOwner {
    closed = true;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}

// developed by Kanye East