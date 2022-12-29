// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/interfaces/vesper/IPoolRewards.sol";
import "./CompoundV3Xy.sol";

/// @title Deposit Collateral in Compound and earn interest by depositing borrowed token in a Vesper Pool.
contract CompoundV3VesperXy is CompoundV3Xy {
    using SafeERC20 for IERC20;

    // Destination Grow Pool for borrowed Token
    IVesperPool public immutable vPool;
    // VSP token address
    address public immutable vsp;

    constructor(
        address pool_,
        address swapper_,
        address compRewards_,
        address rewardToken_,
        address comet_,
        address borrowToken_,
        address vPool_,
        address vsp_,
        string memory name_
    ) CompoundV3Xy(pool_, swapper_, compRewards_, rewardToken_, comet_, borrowToken_, name_) {
        require(vsp_ != address(0), "vsp-address-is-zero");
        require(address(IVesperPool(vPool_).token()) == borrowToken, "invalid-grow-pool");
        vPool = IVesperPool(vPool_);
        vsp = vsp_;
    }

    /// @notice Gets amount of borrowed Y collateral in strategy + Y collateral amount deposited in vPool
    function borrowBalance() external view returns (uint256) {
        return IERC20(borrowToken).balanceOf(address(this)) + _getYTokensInProtocol();
    }

    /// @notice Claim VSP and convert to collateral token
    function harvestVSP() external {
        address _poolRewards = vPool.poolRewards();
        if (_poolRewards != address(0)) {
            IPoolRewards(_poolRewards).claimReward(address(this));
        }
        uint256 _vspAmount = IERC20(vsp).balanceOf(address(this));
        if (_vspAmount > 0) {
            _swapExactInput(vsp, address(collateralToken), _vspAmount);
        }
    }

    function isReservedToken(address token_) public view virtual override returns (bool) {
        return super.isReservedToken(token_) || token_ == address(vPool);
    }

    /// @notice After borrowing Y, deposit to Vesper Pool
    function _afterBorrowY(uint256 amount_) internal override {
        vPool.deposit(amount_);
    }

    function _approveToken(uint256 amount_) internal override {
        super._approveToken(amount_);
        IERC20(borrowToken).safeApprove(address(vPool), amount_);
        IERC20(vsp).safeApprove(address(swapper), amount_);
    }

    function _getYTokensInProtocol() internal view override returns (uint256) {
        return (vPool.pricePerShare() * vPool.balanceOf(address(this))) / 1e18;
    }

    /// @notice Withdraw _shares proportional to collateral _amount from vPool
    function _withdrawY(uint256 amount_) internal override {
        uint256 _pricePerShare = vPool.pricePerShare();
        uint256 _shares = (amount_ * 1e18) / _pricePerShare;
        _shares = amount_ > ((_shares * _pricePerShare) / 1e18) ? _shares + 1 : _shares;
        uint256 _maxShares = vPool.balanceOf(address(this));
        _shares = _shares > _maxShares ? _maxShares : _shares;
        if (_shares > 0) {
            vPool.withdraw(_shares);
        }
    }
}