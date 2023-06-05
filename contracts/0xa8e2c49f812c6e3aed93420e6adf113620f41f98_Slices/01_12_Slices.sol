// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface iSlices {
  function tokenIds(address _owner) external view returns (uint256[] memory);

  function availableAmounts() external view returns (uint256[] memory);

  function availableAmountsForPhysical()
    external
    view
    returns (uint256[] memory);

  function setStartDate(uint256 startDateInSec) external;

  function mint(uint256 tokenId) external payable;

  function mintWithPhysical(uint256 tokenId) external payable;

  function setIsOnSale(bool isOnSale) external;

  function setBaseTokenURI(string calldata newBaseURI) external;

  function withdraw() external;
}

contract Slices is iSlices, ERC721, ReentrancyGuard, Ownable {
  struct Day {
    uint256 availableAmount;
    uint256 initialTokenId;
    uint256 price;
    uint256 totalAmount;
  }
  uint256 private constant TYPE = 4;
  uint256 private constant LEVEL = 8;
  uint256 private constant EACH_SUPPLY = 20;
  uint256 private constant EACH_SUPPLY_SPECIAL = 6;
  uint256 private constant EACH_SUPPLY_PHYSICAL = 6;
  uint256 private constant PRICE = 0.2 ether;
  uint256 private constant PRICE_SPECIAL = 1.2 ether;
  uint256 private constant PRICE_PHYSICAL = 2.4 ether;
  uint256 private constant SUPPLY_DIFF = EACH_SUPPLY - EACH_SUPPLY_SPECIAL;
  uint256 private constant ONE_MILLION = 1_000_000;
  uint256 private constant A_DAY = 86400; // 60 * 60 * 24 * 1

  uint256 public constant MAX_SUPPLY =
    TYPE * (LEVEL - 1) * EACH_SUPPLY + TYPE * EACH_SUPPLY_SPECIAL;
  uint256 public constant MAX_SUPPLY_PHYSICAL = TYPE * EACH_SUPPLY_PHYSICAL;
  bool public isOnSale;
  uint256 public startDate;
  mapping(uint256 => Day) public daysList;
  mapping(uint256 => uint256) public mintedPhysicalTokenList;
  mapping(uint256 => bytes32) public tokenIdToHash;

  string private _baseTokenURI;

  constructor(string memory baseTokenURI, uint256 startDateInSec)
    ERC721("Slices", "SLICES")
  {
    _baseTokenURI = baseTokenURI;
    startDate = startDateInSec;

    uint256 wholeDay = TYPE * LEVEL;
    for (uint256 i = 1; i <= wholeDay; i++) {
      if (i % LEVEL == 0) {
        daysList[i].availableAmount = EACH_SUPPLY_SPECIAL;
        daysList[i].totalAmount = EACH_SUPPLY_SPECIAL;
        daysList[i].price = PRICE_SPECIAL;
      } else {
        daysList[i].availableAmount = EACH_SUPPLY;
        daysList[i].totalAmount = EACH_SUPPLY;
        daysList[i].price = PRICE;
      }
      daysList[i].initialTokenId = toTokenId(
        i,
        (i - 1) * EACH_SUPPLY - ((i - 1) / LEVEL) * SUPPLY_DIFF
      );
    }
  }

  function toTokenId(uint256 day, uint256 baseId)
    public
    view
    returns (uint256)
  {
    return day * ONE_MILLION + baseId;
  }

  function currentDay() public view returns (uint256) {
    uint256 t = block.timestamp;
    if (t < startDate) {
      return 0;
    }
    return (t - startDate) / A_DAY + 1;
  }

  function toDayFromId(uint256 id) public view returns (uint256) {
    return
      (id + (id / (LEVEL * EACH_SUPPLY - SUPPLY_DIFF)) * SUPPLY_DIFF) /
      EACH_SUPPLY +
      1;
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
      uint256 _day = toDayFromId(i);
      uint256 tokenId = toTokenId(_day, i);
      if (_exists(tokenId) && ownerOf(tokenId) == _owner) {
        ids[count] = tokenId;
        count++;
      }
    }
    for (uint256 i = 0; i < MAX_SUPPLY_PHYSICAL; i++) {
      uint256 _day = (i / EACH_SUPPLY_PHYSICAL + 1) * LEVEL;
      uint256 tokenId = toTokenId(_day, i + MAX_SUPPLY);
      if (_exists(tokenId) && ownerOf(tokenId) == _owner) {
        ids[count] = tokenId;
        count++;
      }
    }
    return ids;
  }

  function availableAmounts()
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256 wholeDay = TYPE * LEVEL;
    uint256[] memory amounts = new uint256[](wholeDay);
    uint256 count;
    for (uint256 i = 1; i <= wholeDay; i++) {
      amounts[count] = daysList[i].availableAmount;
      count++;
    }
    return amounts;
  }

  function availableAmountsForPhysical()
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256[] memory amounts = new uint256[](TYPE);
    uint256 count;
    for (uint256 i = 1; i <= TYPE; i++) {
      amounts[count] =
        EACH_SUPPLY_PHYSICAL -
        mintedPhysicalTokenList[i * LEVEL];
      count++;
    }
    return amounts;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Slices: URI query for nonexistent token");
    return
      string(
        bytes.concat(
          bytes(_baseTokenURI),
          bytes(Strings.toString(tokenId)),
          bytes(".json")
        )
      );
  }

  function setStartDate(uint256 startDateInSec) external override onlyOwner {
    startDate = startDateInSec;
  }

  function mint(uint256 day) external payable override nonReentrant {
    require(isOnSale, "Slices: Not on sale");
    require(daysList[day].availableAmount > 0, "Slices: No token available");
    require(msg.value == daysList[day].price, "Slices: Invalid value");
    require(day <= currentDay(), "Slices: The day is not available yet");

    uint256 tokenId = daysList[day].initialTokenId +
      daysList[day].totalAmount -
      daysList[day].availableAmount;

    tokenIdToHash[tokenId] = keccak256(
      abi.encodePacked(tokenId, block.timestamp, msg.sender)
    );

    daysList[day].availableAmount--;

    _safeMint(_msgSender(), tokenId);
  }

  function mintWithPhysical(uint256 day)
    external
    payable
    override
    nonReentrant
  {
    require(isOnSale, "Slices: Not on sale");
    require(
      mintedPhysicalTokenList[day] < EACH_SUPPLY_PHYSICAL,
      "Slices: No token available"
    );
    require(msg.value == PRICE_PHYSICAL, "Slices: Invalid value");
    require(day <= currentDay(), "Slices: The day is not available yet");

    uint256 initialTokenId = toTokenId(
      day,
      (day / LEVEL - 1) * EACH_SUPPLY_PHYSICAL + MAX_SUPPLY
    );
    uint256 tokenId = initialTokenId + mintedPhysicalTokenList[day];

    tokenIdToHash[tokenId] = keccak256(
      abi.encodePacked(tokenId, block.timestamp, msg.sender)
    );

    mintedPhysicalTokenList[day]++;

    _safeMint(_msgSender(), tokenId);
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