// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/interfaces/vesper/IPoolRewards.sol";
import "vesper-pools/contracts/Errors.sol";
import "../../interfaces/euler/IEuler.sol";
import "./EulerXy.sol";

// solhint-disable no-empty-blocks

/// @title Deposit Collateral in Euler and earn interest by depositing borrowed token in a Vesper Pool.
contract EulerVesperXy is EulerXy {
    using SafeERC20 for IERC20;

    // Destination Grow Pool for borrowed Token
    IVesperPool public immutable vPool;
    // VSP token address
    address public immutable vsp;

    constructor(
        address pool_,
        address swapper_,
        address euler_,
        IEulerMarkets eulerMarkets_,
        IExec eulerExec_,
        IEulDistributor rewardDistributor_,
        address rewardToken_,
        address borrowToken_,
        address vPool_,
        address vsp_,
        string memory name_
    )
        EulerXy(
            pool_,
            swapper_,
            euler_,
            eulerMarkets_,
            eulerExec_,
            rewardDistributor_,
            rewardToken_,
            borrowToken_,
            name_
        )
    {
        require(vsp_ != address(0), "vsp-address-is-zero");
        require(address(IVesperPool(vPool_).token()) == borrowToken, "invalid-grow-pool");
        vPool = IVesperPool(vPool_);
        vsp = vsp_;
    }

    /// @notice After borrowing Y, deposit to Vesper Pool
    function _afterBorrowY(uint256 amount_) internal virtual override {
        vPool.deposit(amount_);
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        IERC20(borrowToken).safeApprove(address(vPool), amount_);
        IERC20(vsp).safeApprove(address(swapper), amount_);
    }

    /// @notice Before repaying Y, withdraw it from Vesper Pool
    function _beforeRepayY(uint256 amount_) internal virtual override {
        _withdrawFromVesperPool(amount_);
    }

    /**
     * @dev Claim VSP rewards and swap for collateral tokens.
     * Keeper will claim EUL and this function will swap those for collateral.
     */
    function _claimAndSwapRewards() internal override {
        // Swap EUL for collateral
        uint256 _eulAmount = IERC20(rewardToken).balanceOf(address(this));
        if (_eulAmount > 0) {
            _safeSwapExactInput(rewardToken, address(collateralToken), _eulAmount);
        }

        // Claim and swap VSP
        address _poolRewards = vPool.poolRewards();
        if (_poolRewards != address(0)) {
            IPoolRewards(_poolRewards).claimReward(address(this));
        }
        uint256 _vspAmount = IERC20(vsp).balanceOf(address(this));
        if (_vspAmount > 0) {
            _safeSwapExactInput(vsp, address(collateralToken), _vspAmount);
        }
    }

    /// @notice Borrowed Y balance deposited in Vesper Pool
    function _getInvestedBorrowBalance() internal view virtual override returns (uint256) {
        return
            IERC20(borrowToken).balanceOf(address(this)) +
            ((vPool.pricePerShare() * vPool.balanceOf(address(this))) / 1e18);
    }

    /// @notice Swap excess borrow for more collateral when underlying  vPool is making profits
    function _rebalanceBorrow(uint256 excessBorrow_) internal virtual override {
        if (excessBorrow_ > 0) {
            _withdrawFromVesperPool(excessBorrow_);
            uint256 _borrowedHere = IERC20(borrowToken).balanceOf(address(this));
            if (_borrowedHere > 0) {
                _safeSwapExactInput(borrowToken, address(collateralToken), _borrowedHere);
            }
        }
    }

    /// @notice Withdraw _shares proportional to collateral amount_ from vPool
    function _withdrawFromVesperPool(uint256 amount_) internal {
        if (amount_ > 0) {
            uint256 _pricePerShare = vPool.pricePerShare();
            uint256 _shares = (amount_ * 1e18) / _pricePerShare;
            _shares = amount_ > ((_shares * _pricePerShare) / 1e18) ? _shares + 1 : _shares;
            vPool.withdraw(Math.min(_shares, vPool.balanceOf(address(this))));
        }
    }
}