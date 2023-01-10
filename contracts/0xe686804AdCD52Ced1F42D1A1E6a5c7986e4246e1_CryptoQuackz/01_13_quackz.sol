// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract CryptoQuackz is ERC721A, ERC2981, Ownable {

  using Strings for uint256;

  string private  uriPrefix = "ipfs://QmQLX3KFbNeCnxP5XM4vt8XvkEPSyiynPqPxiwevJ6i99C/";
  string private  uriSuffix = '.json';
  uint256 public cost = 0.0069 ether;
  uint256 public constant maxSupply = 6969;
  mapping(address => uint) public mintHistory;
  mapping(address => bool) public freebieClaims;
  bool public paused = false;

  constructor() ERC721A("Crypto Quackz", "CQ") {}

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount + mintHistory[msg.sender] <= 4, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(!paused, 'The contract is paused!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }
  
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    _safeMint(msg.sender, _mintAmount);
    mintHistory[msg.sender] += _mintAmount;
  }

 function freeMint() public {
   require(!freebieClaims[msg.sender], "Already claimed free mint");
   require(totalSupply() < maxSupply, 'Max supply exceeded!');
   _safeMint(msg.sender, 1);
   freebieClaims[msg.sender] = true;
 }
  
  function ownerMint(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(_mintAmount > 0 && _mintAmount + totalSupply() < maxSupply, 'Invalid mint amount!');
        _safeMint(_receiver, _mintAmount);
    }

  function mintForAddress(uint256 _mintAmount, address _receiver) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    _safeMint(_receiver, _mintAmount);
    mintHistory[msg.sender] += _mintAmount;
  }

  function burn(uint256 tokenId) public  {
    require(ownerOf(tokenId) == msg.sender, "Not your token");
    _burn(tokenId);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
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
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

    //Withdraw Funds
  function withdraw() public onlyOwner  {
       (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

  function deleteDefaultRoyalty() external onlyOwner {
      _deleteDefaultRoyalty();
     }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return 
        ERC721A.supportsInterface(interfaceId) || 
        ERC2981.supportsInterface(interfaceId);
}
}