// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface iTinySketches {
  function mintedTokenIdList() external view returns (uint256[] memory);

  function tokenIds(address _owner) external view returns (uint256[] memory);

  function setStartDate(uint256 startDateInSec) external;

  function mint(uint256 tokenId) external payable;

  function mintForFree(address to, uint256[] memory tokenIdList) external;

  function setIsOnSale(bool isOnSale) external;

  function setBaseTokenURI(string calldata newBaseURI) external;

  function withdraw() external;
}

contract TinySketches is iTinySketches, ERC721, ReentrancyGuard, Ownable {
  uint256 public constant TOTAL_ART_NUM = 4;
  uint256 public constant EACH_SUPPLY = 60;
  uint256 public constant MAX_SUPPLY = TOTAL_ART_NUM * EACH_SUPPLY;
  uint256 public constant PRICE = 0.05 ether;
  bool public isOnSale;
  uint256 public startDate;

  uint256 private constant A_WEEK = 604800; // 60 * 60 * 24 * 7

  uint256[] private _mintedTokenIdList;
  string private _baseTokenURI;

  constructor(string memory baseTokenURI, uint256 startDateInSec)
    ERC721("Tiny Sketches", "TS")
  {
    _baseTokenURI = baseTokenURI;
    startDate = startDateInSec;
  }

  modifier checkMintable(uint256 tokenId) {
    uint256 _mintableLastTokenId = mintableLastTokenId();
    require(
      tokenId <= _mintableLastTokenId,
      "TinySketches: The tokenId is not available yet."
    );
    _;
  }

  function mintableLastTokenId() public view returns (uint256) {
    uint256 t = block.timestamp;
    require(t > startDate, "TinySketches: no tokens are on sale yet.");
    uint256 passedWeeks = (t - startDate) / A_WEEK + 1;
    if (passedWeeks > 3) {
      return 239;
    } else {
      return passedWeeks * EACH_SUPPLY - 1;
    }
  }

  function tokenIds(address _owner)
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory ids = new uint256[](tokenCount);
    uint256 count;
    for (uint256 i = 0; i < MAX_SUPPLY; i++) {
      if (_exists(i) && ownerOf(i) == _owner) {
        ids[count] = i;
        count++;
      }
    }
    return ids;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "TinySketches: URI query for nonexistent token");
    return
      string(
        bytes.concat(
          bytes(_baseTokenURI),
          bytes(Strings.toString(tokenId)),
          bytes(".json")
        )
      );
  }

  function mintedTokenIdList()
    external
    view
    override
    returns (uint256[] memory)
  {
    return _mintedTokenIdList;
  }

  function setStartDate(uint256 startDateInSec) external override onlyOwner {
    startDate = startDateInSec;
  }

  function mint(uint256 tokenId)
    external
    payable
    override
    nonReentrant
    checkMintable(tokenId)
  {
    require(isOnSale, "TinySketches: Not on sale");
    require(msg.value == PRICE, "TinySketches: Invalid value");

    _mintedTokenIdList.push(tokenId);
    _safeMint(_msgSender(), tokenId);
  }

  function mintForFree(address to, uint256[] memory tokenIdList)
    external
    override
    onlyOwner
  {
    uint256 count = tokenIdList.length;
    for (uint256 i; i < count; i++) {
      uint256 id = tokenIdList[i];
      require(id < MAX_SUPPLY, "TinySketches: Invalid token id");
      _mintedTokenIdList.push(id);
      _safeMint(to, id);
    }
  }

  function setIsOnSale(bool _isOnSale) external override onlyOwner {
    isOnSale = _isOnSale;
  }

  function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
    _baseTokenURI = baseTokenURI;
  }

  function withdraw() external override onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }
}