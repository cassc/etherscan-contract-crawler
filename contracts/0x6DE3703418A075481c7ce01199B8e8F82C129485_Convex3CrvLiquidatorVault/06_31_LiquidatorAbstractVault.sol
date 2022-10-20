// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Libs
import { ILiquidatorVault } from "../../interfaces/ILiquidatorVault.sol";
import { VaultManagerRole } from "../../shared/VaultManagerRole.sol";

/**
 * @title   Vaults must implement this if they integrate to the Liquidator.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-11
 *
 * Implementations must implement the `collectRewards` function.
 *
 * The following functions have to be called by implementing contract.
 * - constructor
 *   - AbstractVault(_asset)
 *   - VaultManagerRole(_nexus)
 * - VaultManagerRole._initialize(_vaultManager)
 * - LiquidatorAbstractVault._initialize(_rewardTokens)
 */
abstract contract LiquidatorAbstractVault is ILiquidatorVault, VaultManagerRole {
    using SafeERC20 for IERC20;

    /// @notice Reward tokens collected by the vault.
    address[] public rewardToken;

    event RewardAdded(address indexed reward, uint256 position);

    /**
     * @param _rewardTokens Address of the reward tokens.
     */
    function _initialize(address[] memory _rewardTokens) internal virtual {
        _addRewards(_rewardTokens);
    }

    /**
     * Collects reward tokens from underlying platforms or vaults to this vault and
     * reports to the caller the amount of tokens now held by the vault.
     * This can be called by anyone but it used by the Liquidator to transfer the
     * rewards tokens from this vault to the liquidator.
     *
     * @param rewardTokens_ Array of reward tokens that were collected.
     * @param rewards The amount of reward tokens that were collected.
     * @param donateTokens The token the Liquidator swaps the reward tokens to.
     */
    function collectRewards()
        external
        virtual
        override
        returns (
            address[] memory rewardTokens_,
            uint256[] memory rewards,
            address[] memory donateTokens
        )
    {
        _beforeCollectRewards();

        uint256 rewardLen = rewardToken.length;
        rewardTokens_ = new address[](rewardLen);
        rewards = new uint256[](rewardLen);
        donateTokens = new address[](rewardLen);

        for (uint256 i = 0; i < rewardLen; ) {
            address rewardTokenMem = rewardToken[i];
            rewardTokens_[i] = rewardTokenMem;
            // Get reward token balance for this vault.
            rewards[i] = IERC20(rewardTokenMem).balanceOf(address(this));
            donateTokens[i] = _donateToken(rewardTokenMem);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Base implementation doesn't do anything.
     * This can be overridden to get rewards from underlying platforms or vaults.
     */
    function _beforeCollectRewards() internal virtual {
        // Do nothing
    }

    /**
     * @dev Tells the Liquidator what token to swap the reward tokens to.
     * For example, the vault asset.
     * @param reward Reward token that is being sold by the Liquidator.
     */
    function _donateToken(address reward) internal view virtual returns (address token);

    /**
     * @notice Adds new reward tokens to the vault so the liquidator module can transfer them from the vault.
     * Can only be called by the protocol governor.
     * @param _rewardTokens A list of reward token addresses.
     */
    function addRewards(address[] memory _rewardTokens) external virtual onlyGovernor {
        _addRewards(_rewardTokens);
    }

    function _addRewards(address[] memory _rewardTokens) internal virtual {
        address liquidator = _liquidatorV2();
        require(liquidator != address(0), "invalid Liquidator V2");

        uint256 rewardTokenLen = rewardToken.length;

        // For reward token
        uint256 len = _rewardTokens.length;
        for (uint256 i = 0; i < len; ) {
            address newReward = _rewardTokens[i];
            rewardToken.push(newReward);
            IERC20(newReward).safeApprove(liquidator, type(uint256).max);

            emit RewardAdded(newReward, rewardTokenLen + i);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns all reward tokens address added to the vault.
     */
    function rewardTokens() external view override returns (address[] memory) {
        return rewardToken;
    }

    /**
     * @notice Returns the token that rewards must be swapped to before donating back to the vault.
     * @param _rewardToken The address of the reward token collected by the vault.
     * @return token The address of the token that `_rewardToken` is to be swapped for.
     * @dev Base implementation returns the vault asset.
     * This can be overridden to swap rewards for other tokens.
     */
    function donateToken(address _rewardToken) external view override returns (address token) {
        token = _donateToken(_rewardToken);
    }
}