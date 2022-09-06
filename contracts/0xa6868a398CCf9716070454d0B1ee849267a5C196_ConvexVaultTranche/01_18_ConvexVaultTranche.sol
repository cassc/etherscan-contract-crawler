pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/tranche/ConvexVaultTranche.sol)

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../../interfaces/external/convex/IConvexStakingProxyERC20Joint.sol";
import "../../../interfaces/external/convex/IConvexRewards.sol";
import "../../../interfaces/external/convex/IConvexVeFxsProxy.sol";
import "../../../interfaces/external/convex/IConvexBooster.sol";

import "./BaseTranche.sol";

/**
  * @notice A tranche which locks the LP into Convex's FRAX vaults (which in turn locks in the gauge)
  * Convex gets an 'owner' fee, and if they are supplying the veFXS boost they also get a booster fee
  * STAX gets a 'joint owner' fee from the convex vault.
  *
  * @dev It's possible to switch the veFXS booster from Convex's proxy <-->  STAX's proxy
  */
contract ConvexVaultTranche is BaseTranche {
    using SafeERC20 for IERC20;

    /// @notice The convex vault implementation to use when creating a new tranche.
    /// @dev If a new implementation id needs to be used (eg convex releases updated vault),
    /// then that will need a new Tranche template to be deployed.
    uint256 public immutable convexVaultImplementationId;

    /// @notice The STAX owner of the Joint Vault (co-owned with convex)
    /// @dev New tranches need to be whitelisted on this so it's able to create a new convex vault.
    address public immutable convexVaultOps;

    /// @notice Convex's immutable veFXS proxy contract which is whitelisted on FRAX
    IConvexVeFxsProxy public immutable convexVeFxsProxy;
    
    /// @notice The underlying convex vault which is created on initialization
    IConvexStakingProxyERC20Joint public convexVault;

    error NotSupported();

    function trancheType() external pure returns (TrancheType) {
        return TrancheType.CONVEX_VAULT;
    }

    function trancheVersion() external pure returns (uint256) {
        return 1;
    }

    constructor(uint256 _convexVaultImplementationId, address _convexVaultOps, address _convexVeFxsProxy) {
        convexVaultImplementationId = _convexVaultImplementationId;
        convexVaultOps = _convexVaultOps;
        convexVeFxsProxy = IConvexVeFxsProxy(_convexVeFxsProxy);
    }

    function _initialize() internal override {
        // The registry execute() is used to whitelist this new tranche on Convex Vault Ops
        // such that it's able to create a convex vault.
        registry.execute(
            convexVaultOps,
            0,
            abi.encodeWithSelector(bytes4(keccak256("setAllowedAddress(address,bool)")), address(this), true)
        );

        // Create the convex vault
        // This needs to be done via the Convex Booster contract - which is upgradeable
        // So lookup the current booster from their VeFXSProxy (which is whitelisted and won't change)
        convexVault = IConvexStakingProxyERC20Joint(
            IConvexBooster(convexVeFxsProxy.operator()).createVault(convexVaultImplementationId)
        );

        // Set the underlying gauge/staking token, pulled from the convex vault.
        underlyingGauge = IFraxGauge(convexVault.stakingAddress());
        stakingToken = IERC20(convexVault.stakingToken());

        // Set staking token allowance to max on initialization, rather than
        // one-by-one later.
        stakingToken.safeIncreaseAllowance(address(convexVault), type(uint256).max);
    }

    function _stakeLocked(uint256 liquidity, uint256 secs) internal override returns (bytes32) {
        convexVault.stakeLocked(liquidity, secs);

        // Need to access the underlying gauge to get the new lock info, it's not returned by the convex vault.
        IFraxGauge.LockedStake[] memory existingLockedStakes = underlyingGauge.lockedStakesOf(address(convexVault));
        uint256 lockedStakesLength = existingLockedStakes.length;
        return existingLockedStakes[lockedStakesLength-1].kek_id;
    }

    function _lockAdditional(bytes32 kek_id, uint256 addl_liq) internal override {
        convexVault.lockAdditional(kek_id, addl_liq);
        emit AdditionalLocked(address(this), kek_id, addl_liq);
    }

    function _withdrawLocked(bytes32 kek_id, address destination_address) internal override returns (uint256 withdrawnAmount) {      
        // The convex vault doesn't have a destination address option.
        // So first withdraw here, and then transfer to the destination
        uint256 stakingTokensBefore = stakingToken.balanceOf(address(this));
        convexVault.withdrawLocked(kek_id);
        unchecked {
            withdrawnAmount = stakingToken.balanceOf(address(this)) - stakingTokensBefore;
        }

        if (destination_address != address(this) && withdrawnAmount > 0) {
            stakingToken.safeTransfer(destination_address, withdrawnAmount);
        }
    }

    function _lockedStakes() internal view override returns (IFraxGauge.LockedStake[] memory) {
        return underlyingGauge.lockedStakesOf(address(convexVault));
    }

    function getRewards(address[] calldata rewardTokens) external override returns (uint256[] memory) {
        // The convex vault fees (co-owner & veFXS boost provider) get sent directly to LiquidityOps
        // (or some other STAX fee collector contract). 
        // The remaining rewards get sent to this contract.
        convexVault.getReward(true, rewardTokens);

        // Now forward the rewards to the tranche owner (liquidity ops)
        address _owner = owner();
        uint256[] memory rewardAmounts = new uint256[](rewardTokens.length);
        for (uint256 i=0; i<rewardTokens.length;) {
            uint256 bal = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (bal > 0) {
                IERC20(rewardTokens[i]).safeTransfer(_owner, bal);
            }
            rewardAmounts[i] = bal;
            unchecked { i++; }
        }

        emit RewardClaimed(address(this), rewardAmounts);
        return rewardAmounts;
    }

    /**
      * @notice Switch the convex vault's veFXS boost to a new proxy. This proxy must be either
      * the stax whitelisted veFXS proxy or the convex whitelisted veFXS proxy.
      * 
      * Calling convexVault.setVeFXSProxy() will:
      *   1. Turn off the convex vault on the old veFXS proxy (eg convex's veFXS proxy)
      *   2. Turn on the convex vault on the new veFXS proxy (eg stax's veFXS proxy)
      *   3. Set the new veFXS proxy on the underlying convex vault
      *
      * @dev Get the current convex booster from their whitelisted veFXS proxy, as it can change
      */
    function setVeFXSProxy(address _proxy) external override onlyOwner {
        IConvexBooster(convexVeFxsProxy.operator()).setVeFXSProxy(address(convexVault), _proxy);
        emit VeFXSProxySet(_proxy);
    }

    function toggleMigrator(address /*migrator_address*/) external pure override {
        // The Convex vault doesn't allow this to be set, and are not willing to add.
        // In this case that this happens, STAX will be paying owner fees until unlock, 
        // but can avoid paying booster fees by switching the vefxs proxy to STAX's veFXSProxy.
        // If very malicious, then FRAX may be willing to global unlock the gauge.
        revert NotSupported();
    }

    function getAllRewardTokens() external view returns (address[] memory) {
        address[] memory gaugeRewardTokens = underlyingGauge.getAllRewardTokens();

        IConvexRewards convexRewards = IConvexRewards(convexVault.rewards());
        if (convexRewards.active()) {
            // Need to construct a fixed size array and copy the underlying gauge + convex reward addresses.
            // Not particularly efficient, however this should only be called off-chain
            uint256 convexRewardsLength = convexRewards.rewardTokenLength();
            uint256 size = gaugeRewardTokens.length + convexRewardsLength;
            address[] memory allRewardTokens = new address[](size);

            uint256 index;
            for (; index < gaugeRewardTokens.length; index++) {
                allRewardTokens[index] = gaugeRewardTokens[index];
            }

            for (uint256 j=0; j < convexRewardsLength; j++) {
                allRewardTokens[index] = convexRewards.rewardTokens(j);
                index++;
            }
            return allRewardTokens;
        } else {
            // Just the underlying gauge reward addresses.
            return gaugeRewardTokens;
        }
    }

}