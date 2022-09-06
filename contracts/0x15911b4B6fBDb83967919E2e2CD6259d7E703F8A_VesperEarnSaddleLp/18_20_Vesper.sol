// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "vesper-pools/contracts/interfaces/vesper/IVesperPool.sol";
import "vesper-pools/contracts/interfaces/vesper/IPoolRewards.sol";
import "../Strategy.sol";

/// @title This Strategy will deposit collateral token in a Vesper Grow Pool
abstract contract Vesper is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    address internal immutable vsp;

    // Note: Same as `receiptToken` but using this in order to save gas since it's `immutable` and `receiptToken` isn't
    IVesperPool internal immutable vToken;

    constructor(
        address pool_,
        address swapper_,
        address receiptToken_,
        address vsp_,
        string memory name_
    ) Strategy(pool_, swapper_, receiptToken_) {
        require(receiptToken_ != address(0), "null-receipt-token");
        vToken = IVesperPool(receiptToken_);
        NAME = name_;
        vsp = vsp_;
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address token_) public view override returns (bool) {
        return token_ == address(vToken) || token_ == address(collateralToken);
    }

    /// @notice Claim VSP and convert to collateral token
    function harvestVSP() external {
        address _poolRewards = vToken.poolRewards();
        if (_poolRewards != address(0)) {
            IPoolRewards(_poolRewards).claimReward(address(this));
        }
        uint256 _vspAmount = IERC20(vsp).balanceOf(address(this));
        if (_vspAmount > 0) {
            _swapExactInput(vsp, address(collateralToken), _vspAmount);
        }
    }

    /// @notice Returns collateral balance + collateral deposited to Vesper
    function tvl() external view override returns (uint256) {
        return collateralToken.balanceOf(address(this)) + _convertToAssets(vToken.balanceOf(address(this)));
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        address _swapper = address(swapper);
        collateralToken.safeApprove(address(vToken), amount_);
        collateralToken.safeApprove(_swapper, amount_);
        IERC20(vsp).safeApprove(_swapper, amount_);
    }

    //solhint-disable-next-line no-empty-blocks
    function _beforeMigration(address _newStrategy) internal override {}

    /// @dev Converts a share amount in its relative collateral for Vesper Grow Pool
    function _convertToAssets(uint256 shares_) internal view returns (uint256 _assets) {
        if (shares_ > 0) {
            uint256 _totalSupply = vToken.totalSupply();
            _assets = (_totalSupply > 0) ? (vToken.totalValue() * shares_) / _totalSupply : 0;
        }
    }

    /// @dev Converts a collateral amount in its relative shares for Vesper Grow Pool
    function _convertToShares(uint256 assets_) internal view returns (uint256 _shares) {
        if (assets_ > 0) {
            uint256 _totalValue = vToken.totalValue();
            _shares = (_totalValue > 0) ? (assets_ * vToken.totalSupply()) / _totalValue : 0;
        }
    }

    /// @notice Deposit collateral in Vesper Grow
    function _deposit() internal {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance > 0) {
            vToken.deposit(_collateralBalance);
        }
    }

    function _generateReport()
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _strategyDebt = IVesperPool(pool).totalDebtOf(address(this));

        uint256 _sharesHere = vToken.balanceOf(address(this));
        uint256 _collateralInVesper = _convertToAssets(_sharesHere);
        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _collateralHere + _collateralInVesper;

        if (_totalCollateral > _strategyDebt) {
            _profit = _totalCollateral - _strategyDebt;
        } else {
            _loss = _strategyDebt - _totalCollateral;
        }

        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_profitAndExcessDebt > _collateralHere) {
            uint256 _amountToWithdraw = Math.min((_profitAndExcessDebt - _collateralHere), _collateralInVesper);
            if (_amountToWithdraw > 0) {
                uint256 _sharesToBurn = Math.min(_convertToShares(_amountToWithdraw), _sharesHere);

                if (_sharesToBurn > 0) {
                    vToken.withdraw(_sharesToBurn);
                    _collateralHere = collateralToken.balanceOf(address(this));
                }
            }
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;
    }

    function _rebalance()
        internal
        virtual
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        (_profit, _loss, _payback) = _generateReport();
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _deposit();
    }

    /// @dev Withdraw collateral here. Do not transfer to pool
    function _withdrawHere(uint256 collateralAmount_) internal override {
        vToken.withdraw(_convertToShares(collateralAmount_));
    }
}