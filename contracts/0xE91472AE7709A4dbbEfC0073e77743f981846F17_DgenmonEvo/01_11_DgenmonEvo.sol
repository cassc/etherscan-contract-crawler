// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721AQueryable.sol";
import "./access/Ownable.sol";
import "./security/Pausable.sol";
import "./security/ReentrancyGuard.sol";
import "./utils/Context.sol";
import "./utils/Presalable.sol";
import "./utils/math/SafeMath.sol";

contract DgenmonEvo is ERC721AQueryable, Ownable, Pausable, Presalable, ReentrancyGuard {
  using SafeMath for uint;

  ERC721A oldDgenmon = ERC721A(0xaf77aF48E73E8F087A8478Ef31dCC7f7F0752822);
  
  string public baseTokenURI;
  string public hiddenTokenUri;
  bool public isRevealed = false;
  uint256 public constant PRICE = 0.003 ether;
  uint256 public constant HOLDER_PRICE = 0.001 ether;
  uint256 public constant MAX_TOKEN_COUNT = 8787;

  address t1 = 0x7debc8366Aad32Bb49DD23B762c219D7b7787878;
  address t2 = 0x7debc8366Aad32Bb49DD23B762c219D7b7787878;

  bool internal _locked;

  constructor(string memory _hiddenTokenUri) ERC721A("Dgenmon Evolution", "DGENEVO")  {
    setHiddenTokenUri(_hiddenTokenUri);
    presale();
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  function totalBurned() public view returns (uint256) {
    return _totalBurned();
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setRevealed(bool _isRevealed) public onlyOwner {
    isRevealed = _isRevealed;
  }

  function setHiddenTokenUri(string memory _hiddenTokenUri) public onlyOwner {
    hiddenTokenUri = _hiddenTokenUri;
  }

  function mint(uint256 _amount) public payable whenNotPresaled whenNotPaused {
    
    if (oldDgenmon.balanceOf(msg.sender) > 0)
        require(msg.value >= HOLDER_PRICE * (_amount), "Ether value sent is not correct");
    else
        require(msg.value >= PRICE * (_amount), "Ether value sent is not correct");
    
    _safeMint(msg.sender, _amount);
  }

  function deployerMint(uint256 _amount) public onlyOwner {        
    _safeMint(msg.sender, _amount);
  }

  function burnUnlucky(uint256[] memory _tokenIds) public onlyOwner whenNotPaused {
    for(uint256 i = 0; i < _tokenIds.length; i++) {
      _burn(_tokenIds[i]);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function withdraw() external onlyOwner nonReentrant {
    uint256 _balance = address(this).balance / 100;

    require(payable(t1).send(_balance * 80));
    require(payable(t2).send(_balance * 20));
  }

  function getOldDgenmonBalance(address _address) public view returns (uint256) {
    return oldDgenmon.balanceOf(_address);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function presale() public onlyOwner {
    _presale();
  }

  function unpresale() public onlyOwner {
    _unpresale();
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (isRevealed == false) {
      return hiddenTokenUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId))):'';
  }
}