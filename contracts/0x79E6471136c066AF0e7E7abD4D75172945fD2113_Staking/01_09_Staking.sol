// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Staking is Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  event Stake(address contractAddress, uint256 tokenId, address owner);
  event Unstake(address contractAddress, uint256 tokenId, address owner);

  constructor() {}

  mapping(address => mapping(address => EnumerableSet.UintSet)) private addressToStakedTokensSet;
  mapping(address => mapping(uint256 => address)) private contractTokenIdToOwner;
  mapping(address => mapping(uint256 => uint256)) private contractTokenIdToStakedTimestamp;

  function stake(address contractAddress, uint256[] memory tokenIds) external nonReentrant {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      contractTokenIdToOwner[contractAddress][tokenId] = _msgSender();
      IERC721(contractAddress).transferFrom(_msgSender(), address(this), tokenId);
      addressToStakedTokensSet[contractAddress][_msgSender()].add(tokenId);
      contractTokenIdToStakedTimestamp[contractAddress][tokenId] = block.timestamp;

      emit Stake(contractAddress, tokenId, _msgSender());
    }
  }

  function unstake(
    address contractAddress,
    uint256[] memory tokenIds
  ) external nonReentrant {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(addressToStakedTokensSet[contractAddress][_msgSender()].contains(tokenId), "Token is not staked");

      delete contractTokenIdToOwner[contractAddress][tokenId];
      IERC721(contractAddress).transferFrom(address(this), _msgSender(), tokenId);
      addressToStakedTokensSet[contractAddress][_msgSender()].remove(tokenId);
      delete contractTokenIdToStakedTimestamp[contractAddress][tokenId];

      emit Unstake(contractAddress, tokenId, _msgSender());
    }
  }

  function stakedTokensOfOwner(address contractAddress, address owner) external view returns (uint256[] memory) {
    EnumerableSet.UintSet storage userTokens = addressToStakedTokensSet[contractAddress][owner];
    uint256[] memory tokenIds = new uint256[](userTokens.length());

    for (uint256 i = 0; i < userTokens.length(); i++) {
      tokenIds[i] = userTokens.at(i);
    }

    return tokenIds;
  }

  function stakedTokenOwner(address contractAddress, uint256 tokenId) external view returns (address) {
    return contractTokenIdToOwner[contractAddress][tokenId];
  }

  function stakedTokenTimestamp(address contractAddress, uint256 tokenId) external view returns (uint256) {
    return contractTokenIdToStakedTimestamp[contractAddress][tokenId];
  }
}