// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../Strategy.sol";
import "../../interfaces/alpha/ISafeBox.sol";

/// @title This strategy will deposit collateral token in Alpha SafeBox (ibXYZv2) and earn interest.
contract AlphaHomora is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    address public immutable rewardToken;
    ISafeBox internal immutable safeBox;

    constructor(
        address pool_,
        address swapper_,
        address rewardToken_,
        address receiptToken_,
        string memory name_
    ) Strategy(pool_, swapper_, receiptToken_) {
        require(rewardToken_ != address(0), "reward-token-is-null");
        require(receiptToken_ != address(0), "receipt-token-is-null");

        safeBox = ISafeBox(receiptToken_);
        rewardToken = rewardToken_;
        _setupCheck(pool_);
        NAME = name_;
    }

    function isReservedToken(address token_) public view virtual override returns (bool) {
        return token_ == receiptToken;
    }

    function tvl() external view override returns (uint256) {
        return _convertToCollateral(safeBox.balanceOf(address(this))) + collateralToken.balanceOf(address(this));
    }

    function updateTokenRate() external returns (uint256) {
        return safeBox.cToken().exchangeRateCurrent();
    }

    // solhint-disable no-empty-blocks
    function _afterWithdrawal() internal virtual {}

    /// @notice Approve all required tokens
    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        collateralToken.safeApprove(address(safeBox), amount_);
        IERC20(rewardToken).safeApprove(address(swapper), amount_);
    }

    // solhint-disable no-empty-blocks
    function _beforeMigration(address newStrategy_) internal virtual override {}

    function _convertToCollateral(uint256 _ibAmount) internal view returns (uint256) {
        return ((_ibAmount * safeBox.cToken().exchangeRateStored()) / 1e18);
    }

    function _convertToIb(uint256 _collateralAmount) internal view virtual returns (uint256) {
        return (_collateralAmount * 1e18) / safeBox.cToken().exchangeRateStored();
    }

    /// @notice Deposit collateral in Alpha
    function _deposit(uint256 amount_) internal virtual {
        if (amount_ > 0) {
            safeBox.deposit(amount_);
        }
    }

    /**
     * @dev Generate profit, loss and payback statement. Also claim rewards.
     */
    function _generateReport() internal virtual returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        // Convert reward tokens into collateral tokens
        uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this));
        if (_rewardAmount > 0) {
            _safeSwapExactInput(rewardToken, address(collateralToken), _rewardAmount);
        }

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _collateralHere + _convertToCollateral(safeBox.balanceOf(address(this)));
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
    }

    /**
     * @dev Generate report for pools accounting and report earning statement to pool.
     */
    function _rebalance() internal virtual override returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        (_profit, _loss, _payback) = _generateReport();
        // Report earning statement to pool
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        // After reportEarning strategy may get more collateral from pool. Deposit those.
        _deposit(collateralToken.balanceOf(address(this)));
    }

    function _setupCheck(address _pool) internal view virtual {
        require(address(IVesperPool(_pool).token()) == address(safeBox.uToken()), "u-token-mismatch");
    }

    function _withdrawHere(uint256 _collateralAmount) internal override {
        uint256 _ibBalance = safeBox.balanceOf(address(this));
        uint256 _ibToWithdraw = _convertToIb(_collateralAmount);
        // Inverse calculation to make sure required amount can be withdrawn
        if (_collateralAmount > _convertToCollateral(_ibToWithdraw)) {
            _ibToWithdraw += 1;
        }
        if (_ibToWithdraw > _ibBalance) {
            _ibToWithdraw = _ibBalance;
        }
        safeBox.withdraw(_ibToWithdraw);
        _afterWithdrawal();
    }

    /************************************************************************************************
     *                          Governor/admin/keeper function                                      *
     ***********************************************************************************************/

    function claimUTokenReward(uint256 amount_, bytes32[] memory proof_) external onlyKeeper {
        safeBox.claim(amount_, proof_);
    }
}