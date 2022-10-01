// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {ERC1155SupplyUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";
import {IDualAuction} from "./interfaces/IDualAuction.sol";
import {AuctionImmutableArgs} from "./utils/AuctionImmutableArgs.sol";
import {AuctionConversions} from "./utils/AuctionConversions.sol";

/**
 * @notice DualAuction contract
 */
contract DualAuction is
    ERC1155SupplyUpgradeable,
    Clone,
    ReentrancyGuardUpgradeable,
    AuctionImmutableArgs,
    AuctionConversions,
    IDualAuction
{
    /// @notice the maximum allowed price is 2^255 because we save the top bit for
    /// differentiating between bids and asks in the token id
    uint256 internal constant MAXIMUM_ALLOWED_PRICE = 2**255 - 1;

    /// @notice The number of ticks allowed between the minimum and maximum price (inclusive)
    uint256 internal constant NUM_TICKS = 100;

    /// @notice The highest bid received so far
    uint256 public maxBid;

    /// @notice The lowest ask received so far
    uint256 public minAsk;

    /// @notice The clearing bid price of the auction, set after settlement
    uint256 public clearingBidPrice;

    /// @notice The clearing ask price of the auction, set after settlement
    uint256 public clearingAskPrice;

    /// @notice The number of bid tokens cleared at the tick closest to clearing price
    uint256 public bidTokensClearedAtClearing;

    /// @notice The number of ask tokens cleared at the tick closest to clearing price
    uint256 public askTokensClearedAtClearing;

    /// @notice True if the auction has been settled, else false
    bool public settled;

    /**
     * @notice Ensures that the given price is valid
     * validity is defined as in range (minPrice, maxPrice) and
     * on a valid tick
     */
    modifier onlyValidPrice(uint256 price) {
        if (price < minPrice() || price > maxPrice()) revert InvalidPrice();
        if ((price - minPrice()) % tickWidth() != 0) revert InvalidPrice();
        _;
    }

    /**
     * @notice Ensures that the auction is active
     */
    modifier onlyAuctionActive() {
        if (block.timestamp >= endDate()) revert AuctionHasEnded();
        _;
    }

    /**
     * @notice Ensures that the auction is finalized
     */
    modifier onlyAuctionEnded() {
        if (block.timestamp < endDate()) revert AuctionIsActive();
        _;
    }

    /**
     * @notice Ensures that the auction has been settled
     */
    modifier onlyAuctionSettled() {
        if (!settled) revert AuctionHasNotSettled();
        _;
    }

    /**
     * @notice Initializes the auction, should be called by DualAuctionFactory
     */
    function initialize() external initializer {
        __ERC1155_init("");
        __ERC1155Supply_init();
        __ReentrancyGuard_init();
        if (bidAsset() == askAsset()) revert MatchingAssets();
        if (
            address(bidAsset()) == address(0) ||
            address(askAsset()) == address(0)
        ) revert ZeroAddressAsset();
        if (minPrice() == 0) revert InvalidPrice();
        if (minPrice() >= maxPrice()) revert InvalidPrice();
        if (maxPrice() > MAXIMUM_ALLOWED_PRICE) revert InvalidPrice();
        if ((maxPrice() - minPrice()) != (NUM_TICKS - 1) * tickWidth()) revert InvalidPrice();
        if (priceDenominator() == 0) revert InvalidPrice();
        if (endDate() <= block.timestamp) revert AuctionHasEnded();
        minAsk = type(uint256).max;
    }

    /**
     * @inheritdoc IDualAuction
     */
    function bid(uint256 amountIn, uint256 price)
        external
        onlyValidPrice(price)
        onlyAuctionActive
        nonReentrant
        returns (uint256)
    {
        if (amountIn == 0) revert ZeroAmount();
        if (price > maxBid) maxBid = price;
        uint256 preTransferBalance = bidAsset().balanceOf(address(this));
        SafeTransferLib.safeTransferFrom(
            bidAsset(),
            msg.sender,
            address(this),
            amountIn
        );
        uint256 postTransferBalance = bidAsset().balanceOf(address(this));
        uint256 bidAmount = postTransferBalance - preTransferBalance;
        _mint(msg.sender, toBidTokenId(price), bidAmount, "");
        emit Bid(msg.sender, amountIn, bidAmount, price);
        return bidAmount;
    }

    /**
     * @inheritdoc IDualAuction
     */
    function ask(uint256 amountIn, uint256 price)
        external
        onlyValidPrice(price)
        onlyAuctionActive
        nonReentrant
        returns (uint256)
    {
        if (amountIn == 0) revert ZeroAmount();
        if (minAsk == 0 || price < minAsk) minAsk = price;
        uint256 preTransferBalance = askAsset().balanceOf(address(this));
        SafeTransferLib.safeTransferFrom(
            askAsset(),
            msg.sender,
            address(this),
            amountIn
        );
        uint256 postTransferBalance = askAsset().balanceOf(address(this));
        uint256 askAmount = postTransferBalance - preTransferBalance;
        _mint(msg.sender, toAskTokenId(price), askAmount, "");
        emit Ask(msg.sender, amountIn, askAmount, price);
        return askAmount;
    }

    /**
     * @inheritdoc IDualAuction
     */
    function settle() external onlyAuctionEnded returns (uint256) {
        if (settled) revert AuctionHasSettled();
        settled = true;

        uint256 currentBid = maxBid;
        uint256 currentAsk = minAsk;
        uint256 _tickWidth = tickWidth();

        // no overlap, nothing will be cleared
        if (currentBid < currentAsk) {
            emit Settle(msg.sender, 0);
            return 0;
        }

        uint256 lowBid = currentBid;
        uint256 highAsk = currentAsk;
        uint256 currentAskTokens;
        uint256 currentDesiredAskTokens;
        uint256 lastBidClear;
        uint256 lastAskClear;

        while (
            currentBid >= currentAsk &&
            currentBid >= minPrice() &&
            currentAsk <= maxPrice()
        ) {
            if (currentAskTokens == 0) {
                currentAskTokens = totalSupply(toAskTokenId(currentAsk));
                if (currentAskTokens > 0) lastBidClear = 0;
            }

            if (currentDesiredAskTokens == 0) {
                currentDesiredAskTokens = bidToAsk(
                    totalSupply(toBidTokenId(currentBid)),
                    currentBid
                );

                if (currentDesiredAskTokens > 0) lastAskClear = 0;
            }

            uint256 cleared = min(currentAskTokens, currentDesiredAskTokens);

            if (cleared > 0) {
                currentAskTokens -= cleared;
                currentDesiredAskTokens -= cleared;
                lastBidClear += cleared;
                lastAskClear += cleared;
                highAsk = currentAsk;
                lowBid = currentBid;
            }

            if (currentAskTokens == 0) currentAsk += _tickWidth;
            if (currentDesiredAskTokens == 0) currentBid -= _tickWidth;
        }

        clearingBidPrice = lowBid;
        clearingAskPrice = highAsk;
        uint256 _clearingPrice = clearingPrice();
        askTokensClearedAtClearing = lastAskClear;
        bidTokensClearedAtClearing = askToBid(lastBidClear, _clearingPrice);

        emit Settle(msg.sender, _clearingPrice);
        return _clearingPrice;
    }

    /**
     * @inheritdoc IDualAuction
     */
    function redeem(uint256 tokenId, uint256 amount)
        external
        onlyAuctionSettled
        nonReentrant
        returns (uint256 bidTokens, uint256 askTokens)
    {
        if (amount == 0) revert ZeroAmount();
        (bidTokens, askTokens) = shareValue(amount, tokenId);
        bool isBid = isBidTokenId(tokenId);

        _burn(msg.sender, tokenId, amount);

        if (bidTokens > 0) {
            if (!isBid && toPrice(tokenId) == clearingAskPrice)
                bidTokensClearedAtClearing -= bidTokens;
            bidTokens = min(bidTokens, bidAsset().balanceOf(address(this)));
            SafeTransferLib.safeTransfer(bidAsset(), msg.sender, bidTokens);
        }

        if (askTokens > 0) {
            if (isBid && toPrice(tokenId) == clearingBidPrice)
                askTokensClearedAtClearing -= askTokens;
            askTokens = min(askTokens, askAsset().balanceOf(address(this)));
            SafeTransferLib.safeTransfer(askAsset(), msg.sender, askTokens);
        }

        emit Redeem(msg.sender, tokenId, amount, bidTokens, askTokens);
    }

    /**
     * @inheritdoc IDualAuction
     */
    function clearingPrice() public view override returns (uint256) {
        return (clearingBidPrice + clearingAskPrice) / 2;
    }

    /**
     * @dev returns the value of the shares after settlement
     * @param shareAmount The number of bid/ask slips to check
     * @param tokenId The token id of the share
     * @return bidTokens The number of bid tokens the share tokens are worth
     * @return askTokens The number of ask tokens the share tokens are worth
     */
    function shareValue(uint256 shareAmount, uint256 tokenId)
        internal
        view
        returns (uint256 bidTokens, uint256 askTokens)
    {
        uint256 price = toPrice(tokenId);
        uint256 _clearingPrice = clearingPrice();

        if (isBidTokenId(tokenId)) {
            uint256 _clearingBid = clearingBidPrice;
            if (_clearingPrice == 0 || price < _clearingBid) {
                // not cleared at all
                return (shareAmount, 0);
            } else if (price > _clearingBid) {
                // fully cleared
                uint256 cleared = bidToAsk(shareAmount, price);
                return (
                    shareAmount - askToBid(cleared, _clearingPrice),
                    cleared
                );
            } else {
                // partially cleared
                uint256 cleared = FixedPointMathLib.mulDivDown(
                    shareAmount,
                    askTokensClearedAtClearing,
                    totalSupply(tokenId)
                );

                return (
                    shareAmount - askToBid(cleared, _clearingPrice),
                    cleared
                );
            }
        } else {
            uint256 _clearingAsk = clearingAskPrice;
            if (_clearingPrice == 0 || price > _clearingAsk) {
                // not cleared at all
                return (0, shareAmount);
            } else if (price < _clearingAsk) {
                // fully cleared, all ask tokens match at clearing price
                return (askToBid(shareAmount, _clearingPrice), 0);
            } else {
                // partially cleared
                uint256 cleared = FixedPointMathLib.mulDivDown(
                    shareAmount,
                    bidTokensClearedAtClearing,
                    totalSupply(tokenId)
                );
                uint256 askValue = askToBid(shareAmount, _clearingPrice);
                // sometimes due to floor rounding ask value is slightly too high
                uint256 notCleared = askValue <= cleared
                    ? 0
                    : bidToAsk(askValue - cleared, _clearingPrice);
                return (cleared, notCleared);
            }
        }
    }
}