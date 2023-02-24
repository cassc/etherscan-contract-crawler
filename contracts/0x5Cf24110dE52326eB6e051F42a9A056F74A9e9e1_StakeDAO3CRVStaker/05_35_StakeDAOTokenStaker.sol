// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../../interfaces/external/stakeDAO/IStakeCurveVault.sol";
import "../../interfaces/external/stakeDAO/ILiquidityGauge.sol";

import "../BorrowStaker.sol";

/// @title StakeDAOTokenStaker
/// @author Angle Labs, Inc.
/// @dev Borrow staker adapted to Curve LP tokens deposited on StakeDAO
abstract contract StakeDAOTokenStaker is BorrowStaker {
    error WithdrawFeeTooLarge();

    /// @notice Initializes the `BorrowStaker` for Stake DAO
    function initialize(ICoreBorrow _coreBorrow) external {
        string memory erc20Name = string(
            abi.encodePacked("Angle ", IERC20Metadata(address(asset())).name(), " Stake DAO Staker")
        );
        string memory erc20Symbol = string(abi.encodePacked("agstk-sd-", IERC20Metadata(address(asset())).symbol()));
        _initialize(_coreBorrow, erc20Name, erc20Symbol);
    }

    /// @inheritdoc BorrowStaker
    function claimableRewards(address from, IERC20 _rewardToken) external view override returns (uint256) {
        uint256 _totalSupply = totalSupply();
        uint256 newIntegral = _totalSupply != 0
            ? integral[_rewardToken] + (_rewardsToBeClaimed(_rewardToken) * BASE_36) / _totalSupply
            : integral[_rewardToken];
        uint256 newClaimable = (totalBalanceOf(from) * (newIntegral - integralOf[_rewardToken][from])) / BASE_36;
        return pendingRewardsOf[_rewardToken][from] + newClaimable;
    }

    // ============================= INTERNAL FUNCTIONS ============================

    /// @inheritdoc ERC20Upgradeable
    function _afterTokenTransfer(
        address from,
        address,
        uint256 amount
    ) internal virtual override {
        // Stake on StakeDAO if it is a deposit
        if (from == address(0)) {
            // Approve the vault contract for the Curve LP tokens
            _changeAllowance(asset(), address(_vault()), amount);
            // Deposit the Curve LP tokens into the vault contract and stake
            _vault().deposit(address(this), amount, true);
        }
    }

    /// @inheritdoc BorrowStaker
    function _withdrawFromProtocol(uint256 amount) internal override {
        if (_withdrawalFee() > 0) revert WithdrawFeeTooLarge();
        _vault().withdraw(amount);
    }

    /// @inheritdoc BorrowStaker
    /// @dev Should be overriden by implementation if there are more rewards
    function _claimGauges() internal override {
        _gauge().claim_rewards(address(this));
    }

    /// @inheritdoc BorrowStaker
    function _rewardsToBeClaimed(IERC20 rewardToken) internal view override returns (uint256 amount) {
        amount = _gauge().claimable_reward(address(this), address(rewardToken));
    }

    // ============================= VIRTUAL FUNCTIONS =============================

    /// @notice Get withdrawal fee from Vault (if any)
    function _withdrawalFee() internal view virtual returns (uint256) {
        return _vault().withdrawalFee();
    }

    /// @notice StakeDAO Vault address
    function _vault() internal pure virtual returns (IStakeCurveVault);

    /// @notice StakeDAO Gauge address
    function _gauge() internal pure virtual returns (ILiquidityGauge);
}