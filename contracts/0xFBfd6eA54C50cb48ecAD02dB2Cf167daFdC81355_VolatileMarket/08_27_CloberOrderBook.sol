// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./CloberOrderKey.sol";

interface CloberOrderBook {
    /**
     * @notice Emitted when an order is created.
     * @param sender The address who sent the tokens to make the order.
     * @param user The address with the rights to claim the proceeds of the order.
     * @param rawAmount The ordered raw amount.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param options LSB: 0 - Ask, 1 - Bid.
     */
    event MakeOrder(
        address indexed sender,
        address indexed user,
        uint64 rawAmount,
        uint32 claimBounty,
        uint256 orderIndex,
        uint16 priceIndex,
        uint8 options
    );

    /**
     * @notice Emitted when an order takes from the order book.
     * @param sender The address who sent the tokens to take the order.
     * @param user The recipient address of the traded token.
     * @param priceIndex The price book index.
     * @param rawAmount The ordered raw amount.
     * @param options MSB: 0 - Limit, 1 - Market / LSB: 0 - Ask, 1 - Bid.
     */
    event TakeOrder(address indexed sender, address indexed user, uint16 priceIndex, uint64 rawAmount, uint8 options);

    /**
     * @notice Emitted when an order is canceled.
     * @param user The owner of the order.
     * @param rawAmount The raw amount remaining that was canceled.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param isBid The flag indicating whether it's a bid order or an ask order.
     */
    event CancelOrder(address indexed user, uint64 rawAmount, uint256 orderIndex, uint16 priceIndex, bool isBid);

    /**
     * @notice Emitted when the proceeds of an order is claimed.
     * @param claimer The address that initiated the claim.
     * @param user The owner of the order.
     * @param rawAmount The ordered raw amount.
     * @param bountyAmount The size of the claim bounty.
     * @param orderIndex The order index.
     * @param priceIndex The price book index.
     * @param isBase The flag indicating whether the user receives the base token or the quote token.
     */
    event ClaimOrder(
        address indexed claimer,
        address indexed user,
        uint64 rawAmount,
        uint256 bountyAmount,
        uint256 orderIndex,
        uint16 priceIndex,
        bool isBase
    );

    /**
     * @notice Emitted when a flash-loan is taken.
     * @param caller The caller address of the flash-loan.
     * @param borrower The address of the flash loan token receiver.
     * @param quoteAmount The amount of quote tokens the user has borrowed.
     * @param baseAmount The amount of base tokens the user has borrowed.
     * @param earnedQuote The amount of quote tokens the protocol earned in quote tokens.
     * @param earnedBase The amount of base tokens the protocol earned in base tokens.
     */
    event Flash(
        address indexed caller,
        address indexed borrower,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 earnedQuote,
        uint256 earnedBase
    );

    /**
     * @notice A struct that represents an order.
     * @param amount The raw amount not filled yet. In case of a stale order, the amount not claimed yet.
     * @param claimBounty The bounty amount in gwei that can be collected by the party that fully claims the order.
     * @param owner The address of the order owner.
     */
    struct Order {
        uint64 amount;
        uint32 claimBounty;
        address owner;
    }

