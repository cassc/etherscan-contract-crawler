// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface StandardToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(address reveiver, uint256 amount) external returns (bool);
    function burn(address sender, uint256 amount) external returns (bool);
}

contract CrocoKingLegendary is ERC721Enumerable, Ownable {
  uint public constant MAX_SUPPLY = 4444;
  uint256 public maxCap = 1000;
  string _baseTokenURI;
  string public _notRevealedURI;
  bool public isActive = false;
  uint256 public reservedAmount = 50;
  uint256 public reservedMinted;
  bool public isRevealed;
  uint256 public unitPrice = .5 ether;
  uint256 public maxPerUser = 3;

  constructor() ERC721("Croco King", "CKL")  {
  }

  function mint(address _to, uint _count) public payable {
    require(isActive, "!active");
    require(_count <= maxPerUser, "> maxPerUser");
    require(totalSupply() < MAX_SUPPLY, "Ended");
    require(totalSupply() + _count < maxCap, "Exceeds current sale amount");
    require(totalSupply() + _count + reservedAmount - reservedMinted <= MAX_SUPPLY, "> MaxSupply");
    require(msg.value >= price(_count), "!value");

    for(uint i = 0; i < _count; i++){
      _safeMint(_to, totalSupply());
    }
  }

  function AdminMint(address _to, uint _count) public onlyOwner {
    require(isActive, "!active");
    require(totalSupply() < MAX_SUPPLY, "Ended");
    require(totalSupply() + _count < maxCap, "Exceeds current sale amount");
    require(totalSupply() + _count <= MAX_SUPPLY, "> MaxSupply");
    require(reservedMinted + _count <= reservedAmount, 'Exceeds admin limitation');
    reservedMinted += _count;

    for(uint i = 0; i < _count; i++){
      _safeMint(_to, totalSupply());
    }
  }

  function price(uint _count) public view returns (uint256) {
    return _count * unitPrice;
  }

  function revealCollection(bool _reveal) public onlyOwner {
      isRevealed = _reveal;
  }

  function setUinitPrice(uint256 newPrice) public onlyOwner () {
    unitPrice = newPrice;
  }

  function setMaxCap(uint256 newCap) public onlyOwner () {
    maxCap = newCap;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function updateMaxPerUser(uint8 _maxPerUser) public onlyOwner {
    maxPerUser = _maxPerUser;
  }

  function tokenURI(uint256 _tokenId)
      public
      view
      override(ERC721)
      returns (string memory)
    {
      if (!isRevealed) {
        return _notRevealedURI;
      }
      return
          bytes(_baseTokenURI).length > 0 ?
              string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId))) :
              "";
    }

  function setNotRevealedURI(string memory _uri) public onlyOwner {
      _notRevealedURI = _uri;
  }


  function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(_owner);
    uint256[] memory tokensIds = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++) {
      tokensIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensIds;
  }

  function setActive(bool _active) public onlyOwner {
    isActive = _active;
  }

  function updateReservedAmount(uint256 _amount) public onlyOwner {
    reservedAmount = _amount;
  }

  function ownerWithdraw(uint256 amount, address _to, address _tokenAddr) public onlyOwner{
    require(_to != address(0));
    if(_tokenAddr == address(0)){
      payable(_to).transfer(amount);
    }else{
      StandardToken(_tokenAddr).transfer(_to, amount);
    }
  }

}