pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/tranche/DirectTranche.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./BaseTranche.sol";

/**
  * @notice A pass through tranche to the underlying gauge
  * @dev Use where STAX wants a direct position on the gauge, and will always use
  * it's own veFXS
  */
contract DirectTranche is BaseTranche {
    using SafeERC20 for IERC20;

    /// @notice The underlying gauge and staking token, set at construction 
    /// @dev New cloned instances use these fixed addresses.
    // immutable such that it persists in the bytecode of the template.
    address public immutable _underlyingGaugeAddress;
    address public immutable _stakingTokenAddress;

    constructor(address _underlyingGauge, address _stakingToken) {
        _underlyingGaugeAddress = _underlyingGauge;
        _stakingTokenAddress = _stakingToken;
    }

    function trancheType() external pure returns (TrancheType) {
        return TrancheType.DIRECT;
    }

    function trancheVersion() external pure returns (uint256) {
        return 1;
    }

    function _initialize() internal override {
        underlyingGauge = IFraxGauge(_underlyingGaugeAddress);
        stakingToken = IERC20(_stakingTokenAddress);

        // Set allowance to max on initialization, rather than
        // one-by-one later.
        stakingToken.safeIncreaseAllowance(address(underlyingGauge), type(uint256).max);
    }

    function _stakeLocked(uint256 liquidity, uint256 secs) internal override returns (bytes32) {
        underlyingGauge.stakeLocked(liquidity, secs);

        // Need to access the underlying gauge to get the new lock info, it's not returned by the stakeLocked function.
        IFraxGauge.LockedStake[] memory existingLockedStakes = underlyingGauge.lockedStakesOf(address(this));
        uint256 lockedStakesLength = existingLockedStakes.length;
        return existingLockedStakes[lockedStakesLength-1].kek_id;
    }

    function _lockAdditional(bytes32 kek_id, uint256 addl_liq) internal override {
        underlyingGauge.lockAdditional(kek_id, addl_liq);
        emit AdditionalLocked(address(this), kek_id, addl_liq);
    }

    function _withdrawLocked(bytes32 kek_id, address destination_address) internal override returns (uint256 withdrawnAmount) {      
        uint256 stakingTokensBefore = stakingToken.balanceOf(destination_address);
        underlyingGauge.withdrawLocked(kek_id, destination_address);
        unchecked {
            withdrawnAmount = stakingToken.balanceOf(destination_address) - stakingTokensBefore;
        }
    }

    function _lockedStakes() internal view override returns (IFraxGauge.LockedStake[] memory) {
        return underlyingGauge.lockedStakesOf(address(this));
    }

    function getRewards(address[] calldata /*rewardTokens*/) external override returns (uint256[] memory rewardAmounts) {
        // Rather than collecing rewards in the DirectTranche first, and then forwarding onto the owner (LiquidityOps)
        // - requiring 2x transfers for each token, the underlying gauge allows us to specify the
        // destination address when calling getReward().
        //
        // So we have them sent directly to owner (LiquditiyOps)
        rewardAmounts = underlyingGauge.getReward(owner());
        emit RewardClaimed(address(this), rewardAmounts);
    }

    function setVeFXSProxy(address _proxy) external override onlyOwner {
        underlyingGauge.stakerSetVeFXSProxy(_proxy);
        emit VeFXSProxySet(_proxy);
    }

    function toggleMigrator(address migrator_address) external override onlyOwner {
        underlyingGauge.stakerToggleMigrator(migrator_address);
        emit MigratorToggled(migrator_address);
    }

    function getAllRewardTokens() external view returns (address[] memory) {
        return underlyingGauge.getAllRewardTokens();
    }

}