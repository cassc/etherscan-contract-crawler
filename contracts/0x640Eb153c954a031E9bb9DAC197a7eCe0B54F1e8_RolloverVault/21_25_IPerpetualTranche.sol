// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { IBondIssuer } from "./IBondIssuer.sol";
import { IFeeStrategy } from "./IFeeStrategy.sol";
import { IPricingStrategy } from "./IPricingStrategy.sol";
import { IDiscountStrategy } from "./IDiscountStrategy.sol";
import { IBondController } from "./buttonwood/IBondController.sol";
import { ITranche } from "./buttonwood/ITranche.sol";

interface IPerpetualTranche is IERC20Upgradeable {
    //--------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when the applied discount for a given token is set.
    /// @param token The address of the token.
    /// @param discount The discount factor applied.
    event DiscountApplied(IERC20Upgradeable token, uint256 discount);

    /// @notice Event emitted the reserve's current token balance is recorded after change.
    /// @param token Address of token.
    /// @param balance The recorded ERC-20 balance of the token held by the reserve.
    event ReserveSynced(IERC20Upgradeable token, uint256 balance);

    /// @notice Event emitted when the active deposit bond is updated.
    /// @param bond Address of the new deposit bond.
    event UpdatedDepositBond(IBondController bond);

    /// @notice Event emitted when the mature tranche balance is updated.
    /// @param matureTrancheBalance The mature tranche balance.
    event UpdatedMatureTrancheBalance(uint256 matureTrancheBalance);

    //--------------------------------------------------------------------------
    // Methods

    /// @notice Deposits tranche tokens into the system and mint perp tokens.
    /// @param trancheIn The address of the tranche token to be deposited.
    /// @param trancheInAmt The amount of tranche tokens deposited.
    function deposit(ITranche trancheIn, uint256 trancheInAmt) external;

    /// @notice Burn perp tokens and redeem the share of reserve assets.
    /// @param perpAmtBurnt The amount of perp tokens burnt from the caller.
    function redeem(uint256 perpAmtBurnt) external;

    /// @notice Rotates newer tranches in for reserve tokens.
    /// @param trancheIn The tranche token deposited.
    /// @param tokenOut The reserve token to be redeemed.
    /// @param trancheInAmt The amount of trancheIn tokens deposited.
    function rollover(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmt
    ) external;

    /// @notice Reference to the wallet or contract that has the ability to pause/unpause operations.
    /// @return The address of the keeper.
    function keeper() external view returns (address);

    /// @notice The address of the underlying rebasing ERC-20 collateral token backing the tranches.
    /// @return Address of the collateral token.
    function collateral() external view returns (IERC20Upgradeable);

    /// @notice The "virtual" balance of all mature tranches held by the system.
    /// @return The mature tranche balance.
    function getMatureTrancheBalance() external returns (uint256);

    /// @notice The parent bond whose tranches are currently accepted to mint perp tokens.
    /// @return Address of the deposit bond.
    function getDepositBond() external returns (IBondController);

    /// @notice Checks if the given `trancheIn` can be rolled out for `tokenOut`.
    /// @param trancheIn The tranche token deposited.
    /// @param tokenOut The reserve token to be redeemed.
    /// @return If the given pair is a valid rollover.
    function isAcceptableRollover(ITranche trancheIn, IERC20Upgradeable tokenOut) external returns (bool);

    /// @notice The strategy contract with the fee computation logic.
    /// @return Address of the strategy contract.
    function feeStrategy() external view returns (IFeeStrategy);

    /// @notice The ERC-20 contract which holds perp balances.
    /// @return Address of the token.
    function perpERC20() external view returns (IERC20Upgradeable);

    /// @notice The contract where the protocol holds funds which back the perp token supply.
    /// @return Address of the reserve.
    function reserve() external view returns (address);

    /// @notice The address which holds any revenue extracted by protocol.
    /// @return Address of the fee collector.
    function protocolFeeCollector() external view returns (address);

    /// @notice The fee token currently used to receive fees in.
    /// @return Address of the fee token.
    function feeToken() external view returns (IERC20Upgradeable);

    /// @notice Total count of tokens held in the reserve.
    /// @return The reserve token count.
    function getReserveCount() external returns (uint256);

