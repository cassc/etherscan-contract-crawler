// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./MakerStrategy.sol";
import "vesper-pools/contracts/interfaces/vesper/IPoolRewards.sol";

/// @title This strategy will deposit collateral token in Maker, borrow Dai and
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
        uint256 _highWater,
        uint256 _lowWater,
        string memory _name
    ) MakerStrategy(_pool, _cm, _swapManager, _vPool, _collateralType, _highWater, _lowWater, _name) {
        require(address(IVesperPool(_vPool).token()) == DAI, "not-a-valid-dai-pool");
    }

    /// @notice Claim VSP and convert to DAI
    function harvestVSP() external {
        address _poolRewards = IVesperPool(receiptToken).poolRewards();
        if (_poolRewards != address(0)) {
            IPoolRewards(_poolRewards).claimReward(address(this));
        }
        uint256 _vspAmount = IERC20(VSP).balanceOf(address(this));
        if (_vspAmount > 0) {
            _swapExactInput(VSP, DAI, _vspAmount);
        }
    }

    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        IERC20(DAI).safeApprove(address(receiptToken), _amount);
        IERC20(VSP).safeApprove(address(swapper), _amount);
    }

    function _depositDaiToLender(uint256 _amount) internal override {
        IVesperPool(receiptToken).deposit(_amount);
    }

    function _daiSupplied() internal view override returns (uint256) {
        return (IVesperPool(receiptToken).pricePerShare() * IVesperPool(receiptToken).balanceOf(address(this))) / 1e18;
    }

    function _withdrawDaiFromLender(uint256 _amount) internal override {
        uint256 _pricePerShare = IVesperPool(receiptToken).pricePerShare();
        uint256 _share = (_amount * 1e18) / _pricePerShare;
        // Should not withdraw less than requested amount
        _share = _amount > ((_share * _pricePerShare) / 1e18) ? _share + 1 : _share;
        IVesperPool(receiptToken).withdraw(Math.min(_share, IVesperPool(receiptToken).balanceOf(address(this))));
    }
}