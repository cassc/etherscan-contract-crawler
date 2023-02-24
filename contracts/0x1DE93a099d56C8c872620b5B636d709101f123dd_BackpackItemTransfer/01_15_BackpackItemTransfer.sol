// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "./mason/utils/Administrable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./IBackpackItem.sol";

error ExceedsMaxSupply();
error RoyaltiesTooHigh();
error NotApproved();
error HoldingContractNotSet();
error TokenContractNotSet();

contract BackpackItemTransfer is Administrable, IBackpackItem {
  using EnumerableSet for EnumerableSet.UintSet;

  mapping(uint256 => fulfillmentRule) private fulfillmentRules;
  mapping(uint256 => uint256) private tokenSupply;

  address private holdingWallet;
  address private onCyberContract;

  EnumerableSet.UintSet private tokenIds;

  struct fulfillmentRule {
    uint256 tokenId;
    uint256 maxSupply;
    bool eligible;
  }

  // Tracks how many tokens should be dropped when fulfillment, if > available tokens,
  // then drop all available tokens, if < then we will randomly select from the available tokens
  uint256 public fulfillmentQuantity = 1;

  constructor() {}

  function setHoldingWallet(address wallet) external onlyOperatorsAndOwner {
    holdingWallet = wallet;
  }

  function setOnCyberContract(address contractAddress) external onlyOperatorsAndOwner {
    onCyberContract = contractAddress;
  }

  function addTokenId(uint256 tokenId, uint256 maxSupply) external onlyOperatorsAndOwner {
    tokenIds.add(tokenId);

    fulfillmentRules[tokenId] = fulfillmentRule(tokenId, maxSupply, true);
  }

  function setMaxSupply(uint256 tokenId, uint256 max) external onlyOperatorsAndOwner {
    fulfillmentRules[tokenId].maxSupply = max;
  }

  function setEligibility(uint256 tokenId, bool eligible) external onlyOperatorsAndOwner {
    fulfillmentRules[tokenId].eligible = eligible;
  }

  function setFullfillmentQuantity(uint256 quantity) external onlyOperatorsAndOwner {
    fulfillmentQuantity = quantity;
  }

  function removeTokenId(uint256 tokenId) external onlyOperatorsAndOwner {
    tokenIds.remove(tokenId);
  }

  function fulfill(address recipient, bool _maximum) external onlyOperatorsAndOwner {
    if (holdingWallet == address(0)) revert HoldingContractNotSet();
    if (onCyberContract == address(0)) revert TokenContractNotSet();
    if (!IERC1155(onCyberContract).isApprovedForAll(holdingWallet, address(this))) revert NotApproved();

    uint256[] memory eligibleTokenIds = _eligibleTokenIds();
    uint256 eligibleTokenIdCount = eligibleTokenIds.length;

    uint256[] memory selectedTokens = eligibleTokenIdCount <= fulfillmentQuantity
      ? eligibleTokenIds
      : _selectTokens(eligibleTokenIds, fulfillmentQuantity);

    for (uint256 i = 0; i < selectedTokens.length; ) {
      // TODO: Validate Quantity?
      IERC1155(onCyberContract).safeTransferFrom(holdingWallet, recipient, selectedTokens[i], 1, "");
      unchecked {
        ++i;
      }
    }
  }

  function _selectTokens(uint256[] memory sourceArray, uint n) internal view returns (uint256[] memory) {
    uint256[] memory selectedItems = new uint256[](n);
    uint sourceLength = sourceArray.length;

    for (uint i = 0; i < n; ) {
      uint randomIndex = uint(uint256(keccak256(abi.encodePacked(block.timestamp, i))) % sourceLength);
      selectedItems[i] = sourceArray[randomIndex];
      unchecked {
        ++i;
      }
    }

    return selectedItems;
  }

  function _hasAvailableSupplyForFulfillment(uint256 maxSupply, uint256 totalSupply) internal pure returns (bool) {
    return maxSupply == 0 || totalSupply < maxSupply;
  }

  function _eligibleTokenIds() internal view returns (uint256[] memory) {
    uint256 count;

    for (uint256 i = 0; i < tokenIds.length(); ) {
      uint256 tokenId = tokenIds.at(i);
      fulfillmentRule memory rule = fulfillmentRules[tokenId];

      if (rule.eligible && _hasAvailableSupplyForFulfillment(rule.maxSupply, tokenSupply[tokenId])) {
        unchecked {
          ++count;
        }
      }

      unchecked {
        ++i;
      }
    }

    uint256[] memory eligibleTokenIds = new uint256[](count);

    for (uint256 i = 0; i < tokenIds.length(); ) {
      uint256 tokenId = tokenIds.at(i);
      fulfillmentRule memory rule = fulfillmentRules[tokenId];

      if (rule.eligible && _hasAvailableSupplyForFulfillment(rule.maxSupply, tokenSupply[tokenId])) {
        eligibleTokenIds[i] = tokenId;
      }

      unchecked {
        ++i;
      }
    }

    return eligibleTokenIds;
  }

  function _quantities(uint256 count) internal pure returns (uint256[] memory) {
    uint256[] memory fulfillmentQuantities = new uint256[](count);

    for (uint256 i = 0; i < count; ) {
      fulfillmentQuantities[i] = 1;

      unchecked {
        ++i;
      }
    }

    return fulfillmentQuantities;
  }

  function _hasAvailableSupply(uint256 tokenId, uint256 quantity) internal view returns (bool) {
    fulfillmentRule memory rule = fulfillmentRules[tokenId];
    if (rule.maxSupply == 0) return true;

    return tokenSupply[tokenId] + quantity <= rule.maxSupply;
  }

  function sum(uint256[] memory amounts) internal pure returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < amounts.length; ) {
      sum += amounts[i];
      unchecked {
        ++i;
      }
    }
    return sum;
  }
}