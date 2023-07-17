// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {PoolVariant, PoolType, RoyaltyDue, NFTs} from "./CollectionStructsAndEnums.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {ITokenIDFilter} from "../filter/ITokenIDFilter.sol";
import {IExternalFilter} from "../filter/IExternalFilter.sol";

interface ICollectionPool is ITokenIDFilter {
    function bondingCurve() external view returns (ICurve);

    function curveParams() external view returns (ICurve.Params memory params);

    /**
     * @notice Only tracked IDs are returned
     */
    function getAllHeldIds() external view returns (uint256[] memory);

    function poolVariant() external view returns (PoolVariant);

    function fee() external view returns (uint24);

    function nft() external view returns (IERC721);

    function poolType() external view returns (PoolType);

    function royaltyNumerator() external view returns (uint24);

    function externalFilter() external view returns (IExternalFilter);

    /**
     * @notice The usable balance of the pool. This is the amount the pool needs to have to buy NFTs and pay out royalties.
     */
    function liquidity() external view returns (uint256);

    function balanceToFulfillSellNFT(uint256 numNFTs) external view returns (uint256 balance);

    /**
     * @notice Rescues a specified set of NFTs owned by the pool to the owner address. (onlyOwnable modifier is in the implemented function)
     * @dev If the NFT is the pool's collection, we also remove it from the id tracking
     * @param a The NFT to transfer
     * @param nftIds The list of IDs of the NFTs to send to the owner
     */
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;

    /**
     * @notice Rescues ERC20 tokens from the pool to the owner. Only callable by the owner (onlyOwnable modifier is in the implemented function).
     * @param a The token to transfer
     * @param amount The amount of tokens to send to the owner
     */
    function withdrawERC20(ERC20 a, uint256 amount) external;

    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external;

    function getSellNFTQuote(uint256 numNFTs)
        external
        view
        returns (ICurve.Params memory newParams, uint256 totalAmount, uint256 outputAmount, ICurve.Fees memory fees);

    /**
     * @dev Deposit NFTs into pool and emit event for indexing.
     */
    function depositNFTs(uint256[] calldata ids, bytes32[] calldata proof, bool[] calldata proofFlags) external;

    /**
     * @dev Used by factory to indicate deposited NFTs.
     * @dev Must only be called by factory. NFT IDs must have been validated against the filter.
     */
    function depositNFTsNotification(uint256[] calldata nftIds) external;

    /**
     * @notice Returns number of NFTs in pool that matches filter
     */
    function NFTsCount() external view returns (uint256);

    /**
     * @notice Sets NFT token ID filter to allow only some NFTs into this pool. Pool must be empty
     * to call this function. This filter is checked on deposits and swapping NFTs into the pool.
     * Selling into the pool may require an additional check (see `setExternalFilter`).
     * @param merkleRoot Merkle root representing all allowed IDs
     * @param encodedTokenIDs Opaque encoded list of token IDs
     */
    function setTokenIDFilter(bytes32 merkleRoot, bytes calldata encodedTokenIDs) external;

    /**
     * @notice Checks if list of NFTs are allowed in this pool using Merkle multiproof and flags
     * @param tokenIDs List of NFT IDs
     * @param proof Merkle multiproof
     * @param proofFlags Merkle multiproof flags
     */
    function acceptsTokenIDs(uint256[] calldata tokenIDs, bytes32[] calldata proof, bool[] calldata proofFlags)
        external
        view
        returns (bool);

    /**
     * @notice Sets an external contract that is consulted before any NFT is swapped into the pool.
     * Typically used to implement dynamic blocklists. Because it is dynamic, deposits are not
     * checked. See also `setTokenIDFilter`.
     */
    function setExternalFilter(address provider) external;

    /**
     * @notice Called during pool creation to set initial parameters
     * @dev Only called once by factory to initialize.
     * We verify this by making sure that the current owner is address(0).
     * The Ownable library we use disallows setting the owner to be address(0), so this condition
     * should only be valid before the first initialize call.
     * @param _assetRecipient The address that will receive the TOKEN or NFT sent to this pool during swaps.
     * NOTE: If set to address(0), they will go to the pool itself.
     * @param _delta The initial delta of the bonding curve
     * @param _fee The initial % fee taken, if this is a trade pool
     * @param _spotPrice The initial price to sell an asset into the pool
     * @param _royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e6
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient fallback is set.
     * @param _royaltyRecipientFallback An address to which all royalties will be paid to if not address(0).
     * This is a fallback to ERC2981 royalties set by the NFT creator, and allows sending royalties to
     * arbitrary addresses if a collection does not support ERC2981.
     */
    function initialize(
        address payable _assetRecipient,
        uint128 _delta,
        uint24 _fee,
        uint128 _spotPrice,
        bytes calldata _props,
        bytes calldata _state,
        uint24 _royaltyNumerator,
        address payable _royaltyRecipientFallback
    ) external payable;

    /**
     * @notice Sends token to the pool in exchange for any `numNFTs` NFTs
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
     * This swap function is meant for users who are ID agnostic
     * @dev The nonReentrant modifier is in swapTokenForSpecificNFTs
     * @param numNFTs The number of NFTs to purchase
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @param nftRecipient The recipient of the NFTs
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable returns (uint256 inputAmount);

    /**
     * @dev Used as read function to query the bonding curve for buy pricing info
     * @param numNFTs The number of NFTs to buy from the pool
     */
    function getBuyNFTQuote(uint256 numNFTs)
        external
        view
        returns (ICurve.Params memory newParams, uint256 totalAmount, uint256 inputAmount, ICurve.Fees memory fees);

    /**
     * @notice Updates the fee taken by the LP. Only callable by the owner.
     * Only callable if the pool is a Trade pool. Reverts if the fee is >=
     * MAX_FEE.
     * @param newFee The new LP fee percentage, 18 decimals
     */
    function changeFee(uint24 newFee) external;

    /**
     * @notice Sends a set of NFTs to the pool in exchange for token. Token must be allowed by
     * filters, see `setTokenIDFilter` and `setExternalFilter`.
     * @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
     * @param nfts The list of IDs of the NFTs to sell to the pool along with its Merkle multiproof.
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param tokenRecipient The recipient of the token output
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return outputAmount The amount of token received
     */
    function swapNFTsForToken(
        NFTs calldata nfts,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller,
        bytes calldata externalFilterContext
    ) external returns (uint256 outputAmount);
}

interface ICollectionPoolETH is ICollectionPool {
    function withdrawAllETH() external;
}