// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/interfaces/vesper/IVesperPool.sol";
import "../../VesperRewards.sol";
import "./AaveV2Xy.sol";

/// @title Deposit Collateral in Aave and earn interest by depositing borrowed token in a Vesper Pool.
contract AaveV2VesperXy is AaveV2Xy {
    using SafeERC20 for IERC20;

    // Destination Grow Pool for borrowed Token
    IVesperPool public immutable vPool;

    constructor(
        address _pool,
        address _swapper,
        address _rewardToken,
        address _receiptToken,
        address _borrowToken,
        address _vPool,
        string memory _name
    ) AaveV2Xy(_pool, _swapper, _rewardToken, _receiptToken, _borrowToken, _name) {
        require(address(IVesperPool(_vPool).token()) == borrowToken, "invalid-grow-pool");
        vPool = IVesperPool(_vPool);
    }

    /// @notice After borrowing Y, deposit to Vesper Pool
    function _afterBorrowY(uint256 _amount) internal virtual override {
        vPool.deposit(_amount);
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        IERC20(borrowToken).safeApprove(address(vPool), _amount);
        VesperRewards._approveToken(vPool, swapper, _amount);
    }

    /// @notice Before repaying Y, withdraw it from Vesper Pool
    function _beforeRepayY(uint256 _amount) internal virtual override {
        _withdrawFromVesperPool(_amount);
    }

    /// @dev Claim AAVE and VSP and swap to collateral
    function _claimAndSwapRewards() internal override {
        // Claim and swap AAVE
        uint256 _aaveAmount = _claimAave();
        if (_aaveAmount > 0) {
            _safeSwapExactInput(AAVE, address(collateralToken), _aaveAmount);
        }
        VesperRewards._claimAndSwapRewards(vPool, swapper, address(collateralToken));
    }

    /// @notice Borrowed Y balance deposited in Vesper Pool
    function _getInvestedBorrowBalance() internal view virtual override returns (uint256) {
        return
            IERC20(borrowToken).balanceOf(address(this)) +
            ((vPool.pricePerShare() * vPool.balanceOf(address(this))) / 1e18);
    }

    /// @notice Swap excess borrow for more collateral when underlying VSP pool is making profits
    function _rebalanceBorrow(uint256 _excessBorrow) internal virtual override {
        if (_excessBorrow > 0) {
            _withdrawFromVesperPool(_excessBorrow);
            uint256 _borrowedHere = IERC20(borrowToken).balanceOf(address(this));
            if (_borrowedHere > 0) {
                _safeSwapExactInput(borrowToken, address(collateralToken), _borrowedHere);
            }
        }
    }

    /// @notice Withdraw _shares proportional to collateral _amount from vPool
    function _withdrawFromVesperPool(uint256 _amount) internal {
        if (_amount > 0) {
            uint256 _pricePerShare = vPool.pricePerShare();
            uint256 _shares = (_amount * 1e18) / _pricePerShare;
            _shares = _amount > ((_shares * _pricePerShare) / 1e18) ? _shares + 1 : _shares;
            vPool.withdraw(Math.min(_shares, vPool.balanceOf(address(this))));
        }
    }
}