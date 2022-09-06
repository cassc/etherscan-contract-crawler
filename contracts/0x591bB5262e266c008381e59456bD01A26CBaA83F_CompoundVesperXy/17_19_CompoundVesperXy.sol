// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/interfaces/vesper/IPoolRewards.sol";
import "./CompoundXy.sol";

/// @title Deposit Collateral in Compound and earn interest by depositing borrowed token in a Vesper Pool.
contract CompoundVesperXy is CompoundXy {
    using SafeERC20 for IERC20;

    // Destination Grow Pool for borrowed Token
    IVesperPool public immutable vPool;
    // VSP token address
    address public immutable vsp;

    constructor(
        address _pool,
        address _swapper,
        address _comptroller,
        address _rewardToken,
        address _receiptToken,
        address _borrowCToken,
        address _vPool,
        address _vsp,
        string memory _name
    ) CompoundXy(_pool, _swapper, _comptroller, _rewardToken, _receiptToken, _borrowCToken, _name) {
        require(_vsp != address(0), "vsp-address-is-zero");
        require(address(IVesperPool(_vPool).token()) == borrowToken, "invalid-grow-pool");
        vPool = IVesperPool(_vPool);
        vsp = _vsp;
    }

    /// @notice Gets amount of borrowed Y collateral in strategy + Y collateral amount deposited in vPool
    function borrowBalance() external view returns (uint256) {
        return _getBorrowBalance();
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

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return super.isReservedToken(_token) || _token == address(vPool);
    }

    /// @notice After borrowing Y, deposit to Vesper Pool
    function _afterBorrowY(uint256 _amount) internal override {
        vPool.deposit(_amount);
    }

    function _approveToken(uint256 _amount) internal override {
        super._approveToken(_amount);
        IERC20(borrowToken).safeApprove(address(vPool), _amount);
        IERC20(vsp).safeApprove(address(swapper), _amount);
    }

    /// @notice Before repaying Y, withdraw it from Vesper Pool
    function _beforeRepayY(uint256 _amount) internal override {
        _withdrawFromPool(_amount);
    }

    /// @notice Borrowed Y balance deposited in Vesper Pool
    function _getBorrowBalance() internal view override returns (uint256) {
        return
            IERC20(borrowToken).balanceOf(address(this)) +
            ((vPool.pricePerShare() * vPool.balanceOf(address(this))) / 1e18);
    }

    function _rebalanceBorrow(uint256 _excessBorrow) internal override {
        if (_excessBorrow > 0) {
            uint256 _borrowedHereBefore = IERC20(borrowToken).balanceOf(address(this));
            _withdrawFromPool(_excessBorrow);
            uint256 _borrowedHere = IERC20(borrowToken).balanceOf(address(this)) - _borrowedHereBefore;
            if (_borrowedHere > 0) {
                _safeSwapExactInput(borrowToken, address(collateralToken), _borrowedHere);
            }
        }
    }

    /// @notice Withdraw _shares proportional to collateral _amount from vPool
    function _withdrawFromPool(uint256 _amount) internal {
        uint256 _pricePerShare = vPool.pricePerShare();
        uint256 _shares = (_amount * 1e18) / _pricePerShare;
        _shares = _amount > ((_shares * _pricePerShare) / 1e18) ? _shares + 1 : _shares;

        uint256 _maxShares = vPool.balanceOf(address(this));
        vPool.withdraw(_shares > _maxShares ? _maxShares : _shares);
    }
}