// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./IDropClaimCondition.sol";

/**
 *  'Drop' contracts are distribution mechanisms for tokens. The
 *  `DropERC721` contract is a distribution mechanism for ERC721 tokens.
 *
 *  A minter wallet (i.e. holder of `MINTER_ROLE`) can (lazy)mint 'n' tokens
 *  at once by providing a single base URI for all tokens being lazy minted.
 *  The URI for each of the 'n' tokens lazy minted is the provided base URI +
 *  `{tokenId}` of the respective token. (e.g. "ipsf://Qmece.../1").
 *
 *  A minter can choose to lazy mint 'delayed-reveal' tokens. More on 'delayed-reveal'
 *  tokens.
 *
 *  A contract admin (i.e. holder of `DEFAULT_ADMIN_ROLE`) can create claim conditions
 *  with non-overlapping time windows, and accounts can claim the tokens according to
 *  restrictions defined in the claim condition that is active at the time of the transaction.
 */

interface IMSDropERC721 is IERC721Upgradeable, IDropClaimCondition {
    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        address indexed claimer,
        address indexed receiver,
        uint256 tokenIdClaimed,
        uint256 quantityClaimed
    );

    /// @dev Emitted when admin claim tokens.
    event TokensAdminClaimed(
        address indexed claimer,
        address receiver,
        uint256 lastTokenIdClaimed,
        uint256 quantityClaimed
    );

    struct Edition {
        bool isAuction;
        Auction auction;
        bool isPhysic;
        ClaimConditionList claimCondition;
    }
  
    struct Bid {
        uint256 price;
        address owner;
        uint256 time;
    }

    event ClaimBidEvent(Bid bid, address claimer, uint256 tokenId);

    event BidToken(address sender, uint256 tokenId, uint256 amount, Auction auction);

    /// @dev Emitted when tokens are lazy minted.
    event TokensLazyMinted(uint256 startTokenId, uint256 endTokenId, string baseURI, address indexed artist);

    /// @dev Emitted when the URI for a batch of 'delayed-reveal' NFTs is revealed.
    event NFTRevealed(uint256 endTokenId, string revealedURI);

    /// @dev Emitted when new claim conditions are set.
    event ClaimConditionsUpdated(ClaimCondition[] claimConditions, uint256 startTokenId, uint256 endTokenId);
    
    /// @dev Emitted when new claim conditions are set.
    event AuctionsConditionsUpdated(ClaimCondition[] claimConditions, Auction auction, uint256 startTokenId, uint256 endTokenId);

    /// @dev Emitted when the global max supply of tokens is updated.
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);

    /// @dev Emitted when the wallet claim count for an address is updated.
    event WalletClaimCountUpdated(address indexed wallet, uint256 count);

    /// @dev Emitted when the global max wallet claim count is updated.
    event MaxWalletClaimCountUpdated(uint256 count);

    struct ClaimTokenInfos{
        uint256 tokenId;
        uint256 quantity;
        uint256 pricePerToken;
    }
    struct Auction {
        uint256 duration;
        uint256 reservePrice;
        uint256 addedTime;
    }

    /**
     *  @notice Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *          The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     *
     *  @param amount           The amount of NFTs to lazy mint.
     *  @param baseURIForTokens The URI for the NFTs to lazy mint. If lazy minting
     *                           'delayed-reveal' NFTs, the is a URI for NFTs in the
     *                           un-revealed state.
     */
    function lazyMint(
        uint256 amount,
        string calldata baseURIForTokens,
        bool _isAuction,
        Auction calldata _auction,
        bool _isPhysic,ClaimCondition[] calldata phases, bool resetClaimEligibility, bool
    ) external;

    function claim(
        address receiver,
        ClaimTokenInfos memory claimTokenInfos,
        address currency,
        bytes32[] calldata proofs,
        uint256 proofMaxQuantityPerTransaction
    ) external payable;

    /**
     *  @notice Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
     *
     *  @param phases                Claim conditions in ascending order by `startTimestamp`.
     *  @param resetClaimEligibility Whether to reset `limitLastClaimTimestamp` and
     *                               `limitMerkleProofClaim` values when setting new
     *                               claim conditions.
     */
    //function setClaimConditions(uint256 index,ClaimCondition[] calldata phases, bool resetClaimEligibility) internal;
}