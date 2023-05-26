// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = "_metadata.json";
  uint256 public cost = 0.0125 ether;
  uint256 public maxSupply = 10500;
  uint256 public maxMintAmount = 25;
  bool public paused = false;
  uint256 public ownerCost = 0.0001 ether;
  uint256 public royaltyPercentage = 5; // This will be 5% royalties

  event Minted(address indexed minter, uint256 indexed tokenId, uint256 indexed mintAmount);
  event Burned(address indexed burner, uint256 indexed tokenId);
  event PriceChanged(address indexed changer, uint256 oldPrice, uint256 newPrice);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);

   
    if (msg.sender != owner()) {
        require(_mintAmount <= maxMintAmount, "Exceeded max mint amount.");
        require(msg.value >= cost * _mintAmount, "Ether value sent is not correct");
    } else {
        require(msg.value >= ownerCost * _mintAmount, "Owner's Ether value sent is not correct");
    }

    require(supply + _mintAmount <= maxSupply, "Exceeded max supply");

    for (uint256 i = 1; i <= _mintAmount; i++) {
        _safeMint(msg.sender, supply + i);
        emit Minted(msg.sender, supply + i, _mintAmount);
    }
  }

  function burn(uint256 tokenId) public virtual {
    require(_msgSender() == ownerOf(tokenId), "Caller is not owner of the token");
    _burn(tokenId);
    emit Burned(_msgSender(), tokenId);
  }

  function setCost(uint256 _newCost) public onlyOwner {
    emit PriceChanged(_msgSender(), cost, _newCost);
    cost = _newCost;
  }

  function royaltyInfo(uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    return (owner(), (_salePrice * royaltyPercentage) / 100);
}

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId));
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }


  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }
  

}