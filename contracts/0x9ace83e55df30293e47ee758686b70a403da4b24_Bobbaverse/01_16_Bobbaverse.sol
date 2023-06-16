// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Bobbaverse is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  mapping(address => uint256) public freeClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  uint256 public cornerShopPrice = 0.0044 ether;
  uint256 public mallPrice = 0.0088 ether;
  uint256 public hotelPrice = 0.012 ether;
  uint256 public mansionPrice = 0.1 ether;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public freeSupply = 1000;

  uint256 public cornerShop = 5800;
  uint256 public mall = 3000;
  uint256 public hotel = 1000;

  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    if (cornerShop > 0) {
      require(cornerShop - _mintAmount >= 0, 'Cornershop all minted out!');
    } else if (mall > 0) {
      require(mall - _mintAmount >= 0, "Mall all minted out!");
    } else if (hotel > 0) {
      require(hotel - _mintAmount >= 0, "Hotel all minted out!");
    } else {
      require(totalSupply() + _mintAmount <= maxSupply, "Mansion all minted out!");
    }
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    if (cornerShop > 0) {
      if (_mintAmount == 1 && freeSupply > 0 && freeClaimed[msg.sender] < 2) {
      } else {
        require(msg.value >= cornerShopPrice * _mintAmount, "Not enough funds to mint Cornershop");
      }
    } else if (mall > 0) {
      require(msg.value >= mallPrice * _mintAmount, "Not enough funds to mint Mall");
    } else if (hotel > 0) {
      require(msg.value >= hotelPrice * _mintAmount, "Not enough funds to mint Hotel");
    } else {
      require(msg.value >= mansionPrice * _mintAmount, "Not enough funds to mint Mansion");
    }
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    if (cornerShop > 0) {
      if (_mintAmount == 1 && freeSupply > 0 && freeClaimed[msg.sender] < 2) {
        freeClaimed[msg.sender]++;
        cornerShop -= 1;
      } else {
        cornerShop -= _mintAmount;
      }
    } else if (mall > 0) {
      mall -= _mintAmount;
    } else if (hotel > 0) {
      hotel -= _mintAmount;
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
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

  function setSupply(uint256 _index, uint256 _supply) public onlyOwner {
    if (_index == 0) {
      cornerShop = _supply;
    } else if (_index == 1) {
      mall = _supply;
    } else if (_index == 2) {
      hotel = _supply;
    }
  }

  function setFree(uint256 _amount) public onlyOwner {
    freeSupply = _amount;
  }

  function setPrice(uint256 _index, uint256 _newPrice) public onlyOwner {
    if (_index == 0) {
      cornerShopPrice = _newPrice;
    } else if (_index == 1) {
      mallPrice = _newPrice;
    } else if (_index == 2) {
      hotelPrice = _newPrice;
    } else {
      mansionPrice = _newPrice;
    }
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}