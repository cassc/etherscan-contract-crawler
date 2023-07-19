// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {IExternalFilter} from "../filter/IExternalFilter.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";

enum PoolVariant {
    ENUMERABLE_ETH,
    MISSING_ENUMERABLE_ETH,
    ENUMERABLE_ERC20,
    MISSING_ENUMERABLE_ERC20
}

enum PoolType {
    TOKEN,
    NFT,
    TRADE
}

enum EventType {
    BOUGHT_NFT_FROM_POOL,
    SOLD_NFT_TO_POOL,
    DEPOSIT_TOKEN,
    DEPOSIT_NFT
}

/**
 * @dev The RoyaltyDue struct is used to track information about royalty payments that are due on NFT swaps.
 * It contains two fields:
 * @dev amount: The amount of the royalty payment, in the token's base units.
 * This value is calculated based on the price of the NFT being swapped, and the royaltyNumerator value set in the AMM pool contract.
 * @dev recipient: The address to which the royalty payment should be sent.
 * This value is determined by the NFT being swapped, and it is specified in the ERC2981 metadata for the NFT.
 * @dev When a user swaps an NFT for tokens using the AMM pool contract, a RoyaltyDue struct is created to track the amount
 * and recipient of the royalty payment that is due on the NFT swap. This struct is then used to facilitate the payment of
 * the royalty to the appropriate recipient.
 */

struct RoyaltyDue {
    uint256 amount;
    address recipient;
}

/**
 * @param ids The list of IDs of the NFTs to sell to the pool
 * @param proof Merkle multiproof proving list is allowed by pool
 * @param proofFlags Merkle multiproof flags for proof
 */
struct NFTs {
    uint256[] ids;
    bytes32[] proof;
    bool[] proofFlags;
}

struct RouterStatus {
    bool allowed;
    bool wasEverAllowed;
}

struct LPTokenParams721 {
    address nftAddress;
    address bondingCurveAddress;
    address tokenAddress;
    address payable poolAddress;
    uint24 fee;
    uint128 delta;
    uint24 royaltyNumerator;
}

/**
 * @param merkleRoot Merkle root for NFT ID filter
 * @param encodedTokenIDs Encoded list of acceptable NFT IDs
 * @param initialProof Merkle multiproof for initial NFT IDs
 * @param initialProofFlags Merkle multiproof flags for initial NFT IDs
 * @param externalFilter Address implementing IExternalFilter for external filtering
 */
struct NFTFilterParams {
    bytes32 merkleRoot;
    bytes encodedTokenIDs;
    bytes32[] initialProof;
    bool[] initialProofFlags;
    IExternalFilter externalFilter;
}

/**
 * @notice Creates a pool contract using EIP-1167.
 * @param nft The NFT contract of the collection the pool trades
 * @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
 * @param assetRecipient The address that will receive the assets traders give during trades.
 * If set to address(0), assets will be sent to the pool address. Not available to TRADE pools.
 * @param receiver Receiver of the LP token generated to represent ownership of the pool
 * @param poolType TOKEN, NFT, or TRADE
 * @param delta The delta value used by the bonding curve. The meaning of delta depends
 * on the specific curve.
 * @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
 * @param spotPrice The initial selling spot price
 * @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e6
 * being sent to the account to which the traded NFT's royalties are awardable.
 * Must be 0 if `_nft` is not IERC2981 and no recipient fallback is set.
 * @param royaltyRecipientFallback An address to which all royalties will
 * be paid to if not address(0) and ERC2981 is not supported or ERC2981 recipient is not set.
 * @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
 * @return pool The new pool
 */
struct CreateETHPoolParams {
    IERC721 nft;
    ICurve bondingCurve;
    address payable assetRecipient;
    address receiver;
    PoolType poolType;
    uint128 delta;
    uint24 fee;
    uint128 spotPrice;
    bytes props;
    bytes state;
    uint24 royaltyNumerator;
    address payable royaltyRecipientFallback;
    uint256[] initialNFTIDs;
}

/**
 * @notice Creates a pool contract using EIP-1167.
 * @param token The ERC20 token used for pool swaps
 * @param nft The NFT contract of the collection the pool trades
 * @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
 * @param assetRecipient The address that will receive the assets traders give during trades.
 * If set to address(0), assets will be sent to the pool address. Not available to TRADE pools.
 * @param receiver Receiver of the LP token generated to represent ownership of the pool
 * @param poolType TOKEN, NFT, or TRADE
 * @param delta The delta value used by the bonding curve. The meaning of delta depends on the
 * specific curve.
 * @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
 * @param spotPrice The initial selling spot price, in ETH
 * @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e6
 * being sent to the account to which the traded NFT's royalties are awardable.
 * Must be 0 if `_nft` is not IERC2981 and no recipient fallback is set.
 * @param royaltyRecipientFallback An address to which all royalties will
 * be paid to if not address(0) and ERC2981 is not supported or ERC2981 recipient is not set.
 * @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
 * @param initialTokenBalance The initial token balance sent from the sender to the new pool
 * @return pool The new pool
 */
struct CreateERC20PoolParams {
    ERC20 token;
    IERC721 nft;
    ICurve bondingCurve;
    address payable assetRecipient;
    address receiver;
    PoolType poolType;
    uint128 delta;
    uint24 fee;
    uint128 spotPrice;
    bytes props;
    bytes state;
    uint24 royaltyNumerator;
    address payable royaltyRecipientFallback;
    uint256[] initialNFTIDs;
    uint256 initialTokenBalance;
}