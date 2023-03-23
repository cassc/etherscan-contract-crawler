// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface ICallPoolEvents {
    event Activate(address account);
    event Deactivate(address account);

    event Deposit(address indexed nft, address user, address indexed onBehalfOf, uint256 indexed tokenId);
    event PreferenceUpdated(address indexed nft, uint256 indexed tokenId, uint8 lowerStrikePriceGapIdx, uint8 upperDurationIdx, uint256 minimumStrikePrice);
    event Withdraw(address indexed nft, address indexed user, address to, uint256 indexed tokenId);
    event CallOpened(address indexed nft, address indexed user, uint256 indexed tokenId, uint8 strikePriceGapIdx, uint8 durationIdx, uint256 exercisePrice, uint40 exercisePeriodBegin, uint40 exercisePeriodEnd);
    event PremiumReceived(address indexed nft, address indexed owner, uint256 indexed tokenId, uint256 premiumToOwner, uint256 premiumToReserve);
    event CallClosed(address indexed nft, address indexed user, address owner, uint256 indexed tokenId, uint256 price);
    event OffMarket(address indexed nft, address indexed owner, uint256 indexed tokenId);
    event OnMarket(address indexed nft, address indexed owner, uint256 indexed tokenId);
    event WithdrawETH(address indexed user, address indexed to, uint256 amount);
    event BalanceChangedETH(address indexed user, uint256 newBalance);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount The amount of token0 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint256 amount);
}