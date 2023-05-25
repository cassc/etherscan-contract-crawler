//SPDX-License-Identifier: None

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FX1 Sports Token
/// @title https://fx1.io/
/// @title https://t.me/fx1_sports_portal
/// @author https://PROOFplatform.io
/// @author https://5thWeb.io

interface IFX1SportsToken is IERC20 {
    struct Param {
        address proofRevenue;
        address proofRewards;
        address proofAdmin;
        address marketingTaxRecv;
        address dexRouter;
        address teamAllocator_1;
        address teamAllocator_2;
        uint256 whitelistPeriod;
        uint256 proofFeeDuration;
        uint16 highPROOFFeeRate;
        uint16 normalPROOFFeeRate;
        uint16 marketingFeeRate;
        uint16 liquidityFeeRate;
        uint16 totalTeamAllocationRate;
        uint16 teamAllocationRate_1;
        uint16 teamAllocationRate_2;
    }

    struct BuyFeeRate {
        uint256 proofFeeDuration;
        uint16 highTotalFeeRate;
        uint16 normalTotalFeeRate;
        uint16 highPROOFFeeRate;
        uint16 normalPROOFFeeRate;
        uint16 marketingFeeRate;
        uint16 liquidityFeeRate;
    }

    struct SellFeeRate {
        uint256 proofFeeDuration;
        uint16 highTotalFeeRate;
        uint16 normalTotalFeeRate;
        uint16 highPROOFFeeRate;
        uint16 normalPROOFFeeRate;
        uint16 marketingFeeRate;
        uint16 liquidityFeeRate;
    }

    /// @notice Cancels Token from Fees and transfers ownership to PROOF.
    /// @dev Only PROOF Admin can call this function.
    function cancelToken() external;

    /// @notice Remove PROOFFeeRate.
    /// @dev Only PROOF Admin can call this function.
    function formatPROOFFee() external;

    /// @notice Locks trading until called. Cannont be called twice.
    /// @dev Only owner can call this function.
    function setLaunchBegin()external;

    /// @notice Set proofAdmin wallet address.
    /// @dev Only PROOF Admin can call this function.
    /// @param newAdmin The address of proofAdmin wallet.
    function updatePROOFAdmin(address newAdmin) external;

    /// @notice Add bots.
    /// @dev Only PROOF Admin can call this function.
    /// @param bots_ The address of bot.
    function setBots(address[] memory bots_) external;

    /// @notice Remove bots.
    /// @dev Only PROOF Admin and Owner can call this function.
    /// @param notbot The address to be removed from bots.
    function delBot(address notbot) external;

    /// @notice Add/Remove whitelists.
    /// @dev Only owner can call this function.
    /// @param _accounts The address of whitelists.
    /// @param _add True/False = Add/Remove
    function addWhitelists(address[] memory _accounts, bool _add) external;

    /// @notice Add/Remove wallets to excludedMaxTransfer.
    /// @dev Only owner can call this function.
    /// @param _accounts The address of accounts.
    /// @param _add True/False = Add/Remove
    function excludeWalletsFromMaxTransfer(
        address[] memory _accounts,
        bool _add
    ) external;

    /// @notice Add/Remove wallets to excludedMaxWallet.
    /// @dev Only owner can call this function.
    /// @param _accounts The address of accounts.
    /// @param _add True/False = Add/Remove
    function excludeWalletsFromMaxWallets(
        address[] memory _accounts,
        bool _add
    ) external;

    /// @notice Add/Remove wallets to excludedFromFees.
    /// @dev Only owner can call this function.
    /// @param _accounts The address of accounts.
    /// @param _add True/False = Add/Remove
    function excludeWalletsFromFees(
        address[] memory _accounts,
        bool _add
    ) external;

    /// @notice Set maxTransferAmount.
    /// @dev Only owner can call this function.
    /// @param _maxTransferAmount New maxTransferAmount.
    function setMaxTransferAmount(uint256 _maxTransferAmount) external;

    /// @notice Set maxWalletAmount.
    /// @dev Only owner can call this function.
    /// @param _maxWalletAmount New maxWalletAmount.
    function setMaxWalletAmount(uint256 _maxWalletAmount) external;

    /// @notice Set marketingTaxRecipient wallet address.
    /// @dev Only owner can call this function.
    /// @param _marketingTaxWallet The address of marketingTaxRecipient wallet.
    function setMarketingTaxWallet(address _marketingTaxWallet) external;

    /// @notice Reduce PROOFFeeRate.
    /// @dev Only owner can call this function.
    function reducePROOFFeeRate() external;

    /// @notice Set MarketingFeeRate.
    /// @dev Only owner can call this function.
    /// @dev Max Rate of 100(10%) 10 = 1%
    /// @param _marketingBuyFeeRate New MarketingBuyFeeRate.
    /// @param _marketingSellFeeRate New MarketingSellFeeRate.
    function setMarketingFeeRate(
        uint16 _marketingBuyFeeRate, 
        uint16 _marketingSellFeeRate
    ) external;

    /// @notice Set LiquidityFeeRate.
    /// @dev Only owner can call this function.
    /// @dev Max Rate of 100(10%) 10 = 1%
    /// @param _liquidityBuyFeeRate New liquiditySellFeeRate.
    /// @param _liquiditySellFeeRate New liquidityBuyFeeRate.
    function setLiquidityFeeRate(
        uint16 _liquidityBuyFeeRate,
        uint16 _liquiditySellFeeRate
    ) external;

    /// @notice Set swapThreshold.
    /// @dev Only owner can call this function.
    /// @param _swapThreshold New swapThreshold amount.
    function setSwapThreshold(uint256 _swapThreshold) external;
}