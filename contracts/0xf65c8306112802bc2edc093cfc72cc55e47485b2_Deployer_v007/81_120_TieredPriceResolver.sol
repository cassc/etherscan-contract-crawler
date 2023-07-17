// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../structs/JBTokenAmount.sol';
import '../interfaces/IPriceResolver.sol';
import '../interfaces/ITokenSupplyDetails.sol';

/**
  @dev Token id 0 has special meaning in NFTRewardDataSourceDelegate where minting will be skipped.
  @dev An example tier collecting might look like this:
  [ { contributionFloor: 1 ether, idCeiling: 1001, remainingAllowance: 1000 }, { contributionFloor: 5 ether, idCeiling: 1501, remainingAllowance: 500 }, { contributionFloor: 10 ether, idCeiling: 1511, remainingAllowance: 10 }]
 */
struct RewardTier {
  /** @notice Minimum contribution to qualify for this tier. */
  uint256 contributionFloor;
  /** @notice Highest token id in this tier. */
  uint256 idCeiling;
  /**
    @notice Remaining number of tokens in this tier.
    @dev Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
  */
  uint256 remainingAllowance;
}

contract TieredPriceResolver is IPriceResolver {
  address public contributionToken;
  uint256 public globalMintAllowance;
  uint256 public userMintCap;
  RewardTier[] public tiers;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_PRICE_SORT_ORDER(uint256);
  error INVALID_ID_SORT_ORDER(uint256);

  /**
    @notice This price resolver allows project admins to define multiple reward tiers for contributions and issue NFTs to people who contribute at those levels. It is also possible to limit total number of NFTs issues and total number of NFTs issued per account regardless of the contribution amount. Let's say the total number of NFTs defined in the tiers is 10k, the global mint cap can limit that number to 5000 across all tiers.

    @dev Tiers list must be sorted by floor otherwise contributors won't be rewarded properly.

    @param _contributionToken Token used for contributions, use JBTokens.ETH to specify ether.
    @param _mintCap Global mint cap, this allows limiting total NFT supply in addition to the limits already defined in the tiers.
    @param _userMintCap Per-account mint cap.
    @param _tiers Sorted tier collection.
   */
  constructor(
    address _contributionToken,
    uint256 _mintCap, // TODO: reconsider this and use token.MaxSupply instead
    uint256 _userMintCap,
    RewardTier[] memory _tiers
  ) {
    contributionToken = _contributionToken;
    globalMintAllowance = _mintCap;
    userMintCap = _userMintCap;

    if (_tiers.length > 0) {
      tiers.push(_tiers[0]);
      for (uint256 i = 1; i < _tiers.length; i++) {
        if (_tiers[i].contributionFloor < _tiers[i - 1].contributionFloor) {
          revert INVALID_PRICE_SORT_ORDER(i);
        }

        if (_tiers[i].idCeiling - _tiers[i].remainingAllowance < _tiers[i - 1].idCeiling) {
          revert INVALID_ID_SORT_ORDER(i);
        }

        tiers.push(_tiers[i]);
      }
    }
  }

  /**
    @notice Returns the token id that should be minted for a given contribution for the contributor account.

    @dev If token id 0 is returned, the mint should be skipped. This function specifically does not revert so that it doesn't interrupt the contribution flow since NFT rewards are optional and may be exhausted during project or funding cycle lifetime.

    @param account Address sending the contribution.
    @param contribution Contribution amount.
    @param token Reward token to be issued as a reward, used to read token data only.
   */
  function validateContribution(
    address account,
    JBTokenAmount calldata contribution,
    ITokenSupplyDetails token
  ) public override returns (uint256 tokenId) {
    if (contribution.token != contributionToken) {
      return 0;
    }

    if (globalMintAllowance == 0) {
      return 0;
    }

    if (token.totalOwnerBalance(account) >= userMintCap) {
      return 0;
    }

    tokenId = 0;
    uint256 tiersLength = tiers.length;
    for (uint256 i; i < tiersLength; i++) {
      if (
        tiers[i].contributionFloor <= contribution.value &&
        i == tiersLength - 1 &&
        tiers[i].remainingAllowance > 0
      ) {
        tokenId = tiers[i].idCeiling - tiers[i].remainingAllowance;
        unchecked {
          --tiers[i].remainingAllowance;
          --globalMintAllowance;
        }
        break;
      } else if (
        tiers[i].contributionFloor <= contribution.value &&
        tiers[i + 1].contributionFloor > contribution.value &&
        tiers[i].remainingAllowance > 0
      ) {
        tokenId = tiers[i].idCeiling - tiers[i].remainingAllowance;
        unchecked {
          --tiers[i].remainingAllowance;
          --globalMintAllowance;
        }
        break;
      }
    }
  }
}