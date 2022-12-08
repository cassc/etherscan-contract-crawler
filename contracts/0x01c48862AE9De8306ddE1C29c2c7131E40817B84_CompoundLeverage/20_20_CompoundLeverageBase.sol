// SPDX-License-Identifier: MIT
// Heavily inspired from CompoundLeverage strategy of Yearn. https://etherscan.io/address/0x4031afd3B0F71Bace9181E554A9E680Ee4AbE7dF#code

pragma solidity 0.8.9;

import "../../interfaces/compound/ICompound.sol";
import "../Strategy.sol";

/// @title This strategy will deposit collateral token in Compound and based on position
/// it will borrow same collateral token. It will use borrowed asset as supply and borrow again.
abstract contract CompoundLeverageBase is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    uint256 internal constant MAX_BPS = 10_000; //100%
    uint256 public minBorrowRatio = 5_000; // 50%
    uint256 public maxBorrowRatio = 6_000; // 60%
    uint256 internal constant COLLATERAL_FACTOR_LIMIT = 9_500; // 95%
    CToken internal cToken;

    Comptroller public immutable comptroller;
    address public rewardToken;

    event UpdatedBorrowRatio(
        uint256 previousMinBorrowRatio,
        uint256 newMinBorrowRatio,
        uint256 previousMaxBorrowRatio,
        uint256 newMaxBorrowRatio
    );

    constructor(
        address _pool,
        address _swapper,
        address _comptroller,
        address _rewardToken,
        address _receiptToken,
        string memory _name
    ) Strategy(_pool, _swapper, _receiptToken) {
        NAME = _name;
        require(_comptroller != address(0), "comptroller-address-is-zero");
        comptroller = Comptroller(_comptroller);
        rewardToken = _rewardToken;

        require(_receiptToken != address(0), "cToken-address-is-zero");
        cToken = CToken(_receiptToken);
    }

    /**
     * @notice Current borrow ratio, calculated as current borrow divide by max allowed borrow
     * Return value is based on basis points, i.e. 7500 = 75% ratio
     */
    function currentBorrowRatio() external view returns (uint256) {
        (uint256 _supply, uint256 _borrow) = getPosition();
        return _borrow == 0 ? 0 : (_borrow * MAX_BPS) / _supply;
    }

    /// @notice Return supply and borrow position. Position may return few block old value
    function getPosition() public view returns (uint256 _supply, uint256 _borrow) {
        (, uint256 _cTokenBalance, uint256 _borrowBalance, uint256 _exchangeRate) = cToken.getAccountSnapshot(
            address(this)
        );
        _supply = (_cTokenBalance * _exchangeRate) / 1e18;
        _borrow = _borrowBalance;
    }

    /// @inheritdoc Strategy
    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == address(cToken) || _token == address(collateralToken);
    }

    /// @inheritdoc Strategy
    function tvl() public view virtual override returns (uint256) {
        (uint256 _supply, uint256 _borrow) = getPosition();
        return collateralToken.balanceOf(address(this)) + _supply - _borrow;
    }

    /**
     * @dev Adjust position by normal leverage and deleverage.
     * @param _adjustBy Amount by which we want to increase or decrease _borrow
     * @param _shouldRepay True indicate we want to deleverage
     * @return amount Actual adjusted amount
     */
    function _adjustPosition(uint256 _adjustBy, bool _shouldRepay) internal returns (uint256 amount) {
        // We can get position via view function, as this function will be called after _calculateDesiredPosition
        (uint256 _supply, uint256 _borrow) = getPosition();

        // If no borrow then there is nothing to deleverage
        if (_borrow == 0 && _shouldRepay) {
            return 0;
        }

        uint256 collateralFactor = _getCollateralFactor();

        if (_shouldRepay) {
            amount = _normalDeleverage(_adjustBy, _supply, _borrow, collateralFactor);
        } else {
            amount = _normalLeverage(_adjustBy, _supply, _borrow, collateralFactor);
        }
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        collateralToken.safeApprove(address(cToken), _amount);
        IERC20(rewardToken).safeApprove(address(swapper), _amount);
    }

    /**
     * @dev Payback borrow before migration
     * @param _newStrategy Address of new strategy.
     */
    function _beforeMigration(address _newStrategy) internal virtual override {
        require(IStrategy(_newStrategy).token() == address(cToken), "wrong-receipt-token");
        minBorrowRatio = 0;
        // It will calculate amount to repay based on borrow limit and payback all
        _deposit();
    }

    function _borrowCollateral(uint256 _amount) internal virtual {
        require(cToken.borrow(_amount) == 0, "borrow-from-compound-failed");
    }

    /**
     * @notice Calculate borrow position based on borrow ratio, current supply, borrow, amount
     * being deposited or withdrawn.
     * @param _amount Collateral amount
     * @param _isDeposit Flag indicating whether we are depositing _amount or withdrawing
     * @return _position Amount of borrow that need to be adjusted
     * @return _shouldRepay Flag indicating whether _position is borrow amount or repay amount
     */
    function _calculateDesiredPosition(
        uint256 _amount,
        bool _isDeposit
    ) internal returns (uint256 _position, bool _shouldRepay) {
        uint256 _totalSupply = cToken.balanceOfUnderlying(address(this));
        uint256 _currentBorrow = cToken.borrowBalanceStored(address(this));
        // If minimum borrow limit set to 0 then repay borrow
        if (minBorrowRatio == 0) {
            return (_currentBorrow, true);
        }

        uint256 _supply = _totalSupply - _currentBorrow;

        // In case of withdraw, _amount can be greater than _supply
        uint256 _newSupply = _isDeposit ? _supply + _amount : _supply > _amount ? _supply - _amount : 0;

        // (supply * borrowRatio)/(BPS - borrowRatio)
        uint256 _borrowUpperBound = (_newSupply * maxBorrowRatio) / (MAX_BPS - maxBorrowRatio);
        uint256 _borrowLowerBound = (_newSupply * minBorrowRatio) / (MAX_BPS - minBorrowRatio);

        // If our current borrow is greater than max borrow allowed, then we will have to repay
        // some to achieve safe position else borrow more.
        if (_currentBorrow > _borrowUpperBound) {
            _shouldRepay = true;
            // If borrow > upperBound then it is greater than lowerBound too.
            _position = _currentBorrow - _borrowLowerBound;
        } else if (_currentBorrow < _borrowLowerBound) {
            _shouldRepay = false;
            // We can borrow more.
            _position = _borrowLowerBound - _currentBorrow;
        }
    }

    /// @notice Deposit collateral in Compound and adjust borrow position
    function _deposit() internal {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        (uint256 _position, bool _shouldRepay) = _calculateDesiredPosition(_collateralBalance, true);
        // Supply collateral to compound.
        _mint(_collateralBalance);

        // During reinvest, _shouldRepay will be false which indicate that we will borrow more.
        _position -= _doFlashLoan(_position, _shouldRepay);

        uint256 i;
        while (_position > 0 && i <= 6) {
            unchecked {
                _position -= _adjustPosition(_position, _shouldRepay);
                i++;
            }
        }
    }

    /**
     * @dev Aave flash is used only for withdrawal due to high fee compare to DyDx
     * @param _flashAmount Amount for flash loan
     * @param _shouldRepay Flag indicating we want to leverage or deleverage
     * @return Total amount we leverage or deleverage using flash loan
     */
    function _doFlashLoan(uint256 _flashAmount, bool _shouldRepay) internal virtual returns (uint256);

    /**
     * @notice Generate report for pools accounting and also send profit and any payback to pool.
     * @dev Call claimAndSwapRewards to convert rewards to collateral before calling this function.
     */
    function _generateReport() internal returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        (, , , , uint256 _totalDebt, , , uint256 _debtRatio, ) = IVesperPool(pool).strategy(address(this));

        // Invested collateral = supply - borrow
        uint256 _investedCollateral = cToken.balanceOfUnderlying(address(this)) -
            cToken.borrowBalanceStored(address(this));

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _investedCollateral + _collateralHere;

        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        } else {
            _loss = _totalDebt - _totalCollateral;
        }
        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_collateralHere < _profitAndExcessDebt) {
            uint256 _totalAmountToWithdraw = Math.min((_profitAndExcessDebt - _collateralHere), _investedCollateral);
            if (_totalAmountToWithdraw > 0) {
                _withdrawHere(_totalAmountToWithdraw);
                _collateralHere = collateralToken.balanceOf(address(this));
            }
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;

        // Handle scenario if debtRatio is zero and some supply left.
        // Remaining tokens are profit.
        if (_debtRatio == 0) {
            (uint256 _supply, uint256 _borrow) = getPosition();
            if (_supply > 0 && _borrow == 0) {
                // This will redeem all cTokens this strategy has
                _redeemUnderlying(MAX_UINT_VALUE);
                _profit += _supply;
            }
        }
    }

    /**
     * @notice Get Collateral Factor
     */
    function _getCollateralFactor() internal view virtual returns (uint256 _collateralFactor) {
        (, _collateralFactor, ) = comptroller.markets(address(cToken));
        // Take 95% of collateralFactor to avoid any rounding issue.
        _collateralFactor = (_collateralFactor * COLLATERAL_FACTOR_LIMIT) / MAX_BPS;
    }

    /**
     * @dev Compound support ETH as collateral not WETH. So ETH strategy can override
     * below functions and handle wrap/unwrap of WETH.
     */
    function _mint(uint256 _amount) internal virtual {
        require(cToken.mint(_amount) == 0, "supply-to-compound-failed");
    }

    /**
     * Deleverage: Reduce borrow to achieve safe position
     * @param _maxDeleverage Reduce borrow by this amount
     * @return _deleveragedAmount Amount we actually reduced
     */
    function _normalDeleverage(
        uint256 _maxDeleverage,
        uint256 _supply,
        uint256 _borrow,
        uint256 _collateralFactor
    ) internal returns (uint256 _deleveragedAmount) {
        uint256 _theoreticalSupply;

        if (_collateralFactor > 0) {
            // Calculate minimum supply required to support _borrow
            _theoreticalSupply = (_borrow * 1e18) / _collateralFactor;
        }

        _deleveragedAmount = _supply - _theoreticalSupply;

        if (_deleveragedAmount >= _borrow) {
            _deleveragedAmount = _borrow;
        }
        if (_deleveragedAmount >= _maxDeleverage) {
            _deleveragedAmount = _maxDeleverage;
        }

        _redeemUnderlying(_deleveragedAmount);
        _repayBorrow(_deleveragedAmount);
    }

    /**
     * Leverage: Borrow more
     * @param _maxLeverage Max amount to borrow
     * @return _leveragedAmount Amount we actually borrowed
     */
    function _normalLeverage(
        uint256 _maxLeverage,
        uint256 _supply,
        uint256 _borrow,
        uint256 _collateralFactor
    ) internal returns (uint256 _leveragedAmount) {
        // Calculate maximum we can borrow at current _supply
        uint256 theoreticalBorrow = (_supply * _collateralFactor) / 1e18;

        _leveragedAmount = theoreticalBorrow - _borrow;

        if (_leveragedAmount >= _maxLeverage) {
            _leveragedAmount = _maxLeverage;
        }
        _borrowCollateral(_leveragedAmount);
        _mint(collateralToken.balanceOf(address(this)));
    }

    function _rebalance() internal virtual override returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        (_profit, _loss, _payback) = _generateReport();
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _deposit();
    }

    function _redeemUnderlying(uint256 _amount) internal virtual {
        if (_amount == MAX_UINT_VALUE) {
            // Withdraw all cTokens
            require(cToken.redeem(cToken.balanceOf(address(this))) == 0, "withdraw-from-compound-failed");
        } else {
            // Withdraw underlying
            require(cToken.redeemUnderlying(_amount) == 0, "withdraw-from-compound-failed");
        }
    }

    function _repayBorrow(uint256 _amount) internal virtual {
        require(cToken.repayBorrow(_amount) == 0, "repay-to-compound-failed");
    }

    /// @dev Withdraw collateral here.
    function _withdrawHere(uint256 _amount) internal override {
        (uint256 _position, bool _shouldRepay) = _calculateDesiredPosition(_amount, false);
        if (_shouldRepay) {
            // Do deleverage by flash loan
            _position -= _doFlashLoan(_position, _shouldRepay);

            // If we still have _position to deleverage do it via normal deleverage
            uint256 i;
            while (_position > 0 && i <= 10) {
                unchecked {
                    _position -= _adjustPosition(_position, true);
                    i++;
                }
            }

            (uint256 _supply, uint256 _borrow) = getPosition();
            // If we are not able to deleverage enough
            if (_position > 0) {
                // Calculate redeemable at current borrow and supply.
                uint256 _supplyToSupportBorrow;
                if (maxBorrowRatio > 0) {
                    _supplyToSupportBorrow = (_borrow * MAX_BPS) / maxBorrowRatio;
                }
                // Current supply minus supply required to support _borrow at _maxBorrowRatio
                uint256 _redeemable = _supply - _supplyToSupportBorrow;
                if (_amount > _redeemable) {
                    _amount = _redeemable;
                }
            }
            // Position is 0 and amount > supply due to deleverage
            else if (_amount > _supply) {
                _amount = _supply;
            }
        }
        _redeemUnderlying(_amount);
    }

    /************************************************************************************************
     *                          Governor/admin/keeper function                                      *
     ***********************************************************************************************/

    /**
     * @notice Update upper and lower borrow ratio
     * @dev It is possible to set 0 as _minBorrowRatio to not borrow anything
     * @param _minBorrowRatio Minimum % we want to borrow
     * @param _maxBorrowRatio Maximum % we want to borrow
     */
    function updateBorrowRatio(uint256 _minBorrowRatio, uint256 _maxBorrowRatio) external onlyGovernor {
        // CollateralFactor is 1e18 based and borrow ratio is 1e4 based. Hence using 1e14 for conversion.
        require(_maxBorrowRatio < (_getCollateralFactor() / 1e14), "invalid-max-borrow-limit");
        require(_maxBorrowRatio > _minBorrowRatio, "max-should-be-higher-than-min");
        emit UpdatedBorrowRatio(minBorrowRatio, _minBorrowRatio, maxBorrowRatio, _maxBorrowRatio);
        minBorrowRatio = _minBorrowRatio;
        maxBorrowRatio = _maxBorrowRatio;
    }
}