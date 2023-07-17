// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../structs/JBTokenAmount.sol';
import '../interfaces/IPriceResolver.sol';
import '../interfaces/ITokenSupplyDetails.sol';

/**
  @dev Token id 0 has special meaning in NFTRewardDataSourceDelegate where minting will be skipped.
  @dev An example tier collecting might look like this:
  [ { contributionFloor: 1 ether }, { contributionFloor: 5 ether }, { contributionFloor: 10 ether } ]
 */
struct OpenRewardTier {
  /** @notice Minimum contribution to qualify for this tier. */
  uint256 contributionFloor;
}

contract OpenTieredPriceResolver is IPriceResolver {
  address public contributionToken;
  OpenRewardTier[] public tiers;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_PRICE_SORT_ORDER(uint256);
  error INVALID_ID_SORT_ORDER(uint256);

  /**
    @notice This price resolver allows project admins to define multiple reward tiers for contributions and issue NFTs to people who contribute at those levels. 

    @dev This pride resolver requires a custom token uri resolver which is defined in OpenTieredTokenUriResolver.

    @dev Tiers list must be sorted by floor otherwise contributors won't be rewarded properly.

    @dev There is a limit of 255 tiers.

    @param _contributionToken Token used for contributions, use JBTokens.ETH to specify ether.
    @param _tiers Sorted tier collection.
   */
  constructor(address _contributionToken, OpenRewardTier[] memory _tiers) {
    contributionToken = _contributionToken;

    if (_tiers.length > type(uint8).max) {
      revert();
    }

    if (_tiers.length > 0) {
      tiers.push(_tiers[0]);
      for (uint256 i = 1; i < _tiers.length; i++) {
        if (_tiers[i].contributionFloor < _tiers[i - 1].contributionFloor) {
          revert INVALID_PRICE_SORT_ORDER(i);
        }

        tiers.push(_tiers[i]);
      }
    }
  }

  /**
    @notice Returns the token id that should be minted for a given contribution for the contributor account.

    @dev If token id 0 is returned, the mint should be skipped. This function specifically does not revert so that it doesn't interrupt the contribution flow since NFT rewards are optional.

    @dev Since this contract is agnostic of the token type it operates on, ERC721 or ERC1155, the token id being returned is not checked for collisions.

    @param account Address sending the contribution.
    @param contribution Contribution amount.
    ignored ITokenSupplyDetails
   */
  function validateContribution(
    address account,
    JBTokenAmount calldata contribution,
    ITokenSupplyDetails
  ) public view override returns (uint256 tokenId) {
    if (contribution.token != contributionToken) {
      return 0;
    }

    tokenId = 0;
    uint256 tiersLength = tiers.length;
    for (uint256 i; i < tiersLength; ) {
      if (
        (tiers[i].contributionFloor <= contribution.value && i == tiers.length - 1) ||
        (tiers[i].contributionFloor <= contribution.value &&
          tiers[i + 1].contributionFloor > contribution.value)
      ) {
        tokenId = i | (uint248(uint256(keccak256(abi.encodePacked(account, block.number)))) << 8);
        break;
      }
      unchecked {
        ++i;
      }
    }
  }
}