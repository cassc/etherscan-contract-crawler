// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./MakerStrategy.sol";
import "../../interfaces/vesper/IPoolRewards.sol";

/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in Vesper DAI pool to earn interest.
contract VesperMakerStrategy is MakerStrategy {
    using SafeERC20 for IERC20;
    address internal constant VSP = 0x1b40183EFB4Dd766f11bDa7A7c3AD8982e998421;

    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _vPool,
        bytes32 _collateralType,
        string memory _name
    ) MakerStrategy(_pool, _cm, _swapManager, _vPool, _collateralType, _name) {
        require(address(IVesperPool(_vPool).token()) == DAI, "not-a-valid-dai-pool");
    }

    function _approveToken(uint256 _amount) internal override {
        super._approveToken(_amount);
        IERC20(DAI).safeApprove(address(receiptToken), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(VSP).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    function _getDaiBalance() internal view override returns (uint256) {
        return (IVesperPool(receiptToken).pricePerShare() * IVesperPool(receiptToken).balanceOf(address(this))) / 1e18;
    }

    function _depositDaiToLender(uint256 _amount) internal override {
        IVesperPool(receiptToken).deposit(_amount);
    }

    function _withdrawDaiFromLender(uint256 _amount) internal override {
        uint256 _pricePerShare = IVesperPool(receiptToken).pricePerShare();
        uint256 _share = (_amount * 1e18) / _pricePerShare;
        // Should not withdraw less than requested amount
        _share = _amount > ((_share * _pricePerShare) / 1e18) ? _share + 1 : _share;
        IVesperPool(receiptToken).whitelistedWithdraw(_share);
    }

    function _rebalanceDaiInLender() internal virtual override {
        uint256 _daiDebt = cm.getVaultDebt(address(this));
        uint256 _daiBalance = _getDaiBalance();
        if (_daiBalance > _daiDebt) {
            _withdrawDaiFromLender(_daiBalance - _daiDebt);
        }
    }

    /// @notice Claim rewardToken from lender and convert it into DAI
    function _claimRewardsAndConvertTo(address _toToken) internal virtual override {
        uint256 _vspAmount = IERC20(VSP).balanceOf(address(this));
        if (_vspAmount > 0) {
            _safeSwap(VSP, _toToken, _vspAmount, 1);
        }
    }
}