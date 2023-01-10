// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

// External
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Libs
import { ILiquidatorVault } from "../../interfaces/ILiquidatorVault.sol";
import { ILiquidatorV2 } from "../../interfaces/ILiquidatorV2.sol";
import { DexSwapData, IDexSwap, IDexAsyncSwap } from "../../interfaces/IDexSwap.sol";
import { InitializableReentrancyGuard } from "../../shared/InitializableReentrancyGuard.sol";
import { ImmutableModule } from "../../shared/ImmutableModule.sol";

struct Liquidation {
    mapping(address => uint256) vaultRewards;
    uint128 rewards;
    uint128 assets;
}

/**
 * @title   Collects reward tokens from vaults, swaps them and donated the purchased token back to the vaults.
 *          Supports asynchronous and synchronous swaps.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-11
 */
contract Liquidator is Initializable, ImmutableModule, InitializableReentrancyGuard, ILiquidatorV2 {
    using SafeERC20 for IERC20;

    /// @notice Mapping of reward tokens to asset tokens to a list of liquidation batch data.
    /// @dev rewards => assets => liquidation batches
    mapping(address => mapping(address => Liquidation[])) internal pairs;

    /// @notice Contract that implements on-chain swaps
    IDexSwap public syncSwapper;
    /// @notice Contract that implements on-chain async swaps
    IDexAsyncSwap public asyncSwapper;

    event ClaimedAssets(uint256);
    /// @dev rewardTokens[vaults][tokens], rewards[vaultsIdx][rewardTokenIdx], purchaseTokens[vaults][tokens]
    event CollectedRewards(
        address[][] rewardTokens,
        uint256[][] rewards,
        address[][] purchaseTokens
    );
    event DonatedAssets(uint256[] assets);

    /// swap events
    event SwapperUpdated(address indexed oldSwapper, address indexed newSwapper);
    event Swapped(uint256 batch, uint256 rewards, uint256 assets);
    event SwapInitiated(uint256 batch, uint256 rewards, uint256 assets);
    event SwapSettled(uint256 batch, uint256 rewards, uint256 assets);

    /**
     * @param _nexus  Address of the Nexus contract that resolves protocol modules and roles.
     */
    constructor(address _nexus) ImmutableModule(_nexus) {}

    /**
     * Initilalise the smart contract with the address of the async and sync swappers.
     * @param _syncSwapper Address of the sync DEX swapper.
     * @param _asyncSwapper Address of the async DEX swapper.
     */
    function initialize(address _syncSwapper, address _asyncSwapper) external initializer {
        _initializeReentrancyGuard();
        _setSyncSwapper(_syncSwapper);
        _setAsyncSwapper(_asyncSwapper);
    }

    /**
     * @notice The keeper or governor can collect different rewards from a list of vaults.
     * The Liquidator calls each vault to collect their rewards.
     * The vaults transfer the rewards to themselves first and then the Liquidator
     * transfers each reward from each vault to the Liquidator.
     * Vault rewards can be collect multiple times before they are swapped
     * for the vault asset. It's the responsibility of the Liquidator to
     * account for how many rewards were collected from each vault.
     *
     * @dev Emits the `CollectedRewards` event with the `tokens` and `rewards` return parameters.
     *
     * @param vaults List of vault addresses to collect rewards from.
     * @return rewardTokens Reward token addresses for each vault.
     * The first dimension is vault from the `vaults` param.
     * The second dimension is the index of the reward token within the vault.
     * @return rewards Amount of reward tokens collected for each vault.
     * The first dimension is vault from the `vaults` param.
     * The second dimension is the index of the reward token within the vault.
     * @return purchaseTokens The token to purchase for each of the rewards.
     * The first dimension is vault from the `vaults` param.
     * The second dimension is the index of the reward token within the vault.
     */
    function collectRewards(address[] memory vaults)
        external
        nonReentrant
        onlyKeeperOrGovernor
        returns (
            address[][] memory rewardTokens,
            uint256[][] memory rewards,
            address[][] memory purchaseTokens
        )
    {
        uint256 vaultLen = vaults.length;
        rewardTokens = new address[][](vaultLen);
        rewards = new uint256[][](vaultLen);
        purchaseTokens = new address[][](vaultLen);

        // For each vault
        for (uint256 v = 0; v < vaultLen; ) {
            ILiquidatorVault vault = ILiquidatorVault(vaults[v]);
            (rewardTokens[v], rewards[v], purchaseTokens[v]) = vault.collectRewards();

            uint256 rewardsLen = rewards[v].length;

            // For each reward collected
            for (uint256 r = 0; r < rewardsLen; ++r) {
                address rewardToken = rewardTokens[v][r];
                uint256 reward = rewards[v][r];
                address purchaseToken = purchaseTokens[v][r];

                // If there are no rewards at this index then just move to the next reward
                if (reward == 0) continue;

                // Get the current liquidation batch
                uint256 batch = pairs[rewardToken][purchaseToken].length;
                // If the first liquidation for this reward/asset pair
                if (batch == 0) {
                    // Add the liquidation batch. After this new batches are added after each swap.
                    pairs[rewardToken][purchaseToken].push();
                } else {
                    // The last batch is length - 1.
                    batch -= 1;
                }

                // Transfer the collected rewards from the vault to this contract
                IERC20(rewardToken).safeTransferFrom(address(vault), address(this), reward);

                // Increment the total rewards and vault rewards for this batch of rewards to assets pair
                pairs[rewardToken][purchaseToken][batch].rewards += SafeCast.toUint128(reward);
                pairs[rewardToken][purchaseToken][batch].vaultRewards[address(vault)] += reward;
            }

            unchecked {
                ++v;
            }
        }

        emit CollectedRewards(rewardTokens, rewards, purchaseTokens);
    }

    function _donateTokensToVault(
        address purchaseToken,
        address vault,
        uint256 amount
    ) internal {
        require(amount > 0, "nothing to donate");
        // Approve the vault to transfer its share of the purchased assets
        IERC20(purchaseToken).safeIncreaseAllowance(vault, amount);

        // Call the vault's donate function which will tranfer the vault's share of the purchased assets
        // from this Liquiation contract to the vault.
        ILiquidatorVault(vault).donate(purchaseToken, amount);
    }

    function _donateTokens(
        uint256 batch,
        address rewardToken,
        address purchaseToken,
        address vault
    ) internal returns (uint256 amount) {
        require(pairs[rewardToken][purchaseToken][batch].assets > 0, "not swapped");
        require(
            pairs[rewardToken][purchaseToken][batch].vaultRewards[vault] > 0,
            "already donated"
        );

        amount =
            (pairs[rewardToken][purchaseToken][batch].assets *
                pairs[rewardToken][purchaseToken][batch].vaultRewards[vault]) /
            pairs[rewardToken][purchaseToken][batch].rewards;

        // Reset the vault's share back to zero
        pairs[rewardToken][purchaseToken][batch].vaultRewards[vault] = 0;
    }

    /**
     * @notice The protocol Governor or Keeper can send the purchased assets in a batch back to the vaults.
     * The order of the input elements is important to aggreate multiple deposits of the same asset to the vault.
     *
     * ie. Vault 1 has Reward A, Reward B, both rewards are swapped for the same donated Token T.
     * - donateTokens([rewardA.address, rewardB.address], [tokenT.address, tokenT.address], [vault1.Address, vault1.Address]
     * Only triggers one deposit of Token T to the underlying vault
     *
     * @dev Emits the `DontatedAssets` event with the `assets` return parameter.

     * @param rewardTokens  List of addresses of the reward token that was sold.
     * @param purchaseTokens  List of addresses of the token that was purchased.
     * @param vaults List of addresses for the vaults with the reward to asset pair.
     * @return assets Amount of asset tokens purchased for each different vault in the `vaults` parameter.
     */
    function donateTokens(
        address[] memory rewardTokens,
        address[] memory purchaseTokens,
        address[] memory vaults
    ) external onlyKeeperOrGovernor returns (uint256[] memory assets) {
        uint256 len = vaults.length;
        require(
            len == rewardTokens.length && len == purchaseTokens.length && len > 0,
            "Wrong input"
        );
        assets = new uint256[](len);
        address rewardToken;
        address vault;
        address purchaseToken;
        address previousVault;
        address previousPurchaseToken;
        uint256 batch;
        uint256 donations = 0;

        // For each input index
        for (uint256 i; i < len; ) {
            rewardToken = rewardTokens[i];
            vault = vaults[i];
            purchaseToken = purchaseTokens[i];
            batch = pairs[rewardToken][purchaseToken].length;
            // if vault changes or purchase token changes trigger a donation to the vault.
            if (i > 0 && (vault != previousVault || purchaseToken != previousPurchaseToken)) {
                _donateTokensToVault(previousPurchaseToken, previousVault, assets[donations]);
                unchecked {
                    ++donations;
                }
            }
            previousVault = vault;
            previousPurchaseToken = purchaseToken;

            // for each swapped batch but not donated
            if (batch > 0) {
                do {
                    unchecked {
                        --batch;
                    }
                    // If already swapped rewards for purchase tokens
                    if (pairs[rewardToken][purchaseToken][batch].assets > 0) {
                        // if swapped and donated
                        if (pairs[rewardToken][purchaseToken][batch].vaultRewards[vault] == 0) {
                            break;
                        }
                        // if swapped and not donated
                        else {
                            assets[donations] += _donateTokens(
                                batch,
                                rewardToken,
                                purchaseToken,
                                vault
                            );
                        }
                    }
                    // if not swapped, do nothing and move to the next one.
                } while (batch > 0);
            }
            unchecked {
                ++i;
            }
        }
        // Donating to vault is expensive, aggregate same purchaseToken-vault txs.
        // Donate after the last iteration so donate
        _donateTokensToVault(purchaseToken, vault, assets[donations]);

        emit DonatedAssets(assets);
    }

    /**
     * @notice Vault claims the purchased assets in a batch back.
     * Separate transactions are required if a vault has multiple reward tokens.
     *
     * @dev Emits the `ClaimedAssets` event with the `assets` return parameter.
     *
     * @param batch Liquidation batch index from the previously executed `swap`.
     * @param rewardToken Address of the reward token that was sold.
     * @param assetToken Address of the asset token that was purchased.
     * @return assets Amount of asset tokens purchased in the batch.
     */
    function claimAssets(
        uint256 batch,
        address rewardToken,
        address assetToken
    ) external returns (uint256 assets) {
        require(batch < pairs[rewardToken][assetToken].length, "invalid batch");
        assets = _donateTokens(batch, rewardToken, assetToken, msg.sender);
        _donateTokensToVault(assetToken, msg.sender, assets);
        emit ClaimedAssets(assets);
    }

    /***************************************
                View Functions
    ****************************************/

    /**
     * @param rewardToken Address of the rewards being sold.
     * @param assetToken Address of the assets being purchased.
     * @return batch Current liquidation batch index.
     * @return rewards Amount of reward tokens that are waiting to be swapped.
     */
    function pendingRewards(address rewardToken, address assetToken)
        external
        view
        returns (uint256 batch, uint256 rewards)
    {
        if (pairs[rewardToken][assetToken].length > 0) {
            batch = pairs[rewardToken][assetToken].length - 1;
            rewards = pairs[rewardToken][assetToken][batch].rewards;
        }
    }

    /**
     * @param rewardToken Address of the rewards being sold.
     * @param assetToken Address of the assets being purchased.
     * @param vault Address of the vault with the reward to asset pair.
     * @return batch Current liquidation batch index.
     * @return rewards Amount of reward tokens that are waiting to be swapped.
     */
    function pendingVaultRewards(
        address rewardToken,
        address assetToken,
        address vault
    ) external view returns (uint256 batch, uint256 rewards) {
        if (pairs[rewardToken][assetToken].length > 0) {
            batch = pairs[rewardToken][assetToken].length - 1;
            rewards = pairs[rewardToken][assetToken][batch].vaultRewards[vault];
        }
    }

    /**
     * @param batch Liquidation batch index from the previously executed `swap`.
     * @param rewardToken Address of the reward token that was sold.
     * @param assetToken Address of the asset token that was purchased.
     * @param vault Address of the vault with the reward to asset pair.
     * @return assets Amount of asset tokens purchased and not yet claimed.
     * It is zero if assets have already been claimed.
     */
    function purchasedAssets(
        uint256 batch,
        address rewardToken,
        address assetToken,
        address vault
    ) external view returns (uint256 assets) {
        require(pairs[rewardToken][assetToken].length > batch, "invalid batch");
        assets =
            (pairs[rewardToken][assetToken][batch].assets *
                pairs[rewardToken][assetToken][batch].vaultRewards[vault]) /
            pairs[rewardToken][assetToken][batch].rewards;
    }

    /***************************************
                Swap Functions
    ****************************************/
    function _beforeSwapValidation(address rewardToken, address assetToken)
        internal
        view
        returns (uint256 batch, uint256 rewards)
    {
        batch = pairs[rewardToken][assetToken].length;

        require(batch > 0, "invalid swap pair");
        // Current batch is length - 1
        unchecked {
            --batch;
        }
        rewards = pairs[rewardToken][assetToken][batch].rewards;

        require(rewards > 0, "no pending rewards");
    }

    function _afterSwapHook(
        address rewardToken,
        address assetToken,
        uint256 batch,
        uint256 assets
    ) internal {
        pairs[rewardToken][assetToken][batch].assets = SafeCast.toUint128(assets);
        // Create the next liquidation batch for this reward/asset pair
        pairs[rewardToken][assetToken].push();
    }

    /**
     * @notice Swap the collected rewards to desired asset.
     *
     * @dev Emits the `Swapped` event with the `batch`, `rewards` and `assets` return parameters.
     *
     * @param rewardToken Address of the rewards being sold.
     * @param assetToken Address of the assets being purchased.
     * @param minAssets Minimum amount of assets that can be returned from the swap.
     * @param data Is specific for the swap implementation. eg 1Inch, Cowswap, Matcha...
     */
    function swap(
        address rewardToken,
        address assetToken,
        uint256 minAssets,
        bytes memory data
    )
        external
        nonReentrant
        onlyKeeperOrGovernor
        returns (
            uint256 batch,
            uint256 rewards,
            uint256 assets
        )
    {
        (batch, rewards) = _beforeSwapValidation(rewardToken, assetToken);

        IERC20(rewardToken).safeIncreaseAllowance(address(syncSwapper), rewards);

        DexSwapData memory swapData = DexSwapData({
            fromAsset: rewardToken,
            fromAssetAmount: rewards,
            toAsset: assetToken,
            minToAssetAmount: minAssets,
            data: data
        });

        assets = syncSwapper.swap(swapData);

        _afterSwapHook(rewardToken, assetToken, batch, assets);

        emit Swapped(batch, rewards, assets);
    }

    /***************************************
                Async Functions
    ****************************************/

    function _initiateSwap(
        address rewardToken,
        address assetToken,
        bytes memory data
    ) internal returns (uint256 batch, uint256 rewards) {
        (batch, rewards) = _beforeSwapValidation(rewardToken, assetToken);

        DexSwapData memory swapData = DexSwapData({
            fromAsset: rewardToken,
            fromAssetAmount: rewards,
            toAsset: assetToken,
            minToAssetAmount: 0, // is not used on async dex
            data: data // data(bytes orderUid, bool transfer) for cow swap
        });

        //  initiates swap on-chain , then off-chain data should monitor when swap is done (fail or success) and call `settleSwap`
        asyncSwapper.initiateSwap(swapData);
        emit SwapInitiated(batch, rewards, 0);
    }

    /**
     * @notice Swap the collected rewards to desired asset.
     * Off-chain order must be created providing a "receiver" of the swap.
     *
     * @dev Emits the `Swapped` event with the `batch`, `rewards` and `assets` return parameters.
     *
     * @param rewardToken Address of the rewards being sold.
     * @param assetToken Address of the assets being purchased.
     * @param data Is specific for the swap implementation. eg Cowswap, Matcha...
     */
    function initiateSwap(
        address rewardToken,
        address assetToken,
        bytes memory data
    ) external nonReentrant onlyKeeperOrGovernor returns (uint256 batch, uint256 rewards) {
        (batch, rewards) = _initiateSwap(rewardToken, assetToken, data);
    }

    /**
     * @notice Swaps the collected rewards to desired assets.
     * Off-chain order must be created providing a "receiver" of the swap.
     *
     * @dev Emits the `Swapped` event with the `batch`, `rewards` and `assets` return parameters.
     *
     * @param rewardTokens Address of the rewards being sold.
     * @param assetTokens Address of the assets being purchased.
     * @param datas Is specific for the swap implementation. eg Cowswap, Matcha...
     */
    function initiateSwaps(
        address[] memory rewardTokens,
        address[] memory assetTokens,
        bytes[] memory datas
    )
        external
        nonReentrant
        onlyKeeperOrGovernor
        returns (uint256[] memory batchs, uint256[] memory rewards)
    {
        uint256 len = rewardTokens.length;
        require(
            len == rewardTokens.length &&
                len == assetTokens.length &&
                len == datas.length &&
                len > 0,
            "Wrong input"
        );
        batchs = new uint256[](len);
        rewards = new uint256[](len);

        for (uint256 i; i < len; ) {
            (batchs[i], rewards[i]) = _initiateSwap(rewardTokens[i], assetTokens[i], datas[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _settleSwap(
        address rewardToken,
        address assetToken,
        uint256 assets,
        bytes memory
    ) internal returns (uint256 batch, uint256 rewards) {
        (batch, rewards) = _beforeSwapValidation(rewardToken, assetToken);

        _afterSwapHook(rewardToken, assetToken, batch, assets);

        emit SwapSettled(batch, rewards, assets);
    }

    /**
     * @notice settles the last batch swap of rewards for assets.
     * `initiateSwap` must be called and the swap executed before `settleSwap`.
     *
     * @dev Emits the `SwapSettled` event with the `batch`, `rewards` and `assets` return parameters.
     *
     * @param rewardToken Address of the rewards being sold.
     * @param assetToken Address of the assets being purchased.
     * @param assets Amount of purchaed assets received from the swap.
     */
    function settleSwap(
        address rewardToken,
        address assetToken,
        uint256 assets,
        bytes memory data
    ) external onlyKeeperOrGovernor returns (uint256 batch, uint256 rewards) {
        (batch, rewards) = _settleSwap(rewardToken, assetToken, assets, data);
    }

    /**
     * @notice Swaps the collected rewards to desired assets.
     * initiateSwap must be called first before settleSwap
     *
     * @dev Emits the `SwapSettled` event with the `batch`, `rewards` and `assets` return parameters.
     *
     * @param rewardTokens Address of the rewards being sold.
     * @param assetTokens Address of the assets being purchased.
     * @param assets Amount of assets to swapped.
     * @param datas Custom data for the swap.
     */

    function settleSwaps(
        address[] memory rewardTokens,
        address[] memory assetTokens,
        uint256[] memory assets,
        bytes[] memory datas
    )
        external
        nonReentrant
        onlyKeeperOrGovernor
        returns (uint256[] memory batchs, uint256[] memory rewards)
    {
        uint256 len = rewardTokens.length;
        require(
            len == rewardTokens.length &&
                len == assetTokens.length &&
                len == assets.length &&
                len == datas.length &&
                len > 0,
            "Wrong input"
        );
        batchs = new uint256[](len);
        rewards = new uint256[](len);

        for (uint256 i; i < len; ) {
            (batchs[i], rewards[i]) = _settleSwap(
                rewardTokens[i],
                assetTokens[i],
                assets[i],
                datas[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    /***************************************
                Admin Functions
    ****************************************/
    /**
     * @notice Sets a new implementation of the DEX syncSwapper.
     * @param _syncSwapper Address of the DEX syncSwapper.
     */
    function setSyncSwapper(address _syncSwapper) external onlyGovernor {
        _setSyncSwapper(_syncSwapper);
    }

    function _setSyncSwapper(address _syncSwapper) internal {
        emit SwapperUpdated(address(syncSwapper), _syncSwapper);
        syncSwapper = IDexSwap(_syncSwapper);
    }

    /**
     * @notice Sets a new implementation of the DEX asyncSwapper.
     * @param _asyncSwapper Address of the DEX asyncSwapper.
     */
    function setAsyncSwapper(address _asyncSwapper) external onlyGovernor {
        _setAsyncSwapper(_asyncSwapper);
    }

    function _setAsyncSwapper(address _asyncSwapper) internal {
        emit SwapperUpdated(address(asyncSwapper), _asyncSwapper);
        asyncSwapper = IDexAsyncSwap(_asyncSwapper);
    }

    /**
     * @notice Governor rescues tokens from the liquidator in case a vault's donateToken is failing.
     */
    function rescueToken(address token, uint256 amount) external onlyGovernor {
        IERC20(token).safeTransfer(_governor(), amount);
    }

    /**
     * @notice Approves a token to be sold by the asynchronous swapper.
     * @param token Address of the token that is to be sold.
     */
    function approveAsyncSwapper(address token) external onlyGovernor {
        IERC20(token).safeApprove(address(asyncSwapper), 0);
        IERC20(token).safeApprove(address(asyncSwapper), type(uint256).max);
    }

    /**
     * @notice Revokes the asynchronous swapper from selling a token.
     * @param token Address of the token that is to no longer be sold.
     */
    function revokeAsyncSwapper(address token) external onlyGovernor {
        IERC20(token).safeApprove(address(asyncSwapper), 0);
    }
}