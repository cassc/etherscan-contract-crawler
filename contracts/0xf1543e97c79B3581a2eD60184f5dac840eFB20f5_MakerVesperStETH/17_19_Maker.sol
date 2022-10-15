// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/Math.sol";
import "../Strategy.sol";
import "../../interfaces/vesper/ICollateralManager.sol";

/// @title This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in other lending pool to earn interest.
abstract contract Maker is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    ICollateralManager public immutable cm;
    bytes32 public immutable collateralType;
    uint256 public highWater;
    uint256 public lowWater;
    uint256 public immutable decimalConversionFactor;
    uint256 private constant WAT = 10**16;

    constructor(
        address _pool,
        address _cm,
        address _swapper,
        address _receiptToken,
        bytes32 _collateralType,
        uint256 _highWater,
        uint256 _lowWater,
        string memory _name
    ) Strategy(_pool, _swapper, _receiptToken) {
        require(_cm != address(0), "cm-address-is-zero");
        collateralType = _collateralType;
        cm = ICollateralManager(_cm);
        _updateBalancingFactor(_highWater, _lowWater);
        // Assuming token supports 18 or less decimals.
        uint256 _decimals = IERC20Metadata(address(IVesperPool(_pool).token())).decimals();
        decimalConversionFactor = 10**(18 - _decimals);
        NAME = _name;
    }

    /// @notice Convert from 18 decimals to token defined decimals.
    function convertFrom18(uint256 _amount) public view returns (uint256) {
        return _amount / decimalConversionFactor;
    }

    /// @notice Convert from 18 decimals to token defined decimals.
    function convertTo18(uint256 _amount) public view returns (uint256) {
        return _amount * decimalConversionFactor;
    }

    /// @notice Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == receiptToken || _token == address(collateralToken);
    }

    /**
     * @notice Returns true if pool is underwater.
     * @notice Underwater - If debt is greater than (earning of pool + DAI in pool + some wei buffer).
     * @notice Earning - Sum of DAI balance and DAI from accrued reward, if any, in lending pool.
     */
    function isUnderwater() external view virtual returns (bool) {
        return cm.getVaultDebt(address(this)) > (_daiSupplied() + IERC20(DAI).balanceOf(address(this)));
    }

    /// @notice Returns total collateral locked in the strategy
    function tvl() external view override returns (uint256) {
        return convertFrom18(cm.getVaultBalance(address(this))) + collateralToken.balanceOf(address(this));
    }

    function vaultNum() external view returns (uint256) {
        return cm.vaultNum(address(this));
    }

    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        IERC20(DAI).safeApprove(address(cm), _amount);
        collateralToken.safeApprove(address(cm), _amount);
        collateralToken.safeApprove(address(swapper), _amount);
        IERC20(DAI).safeApprove(address(swapper), _amount);
    }

    /**
     * @dev It will be called during migration. Transfer Maker vault ownership to new strategy
     * @param _newStrategy Address of new strategy.
     */
    function _beforeMigration(address _newStrategy) internal virtual override {
        require(Maker(_newStrategy).collateralType() == collateralType, "collateral-type-must-be-the-same");
        cm.transferVaultOwnership(_newStrategy);
    }

    function _calculateSafeBorrowPosition(
        uint256 _collateralLocked, // All collateral are 18 decimal in Maker
        uint256 _currentDaiDebt, // DAI is 18 decimal
        uint256 _collateralUsdRate,
        uint256 _minimumDebt
    ) internal view returns (uint256 _daiToRepay, uint256 _daiToBorrow) {
        uint256 _safeDebt = (_collateralLocked * _collateralUsdRate) / highWater;
        if (_safeDebt < _minimumDebt) {
            _daiToRepay = _currentDaiDebt;
        } else {
            uint256 _unSafeDebt = (_collateralLocked * _collateralUsdRate) / lowWater;
            if (_currentDaiDebt > _unSafeDebt) {
                // Being below low water brings risk of liquidation in Maker.
                // Withdraw DAI from Lender and deposit in Maker
                // highWater > lowWater hence _safeDebt < unSafeDebt
                _daiToRepay = _currentDaiDebt - _safeDebt;
            } else if (_currentDaiDebt < _safeDebt) {
                _daiToBorrow = _safeDebt - _currentDaiDebt;
            }
        }
    }

    /**
     * @notice Convert amount to wrapped (i.e. asset to shares)
     * @dev Only used when dealing with wrapped token as collateral (e.g. wstETH)
     */
    function _convertToWrapped(uint256 _amount) internal virtual returns (uint256 _wrappedAmount) {
        _wrappedAmount = _amount;
    }

    function _depositDaiToLender(uint256 _amount) internal virtual;

    // Dai supplied to other protocol to generate yield in DAI.
    function _daiSupplied() internal view virtual returns (uint256);

    function _moveDaiToMaker(uint256 _amount) internal {
        if (_amount > 0) {
            _withdrawDaiFromLender(_amount);
            cm.payback(_amount);
        }
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
        (
            uint256 _wrappedCollateralInVault18,
            uint256 _currentDaiDebt,
            uint256 _collateralUsdRate,
            ,
            uint256 _minimumDaiDebt
        ) = cm.getVaultInfo(address(this));
        _payback = IVesperPool(pool).excessDebt(address(this));
        uint256 withdrawFromVault;
        if (_payback > 0) {
            withdrawFromVault = _convertToWrapped(_payback);
        }
        // Assets in maker is always in 18 decimal.
        {
            uint256 _wrappedCollateralInVault = convertFrom18(_wrappedCollateralInVault18);
            uint256 _strategyDebtInWrapped = _convertToWrapped(IVesperPool(pool).totalDebtOf(address(this)));
            if (_wrappedCollateralInVault > _strategyDebtInWrapped) {
                withdrawFromVault += _wrappedCollateralInVault - _strategyDebtInWrapped;
            }
            if (withdrawFromVault > _wrappedCollateralInVault) {
                withdrawFromVault = _wrappedCollateralInVault;
            }
        }
        // remaining _collateralInVault
        _wrappedCollateralInVault18 -= convertTo18(withdrawFromVault); // Collateral in Maker vault is always 18 decimal.

        // Calculate daiToRepay or daiToBorrow considering current collateral in Vault, payback, collateralUsdRate
        (uint256 _daiToRepay, uint256 _daiToBorrow) = _calculateSafeBorrowPosition(
            _wrappedCollateralInVault18,
            _currentDaiDebt,
            _collateralUsdRate,
            _minimumDaiDebt
        );
        uint256 _daiToWithdraw = _daiToRepay;

        uint256 _daiInLender = _daiSupplied();
        if (_daiInLender > _currentDaiDebt) {
            // Yield generated in DAI. Withdraw these yield to convert to collateral.
            _daiToWithdraw += _daiInLender - _currentDaiDebt;
        }
        if (_daiToWithdraw > 0) {
            // This can withdraw less than requested amount.  This is not problem as long as Dai here >= _daiToRepay. Profit earned in DAI can be reused for _daiToRepay.
            _withdrawDaiFromLender(_daiToWithdraw);
        }

        if (_daiToRepay > 0) {
            cm.payback(_daiToRepay);
            _currentDaiDebt -= _daiToRepay;
        }
        // Dai paid back by now. Good to withdraw excessDebt in collateral.
        if (withdrawFromVault > 0) {
            cm.withdrawCollateral(withdrawFromVault);
            _unwrap(withdrawFromVault);
        }

        // All remaining dai here is profit.
        uint256 _profitInDai = IERC20(DAI).balanceOf(address(this));
        if (_profitInDai > 0) {
            // calling safeSwap to not revert in case profit conversion to collateralToken fails. Let Dai remains here. It doesn't harm overall.
            _safeSwapExactInput(DAI, address(collateralToken), _profitInDai);
        }

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        _payback = Math.min(_payback, _collateralHere);
        if (_collateralHere > _payback) {
            _profit = _collateralHere - _payback;
        }

        // Pool expect this contract has _profit + _payback in the contract. This method would revert if collateral.balanceOf(strategy) < (_profit + _excessDebt);
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);

        // Pool may send some collateral after reporting earning.
        _collateralHere = collateralToken.balanceOf(address(this));
        if (_collateralHere > 0) {
            uint256 _wrappedHere = _wrap(_collateralHere);
            cm.depositCollateral(_wrappedHere);
            _wrappedCollateralInVault18 += convertTo18(_wrappedHere);
            (, _daiToBorrow) = _calculateSafeBorrowPosition(
                _wrappedCollateralInVault18,
                _currentDaiDebt,
                _collateralUsdRate,
                _minimumDaiDebt
            );
        }

        if (_daiToBorrow > 100e18) {
            // borrow only if its above dust
            cm.borrow(_daiToBorrow);
            _depositDaiToLender(_daiToBorrow);
        }
    }

    function _resurface(uint256 _maximumCollateralForDaiSwap) internal virtual {
        uint256 _totalDaiBalance = _daiSupplied() + IERC20(DAI).balanceOf(address(this));
        uint256 _daiDebt = cm.getVaultDebt(address(this));
        require(_daiDebt > _totalDaiBalance, "pool-is-above-water");
        uint256 _daiNeeded = _daiDebt - _totalDaiBalance;
        uint256 _collateralNeeded = swapper.getAmountIn(address(collateralToken), DAI, _daiNeeded);
        require(_collateralNeeded <= _maximumCollateralForDaiSwap, "collateral-require-too-high");
        if (_collateralNeeded > 0) {
            uint256 _wrappedNeeded = _convertToWrapped(_collateralNeeded);
            if (_wrappedNeeded > 0) {
                cm.withdrawCollateral(_wrappedNeeded);
                _collateralNeeded = _unwrap(_wrappedNeeded);
                swapper.swapExactOutput(address(collateralToken), DAI, _daiNeeded, _collateralNeeded, address(this));
                cm.payback(IERC20(DAI).balanceOf(address(this)));
                IVesperPool(pool).reportLoss(_collateralNeeded);
            }
        }
    }

    /**
     * @notice Unwraps collateral token
     * @dev Only used when dealing with wrapped token as collateral (e.g. wstETH)
     */
    function _unwrap(uint256 _amount) internal virtual returns (uint256 _unwrappedAmount) {
        _unwrappedAmount = _amount;
    }

    function _updateBalancingFactor(uint256 _highWater, uint256 _lowWater) internal {
        require(_lowWater > 0, "lowWater-is-zero");
        require(_highWater > _lowWater, "highWater-less-than-lowWater");
        highWater = _highWater * WAT;
        lowWater = _lowWater * WAT;
    }

    function _withdrawDaiFromLender(uint256 _amount) internal virtual;

    /**
     * @notice Wraps collateral token
     * @dev Only used when dealing with wrapped token as collateral (e.g. wstETH)
     */
    function _wrap(uint256 _amount) internal virtual returns (uint256 _wrappedAmount) {
        _wrappedAmount = _amount;
    }

    function _withdrawHere(uint256 _amount) internal virtual override {
        _amount = _convertToWrapped(_amount);

        (
            uint256 collateralLocked,
            uint256 debt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        ) = cm.whatWouldWithdrawDo(address(this), _amount);
        if (debt > 0 && collateralRatio < lowWater) {
            // If this withdraw results in Low Water scenario.
            uint256 maxDebt = (collateralLocked * collateralUsdRate) / highWater;
            if (maxDebt < minimumDebt) {
                // This is Dusting scenario
                _moveDaiToMaker(debt);
            } else if (maxDebt < debt) {
                _moveDaiToMaker(debt - maxDebt);
            }
        }
        cm.withdrawCollateral(_amount);
        _unwrap(_amount);
    }

    /******************************************************************************
     *                            Admin functions                              *
     *****************************************************************************/

    /// @notice Create new Maker vault
    function createVault() external onlyGovernor {
        cm.createVault(collateralType);
    }

    /**
     * @param _maximumCollateralForDaiSwap To protect from sandwich attack let keeper send _maximumCollateralForDaiSwap
     * @dev If pool is underwater this function will resolve underwater condition.
     * If Debt in Maker is greater than Dai balance in lender then pool is underwater.
     * Lowering DAI debt in Maker will resolve underwater condition.
     * Resolve: Calculate required collateral token to lower DAI debt. Withdraw required
     * collateral token from Maker and convert those to DAI via Uniswap.
     * Finally payback debt in Maker using DAI.
     * @dev Also report loss in pool.
     */
    function resurface(uint256 _maximumCollateralForDaiSwap) external onlyKeeper {
        _resurface(_maximumCollateralForDaiSwap);
    }

    /**
     * @notice Update balancing factors aka high water and low water values.
     * Water mark values represent Collateral Ratio in Maker. For example 300 as high water
     * means 300% collateral ratio.
     * @param _highWater Value for high water mark.
     * @param _lowWater Value for low water mark.
     */
    function updateBalancingFactor(uint256 _highWater, uint256 _lowWater) external onlyGovernor {
        _updateBalancingFactor(_highWater, _lowWater);
    }
}