    /**
     * @notice Take orders better or equal to the given priceIndex and make an order with the remaining tokens.
     * @dev `msg.value` will be used as the claimBounty.
     * @param user The taker/maker address.
     * @param priceIndex The price book index.
     * @param rawAmount The raw quote amount to trade, utilized by bids.
     * @param baseAmount The base token amount to trade, utilized by asks.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - Post only.
     * @param data Custom callback data
     * @return The order index. If an order is not made `type(uint256).max` is returned instead.
     */
    function limitOrder(
        address user,
        uint16 priceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Returns the expected input amount and output amount.
     * @param limitPriceIndex The price index to take until.
     * @param rawAmount The raw amount to trade.
     * Bid & expendInput => Used as input amount.
     * Bid & !expendInput => Not used.
     * Ask & expendInput => Not used.
     * Ask & !expendInput => Used as output amount.
     * @param baseAmount The base token amount to trade.
     * Bid & expendInput => Not used.
     * Bid & !expendInput => Used as output amount.
     * Ask & expendInput => Used as input amount.
     * Ask & !expendInput => Not used.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - expend input.
     */
    function getExpectedAmount(
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options
    ) external view returns (uint256, uint256);

    /**
     * @notice Take opens orders until certain conditions are met.
     * @param user The taker address.
     * @param limitPriceIndex The price index to take until.
     * @param rawAmount The raw amount to trade.
     * This value is used as the maximum input amount by bids and minimum output amount by asks.
     * @param baseAmount The base token amount to trade.
     * This value is used as the maximum input amount by asks and minimum output amount by bids.
     * @param options LSB: 0 - Ask, 1 - Bid. Second bit: 1 - expend input.
     * @param data Custom callback data.
     */
    function marketOrder(
        address user,
        uint16 limitPriceIndex,
        uint64 rawAmount,
        uint256 baseAmount,
        uint8 options,
        bytes calldata data
    ) external;

    /**
     * @notice Cancel orders.
     * @dev The length of orderKeys must be controlled by the caller to avoid block gas limit exceeds.
     * @param receiver The address to receive canceled tokens.
     * @param orderKeys The order keys of the orders to cancel.
     */
    function cancel(address receiver, OrderKey[] calldata orderKeys) external;

    /**
     * @notice Claim the proceeds of orders.
     * @dev The length of orderKeys must be controlled by the caller to avoid block gas limit exceeds.
     * @param claimer The address to receive the claim bounties.
     * @param orderKeys The order keys of the orders to claim.
     */
    function claim(address claimer, OrderKey[] calldata orderKeys) external;

    /**
     * @notice Flash loan the tokens in the OrderBook.
     * @param borrower The address to receive the loan.
     * @param quoteAmount The quote token amount to borrow.
     * @param baseAmount The base token amount to borrow.
     * @param data The user's custom callback data.
     */
    function flash(
        address borrower,
        uint256 quoteAmount,
        uint256 baseAmount,
        bytes calldata data
    ) external;

    /**
     * @notice Returns the quote unit amount.
     * @return The amount that one raw amount represent in quote tokens.
     */
    function quoteUnit() external view returns (uint256);

    /**
     * @notice Returns the maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @return The maker fee. 100 = 1bp.
     */
    function makerFee() external view returns (int24);

    /**
     * @notice Returns the take fee
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @return The taker fee. 100 = 1bps.
     */
    function takerFee() external view returns (uint24);

    /**
     * @notice Returns the address of the order NFT contract.
     * @return The address of the order NFT contract.
     */
    function orderToken() external view returns (address);

    /**
     * @notice Returns the address of the quote token.
     * @return The address of the quote token.
     */
    function quoteToken() external view returns (address);

    /**
     * @notice Returns the address of the base token.
     * @return The address of the base token.
     */
    function baseToken() external view returns (address);

    /**
     * @notice Returns the current total open amount at the given price.
     * @param isBid The flag to choose which side to check the depth for.
     * @param priceIndex The price book index.
     * @return The total open amount.
     */
    function getDepth(bool isBid, uint16 priceIndex) external view returns (uint64);

    /**
     * @notice Returns the fee balance that has not been collected yet.
     * @return quote The current fee balance for the quote token.
     * @return base The current fee balance for the base token.
     */
    function getFeeBalance() external view returns (uint128 quote, uint128 base);

    /**
     * @notice Returns the amount of tokens that can be collected by the host.
     * @param token The address of the token to be collected.
     * @return The amount of tokens that can be collected by the host.
     */
    function uncollectedHostFees(address token) external view returns (uint256);

    /**
     * @notice Returns the amount of tokens that can be collected by the dao treasury.
     * @param token The address of the token to be collected.
     * @return The amount of tokens that can be collected by the dao treasury.
     */
    function uncollectedProtocolFees(address token) external view returns (uint256);

    /**
     * @notice Returns whether the order book is empty or not.
     * @param isBid The flag to choose which side to check the emptiness of.
     * @return Whether the order book is empty or not on that side.
     */
    function isEmpty(bool isBid) external view returns (bool);

    /**
     * @notice Returns the order information.
     * @param orderKey The order key of the order.
     * @return The order struct of the given order key.
     */
    function getOrder(OrderKey calldata orderKey) external view returns (Order memory);

    /**
     * @notice Returns the lowest ask price index or the highest bid price index.
     * @param isBid Returns the lowest ask price if false, highest bid price if true.
     * @return The current price index. If the order book is empty, it will revert.
     */
    function bestPriceIndex(bool isBid) external view returns (uint16);

    /**
     * @notice Converts a raw amount to its corresponding base amount using a given price index.
     * @param rawAmount The raw amount to be converted.
     * @param priceIndex The index of the price to be used for the conversion.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted base amount.
     */
    function rawToBase(
        uint64 rawAmount,
        uint16 priceIndex,
        bool roundingUp
    ) external view returns (uint256);

    /**
     * @notice Converts a raw amount to its corresponding quote amount.
     * @param rawAmount The raw amount to be converted.
     * @return The converted quote amount.
     */
    function rawToQuote(uint64 rawAmount) external view returns (uint256);

    /**
     * @notice Converts a base amount to its corresponding raw amount using a given price index.
     * @param baseAmount The base amount to be converted.
     * @param priceIndex The index of the price to be used for the conversion.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted raw amount.
     */
    function baseToRaw(
        uint256 baseAmount,
        uint16 priceIndex,
        bool roundingUp
    ) external view returns (uint64);

    /**
     * @notice Converts a quote amount to its corresponding raw amount.
     * @param quoteAmount The quote amount to be converted.
     * @param roundingUp Specifies whether the result should be rounded up or down.
     * @return The converted raw amount.
     */
    function quoteToRaw(uint256 quoteAmount, bool roundingUp) external view returns (uint64);

    /**
     * @notice Collects fees for either the protocol or host.
     * @param token The token address to collect. It should be the quote token or the base token.
     * @param destination The destination address to transfer fees.
     * It should be the dao treasury address or the host address.
     */
    function collectFees(address token, address destination) external;

    /**
     * @notice Change the owner of the order.
     * @dev Only the OrderToken contract can call this function.
     * @param orderKey The order key of the order.
     * @param newOwner The new owner address.
     */
    function changeOrderOwner(OrderKey calldata orderKey, address newOwner) external;
}