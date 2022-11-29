// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../../api/issuance/IDropClaimCondition.sol";
import "../../api/royalties/IRoyalty.sol";

interface DropERC1155DataTypes {
    struct ClaimData {
        /// @dev The set of all claim conditions, at any given moment.
        mapping(uint256 => IDropClaimConditionV0.ClaimConditionList) claimCondition;
        /// @dev Mapping from token ID => claimer wallet address => total number of NFTs of the token ID a wallet has claimed.
        mapping(uint256 => mapping(address => uint256)) walletClaimCount;
        /// @dev The next token ID of the NFT to "lazy mint".
        uint256 nextTokenIdToMint;
        /// @dev Mapping from token ID => maximum possible total circulating supply of tokens with that ID.
        mapping(uint256 => uint256) maxTotalSupply;
        /// @dev Mapping from token ID => the max number of NFTs of the token ID a wallet can claim.
        mapping(uint256 => uint256) maxWalletClaimCount;
        /// @dev The address that receives all platform fees from all sales.
        address platformFeeRecipient;
        /// @dev The % of primary sales collected as platform fees.
        uint16 platformFeeBps;
        /// @dev Mapping from token ID => total circulating supply of tokens with that ID.
        mapping(uint256 => uint256) totalSupply;
        /// @dev Mapping from token ID => the address of the recipient of primary sales.
        mapping(uint256 => address) saleRecipient;
        /// @dev The recipient of who gets the royalty.
        address royaltyRecipient;
        /// @dev The (default) address that receives all royalty value.
        uint16 royaltyBps;
        /// @dev Mapping from token ID => royalty recipient and bps for tokens of the token ID.
        mapping(uint256 => IRoyaltyV0.RoyaltyInfo) royaltyInfoForToken;
    }
}