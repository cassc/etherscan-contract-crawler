// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol"; // Delete

interface INFT {
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address);
}

interface IToken {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function burn(address _from, uint256 _amount) external;
}

contract Eggzilla is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public mintPrice = 1000 ether;
  uint256 public hatchPrice = 200 ether;
  uint256 public ransomPrice = 300 ether;

  mapping(uint256 => bool) public hatched;
  mapping(uint256 => uint256) public kidnapper;
  mapping(uint256 => uint256) public victim;

  string public baseURI;
  string public kidnappedURI;
  string public unhatchedURI;

  INFT public polzillaContract;
  INFT public kongzillaContract;
  IToken public eggzContract;
  address public metaRageAddress;

  constructor(
    string memory _baseURI,
    string memory _unhatchedURI,
    string memory _kidnappedURI,
    address _polzillaContractAddress,
    address _eggzContractAddress
  ) ERC721("Eggzilla", "EGGZILLA") {
    setBaseURI(_baseURI);
    setUnhatchedURI(_unhatchedURI);
    setKidnappedURI(_kidnappedURI);
    setPolzillaContract(_polzillaContractAddress);
    setEggzContract(_eggzContractAddress);
  }

  function setMintPrice(uint256 _newMintPrice) external onlyOwner {
    mintPrice = _newMintPrice;
  }

  function setHatchPrice(uint256 _newHatchPrice) external onlyOwner {
    hatchPrice = _newHatchPrice;
  }

  function setRansomPrice(uint256 _newRansomPrice) external onlyOwner {
    ransomPrice = _newRansomPrice;
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }
  
  function setUnhatchedURI(string memory _unhatchedURI) public onlyOwner {
    unhatchedURI = _unhatchedURI;
  }
  
  function setKidnappedURI(string memory _kidnappedURI) public onlyOwner {
    kidnappedURI = _kidnappedURI;
  }

  function setPolzillaContract(address _address) public onlyOwner {
    polzillaContract = INFT(_address);
  }

  function setKongzillaContract(address _address) public onlyOwner {
    kongzillaContract = INFT(_address);
  }

  function setEggzContract(address _address) public onlyOwner {
    eggzContract = IToken(_address);
  }

  function setMetaRageAddress(address _address) public onlyOwner {
    metaRageAddress = _address;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require (_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (hatched[_tokenId] == false) {
      return unhatchedURI;
    }

    if (kidnapper[_tokenId] > 0) {
      return string(abi.encodePacked(kidnappedURI, _tokenId.toString(), ".json"));
    }

    return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);

    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    
    return tokenIds;
  }

  function status(uint256 _tokenId) external view returns (string memory) {
    if (hatched[_tokenId] == false) {
      return "Unhatched";
    }

    if (kidnapper[_tokenId] > 0) {
      return "Kidnapped";
    }

    return "Free";
  }

  function kidnap(uint256 _tokenId, uint256 _kongzillaId) external returns (bool) {
    require (msg.sender == metaRageAddress, "Forbidden");
    require (_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    require (hatched[_tokenId] == true, "Not hatched");
    require (kongzillaContract.ownerOf(_kongzillaId) != msg.sender, "Can't kidnap your own");

    if (victim[_kongzillaId] > 0) {
      return false;
    }

    kidnapper[_tokenId] = _kongzillaId;
    victim[_kongzillaId] = _tokenId;

    return true;
  }
  
  function free(uint256 _tokenId) external returns (bool) {
    require (msg.sender == metaRageAddress, "Forbidden");
    require (_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    require (hatched[_tokenId] == true, "Not hatched");

    uint256 kongzillaId = kidnapper[_tokenId];
    
    if (kongzillaId == 0) {
      return false;
    }

    kidnapper[_tokenId] = 0;
    victim[kongzillaId] = 0;

    return true;
  }

  function payRansom(uint256 _tokenId) external {
    uint256 kongzillaId = kidnapper[_tokenId];
    require (_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    require (kongzillaId > 0, "Not kidnapped");
    require (eggzContract.balanceOf(msg.sender) >= ransomPrice, "Need more EGGZ");

    address kongzillaOwner = kongzillaContract.ownerOf(kongzillaId);

    require (
      eggzContract.transferFrom(msg.sender, kongzillaOwner, ransomPrice),
      "Ransom didn't go through"
    );

    kidnapper[_tokenId] = 0;
    victim[kongzillaId] = 0;
  }

  function hatch(uint256 _tokenId) external {
    require (ownerOf(_tokenId) == msg.sender, "Forbidden");
    require (hatched[_tokenId] == false, "Already hatched");
    require (eggzContract.balanceOf(msg.sender) >= hatchPrice, "Need more EGGZ");

    eggzContract.burn(msg.sender, hatchPrice);

    hatched[_tokenId] = true;
  }

  function mint() public returns (uint256) {
    require (polzillaContract.balanceOf(msg.sender) > 1, "Need at least 2 Polzilla");
    require (eggzContract.balanceOf(msg.sender) >= mintPrice, "Need more EGGZ");
    uint256 tokenId = totalSupply() + 1;
    require (tokenId <= 15555, "All Eggzilla are born");

    eggzContract.burn(msg.sender, mintPrice);

    _safeMint(msg.sender, tokenId);

    return tokenId;
  }
}