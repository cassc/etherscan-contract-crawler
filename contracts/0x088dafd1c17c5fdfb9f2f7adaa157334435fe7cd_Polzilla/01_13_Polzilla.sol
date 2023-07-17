// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface CryptoPolzInterface {
  function ownerOf(uint256 tokenId) external view returns (address);
  function walletOfOwner(address _owner) external view returns (uint256[] memory);
  function balanceOf(address owner) external view returns (uint256);
}

contract Polzilla is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0 ether;
  uint256 public maxSupply = 9696;
  bool public paused = true;
  bool public privateSale = true;
  CryptoPolzInterface polz;
  uint256[] private _claimedTokens;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    address _polzContractAddress
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setPolzContract(_polzContractAddress);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _tokenId) public payable {
    require(paused == false, "Paused");
    require(_exists(_tokenId) == false, "Already minted");
    require((_tokenId > 0) && (_tokenId <= maxSupply), "Invalid token ID");
    
    if (privateSale == true) {
      require(polz.ownerOf(_tokenId) == msg.sender, "Wrong owner");
    } else {
      if (msg.sender != owner()) {
        require(msg.value >= cost, "Not enough funds");
      }
    }

    _safeMint(msg.sender, _tokenId);
    _claimedTokens.push(_tokenId);
  }

  function claimWallet() public payable {
    require(paused == false, "Paused");
    uint256 walletTokenCount = polz.balanceOf(msg.sender);
    require(walletTokenCount > 0, "No Polz in wallet");
    uint256[] memory wallet = polz.walletOfOwner(msg.sender);

    for (uint256 i; i < walletTokenCount; i++) {
      mint(wallet[i]);
    }
  }

  function claimedTokens() public view returns (uint256[] memory) {
    return _claimedTokens;
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
        : "";
  }
  
  function setPolzContract(address _polzContractAddress) public onlyOwner {
    polz = CryptoPolzInterface(_polzContractAddress);
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function flipPause() public onlyOwner {
    paused = !paused;
  }

  function flipPrivateSale() public onlyOwner {
    privateSale = !privateSale;
  }
  
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}