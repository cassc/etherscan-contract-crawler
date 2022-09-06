// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface iAHeavenInAWildFlower {
  function mintedTokenIdList() external view returns (uint256[] memory);

  function tokenIds(address _owner) external view returns (uint256[] memory);

  function mint(uint256 quantity) external payable;

  function mintForFree(address to, uint256 quantity) external;

  function setIsOnSale(bool isOnSale) external;

  function setIsMetadataFrozen(bool isMetadataFrozen) external;

  function setBaseTokenURI(string calldata newBaseURI) external;

  function withdraw() external;
}

contract AHeavenInAWildFlower is
  iAHeavenInAWildFlower,
  ERC721,
  ReentrancyGuard,
  Ownable
{
  uint256 public constant MAX_SUPPLY = 256;
  uint256 public constant PRICE = 0.08 ether;
  address public constant ARTIST = 0xAbc9B3AF7ba302c60049Dc826fb2532b37504196;

  bool public isOnSale;
  bool public isMetadataFrozen;
  mapping(uint256 => bytes32) public tokenIdToHash;
  uint256[] private _mintedTokenIdList;

  string private _baseTokenURI;

  constructor(string memory baseTokenURI)
    ERC721("A heaven in a wild flower", "HIWF")
  {
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
    require(
      _exists(tokenId),
      "AHeavenInAWildFlower: URI query for nonexistent token"
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

  function mintAndTransfer(address to, uint256 quantity) internal {
    uint256 nextTokenId = _mintedTokenIdList.length;
    require(
      nextTokenId + quantity <= MAX_SUPPLY,
      "AHeavenInAWildFlower: Sold out or invalid amount"
    );

    for (uint256 i = 0; i < quantity; i++) {
      uint256 tokenId = nextTokenId + i;
      tokenIdToHash[tokenId] = keccak256(
        abi.encodePacked(tokenId, block.timestamp, msg.sender)
      );

      _mintedTokenIdList.push(tokenId);
      _safeMint(ARTIST, tokenId);
      _safeTransfer(ARTIST, to, tokenId, "");
    }
  }

  function mint(uint256 quantity) external payable override nonReentrant {
    require(isOnSale, "AHeavenInAWildFlower: Not on sale");
    require(
      msg.value == PRICE * quantity,
      "AHeavenInAWildFlower: Invalid value"
    );
    mintAndTransfer(_msgSender(), quantity);
  }

  function mintForFree(address to, uint256 quantity)
    external
    override
    onlyOwner
  {
    mintAndTransfer(to, quantity);
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
      "AHeavenInAWildFlower: isMetadataFrozen cannot be changed"
    );
    isMetadataFrozen = _isMetadataFrozen;
  }

  function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
    require(
      !isMetadataFrozen,
      "AHeavenInAWildFlower: Metadata is already frozen"
    );
    _baseTokenURI = baseTokenURI;
  }

  function withdraw() external override onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }
}