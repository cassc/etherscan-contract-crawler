// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import '@hashflow/contracts-evm/contracts/interfaces/IHashflowRouter.sol';
import '../nft/IRenovaAvatarBase.sol';

/// @title IRenovaQuest
/// @author Victor Ionescu
/**
@notice Contract that represents one Quest. Every Quest gets deployed by the Command Deck.

Quests have a start time and end time. Trading happens during those time bounds.

Quests each have a deposit token and a minimum deposit amount.
Only one deposit is allowed.

Deposits can occur at any time prior to quest end. Withdrawals can occur at any time.

Players register by depositing.
*/
interface IRenovaQuest {
    /// @notice Emitted when a token authorization status changes.
    /// @param token The address of the token.
    /// @param status Whether the token is allowed for trading.
    event UpdateTokenAuthorizationStatus(address token, bool status);

    /// @notice Emitted when a player registers for a quest.
    /// @param player The player registering for the quest.
    event RegisterPlayer(address indexed player);

    /// @notice Emitted when a player deposits a token for a Quest.
    /// @param player The player who deposits the token.
    /// @param token The address of the token (0x0 for native token).
    /// @param amount The amount of token being deposited.
    event DepositToken(address indexed player, address token, uint256 amount);

    /// @notice Emitted when a player withdraws a token from a Quest.
    /// @param player The player who withdraws the token.
    /// @param token The address of the token (0x0 for native token).
    /// @param amount The amount of token being withdrawn.
    event WithdrawToken(address indexed player, address token, uint256 amount);

    /// @notice Emitted when a player trades as part of the Quest.
    /// @param player The player who traded.
    /// @param baseToken The address of the token the player sold.
    /// @param quoteToken The address of the token the player bought.
    /// @param baseTokenAmount The amount sold.
    /// @param quoteTokenAmount The amount bought.
    event Trade(
        address indexed player,
        address baseToken,
        address quoteToken,
        uint256 baseTokenAmount,
        uint256 quoteTokenAmount
    );

    /// @notice Returns the Quest start time.
    /// @return The Quest start time.
    function startTime() external view returns (uint256);

    /// @notice Returns the Quest end time.
    /// @return The Quest end time.
    function endTime() external view returns (uint256);

    /// @notice Returns the token to deposit to enter.
    /// @return The address of the deposit token.
    function depositToken() external view returns (address);

    /// @notice Return the minimum deposit amount to enter.
    /// @return The minimum deposit amount.
    function minDepositAmount() external view returns (uint256);

    /// @notice Returns the address that has authority over the quest.
    /// @return The address that has authority over the quest.
    function questOwner() external view returns (address);

    /// @notice Returns whether a player has registered for the Quest.
    /// @param player The address of the player.
    /// @return Whether the player has registered.
    function registered(address player) external view returns (bool);

    /// @notice Used by the owner to allow / disallow a token for trading.
    /// @param token The address of the token.
    /// @param status The authorization status.
    function updateTokenAuthorization(address token, bool status) external;

    /// @notice Returns whether a token is allowed for deposits / trading.
    /// @param token The address of the token.
    /// @return Whether the token is allowed for trading.
    function allowedTokens(address token) external view returns (bool);

    /// @notice Returns the number of registered players.
    /// @return The number of registered players.
    function numRegisteredPlayers() external view returns (uint256);

    /// @notice Returns the token balance for each token the player has in the Quest.
    /// @param player The address of the player.
    /// @param token The address of the token.
    /// @return The player's token balance for this Quest.
    function portfolioTokenBalances(
        address player,
        address token
    ) external view returns (uint256);

    /// @notice Deposits tokens prior to the beginning of the Quest.
    /// @param depositAmount The amount of depositToken to deposit.
    function depositAndEnter(uint256 depositAmount) external payable;

    /// @notice Withdraws the full balance of the selected tokens from the Quest.
    /// @param tokens The addresses of the tokens to withdraw.
    function withdrawTokens(address[] memory tokens) external;

    /// @notice Trades within the Quest.
    /// @param quote The Hashflow Quote.
    function trade(IHashflowRouter.RFQTQuote memory quote) external;
}