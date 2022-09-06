// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IDealer.sol";
import "./abstracts/ShibaCardsAccessible.sol";

contract ShibaCardsDealer is IDealer, ShibaCardsAccessible {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter public total;
  Counters.Counter public set;
  mapping(uint256 => uint256[]) private mintableBySet;
  mapping(uint256 => Counters.Counter) private totalMintableBySet;
 
  uint256 constant EDITIONS = 3;
  
  /**
   * @dev stores the shares of cards
   */
  mapping(uint256 => uint256) public sharesOf;

  function getSharesOf(uint256 tokenId) public override view returns (uint256) {
    return sharesOf[tokenId];
  }

  function getSharesOf(uint256[] memory tokenIds) external override view returns(uint256) {
    uint256 totalShares;
    
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      totalShares += getSharesOf(tokenId);
    }

    return totalShares;
  }

  function getIdsAndShares(uint256[] memory rnds) external view override returns (uint256[] memory, uint256) {
    uint256[] memory ids = new uint256[](rnds.length);
    uint256 shares;
 
    for (uint256 i = 0; i < rnds.length; i++) {
      uint256 rnd = rnds[i];
      ids[i] = rnd.mod(totalMintableBySet[set.current()].current().div(EDITIONS)).mul(EDITIONS).add(pickEdition(rnd % 100));
      shares +=  getSharesOf(ids[i]);
    }

    return (ids, shares);
  }

  /**
   * @dev Gets the edition by the token id. Assumes the amount of tokens is always a multiple of edtiions.
   */
  function getEditionByTokenId(uint256 tokenId) external override pure returns (uint256) {
    return [3, 1, 2][tokenId.mod(EDITIONS)];
  }

  /**
   * @dev Creates a new token by simply increasing the counter.
   */
  function _getNewId() internal returns (uint256 newId) {
    total.increment();
    return total.current();
  }

  /**
   * @dev Set the next set to mint cards from
   */
  function nextSet() public onlyAdmin {
    set.increment();
  }

  /**
   * @dev Creates a new mintable token with editions.
   */
  function create() public override onlyWhitelistedOrAdmin returns(uint256[] memory) {
    uint256[] memory ids = new uint256[](EDITIONS);
    
    for (uint256 i = 0; i < EDITIONS; i++) {
      uint256 newId = _getNewId();
      uint256 shares = 10**i;

      sharesOf[newId] = shares;
      mintableBySet[set.current()].push(newId);
      totalMintableBySet[set.current()].increment();

      ids[i] = newId;
    }

    emit CardCreated(ids, true);

    return ids;
  }

  /**
   * @dev Creates a new platinum token with editions.
   */
  function createNonMintable() public override onlyWhitelistedOrAdmin returns(uint256[] memory) {
    uint256[] memory ids = new uint256[](EDITIONS);
    
    for (uint256 i = 0; i < EDITIONS; i++) {
      uint256 newId = _getNewId();
      uint256 shares = 10**i;

      sharesOf[newId] = shares.add(shares.mul(100).div(20));

      ids[i] = newId;
    }

    emit CardCreated(ids, false);

    return ids;
  }

  /**
   * @dev Get mintable cards as array.
   */
  function getMintableCards() public view returns (uint256[] memory) {
    return mintableBySet[set.current()];
  }

  /**
   * @dev Pick a random weighted edition.
   */
  function pickEdition(uint256 rnd) internal pure returns (uint256 edition) {
    if (rnd == 99) return 3; // Legendary
    if (rnd > 89) return 2; // Rare
    return 1; // Common
  }
}