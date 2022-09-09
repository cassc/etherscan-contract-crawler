// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.7;

import "../../api/issuance/IDropClaimCondition.sol";

interface DataTypes {
  struct ClaimData {
    /// @dev The set of all claim conditions, at any given moment.
    IDropClaimConditionV0.ClaimConditionList claimCondition;

    /// @dev The next token ID of the NFT that can be claimed.
    uint256 nextTokenIdToClaim;

    /// @dev Mapping from address => total number of NFTs a wallet has claimed.
    mapping(address => uint256) walletClaimCount;

    /// @dev The next token ID of the NFT to "lazy mint".
    uint256 nextTokenIdToMint;

    /// @dev Global max total supply of NFTs.
    uint256 maxTotalSupply;

    /// @dev The max number of NFTs a wallet can claim.
    uint256 maxWalletClaimCount;

     /// @dev The address that receives all primary sales value.
    address primarySaleRecipient;

    /// @dev The address that receives all platform fees from all sales.
    address platformFeeRecipient;

    /// @dev The % of primary sales collected as platform fees.
    uint16 platformFeeBps;
  }
}