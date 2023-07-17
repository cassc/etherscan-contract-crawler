// SPDX-License-Identifier: GPL-3.0

/*
      db       .g8""8q.  MMP""MM""YMM `7MMF'
     ;MM:    .dP'    `YM.P'   MM   `7   MM  
    ,V^MM.   dM'      `MM     MM        MM  
   ,M  `MM   MM        MM     MM        MM  
   AbmmmqMA  MM.      ,MP     MM        MM  
  A'     VML `Mb.    ,dP'     MM   (O)  MM  
.AMA.   .AMMA. `"bmmd"'     .JMML.  Ymmm9   
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ApesOfTheJungle is ERC721Enumerable, Ownable, Pausable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenId;
  Counters.Counter private whitelistCount;
  Counters.Counter private apeKingCount;

  uint256 public constant MAX_SUPPLY = 8888;
  uint256 public constant PUBLIC_PRICE = 0.07 ether;
  uint256 public constant PRESALE_PRICE = 0.05 ether;
  bool public IS_PRESALE_ACTIVE;
  bool public IS_PUBLIC_SALE_ACTIVE;
  string public baseURI;

  mapping(address => bool) public whitelisted;
  mapping(address => bool) public apeKing;
  mapping(address => bool) public presalePurchased;
  mapping(uint256 => bool) private isDnaExist;
  mapping(uint256 => uint256[]) private choruses;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    _tokenId.increment(); //To start token id with 1.
    whitelistCount.increment();
    apeKingCount.increment();
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  // public
  function mint(address _to, uint256[] memory _apes) external payable whenNotPaused {
    uint256 supply = totalSupply();
    require(IS_PRESALE_ACTIVE || IS_PUBLIC_SALE_ACTIVE, "Sale is not active");
    require(supply < MAX_SUPPLY, "Sold out!");

    if (msg.sender != owner()) {
      if (IS_PRESALE_ACTIVE) {
        require(whitelisted[msg.sender] || apeKing[msg.sender], "Address not whitelisted");
        require(!presalePurchased[msg.sender], "Already minted during presale");
        require(msg.value == PRESALE_PRICE || apeKing[msg.sender], "Not enough balance");
        presalePurchased[msg.sender] = true;
      } else {
        require(msg.value == PUBLIC_PRICE, "Not enough balance");
      }
    }

    //Create a copy of _apes array and sort it.
    uint256[] memory _apesSorted = new uint256[](5);

    for (uint256 i = 0; i < 5; i++) {
      _apesSorted[i] = _apes[i];
    }

    uint256 _dna = genDNA(_apesSorted);
    require(!isDnaExist[_dna], "DNA already exists.");
    isDnaExist[_dna] = true;

    choruses[_tokenId.current()] = _apes;

    _safeMint(_to, _tokenId.current());
    _tokenId.increment();
  }

  // Returns array of token IDs of given address
  function walletOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  //only owner
  function setPreSale(bool _state) external onlyOwner {
    IS_PRESALE_ACTIVE = _state;
  }

  function setPublicSale(bool _state) external onlyOwner {
    IS_PUBLIC_SALE_ACTIVE = _state;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function whitelistUser(address _user) external onlyOwner {
    whitelisted[_user] = true;
  }

  function removeWhitelistUser(address _user) external onlyOwner {
    whitelisted[_user] = false;
  }

  function bulkWhitelist(address[] memory addresses) public onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      address addr = addresses[i];
      if (whitelisted[addr] != true && addr != address(0)) {
        whitelisted[addr] = true;
        whitelistCount.increment();
      }
    }
  }

  function removeWhitelist(address _address) public onlyOwner {
    whitelisted[_address] = false;
    whitelistCount.decrement();
  }

  function addApeKing(address _user) external onlyOwner {
    apeKing[_user] = true;
  }

  function bulkAddApeKing(address[] memory addresses) public onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      address addr = addresses[i];
      if (apeKing[addr] != true && addr != address(0)) {
        apeKing[addr] = true;
        apeKingCount.increment();
      }
    }
  }

  function removeApeKing(address _user) external onlyOwner {
    apeKing[_user] = false;
    apeKingCount.decrement();
  }

  function bulkMint(uint256[][] memory _listOfApesList) external onlyOwner {
    uint256 supply = totalSupply();
    require(supply < MAX_SUPPLY - _listOfApesList.length, "Sold out!");

    for (uint256 i = 0; i < _listOfApesList.length; i++) {
      //Create a copy of _apes array and sort it.
      uint256[] memory _apesSorted = new uint256[](5);

      for (uint256 j = 0; j < 5; j++) {
        _apesSorted[j] = _listOfApesList[i][j];
      }

      uint256 _dna = genDNA(_apesSorted);
      require(!isDnaExist[_dna], "DNA already exists.");
      isDnaExist[_dna] = true;

      choruses[_tokenId.current()] = _listOfApesList[i];

      _safeMint(owner(), _tokenId.current());
      _tokenId.increment();
    }
  }

  function isWhitelisted(address _address) external view returns (bool) {
    return whitelisted[_address];
  }

  function isApeKing(address _address) external view returns (bool) {
    return apeKing[_address];
  }

  function getWhitelistCount() external view returns (uint256) {
    return whitelistCount.current();
  }

  function getApeKingCount() external view returns (uint256) {
    return apeKingCount.current();
  }

  function withdraw() external onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function getChorusForToken(uint256 tokenId) public view returns (uint256[] memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return choruses[tokenId];
  }

  function genDNA(uint256[] memory _apes) public pure returns (uint256 dna) {
    require(_apes.length == 5, "Apes count error");
    require(isChoirAllUnique(_apes), "Duplicate ID detected");
    require(isApesInChoirInValidRange(_apes), "Invalid ID Range");

    sort(_apes);
    uint256 length = _apes.length;
    for (uint256 i = 0; i < length; i++) {
      dna += _apes[i] * (100**(length - i - 1));
    }
  }

  function isChoirAvailable(uint256[] memory _apes) external view returns (bool) {
    return !isDnaExist[genDNA(_apes)];
  }

  //Sorts the given array in ascending order.

  function uniqueSort(uint256[] memory data) internal pure {
    uint256 length = data.length;
    bool[] memory set = new bool[](31);
    for (uint256 i = 0; i < length; i++) {
      set[data[i]] = true;
    }
    uint256 n = 0;
    for (uint256 i = 0; i < 31; i++) {
      if (set[i]) {
        data[n] = i;
        if (++n >= length) break;
      }
    }
  }

  function sort(uint256[] memory data) internal pure returns (uint256[] memory) {
    uniqueSort(data);
    return data;
  }

  function isChoirAllUnique(uint256[] memory _apes) internal pure returns (bool) {
    for (uint256 i = 0; i < 5; i++) {
      for (uint256 j = i + 1; j < 5; j++) {
        if (_apes[i] == _apes[j]) {
          return false;
        }
      }
    }

    return true;
  }

  /*
   *  Returns true if the Ape IDs in the choir array are in the following range:
   *  > 0 && <= 30
   */
  function isApesInChoirInValidRange(uint256[] memory _apes) internal pure returns (bool) {
    for (uint256 i = 0; i < 5; i++) {
      if (_apes[i] == 0 || _apes[i] > 30) {
        return false;
      }
    }

    return true;
  }
}