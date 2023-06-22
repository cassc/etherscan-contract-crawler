// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct RewardsData {
    address rewardToken;
    uint256 outstandingRewards;
}

interface IBLVault {
    //============================================================================================//
    //                                      LIQUIDITY FUNCTIONS                                   //
    //============================================================================================//

    /// @notice                         Mints OHM against a pair token deposit and uses the OHM and pair tokens to add liquidity to a Balancer pool
    /// @dev                            Can only be called by the owner of the vault
    /// @param amount_                  The amount of pair tokens to deposit
    /// @param minLpAmount_             The minimum acceptable amount of LP tokens to receive back
    /// @return lpAmountOut             The amount of LP tokens received by the transaction
    function deposit(uint256 amount_, uint256 minLpAmount_) external returns (uint256 lpAmountOut);

    /// @notice                         Withdraws LP tokens from Aura and Balancer, burns the OHM side, and returns the pair token side to the user
    /// @dev                            Can only be called by the owner of the vault
    /// @param lpAmount_                The amount of LP tokens to withdraw from Balancer
    /// @param minTokenAmountsBalancer_ The minimum acceptable amounts of OHM (first entry), and pair tokens (second entry) to receive back from Balancer
    /// @param minTokenAmountUser_      The minimum acceptable amount of pair tokens to receive back from the vault
    /// @param claim_                   Whether to claim outstanding rewards from Aura
    /// @return uint256                 The amount of OHM received
    /// @return uint256                 The amount of pair tokens received
    function withdraw(
        uint256 lpAmount_,
        uint256[] calldata minTokenAmountsBalancer_,
        uint256 minTokenAmountUser_,
        bool claim_
    ) external returns (uint256, uint256);

    /// @notice                         Withdraws LP tokens from Aura and Balancer, returns the pair tokens to the user
    /// @dev                            Can only be called by the owner of the vault. Can only be called when the vault is paused
    /// @param lpAmount_                The amount of LP tokens to withdraw from Balancer
    /// @param minTokenAmounts_         The minimum acceptable amounts of OHM (first entry), and pair tokens (second entry) to receive back from Balancer
    /// @return uint256                 The amount of OHM received
    /// @return uint256                 The amount of pair tokens received
    function emergencyWithdraw(
        uint256 lpAmount_,
        uint256[] calldata minTokenAmounts_
    ) external returns (uint256, uint256);

    //============================================================================================//
    //                                       REWARDS FUNCTIONS                                    //
    //============================================================================================//

    /// @notice                         Claims outstanding rewards from Aura
    /// @dev                            Can only be called by the owner of the vault
    function claimRewards() external;

    //============================================================================================//
    //                                        VIEW FUNCTIONS                                      //
    //============================================================================================//

    /// @notice                         Gets whether enough time has passed since the last deposit for the user to be ale to withdraw
    /// @return bool                    Whether enough time has passed since the last deposit for the user to be ale to withdraw
    function canWithdraw() external view returns (bool);

    /// @notice                         Gets the LP balance of the contract based on its deposits to Aura
    /// @return uint256                 LP balance deposited into Aura
    function getLpBalance() external view returns (uint256);

    /// @notice                         Gets the contract's claim on pair tokens based on its LP balance deposited into Aura
    /// @return uint256                 Claim on pair tokens
    function getUserPairShare() external view returns (uint256);

    /// @notice                         Returns the vault's unclaimed rewards in Aura
    /// @return RewardsData[]           The vault's unclaimed rewards in Aura
    function getOutstandingRewards() external view returns (RewardsData[] memory);
}