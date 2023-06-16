// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;
import "../../Earn.sol";
import "../VesperStrategy.sol";
import "../../../interfaces/vesper/IVesperPool.sol";

/// @title This Earn strategy will deposit collateral token in a Vesper Grow Pool
/// and converts the yield to another Drip Token
// solhint-disable no-empty-blocks
abstract contract EarnVesperStrategy is VesperStrategy, Earn {
    using SafeERC20 for IERC20;

    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken,
        address _dripToken
    ) VesperStrategy(_pool, _swapManager, _receiptToken) Earn(_dripToken) {}

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override(VesperStrategy, Strategy) {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(vToken), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(VSP).safeApprove(address(swapManager.ROUTERS(i)), _amount);
            collateralToken.safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /**
     * @notice Calculate earning and withdraw it from Vesper Grow.
     * @param _totalDebt Total collateral debt of this strategy
     * @return profit in collateral token
     */
    function _realizeProfit(uint256 _totalDebt) internal virtual override(VesperStrategy, Strategy) returns (uint256) {
        _claimRewardsAndConvertTo(address(dripToken));
        uint256 _collateralBalance = _getCollateralBalance();
        if (_collateralBalance > _totalDebt) {
            _withdrawHere(_collateralBalance - _totalDebt);
        }
        _convertCollateralToDrip();
        _forwardEarning();
        return 0;
    }

    /// @notice Claim VSP rewards in underlying Grow Pool, if any
    function _claimRewardsAndConvertTo(address _toToken) internal virtual override(VesperStrategy, Strategy) {
        VesperStrategy._claimRewardsAndConvertTo(_toToken);
    }
}