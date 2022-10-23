// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../../api/issuance/IDropClaimCondition.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

interface DropERC721DataTypes {
    struct SequencedURI {
        string uri;
        /// @dev The high-watermark sequence number a URI - used to tell if one URI is fresher than a another
        /// taken from the current value of uriSequenceCounter after it is incremented.
        uint256 sequenceNumber;
    }

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
        /// @dev Sequence number counter for the synchronisation of per-token URIs and baseURIs relative base on which
        /// was set most recently. Incremented on each URI-mutating action.
        CountersUpgradeable.Counter uriSequenceCounter;
        /// @dev One more than the Largest tokenId of each batch of tokens with the same baseURI
        uint256[] baseURIIndices;
        /// @dev Mapping from the 'base URI index' defined as the tokenId one more than the largest tokenId a batch of
        /// tokens which all same the same baseURI.
        /// Suppose we have two batches (and two baseURIs), with 3 and 4 tokens respectively, then in pictures we have:
        /// [baseURI1 | baseURI2]
        /// [ 0, 1, 2 | 3, 4, 5, 6]
        /// The baseURIIndices would be:
        /// [ 3, 7]
        mapping(uint256 => SequencedURI) baseURI;
        // Optional mapping for token URIs
        mapping(uint256 => SequencedURI) tokenURIs;
    }
}