    /// @notice The token address from the reserve list by index.
    /// @param index The index of a token.
    /// @return The reserve token address.
    function getReserveAt(uint256 index) external returns (IERC20Upgradeable);

    /// @notice Checks if the given token is part of the reserve.
    /// @param token The address of a token to check.
    /// @return If the token is part of the reserve.
    function inReserve(IERC20Upgradeable token) external returns (bool);

    /// @notice Fetches the reserve's token balance.
    /// @param token The address of the tranche token held by the reserve.
    /// @return The ERC-20 balance of the reserve token.
    function getReserveTokenBalance(IERC20Upgradeable token) external returns (uint256);

    /// @notice Fetches the reserve's tranche token balance.
    /// @param tranche The address of the tranche token held by the reserve.
    /// @return The ERC-20 balance of the reserve tranche token.
    function getReserveTrancheBalance(IERC20Upgradeable tranche) external returns (uint256);

    /// @notice Calculates the reserve's tranche token value,
    ///         in a standard denomination as defined by the implementation.
    /// @param tranche The address of the tranche token held by the reserve.
    /// @return The value of the reserve tranche balance held by the reserve, in a standard denomination.
    function getReserveTrancheValue(IERC20Upgradeable tranche) external returns (uint256);

    /// @notice Computes the price of each perp token, i.e) reserve value / total supply.
    /// @return The average price per perp token.
    function getAvgPrice() external returns (uint256);

    /// @notice Fetches the list of reserve tokens which are up for rollover.
    /// @return The list of reserve tokens up for rollover.
    function getReserveTokensUpForRollover() external returns (IERC20Upgradeable[] memory);

    /// @notice Computes the amount of perp tokens minted when `trancheInAmt` `trancheIn` tokens
    ///         are deposited into the system.
    /// @param trancheIn The tranche token deposited.
    /// @param trancheInAmt The amount of tranche tokens deposited.
    /// @return The amount of perp tokens to be minted.
    function computeMintAmt(ITranche trancheIn, uint256 trancheInAmt) external returns (uint256);

    /// @notice Computes the amount reserve tokens redeemed when burning given number of perp tokens.
    /// @param perpAmtBurnt The amount of perp tokens to be burnt.
    /// @return tokensOut The list of reserve tokens redeemed.
    /// @return tokenOutAmts The list of reserve token amounts redeemed.
    function computeRedemptionAmts(uint256 perpAmtBurnt)
        external
        returns (IERC20Upgradeable[] memory tokensOut, uint256[] memory tokenOutAmts);

    struct RolloverPreview {
        /// @notice The perp denominated value of tokens rolled over.
        uint256 perpRolloverAmt;
        /// @notice The amount of tokens rolled out.
        uint256 tokenOutAmt;
        /// @notice The tranche denominated amount of tokens rolled out.
        /// @dev tokenOutAmt and trancheOutAmt can only be different values
        ///      in the case of rolling over the mature tranche.
        uint256 trancheOutAmt;
        /// @notice The amount of trancheIn tokens rolled in.
        uint256 trancheInAmt;
        /// @notice The difference between the available trancheIn amount and
        ///        the amount of tokens used for the rollover.
        uint256 remainingTrancheInAmt;
    }

    /// @notice Computes the amount reserve tokens that are rolled out for the given number
    ///         of `trancheIn` tokens rolled in.
    /// @param trancheIn The tranche token rolled in.
    /// @param tokenOut The reserve token to be rolled out.
    /// @param trancheInAmtAvailable The amount of trancheIn tokens rolled in.
    /// @param tokenOutAmtRequested The amount of tokenOut tokens requested to be rolled out.
    /// @return r The rollover amounts in various denominations.
    function computeRolloverAmt(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtAvailable,
        uint256 tokenOutAmtRequested
    ) external returns (RolloverPreview memory);

    /// @notice The discount to be applied given the reserve token.
    /// @param token The address of the reserve token.
    /// @return The discount applied.
    function computeDiscount(IERC20Upgradeable token) external view returns (uint256);

    /// @notice The price of the given reserve token.
    /// @param token The address of the reserve token.
    /// @return The computed price.
    function computePrice(IERC20Upgradeable token) external view returns (uint256);

    /// @notice Updates time dependent storage state.
    function updateState() external;
}