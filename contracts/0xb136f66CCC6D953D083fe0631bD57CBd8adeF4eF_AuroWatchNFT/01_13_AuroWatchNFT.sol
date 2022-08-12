//SPDX-License-Identifier: MIT

// _____/\\\\\\\\\_____/\\\________/\\\____/\\\\\\\\\___________/\\\\\______        
//  ___/\\\\\\\\\\\\\__\/\\\_______\/\\\__/\\\///////\\\_______/\\\///\\\____       
//   __/\\\/////////\\\_\/\\\_______\/\\\_\/\\\_____\/\\\_____/\\\/__\///\\\__      
//    _\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\\\\\\\\\/_____/\\\______\//\\\_     
//     _\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\//////\\\____\/\\\_______\/\\\_    
//      _\/\\\/////////\\\_\/\\\_______\/\\\_\/\\\____\//\\\___\//\\\______/\\\__   
//       _\/\\\_______\/\\\_\//\\\______/\\\__\/\\\_____\//\\\___\///\\\__/\\\____  
//        _\/\\\_______\/\\\__\///\\\\\\\\\/___\/\\\______\//\\\____\///\\\\\/_____ 
//         _\///________\///_____\/////////_____\///________\///_______\/////_______

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AuroWatchNFT is ERC721, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string uriPrefix = "";
  string public uriSuffix = ".json";
  
  uint256 public price = 0.15 ether;
  uint256 public maxSupply = 250;
  uint256 public maxMintAmount = 2;

  bool public paused = false;

  constructor(address _initOwner, string memory _initURI) ERC721("AuroWatchNFT", "AURO") {
    setUriPrefix(_initURI);
    transferOwnership(_initOwner);
    _mintLoop(_initOwner, 1);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function getMaxSupply() public view returns (uint256) {
    return maxSupply;
  }

  function getMaxMintAmount() public view returns (uint256) {
    return maxMintAmount;
  }

  function getPrice() public view returns (uint256) {
    return price;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {
    require(!paused, "The contract is paused!");
    require(maxMintAmount >= _mintAmount, "Invalid mint amount!");
    require(msg.value >= price * _mintAmount, "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setPrice(uint256 _newPrice) public onlyOwner {
    price = _newPrice;
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

  function setMaxSupply(uint256 _amount) public onlyOwner {
    maxSupply = _amount;
  }

  function setMaxMintAmount(uint256 _amount) public onlyOwner {
    maxMintAmount = _amount;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }
}