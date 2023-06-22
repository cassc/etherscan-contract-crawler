// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Import system dependencies
import {MINTRv1} from "src/modules/MINTR/MINTR.v1.sol";
import {ROLESv1} from "src/modules/ROLES/ROLES.v1.sol";
import {TRSRYv1} from "src/modules/TRSRY/TRSRY.v1.sol";

// Import external dependencies
import {AggregatorV3Interface} from "interfaces/AggregatorV2V3Interface.sol";
import {IAuraMiningLib} from "policies/BoostedLiquidity/interfaces/IAura.sol";

// Import vault dependencies
import {IBLVault, RewardsData} from "policies/BoostedLiquidity/interfaces/IBLVault.sol";

interface IBLVaultManager {
    // ========= DATA STRUCTURES ========= //

    struct TokenData {
        address ohm;
        address pairToken;
        address aura;
        address bal;
    }

    struct BalancerData {
        address vault;
        address liquidityPool;
        address balancerHelper;
    }

    struct AuraData {
        uint256 pid;
        address auraBooster;
        address auraRewardPool;
    }

    struct OracleFeed {
        AggregatorV3Interface feed;
        uint48 updateThreshold;
    }

    //============================================================================================//
    //                                        STATE VARIABLES                                     //
    //============================================================================================//

    /// @notice                         The minimum length of time between a deposit and a withdrawal
    function minWithdrawalDelay() external returns (uint48);

    //============================================================================================//
    //                                        VAULT DEPLOYMENT                                    //
    //============================================================================================//

    /// @notice                         Deploys a personal single sided vault for the user
    /// @dev                            The vault is deployed with the user as the owner
    /// @return vault                   The address of the deployed vault
    function deployVault() external returns (address);

    //============================================================================================//
    //                                         OHM MANAGEMENT                                     //
    //============================================================================================//

    /// @notice                         Mints OHM to the caller
    /// @dev                            Can only be called by an approved vault
    /// @param amount_                  The amount of OHM to mint
    function mintOhmToVault(uint256 amount_) external;

    /// @notice                         Burns OHM from the caller
    /// @dev                            Can only be called by an approved vault. The caller must have an OHM approval for the MINTR.
    /// @param amount_                  The amount of OHM to burn
    function burnOhmFromVault(uint256 amount_) external;

    //============================================================================================//
    //                                     VAULT STATE MANAGEMENT                                 //
    //============================================================================================//

    /// @notice                         Increases the tracked value for totalLP
    /// @dev                            Can only be called by an approved vault
    /// @param amount_                  The amount of LP tokens to add to the total
    function increaseTotalLp(uint256 amount_) external;

    /// @notice                         Decreases the tracked value for totalLP
    /// @dev                            Can only be called by an approved vault
    /// @param amount_                  The amount of LP tokens to remove from the total
    function decreaseTotalLp(uint256 amount_) external;

    //============================================================================================//
    //                                         VIEW FUNCTIONS                                     //
    //============================================================================================//

    /// @notice                         Returns whether enough time has passed since the last deposit for the user to be ale to withdraw
    /// @param user_                    The user to check the vault of
    /// @return bool                    Whether enough time has passed since the last deposit for the user to be ale to withdraw
    function canWithdraw(address user_) external view returns (bool);

    /// @notice                         Returns the user's vault's LP balance
    /// @param user_                    The user to check the vault of
    /// @return uint256                 The user's vault's LP balance
    function getLpBalance(address user_) external view returns (uint256);

    /// @notice                         Returns the user's vault's claim on the pair token
    /// @param user_                    The user to check the vault of
    /// @return uint256                 The user's vault's claim on the pair token
    function getUserPairShare(address user_) external view returns (uint256);

    /// @notice                         Returns the user's vault's unclaimed rewards in Aura
    /// @param user_                    The user to check the vault of
    /// @return RewardsData[]           The user's vault's unclaimed rewards in Aura
    function getOutstandingRewards(address user_) external view returns (RewardsData[] memory);

    /// @notice                         Calculates the max pair token deposit based on the limit and current amount of OHM minted
    /// @return uint256                 The max pair token deposit
    function getMaxDeposit() external view returns (uint256);

