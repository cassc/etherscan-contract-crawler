// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenVaultWitnet.sol";
import "./ITokenVaultAuctionDutch.sol";

abstract contract IWittyPixelsTokenVault
    is
        ITokenVaultWitnet,
        ITokenVaultAuctionDutch
{
    event Donation(address from, address charity, uint256 value);

    struct Stats {
        uint256 redeemedPixels;
        uint256 redeemedPlayers;
        uint256 totalPixels;
        uint256 totalTransfers;
        uint256 totalWithdrawals;
        uint256 ethSoFarDonated;
    }

    enum Status {
        /* 0 */ Awaiting,
        /* 1 */ Randomizing,
        /* 2 */ Auctioning,
        /* 3 */ Acquired
    }

    /// @notice Returns number of legitimate players that have redeemed authorhsip of at least one pixel from the NFT token.
    function getAuthorsCount() virtual external view returns (uint256);

    /// @notice Returns range of authors's address and legacy pixels, as specified by `offset` and `count` params.
    function getAuthorsRange(uint offset, uint count) virtual external view returns (address[] memory, uint256[] memory);

    /// @notice Returns status data about the token vault contract, relevant from an UI/UX perspective
    /// @return status Enum value representing current contract status: Awaiting, Randomizing, Auctioning, Acquired
    /// @return stats Set of meters reflecting number of pixels, players, ERC20 transfers and withdrawls, up to date. 
    /// @return currentPrice Price in ETH/wei at which the whole NFT ownership can be bought, or at which it was actually sold.
    /// @return nextPriceTimestamp The approximate timestamp at which the currentPrice may change. Zero, if it's not expected to ever change again.
    function getInfo() virtual external view returns (
            Status  status,
            Stats memory stats,
            uint256 currentPrice,
            uint256 nextPriceTimestamp
        );

    /// @notice Returns Charity information related to this token vault contract.
    /// @return wallet The Charity EVM address where donations will be transferred to.
    /// @return percentage Percentage of the final price that will be eventually donated to the Charity wallet.
    /// @return ethSoFarDonated Cumuled amount of ETH that has been so far donated to the Charity wallet.
    function getCharityInfo() virtual external view returns (
            address wallet,
            uint8   percentage,
            uint256 ethSoFarDonated
        );

    /// @notice Gets info regarding a formerly verified player, given its index. 
    /// @return playerAddress Address from which the token's ownership was redeemed. Zero if this player hasn't redeemed ownership yet.
    /// @return redeemedPixels Number of pixels formerly redemeed by given player. 
    function getPlayerInfo(uint256) virtual external view returns (
            address playerAddress,
            uint256 redeemedPixels
        );

    /// @notice Returns set of meters reflecting number of pixels, players, ERC20 transfers, withdrawals, 
    /// @notice and totally donated funds up to now.
    function getStats() virtual external view returns (Stats memory stats);

    /// @notice Gets accounting info regarding given address.
    /// @return wpxBalance Current ERC20 balance.
    /// @return wpxShare10000 NFT ownership percentage based on current ERC20 balance, multiplied by 100.
    /// @return ethWithdrawable ETH/wei amount that can be potentially withdrawn from this address.
    /// @return soulboundPixels Soulbound pixels contributed from this wallet address, if any.    
    function getWalletInfo(address) virtual external view returns (
            uint256 wpxBalance,
            uint256 wpxShare10000,
            uint256 ethWithdrawable,
            uint256 soulboundPixels
        );

    /// @notice Returns sum of legacy pixels ever redeemed from the given address.
    /// The moral right over a player's finalized pixels is inalienable, so the value returned by this method
    /// will be preserved even though the player transfers ERC20/WPX tokens to other accounts, or if she decides to cash out 
    /// her share if the parent NFT token ever gets acquired. 
    function pixelsOf(address) virtual external view returns (uint256);

    /// @notice Returns total number of finalized pixels within the WittyPixels canvas.
    function totalPixels() virtual external view returns (uint256);

}