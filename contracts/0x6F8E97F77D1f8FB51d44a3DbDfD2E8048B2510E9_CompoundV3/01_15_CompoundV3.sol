// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../Strategy.sol";
import "../../../interfaces/compound/ICompoundV3.sol";

/// @title This strategy will deposit base asset i.e. USDC in Compound V3 and earn interest.
contract CompoundV3 is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.1.0";

    IComet public immutable comet;
    IRewards public immutable compRewards;
    address public immutable rewardToken;

    constructor(
        address pool_,
        address swapper_,
        address compRewards_,
        address rewardToken_,
        address comet_,
        string memory name_
    ) Strategy(pool_, swapper_, comet_) {
        require(comet_ != address(0), "comet-address-is-zero");
        require(compRewards_ != address(0), "rewards-address-is-zero");
        require(rewardToken_ != address(0), "reward-token-address-is-zero");
        comet = IComet(comet_);
        compRewards = IRewards(compRewards_);
        rewardToken = rewardToken_;
        NAME = name_;
    }

    function isReservedToken(address token_) public view virtual override returns (bool) {
        return token_ == address(comet);
    }

    function tvl() external view override returns (uint256) {
        return comet.balanceOf(address(this)) + collateralToken.balanceOf(address(this));
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        collateralToken.safeApprove(address(comet), amount_);
        IERC20(rewardToken).safeApprove(address(swapper), amount_);
    }

    //solhint-disable-next-line no-empty-blocks
    function _beforeMigration(address newStrategy_) internal virtual override {}

    /// @dev Claim COMP
    function _claimRewards() internal override returns (address, uint256) {
        compRewards.claim(address(comet), address(this), true);
        return (rewardToken, IERC20(rewardToken).balanceOf(address(this)));
    }

    /**
     * @dev Deposit collateral in Compound.
     */
    function _deposit(uint256 _amount) internal virtual {
        if (_amount > 0) {
            comet.supply(address(collateralToken), _amount);
        }
    }

    function _getAvailableLiquidity() internal view returns (uint256) {
        uint256 _totalSupply = comet.totalSupply();
        uint256 _totalBorrow = comet.totalBorrow();
        return _totalSupply > _totalBorrow ? _totalSupply - _totalBorrow : 0;
    }

    /**
     * @dev Generate report for pools accounting and also send profit and any payback to pool.
     */
    function _rebalance() internal virtual override returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _collateralHere + comet.balanceOf(address(this));
        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        } else {
            _loss = _totalDebt - _totalCollateral;
        }

        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_profitAndExcessDebt > _collateralHere) {
            _withdrawHere(_profitAndExcessDebt - _collateralHere);
            _collateralHere = collateralToken.balanceOf(address(this));
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        // After reportEarning strategy may get more collateral from pool. Deposit those in Compound.
        _deposit(collateralToken.balanceOf(address(this)));
    }

    /// @dev Withdraw collateral here. Do not transfer to pool
    function _withdrawHere(uint256 _amount) internal override {
        // Get minimum of _amount and _available collateral and _availableLiquidity
        uint256 _withdrawAmount = Math.min(_amount, Math.min(comet.balanceOf(address(this)), _getAvailableLiquidity()));
        comet.withdraw(address(collateralToken), _withdrawAmount);
    }
}