    /// @notice                         Calculates the amount of LP tokens that will be generated for a given amount of pair tokens
    /// @param amount_                  The amount of pair tokens to calculate the LP tokens for
    /// @return uint256                 The amount of LP tokens that will be generated
    function getExpectedLpAmount(uint256 amount_) external returns (uint256);

    /// @notice                         Calculates the amount of OHM and pair tokens that should be received by the vault for withdrawing a given amount of LP tokens
    /// @param lpAmount_                The amount of LP tokens to calculate the OHM and pair tokens for
    /// @return expectedTokenAmounts    The amount of OHM and pair tokens that should be received
    function getExpectedTokensOutProtocol(
        uint256 lpAmount_
    ) external returns (uint256[] memory expectedTokenAmounts);

    /// @notice                         Calculates the amount of pair tokens that should be received by the user for withdrawing a given amount of LP tokens after the treasury takes any arbs
    /// @param lpAmount_                The amount of LP tokens to calculate the pair tokens for
    /// @return expectedTknAmount       The amount of pair tokens that should be received
    function getExpectedPairTokenOutUser(
        uint256 lpAmount_
    ) external returns (uint256 expectedTknAmount);

    /// @notice                         Gets all the reward tokens from the Aura pool
    /// @return address[]               The addresses of the reward tokens
    function getRewardTokens() external view returns (address[] memory);

    /// @notice                         Gets the reward rate (tokens per second) of the passed reward token
    /// @return uint256                 The reward rate (tokens per second)
    function getRewardRate(address rewardToken_) external view returns (uint256);

    /// @notice                         Returns the amount of OHM in the pool that is owned by this vault system.
    /// @return uint256                 The amount of OHM in the pool that is owned by this vault system.
    function getPoolOhmShare() external view returns (uint256);

    /// @notice                         Gets the net OHM emitted or removed by the system since inception
    /// @return uint256                 Vault system's current claim on OHM from the Balancer pool
    /// @return uint256                 Current amount of OHM minted by the system into the Balancer pool
    /// @return uint256                 OHM that wasn't minted, but was previously circulating that has been burned by the system
    function getOhmSupplyChangeData() external view returns (uint256, uint256, uint256);

    /// @notice                         Gets the number of OHM per 1 pair token using oracle prices
    /// @return uint256                 OHM per 1 pair token (9 decimals)
    function getOhmTknPrice() external view returns (uint256);

    /// @notice                         Gets the number of pair tokens per 1 OHM using oracle prices
    /// @return uint256                 Pair tokens per 1 OHM (18 decimals)
    function getTknOhmPrice() external view returns (uint256);

    /// @notice                         Gets the number of OHM per 1 pair token using pool prices
    /// @return uint256                 OHM per 1 pair token (9 decimals)
    function getOhmTknPoolPrice() external view returns (uint256);

    //============================================================================================//
    //                                        ADMIN FUNCTIONS                                     //
    //============================================================================================//

    /// @notice                         Emergency burns OHM that has been sent to the manager in the event a user had to emergency withdraw
    /// @dev                            Can only be called by the admin
    /// @param amount_                  The amount of OHM to burn
    function emergencyBurnOhm(uint256 amount_) external;

    /// @notice                         Updates the limit on minting OHM
    /// @dev                            Can only be called by the admin. Cannot be set lower than the current outstanding minted OHM.
    /// @param newLimit_                The new OHM limit (9 decimals)
    function setLimit(uint256 newLimit_) external;

    /// @notice                         Updates the fee on reward tokens
    /// @dev                            Can only be called by the admin. Cannot be set beyond 10_000 (100%). Only is used by vaults deployed after the update.
    /// @param newFee_                  The new fee (in basis points)
    function setFee(uint64 newFee_) external;

    /// @notice                         Updates the minimum holding period before a user can withdraw
    /// @dev                            Can only be called by the admin
    /// @param newDelay_                The new minimum holding period (in seconds)
    function setWithdrawalDelay(uint48 newDelay_) external;

    /// @notice                         Activates the vault manager and all approved vaults
    /// @dev                            Can only be called by the admin
    function activate() external;

    /// @notice                         Deactivates the vault manager and all approved vaults
    /// @dev                            Can only be called by the admin
    function deactivate() external;
}