// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC1155SupplyUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";
import {IAuctionConversions} from "./IAuctionConversions.sol";

interface IDualAuction is IAuctionConversions {
    /// @notice Zero address given for asset
    error ZeroAddressAsset();

    /// @notice Matching buy/sell assets
    error MatchingAssets();

    /// @notice Zero amount of asset given
    error ZeroAmount();

    /// @notice The end date has not yet passed
    error AuctionIsActive();

    /// @notice The end date has passed
    error AuctionHasEnded();

    /// @notice The auction has not been settled
    error AuctionHasNotSettled();

    /// @notice The auction has already been settled
    error AuctionHasSettled();

    /// @notice The auction ended with no clearing price
    error NoClearingPrice();

    /// @notice The settlement somehow ended with cleared tokens but no clearing price
    error SettleHasFailed();

    /// @notice Event declaring that a bid was made
    event Bid(
        address indexed actor,
        uint256 amountIn,
        uint256 amountOut,
        uint256 indexed price
    );

    /// @notice Event declaring that an ask was made
    event Ask(
        address indexed actor,
        uint256 amountIn,
        uint256 amountOut,
        uint256 indexed price
    );

    /// @notice Event notifying about the settlement of an auction
    event Settle(address indexed actor, uint256 clearingPrice);

    /// @notice Event notifying about the redemption of share tokens
    event Redeem(
        address indexed actor,
        uint256 indexed tokenId,
        uint256 shareAmount,
        uint256 bidValue,
        uint256 askValue
    );

    /// @notice The highest bid received so far
    function maxBid() external view returns (uint256);

    /// @notice The lowest ask received so far
    function minAsk() external view returns (uint256);

    /// @notice The clearing price of the auction, set after settlement
    function clearingPrice() external view returns (uint256);

    /// @notice True if the auction has been settled, eles false
    function settled() external view returns (bool);

    /**
     * @notice Places a bid using amountIn bidAsset tokens,
     * for askAsset tokens at the given price
     * @param amountIn The amount to bid, in bidAsset
     * @param price the price at which to bid, denominated in terms of bidAsset per askAsset
     * @return The number of shares output
     */
    function bid(uint256 amountIn, uint256 price) external returns (uint256);

    /**
     * @notice Places an ask using amountIn askAsset tokens,
     * for bidAsset tokens at the given price
     * @param amountIn The amount to sell, in askAsset
     * @param price the price at which to ask, denominated in terms of bidAsset per askAsset
     * @return The number of shares output
     */
    function ask(uint256 amountIn, uint256 price) external returns (uint256);

    /**
     * @notice Settles the auction after the end date
     * @dev iterates through the bids and asks to determine
     *  The clearing price, setting the clearingPrice variable afterwards
     * @return The settled clearing price, or 0 if none
     */
    function settle() external returns (uint256);

    /**
     * @notice Redeems bid/ask slips after the auction has concluded
     * @param tokenId The id of the bid/ask slip to redeem
     * @param amount The amount of slips to redeem
     * @return The number of tokens received
     */
    function redeem(uint256 tokenId, uint256 amount)
        external
        returns (uint256, uint256);
}