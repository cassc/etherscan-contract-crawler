// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface iThalesEngraving {
  function mintedTokenIdList() external view returns (uint256[] memory);

  function tokenIds(address _owner) external view returns (uint256[] memory);

  function mint(uint256 tokenId) external payable;

  function mintForFree(address to, uint256[] memory tokenIdList) external;

  function mintWithCard(uint256 tokenId) external;

  function setIsOnSale(bool isOnSale) external;

  function setIsMetadataFrozen(bool isMetadataFrozen) external;

  function setBaseTokenURI(string calldata newBaseURI) external;

  function withdraw() external;
}

contract ThalesEngraving is iThalesEngraving, ERC721, ReentrancyGuard, Ownable {
  uint256 public constant MAX_SUPPLY = 100;
  uint256 public constant PRICE = 0.1 ether;
  address public constant ARTIST = 0xAe7AEdC47AE016B4B6c95F5E311719804c57ebaB;

  bool public isOnSale;
  bool public isMetadataFrozen;
  uint256[] private _mintedTokenIdList;

  string private _baseTokenURI;

  constructor(string memory baseTokenURI) ERC721("Thales Engraving", "TE") {
    _baseTokenURI = baseTokenURI;
  }

  function mintedTokenIdList()
    external
    view
    override
    returns (uint256[] memory)
  {
    return _mintedTokenIdList;
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
    for (uint256 i = 1; i <= MAX_SUPPLY; i++) {
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
    require(
      _exists(tokenId),
      "ThalesEngraving: URI query for nonexistent token"
    );
    return
      string(
        bytes.concat(
          bytes(_baseTokenURI),
          bytes(Strings.toString(tokenId)),
          bytes(".json")
        )
      );
  }

  function mintAndTransfer(address to, uint256 tokenId) internal {
    require(
      tokenId > 0 && tokenId <= MAX_SUPPLY,
      "ThalesEngraving: Invalid tokenId"
    );
    _mintedTokenIdList.push(tokenId);
    _safeMint(ARTIST, tokenId);
    _safeTransfer(ARTIST, to, tokenId, "");
  }

  function mint(uint256 tokenId) external payable override nonReentrant {
    require(isOnSale, "ThalesEngraving: Not on sale");
    require(msg.value == PRICE, "ThalesEngraving: Invalid value");
    mintAndTransfer(_msgSender(), tokenId);
  }

  function mintForFree(address to, uint256[] memory tokenIdList)
    external
    override
    onlyOwner
  {
    uint256 count = tokenIdList.length;
    for (uint256 i; i < count; i++) {
      uint256 tokenId = tokenIdList[i];
      mintAndTransfer(to, tokenId);
    }
  }

  // Keep token temporary
  function mintWithCard(uint256 tokenId) external override onlyOwner {
    require(isOnSale, "ThalesEngraving: Not on sale");
    mintAndTransfer(owner(), tokenId);
  }

  function setIsOnSale(bool _isOnSale) external override onlyOwner {
    isOnSale = _isOnSale;
  }

  function setIsMetadataFrozen(bool _isMetadataFrozen)
    external
    override
    onlyOwner
  {
    require(
      !isMetadataFrozen,
      "ThalesEngraving: isMetadataFrozen cannot be changed"
    );
    isMetadataFrozen = _isMetadataFrozen;
  }

  function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
    require(!isMetadataFrozen, "ThalesEngraving: Metadata is already frozen");
    _baseTokenURI = baseTokenURI;
  }

  function withdraw() external override onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }
}