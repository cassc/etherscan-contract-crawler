// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Admin.sol";

// ● ○ ▲

// Paradigm Shift
// 0xG

contract ParadigmShift is ERC721, Admin {
  bool initialized;
  uint256 tokenId;
  // Token states:
  // 0 Paradigm
  // 1 Shift
  // 2 Paradigm Shift
  mapping(uint256 => uint8) public tokenState;
  mapping(uint16  => uint256) public ofYear;
  mapping(uint256 => uint16) _existsSince;
  mapping(uint256 => uint16) _existsUntil;

  IDateTime dateTime;
  IRender renderer;

  uint256 public royalties;
  address public royaltiesRecipient;

  event Exist(
    address indexed owner,
    uint256 indexed tokenId
  );
  event ParadigmShift(
    address indexed owner,
    uint256 indexed tokenId
  );
  event Paradigm(
    address indexed owner,
    uint256 indexed from,
    uint256 indexed to,
    bool fromParadigmShift
  );
  event Shift(
    address indexed owner,
    uint256 indexed from,
    uint256 indexed to,
    bool fromParadigmShift
  );

  constructor() ERC721("Paradigm Shift", "PS") {}

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return (
      interfaceId == /* EIP2981 */ 0x2a55205a ||
      super.supportsInterface(interfaceId)
    );
  }

  function mint(address to) external adminOnly {
    tokenId += 1;
    _mint(to, tokenId);
  }

  function burn(uint256 tokenId) external {
    require(msg.sender == ERC721.ownerOf(tokenId), "Unauthorized");
    _burn(tokenId);
    _existsSince[tokenId] = 0;
    _existsUntil[tokenId] = 0;
    if (tokenState[tokenId] != 0) {
      tokenState[tokenId] = 0;
    }
  }

  function setDateTime(address addr) external adminOnly {
    dateTime = IDateTime(addr);
  }

  function _isDead(uint256 tokenId) internal view returns (bool) {
    if (tokenState[tokenId] == 2) {
      return false;
    }

    IDateTime.Date memory date = dateTime.parseTimestamp(block.timestamp);

    uint8 delta =
      (date.month == 10 && date.day == 31) || date.month > 10
        ? 1
        : 0;

    return _existsUntil[tokenId] < date.year + delta;
  }

  function isDead(uint256 tokenId) external view returns (bool) {
    return _isDead(tokenId);
  }

  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    if (initialized && _isDead(tokenId)) {
      _requireMinted(tokenId);
      return address(0xdEaD);
    }

    return ERC721.ownerOf(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override virtual {
    require(from == address(0) || !_isDead(tokenId), "Transfer locked");
    if (to == address(0xdEaD)) {
      _existsSince[tokenId] = 0;
      _existsUntil[tokenId] = 0;
      tokenState[tokenId] = 0;
    }
  }

  function exist(uint256 tokenId) external {
    require(msg.sender == ERC721.ownerOf(tokenId), "Unauthorized");
    require(tokenState[tokenId] != 2, "Already existing");

    IDateTime.Date memory date = dateTime.parseTimestamp(block.timestamp);
    require(date.month == 10 && date.day == 31, "Can be called only on October 31st");

    if (ofYear[date.year] == 0) {
      ofYear[date.year] = tokenId;
      tokenState[tokenId] = 2;
      _existsSince[tokenId] = date.year;
      emit ParadigmShift(msg.sender, tokenId);
    } else if (_existsUntil[tokenId] != date.year) {
      _existsSince[tokenId] = date.year;
    }
    _existsUntil[tokenId] = date.year + 1;
    emit Exist(msg.sender, tokenId);
  }

  function _setExists(uint256 tokenId) internal {
    IDateTime.Date memory date = dateTime.parseTimestamp(block.timestamp);
    require(date.month != 10 || date.day != 31, "Cannot call on October 31st");
    _existsSince[tokenId] = date.year;
    _existsUntil[tokenId] = date.year + (date.month > 10 ? 1 : 0);
  }

  function existsSince(uint256 tokenId) external view returns (uint16) {
    if (_isDead(tokenId)) {
      return 0;
    }
    return _existsSince[tokenId];
  }

  function age(uint256 tokenId) external view returns (uint256) {
    if (_existsSince[tokenId] == 0 || _isDead(tokenId)) {
      return 0;
    }

    IDateTime.Date memory date = dateTime.parseTimestamp(block.timestamp);

    if (date.year == _existsSince[tokenId]) {
      return 0;
    }
    if (date.month >= 11) {
      return date.year - _existsSince[tokenId];
    }
    return date.year - _existsSince[tokenId] - 1;
  }

  function paradigm(uint256 from, uint256 to) external {
    require(
      msg.sender == ERC721.ownerOf(from) &&
      msg.sender == ERC721.ownerOf(to),
      "Unauthorized"
    );
    require(tokenState[from] != 0 && !_isDead(from), "`from` must be alive and cannot be a paradigm");
    require(_isDead(to), "`to` must be dead");
    if (tokenState[from] == 1) {
      tokenState[from] = 0;
    }
    tokenState[to] = 0;
    _setExists(to);
    emit Paradigm(msg.sender, from, to, tokenState[from] == 2);
  }

  function shift(uint256 from, uint256 to) external {
    require(
      msg.sender == ERC721.ownerOf(from) &&
      msg.sender == ERC721.ownerOf(to),
      "Unauthorized"
    );
    require(tokenState[from] == 2 || _isDead(from), "`from` must be paradigm shift or dead");
    require(tokenState[to] == 0 && !_isDead(to), "`to` must be alive and a paradigm");
    bool fromParadigmShift = tokenState[from] == 2;
    if (fromParadigmShift) {
      tokenState[from] = 0;
      _setExists(from);
    }
    tokenState[to] = 1;
    emit Shift(msg.sender, from, to, fromParadigmShift);
  }

  function setRenderer(address addr) external adminOnly {
    renderer = IRender(addr);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);
    return renderer.render(tokenId);
  }

  function setRoyalties(uint256 value, address recipient) external adminOnly {
    royalties = value;
    royaltiesRecipient = recipient;
  }

  function royaltyInfo(uint256, uint256 value) external view returns (address receiver, uint256 royaltyAmount) {
    if (royalties > 0 && royaltiesRecipient != address(0)) {
      return (royaltiesRecipient, value * royalties / 10000);
    }

    return (address(0), 0);
  }

  function initialize() external adminOnly {
    initialized = true;
  }

  function destroy() external adminOnly {
    require(!initialized, "Unauthorized");
    selfdestruct(payable(owner()));
  }
}

interface IDateTime {
  struct Date {
    uint16 year;
    uint8 month;
    uint8 day;
    uint8 hour;
    uint8 minute;
    uint8 second;
    uint8 weekday;
  }
  function parseTimestamp(uint timestamp) external pure returns (Date memory d);
}

interface IRender {
  function render(uint256 tokenId) external view returns (string memory);
}