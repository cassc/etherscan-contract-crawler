// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

/**
 * @title BosonTypes
 *
 * @notice Enums and structs used by the Boson Protocol contract ecosystem.
 */

contract BosonTypes {
    enum PausableRegion {
        Offers,
        Twins,
        Bundles,
        Groups,
        Sellers,
        Buyers,
        DisputeResolvers,
        Agents,
        Exchanges,
        Disputes,
        Funds,
        Orchestration,
        MetaTransaction
    }

    enum EvaluationMethod {
        None, // None should always be at index 0. Never change this value.
        Threshold,
        SpecificToken
    }

    enum GatingType {
        PerAddress,
        PerTokenId
    }

    enum ExchangeState {
        Committed,
        Revoked,
        Canceled,
        Redeemed,
        Completed,
        Disputed
    }

    enum DisputeState {
        Resolving,
        Retracted,
        Resolved,
        Escalated,
        Decided,
        Refused
    }

    enum TokenType {
        FungibleToken,
        NonFungibleToken,
        MultiToken
    } // ERC20, ERC721, ERC1155

    enum MetaTxInputType {
        Generic,
        CommitToOffer,
        Exchange,
        Funds,
        CommitToConditionalOffer,
        ResolveDispute
    }

    enum AuthTokenType {
        None,
        Custom, // For future use
        Lens,
        ENS
    }

    enum SellerUpdateFields {
        Admin,
        Assistant,
        Clerk, // Deprecated.
        AuthToken
    }

    enum DisputeResolverUpdateFields {
        Admin,
        Assistant,
        Clerk // Deprecated.
    }

    struct AuthToken {
        uint256 tokenId;
        AuthTokenType tokenType;
    }

    struct Seller {
        uint256 id;
        address assistant;
        address admin;
        address clerk; // Deprecated. Kept for backwards compatibility.
        address payable treasury;
        bool active;
        string metadataUri;
    }

    struct Buyer {
        uint256 id;
        address payable wallet;
        bool active;
    }

    struct DisputeResolver {
        uint256 id;
        uint256 escalationResponsePeriod;
        address assistant;
        address admin;
        address clerk; // Deprecated. Kept for backwards compatibility.
        address payable treasury;
        string metadataUri;
        bool active;
    }

    struct DisputeResolverFee {
        address tokenAddress;
        string tokenName;
        uint256 feeAmount;
    }

    struct Agent {
        uint256 id;
        uint256 feePercentage;
        address payable wallet;
        bool active;
    }

    struct DisputeResolutionTerms {
        uint256 disputeResolverId;
        uint256 escalationResponsePeriod;
        uint256 feeAmount;
        uint256 buyerEscalationDeposit;
    }

    struct Offer {
        uint256 id;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 buyerCancelPenalty;
        uint256 quantityAvailable;
        address exchangeToken;
        string metadataUri;
        string metadataHash;
        bool voided;
        uint256 collectionIndex;
    }

    struct OfferDates {
        uint256 validFrom;
        uint256 validUntil;
        uint256 voucherRedeemableFrom;
        uint256 voucherRedeemableUntil;
    }

    struct OfferDurations {
        uint256 disputePeriod;
        uint256 voucherValid;
        uint256 resolutionPeriod;
    }

    struct Group {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
    }

    struct Condition {
        EvaluationMethod method;
        TokenType tokenType;
        address tokenAddress;
        GatingType gating; // added in v2.3.0. All conditions created before that have a default value of "PerAddress"
        uint256 minTokenId;
        uint256 threshold;
        uint256 maxCommits;
        uint256 maxTokenId;
    }

    struct Exchange {
        uint256 id;
        uint256 offerId;
        uint256 buyerId;
        uint256 finalizedDate;
        ExchangeState state;
    }

    struct Voucher {
        uint256 committedDate;
        uint256 validUntilDate;
        uint256 redeemedDate;
        bool expired;
    }

    struct Dispute {
        uint256 exchangeId;
        uint256 buyerPercent;
        DisputeState state;
    }

    struct DisputeDates {
        uint256 disputed;
        uint256 escalated;
        uint256 finalized;
        uint256 timeout;
    }

    struct Receipt {
        uint256 exchangeId;
        uint256 offerId;
        uint256 buyerId;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 buyerCancelPenalty;
        OfferFees offerFees;
        uint256 agentId;
        address exchangeToken;
        uint256 finalizedDate;
        Condition condition;
        uint256 committedDate;
        uint256 redeemedDate;
        bool voucherExpired;
        uint256 disputeResolverId;
        uint256 disputedDate;
        uint256 escalatedDate;
        DisputeState disputeState;
        TwinReceipt[] twinReceipts;
    }

    struct TokenRange {
        uint256 start;
        uint256 end;
        uint256 twinId;
    }

    struct Twin {
        uint256 id;
        uint256 sellerId;
        uint256 amount; // ERC1155 / ERC20 (amount to be transferred to each buyer on redemption)
        uint256 supplyAvailable; // all
        uint256 tokenId; // ERC1155 / ERC721 (must be initialized with the initial pointer position of the ERC721 ids available range)
        address tokenAddress; // all
        TokenType tokenType;
    }

    struct TwinReceipt {
        uint256 twinId;
        uint256 tokenId; // only for ERC721 and ERC1155
        uint256 amount; // only for ERC1155 and ERC20
        address tokenAddress;
        TokenType tokenType;
    }

    struct Bundle {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        uint256[] twinIds;
    }

    struct Funds {
        address tokenAddress;
        string tokenName;
        uint256 availableAmount;
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        bytes functionSignature;
    }

    struct HashInfo {
        bytes32 typeHash;
        function(bytes memory) internal pure returns (bytes32) hashFunction;
    }

    struct OfferFees {
        uint256 protocolFee;
        uint256 agentFee;
    }

    struct VoucherInitValues {
        string contractURI;
        uint256 royaltyPercentage;
        bytes32 collectionSalt;
    }

    struct Collection {
        address collectionAddress;
        string externalId;
    }
}