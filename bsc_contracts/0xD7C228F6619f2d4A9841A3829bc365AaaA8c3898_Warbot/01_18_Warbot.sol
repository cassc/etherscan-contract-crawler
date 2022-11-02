// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./OwnersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Warbot is ERC721EnumerableUpgradeable, OwnersUpgradeable {

  using Counters for Counters.Counter;
  address[] public warbotOwners;
  mapping(address => bool) public warbotOwnersInserted;

  Counters.Counter private _tokenIdCounter;

  string private uriBase;
  bool public openCreateNft;

  mapping(address => bool) public isBlacklisted;

  function initialize(string memory uri)
      external
      initializer
  {
      __Warbot_init(uri);
  }

  function __Warbot_init(string memory uri)
      internal
      onlyInitializing
  {
      __Owners_init_unchained();
      __ERC721_init_unchained("Warbot", "WB");
      __Warbot_init_unchained(uri);
  }

  function __Warbot_init_unchained(string memory uri)
      internal
      onlyInitializing
  {
      uriBase = uri;
      openCreateNft = false;
  }

  function burnBatch(address user, uint256[] memory tokenIds)
      external
      onlyOwners
  {
      for (uint256 i = 0; i < tokenIds.length; i++) {
          require(ownerOf(tokenIds[i]) == user, "Warbot: Not nft owner");
          super._burn(tokenIds[i]);
      }
  }

  function generateNfts(address user, uint count) external onlyOwners returns (uint256[] memory) {
    require(!isBlacklisted[user], "Warbot: Blacklisted address");
    require(openCreateNft, "Warbot: Not open");
  
    if (warbotOwnersInserted[user] == false) {
        warbotOwners.push(user);
        warbotOwnersInserted[user] = true;
    }

    uint256[] memory tokenIds = new uint256[](count);

    for (uint256 i = 0; i < count; i++) {
        uint256 tokenId = _tokenIdCounter.current();
        tokenIds[i] = tokenId;
        _safeMint(user, tokenId);
        _tokenIdCounter.increment();
    }
  
    return tokenIds;
  }

  function setBaseURI(string memory _new) external onlyOwners {
      uriBase = _new;
  }

  function setIsBlacklisted(address _new, bool _value) external onlyOwners {
      isBlacklisted[_new] = _value;
  }

  function setOpenCreateNft(bool _new) external onlyOwners {
      openCreateNft = _new;
  }
  
  function tokensOfOwner(address user)
      external
      view
      returns (uint256[] memory)
  {
      uint256[] memory result = new uint256[](balanceOf(user));
      for (uint256 i = 0; i < balanceOf(user); i++)
          result[i] = tokenOfOwnerByIndex(user, i);
      return result;
  }

  function tokensOfOwnerByIndexesBetween(
        address user,
        uint256 iStart,
        uint256 iEnd
    ) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](iEnd - iStart);
        for (uint256 i = iStart; i < iEnd; i++)
            result[i - iStart] = tokenOfOwnerByIndex(user, i);
        return result;
    }

  function getWarbotOwnersSize() external view returns (uint256) {
      return warbotOwners.length;
  }

  function getWarbotOwnersBetweenIndexes(uint256 iStart, uint256 iEnd)
      external
      view
      returns (address[] memory)
  {
      address[] memory no = new address[](iEnd - iStart);
      for (uint256 i = iStart; i < iEnd; i++) no[i - iStart] = warbotOwners[i];
      return no;
  }

  function _baseURI() internal view override returns (string memory) {
      return uriBase;
  }

  function _transfer(
          address from,
          address to,
          uint256 tokenId
      ) internal override {
          require(
              !isBlacklisted[from] && !isBlacklisted[to],
              "Warbot: Blacklisted address"
          );

          if (warbotOwnersInserted[to] == false) {
              warbotOwners.push(to);
              warbotOwnersInserted[to] = true;
          }

          super._transfer(from, to, tokenId);
      }

  function reclaimERC20(IERC20 erc20Token, address account) external onlyOwners {
    SafeERC20.safeTransfer(erc20Token, account, erc20Token.balanceOf(address(this)));
  }

}