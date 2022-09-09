// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "./IDropClaimCondition.sol";

/**
 *  Thirdweb's 'Drop' contracts are distribution mechanisms for tokens. The
 *  `DropERC721` contract is a distribution mechanism for ERC721 tokens.
 *
 *  A minter wallet (i.e. holder of `MINTER_ROLE`) can (lazy)mint 'n' tokens
 *  at once by providing a single base URI for all tokens being lazy minted.
 *  The URI for each of the 'n' tokens lazy minted is the provided base URI +
 *  `{tokenId}` of the respective token. (e.g. "ipsf://Qmece.../1").
 *
 *  A minter can choose to lazy mint 'delayed-reveal' tokens. More on 'delayed-reveal'
 *  tokens in [this article](https://blog.thirdweb.com/delayed-reveal-nfts).
 *
 *  A contract admin (i.e. holder of `DEFAULT_ADMIN_ROLE`) can create claim conditions
 *  with non-overlapping time windows, and accounts can claim the tokens according to
 *  restrictions defined in the claim condition that is active at the time of the transaction.
 */

interface ICedarSFTIssuanceV0 is IDropClaimConditionV0 {
    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        uint256 indexed tokenId,
        address indexed claimer,
        address receiver,
        uint256 quantityClaimed
    );

    /// @dev Emitted when tokens are issued.
    event TokensIssued(
        uint256 indexed tokenId,
        address indexed claimer,
        address receiver,
        uint256 quantityClaimed
    );

    /// @dev Emitted when new claim conditions are set for a token.
    event ClaimConditionsUpdated(uint256 indexed tokenId, ClaimCondition[] claimConditions);

    /**
     *  @notice Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
     *
     *  @param tokenId               The token ID for which to set mint conditions.
     *  @param phases                Claim conditions in ascending order by `startTimestamp`.
     *  @param resetClaimEligibility Whether to reset `limitLastClaimTimestamp` and
     *                               `limitMerkleProofClaim` values when setting new
     *                               claim conditions.
     */
    function setClaimConditions(
        uint256 tokenId,
        ClaimCondition[] calldata phases,
        bool resetClaimEligibility
    ) external;

    /**
     *  @notice Lets an account claim a given quantity of NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param tokenId                       The unique ID of the token to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     *  @param currency                       The currency in which to pay for the claim.
     *  @param pricePerToken                  The price per token to pay for the claim.
     *  @param proofs                         The proof of the claimer's inclusion in the merkle root allowlist
     *                                        of the claim conditions that apply.
     *  @param proofMaxQuantityPerTransaction (Optional) The maximum number of NFTs an address included in an
     *                                        allowlist can claim.
     */
    function claim(
        address receiver,
        uint256 tokenId,
        uint256 quantity,
        address currency,
        uint256 pricePerToken,
        bytes32[] calldata proofs,
        uint256 proofMaxQuantityPerTransaction
    ) external payable;

    /**
     *  @notice Lets an account with ISSUER_ROLE issue NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param tokenId                       The unique ID of the token to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     */
    function issue(
        address receiver,
        uint256 tokenId,
        uint256 quantity
    ) external;
}

interface ICedarSFTIssuanceV1 is ICedarSFTIssuanceV0 {
    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(uint256 _tokenId) external view returns (ClaimCondition memory condition, uint256 conditionId, uint256 walletMaxClaimCount, uint256 remainingSupply);

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer) external view returns (uint256 conditionId, uint256 walletClaimedCount, uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp);

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) external view;
}