// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/// @title interface design for HashVault
interface ISilicaVault {
    /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal 
    ////////////////////////////////////////////////////////*/
    /// @notice Mints Vault shares to msg.sender by depositing exactly amount in payment
    function deposit(uint256 amount) external;

    /// @notice Schedules a withdrawal of Vault shares that will be processed once the round completes
    function scheduleWithdraw(uint256 shares) external returns (uint256);

    /// @notice Processes a scheduled withdrawal from a previous round. Uses finalized pps for the round
    function processScheduledWithdraw() external returns (uint256 rewardPayout, uint256 paymentPayout);

    /// @notice Buyer redeems their share of rewards
    function redeem(uint256 numShares) external;

    /*////////////////////////////////////////////////////////
                      Admin
    ////////////////////////////////////////////////////////*/
    /// @notice Initialize a new Silica Vault
    function initialize() external;

    /// @notice Function that Vault admin calls to process all withdraw requests of current epoch
    function processWithdraws() external returns (uint256 paymentLockup, uint256 rewardLockup);

    /// @notice Function that Vault admin calls to swap the maximum amount of the rewards to stable
    function maxSwap() external;

    /// @notice Function that Vault admin calls to swap amount of rewards to stable
    /// @param amount the amount of rewards to swap
    function swap(uint256 amount) external;

    /// @notice Function that Vault admin calls to proccess deposit requests at the beginning of the epoch
    function processDeposits() external returns (uint256 mintedShares);

    /// @notice Function that Vault admin calls to start a new epoch
    function startNextRound() external;

    /// @notice Function that Vault admin calls to settle defaulted Silica contracts
    function settleDefaultedSilica(address silicaAddress) external returns (uint256 rewardPayout, uint256 paymentPayout);

    /// @notice Function that Vault admin calls to settle finished Silica contracts
    function settleFinishedSilica(address silicaAddress) external returns (uint256 rewardPayout);

    /// @notice Function that Vault admin calls to purchase Silica contracts
    function purchaseSilica(address silicaAddress, uint256 amount) external returns (uint256 silicaMinted);

    // /*////////////////////////////////////////////////////////
    //                   Properties
    // ////////////////////////////////////////////////////////*/

    // Admin

    /// @notice The address of the admin
    function getAdmin() external view returns (address);
}