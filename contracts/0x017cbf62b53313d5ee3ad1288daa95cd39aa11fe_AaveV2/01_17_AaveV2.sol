// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./AaveV2Core.sol";
import "../../Strategy.sol";

/// @dev This strategy will deposit collateral token in Aave and earn interest.
contract AaveV2 is Strategy, AaveV2Core {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.1.0";

    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken,
        string memory _name
    ) Strategy(_pool, _swapManager, _receiptToken) AaveV2Core(_receiptToken) {
        NAME = _name;
    }

    /// @notice Initiate cooldown to unstake aave.
    function startCooldown() external onlyKeeper returns (bool) {
        return _startCooldown();
    }

    /// @notice Unstake Aave from stakedAave contract
    function unstakeAave() external onlyKeeper {
        _unstakeAave();
    }

    /**
     * @notice Report total value locked
     * @dev aToken and collateral are 1:1
     */
    function tvl() public view virtual override returns (uint256) {
        return aToken.balanceOf(address(this)) + collateralToken.balanceOf(address(this));
    }

    function isReservedToken(address _token) public view override returns (bool) {
        return _token == address(aToken) || _token == address(collateralToken);
    }

    /// @notice Large approval of token
    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        collateralToken.safeApprove(address(aaveLendingPool), _amount);
        IERC20(AAVE).safeApprove(address(swapper), _amount);
    }

    /**
     * @notice Transfer StakeAave to newStrategy
     * @param _newStrategy Address of newStrategy
     */
    function _beforeMigration(address _newStrategy) internal override {
        uint256 _stkAaveAmount = stkAAVE.balanceOf(address(this));
        if (_stkAaveAmount > 0) {
            IERC20(stkAAVE).safeTransfer(_newStrategy, _stkAaveAmount);
        }
    }

    /// @dev Claim Aave rewards
    function _claimRewards() internal virtual override returns (address, uint256) {
        return (AAVE, _claimAave());
    }

    /**
     * @dev Generate report for pools accounting and also send profit and any payback to pool.
     */
    function _generateReport() internal returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = aToken.balanceOf(address(this)) + _collateralHere;

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

        // Set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;
    }

    /**
     * @dev Generate report for pools accounting and also send profit and any payback to pool.
     */
    function _rebalance() internal virtual override returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        (_profit, _loss, _payback) = _generateReport();
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        // Pool may give fund to strategy. Deposit fund to generate yield.
        _deposit(address(collateralToken), collateralToken.balanceOf(address(this)));
    }

    function _withdrawHere(uint256 _amount) internal override {
        _safeWithdraw(address(collateralToken), address(this), _amount);
    }
}