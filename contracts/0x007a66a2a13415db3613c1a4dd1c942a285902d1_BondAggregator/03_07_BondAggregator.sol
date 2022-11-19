// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {IBondAggregator} from "./interfaces/IBondAggregator.sol";
import {IBondTeller} from "./interfaces/IBondTeller.sol";
import {IBondAuctioneer} from "./interfaces/IBondAuctioneer.sol";

import {FullMath} from "./lib/FullMath.sol";

/// @title Bond Aggregator
/// @notice Bond Aggregator Contract
/// @dev Bond Protocol is a permissionless system to create Olympus-style bond markets
///      for any token pair. The markets do not require maintenance and will manage
///      bond prices based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev The Aggregator contract keeps a unique set of market IDs across multiple
///      Tellers and Auctioneers. Additionally, it aggregates market data from
///      multiple Auctioneers in convenient view functions for front-end interfaces.
///      The Aggregator contract should be deployed first since Tellers, Auctioneers, and
///      Callbacks all require it in their constructors.
///
/// @author Oighty, Zeus, Potted Meat, indigo
contract BondAggregator is IBondAggregator, Auth {
    using FullMath for uint256;

    /* ========== ERRORS ========== */
    error Aggregator_OnlyAuctioneer();
    error Aggregator_AlreadyRegistered(address auctioneer_);
    error Aggregator_InvalidParams();

    /* ========== STATE VARIABLES ========== */

    /// @notice Counter for bond markets on approved auctioneers
    uint256 public marketCounter;

    /// @notice Approved auctioneers
    IBondAuctioneer[] public auctioneers;
    mapping(address => bool) internal _whitelist;

    /// @notice Auctioneer for Market ID
    mapping(uint256 => IBondAuctioneer) public marketsToAuctioneers;

    /// @notice Market IDs for payout token
    mapping(address => uint256[]) public marketsForPayout;

    /// @notice Market IDs for quote token
    mapping(address => uint256[]) public marketsForQuote;

    // A 'vesting' param longer than 50 years is considered a timestamp for fixed expiry.
    uint48 private constant MAX_FIXED_TERM = 52 weeks * 50;

    constructor(address guardian_, Authority authority_) Auth(guardian_, authority_) {}

    /// @inheritdoc IBondAggregator
    function registerAuctioneer(IBondAuctioneer auctioneer_) external requiresAuth {
        // Restricted to authorized addresses

        // Check that the auctioneer is not already registered
        if (_whitelist[address(auctioneer_)])
            revert Aggregator_AlreadyRegistered(address(auctioneer_));

        // Add the auctioneer to the whitelist
        auctioneers.push(auctioneer_);
        _whitelist[address(auctioneer_)] = true;
    }

    /// @inheritdoc IBondAggregator
    function registerMarket(ERC20 payoutToken_, ERC20 quoteToken_)
        external
        override
        returns (uint256 marketId)
    {
        if (!_whitelist[msg.sender]) revert Aggregator_OnlyAuctioneer();
        if (address(payoutToken_) == address(0) || address(quoteToken_) == address(0))
            revert Aggregator_InvalidParams();
        marketId = marketCounter;
        marketsToAuctioneers[marketId] = IBondAuctioneer(msg.sender);
        marketsForPayout[address(payoutToken_)].push(marketId);
        marketsForQuote[address(quoteToken_)].push(marketId);
        ++marketCounter;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @inheritdoc IBondAggregator
    function getAuctioneer(uint256 id_) external view returns (IBondAuctioneer) {
        return marketsToAuctioneers[id_];
    }

    /// @inheritdoc IBondAggregator
    function marketPrice(uint256 id_) public view override returns (uint256) {
        IBondAuctioneer auctioneer = marketsToAuctioneers[id_];
        return auctioneer.marketPrice(id_);
    }

    /// @inheritdoc IBondAggregator
    function marketScale(uint256 id_) external view override returns (uint256) {
        IBondAuctioneer auctioneer = marketsToAuctioneers[id_];
        return auctioneer.marketScale(id_);
    }

    /// @inheritdoc IBondAggregator
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) public view override returns (uint256) {
        IBondAuctioneer auctioneer = marketsToAuctioneers[id_];
        return auctioneer.payoutFor(amount_, id_, referrer_);
    }

    /// @inheritdoc IBondAggregator
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256) {
        IBondAuctioneer auctioneer = marketsToAuctioneers[id_];
        return auctioneer.maxAmountAccepted(id_, referrer_);
    }

    /// @inheritdoc IBondAggregator
    function isInstantSwap(uint256 id_) external view returns (bool) {
        IBondAuctioneer auctioneer = marketsToAuctioneers[id_];
        return auctioneer.isInstantSwap(id_);
    }

    /// @inheritdoc IBondAggregator
    function isLive(uint256 id_) public view override returns (bool) {
        IBondAuctioneer auctioneer = marketsToAuctioneers[id_];
        return auctioneer.isLive(id_);
    }

    /// @inheritdoc IBondAggregator
    function liveMarketsBetween(uint256 firstIndex_, uint256 lastIndex_)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 count;
        for (uint256 i = firstIndex_; i < lastIndex_; ++i) {
            if (isLive(i)) ++count;
        }

        uint256[] memory ids = new uint256[](count);
        count = 0;
        for (uint256 i = firstIndex_; i < lastIndex_; ++i) {
            if (isLive(i)) {
                ids[count] = i;
                ++count;
            }
        }
        return ids;
    }

    /// @inheritdoc IBondAggregator
    function liveMarketsFor(address token_, bool isPayout_)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory mkts;

        mkts = isPayout_ ? marketsForPayout[token_] : marketsForQuote[token_];

        uint256 count;
        uint256 len = mkts.length;

        for (uint256 i; i < len; ++i) {
            if (isLive(mkts[i])) ++count;
        }

        uint256[] memory ids = new uint256[](count);
        count = 0;

        for (uint256 i; i < len; ++i) {
            if (isLive(mkts[i])) {
                ids[count] = mkts[i];
                ++count;
            }
        }

        return ids;
    }

    /// @inheritdoc IBondAggregator
    function marketsFor(address payout_, address quote_) public view returns (uint256[] memory) {
        uint256[] memory forPayout = liveMarketsFor(payout_, true);
        uint256 count;

        ERC20 quoteToken;
        IBondAuctioneer auctioneer;
        uint256 len = forPayout.length;
        for (uint256 i; i < len; ++i) {
            auctioneer = marketsToAuctioneers[forPayout[i]];
            (, , , quoteToken, , ) = auctioneer.getMarketInfoForPurchase(forPayout[i]);
            if (isLive(forPayout[i]) && address(quoteToken) == quote_) ++count;
        }

        uint256[] memory ids = new uint256[](count);
        count = 0;

        for (uint256 i; i < len; ++i) {
            auctioneer = marketsToAuctioneers[forPayout[i]];
            (, , , quoteToken, , ) = auctioneer.getMarketInfoForPurchase(forPayout[i]);
            if (isLive(forPayout[i]) && address(quoteToken) == quote_) {
                ids[count] = forPayout[i];
                ++count;
            }
        }

        return ids;
    }

    /// @inheritdoc IBondAggregator
    function findMarketFor(
        address payout_,
        address quote_,
        uint256 amountIn_,
        uint256 minAmountOut_,
        uint256 maxExpiry_
    ) external view returns (uint256) {
        uint256[] memory ids = marketsFor(payout_, quote_);
        uint256 len = ids.length;
        // uint256[] memory payouts = new uint256[](len);

        uint256 highestOut;
        uint256 id = type(uint256).max; // set to max so an empty set doesn't return 0, the first index
        uint48 vesting;
        uint256 maxPayout;
        IBondAuctioneer auctioneer;
        for (uint256 i; i < len; ++i) {
            auctioneer = marketsToAuctioneers[ids[i]];
            (, , , , vesting, maxPayout) = auctioneer.getMarketInfoForPurchase(ids[i]);

            uint256 expiry = (vesting <= MAX_FIXED_TERM) ? block.timestamp + vesting : vesting;

            if (expiry <= maxExpiry_) {
                if (minAmountOut_ <= maxPayout) {
                    try auctioneer.payoutFor(amountIn_, ids[i], address(0)) returns (
                        uint256 payout
                    ) {
                        if (payout > highestOut && payout >= minAmountOut_) {
                            highestOut = payout;
                            id = ids[i];
                        }
                    } catch {
                        // fail silently and try the next market
                    }
                }
            }
        }

        return id;
    }

    /// @inheritdoc IBondAggregator
    function liveMarketsBy(
        address owner_,
        uint256 firstIndex_,
        uint256 lastIndex_
    ) external view returns (uint256[] memory) {
        uint256 count;
        IBondAuctioneer auctioneer;
        for (uint256 i = firstIndex_; i < lastIndex_; ++i) {
            auctioneer = marketsToAuctioneers[i];
            if (auctioneer.isLive(i) && auctioneer.ownerOf(i) == owner_) {
                ++count;
            }
        }

        uint256[] memory ids = new uint256[](count);
        count = 0;
        for (uint256 j = firstIndex_; j < lastIndex_; ++j) {
            auctioneer = marketsToAuctioneers[j];
            if (auctioneer.isLive(j) && auctioneer.ownerOf(j) == owner_) {
                ids[count] = j;
                ++count;
            }
        }

        return ids;
    }

    /// @inheritdoc IBondAggregator
    function getTeller(uint256 id_) external view returns (IBondTeller) {
        IBondAuctioneer auctioneer = marketsToAuctioneers[id_];
        return auctioneer.getTeller();
    }

    /// @inheritdoc IBondAggregator
    function currentCapacity(uint256 id_) external view returns (uint256) {
        IBondAuctioneer auctioneer = marketsToAuctioneers[id_];
        return auctioneer.currentCapacity(id_);
    }
}