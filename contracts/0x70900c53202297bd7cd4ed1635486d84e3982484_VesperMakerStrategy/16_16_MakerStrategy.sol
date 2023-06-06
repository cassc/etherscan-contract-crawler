// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../Strategy.sol";
import "../../interfaces/vesper/ICollateralManager.sol";

/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in other lending pool to earn interest.
abstract contract MakerStrategy is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "4.0.0";

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    ICollateralManager public immutable cm;
    bytes32 public immutable collateralType;
    uint256 public highWater;
    uint256 public lowWater;
    uint256 public decimalConversionFactor;
    uint256 private constant WAT = 10**16;

    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _receiptToken,
        bytes32 _collateralType,
        string memory _name
    ) Strategy(_pool, _swapManager, _receiptToken) {
        require(_cm != address(0), "cm-address-is-zero");
        collateralType = _collateralType;
        cm = ICollateralManager(_cm);
        // Assuming token supports 18 or less decimals.
        uint256 _decimals = IERC20Metadata(address(IVesperPool(_pool).token())).decimals();
        decimalConversionFactor = 10**(18 - _decimals);
        NAME = _name;
    }

    /// @notice Create new Maker vault
    function createVault() external onlyGovernor {
        cm.createVault(collateralType);
    }

    /**
     * @dev If pool is underwater this function will resolve underwater condition.
     * If Debt in Maker is greater than Dai balance in lender then pool is underwater.
     * Lowering DAI debt in Maker will resolve underwater condition.
     * Resolve: Calculate required collateral token to lower DAI debt. Withdraw required
     * collateral token from Maker and convert those to DAI via Uniswap.
     * Finally payback debt in Maker using DAI.
     * @dev Also report loss in pool.
     */
    function resurface() external onlyKeeper {
        _resurface();
    }

    /**
     * @notice Update balancing factors aka high water and low water values.
     * Water mark values represent Collateral Ratio in Maker. For example 300 as high water
     * means 300% collateral ratio.
     * @param _highWater Value for high water mark.
     * @param _lowWater Value for low water mark.
     */
    function updateBalancingFactor(uint256 _highWater, uint256 _lowWater) external onlyGovernor {
        require(_lowWater != 0, "lowWater-is-zero");
        require(_highWater > _lowWater, "highWater-less-than-lowWater");
        highWater = _highWater * WAT;
        lowWater = _lowWater * WAT;
    }

    /// @dev Convert from 18 decimals to token defined decimals.
    function convertFrom18(uint256 _amount) public view returns (uint256) {
        return _amount / decimalConversionFactor;
    }

    /**
     * @notice Report total value of this strategy
     * @dev Make sure to return value in collateral token and in order to do that
     * we are using Uniswap to get collateral amount for earned DAI.
     */
    function totalValue() public view virtual override returns (uint256 _totalValue) {
        uint256 _daiBalance = _getDaiBalance();
        uint256 _debt = cm.getVaultDebt(address(this));
        if (_daiBalance > _debt) {
            uint256 _daiEarned = _daiBalance - _debt;
            (, _totalValue) = swapManager.bestPathFixedInput(DAI, address(collateralToken), _daiEarned, 0);
        }
        _totalValue += convertFrom18(cm.getVaultBalance(address(this)));
    }

    function vaultNum() external view returns (uint256) {
        return cm.vaultNum(address(this));
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == receiptToken;
    }

    /**
     * @notice Returns true if pool is underwater.
     * @notice Underwater - If debt is greater than (earning of pool + DAI in pool + some wei buffer).
     * @notice Earning - Sum of DAI balance and DAI from accrued reward, if any, in lending pool.
     */
    function isUnderwater() public view virtual returns (bool) {
        return cm.getVaultDebt(address(this)) > (_getDaiBalance() + IERC20(DAI).balanceOf(address(this)) + 1_000);
    }

    /**
     * @notice Before migration hook. It will be called during migration
     * @dev Transfer Maker vault ownership to new strategy
     * @param _newStrategy Address of new strategy.
     */
    function _beforeMigration(address _newStrategy) internal virtual override {
        require(MakerStrategy(_newStrategy).collateralType() == collateralType, "collateral-type-must-be-the-same");
        cm.transferVaultOwnership(_newStrategy);
    }

    function _approveToken(uint256 _amount) internal virtual override {
        IERC20(DAI).safeApprove(address(cm), _amount);
        collateralToken.safeApprove(address(cm), _amount);
        collateralToken.safeApprove(pool, _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            collateralToken.safeApprove(address(swapManager.ROUTERS(i)), _amount);
            IERC20(DAI).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    function _moveDaiToMaker(uint256 _amount) internal {
        if (_amount != 0) {
            _withdrawDaiFromLender(_amount);
            cm.payback(_amount);
        }
    }

    function _moveDaiFromMaker(uint256 _amount) internal virtual {
        cm.borrow(_amount);
        _amount = IERC20(DAI).balanceOf(address(this));
        _depositDaiToLender(_amount);
    }

    /**
     * @notice Withdraw collateral to payback excess debt in pool.
     * @param _excessDebt Excess debt of strategy in collateral token
     * @return payback amount in collateral token. Usually it is equal to excess debt.
     */
    function _liquidate(uint256 _excessDebt) internal virtual override returns (uint256) {
        _withdrawHere(_excessDebt);
        return _excessDebt;
    }

    /**
     * @notice Calculate earning and convert it to collateral token
     * @dev Also claim rewards if available.
     *      Withdraw excess DAI from lender.
     *      Swap net earned DAI to collateral token
     * @return profit in collateral token
     */
    function _realizeProfit(
        uint256 /*_totalDebt*/
    ) internal virtual override returns (uint256) {
        _claimRewardsAndConvertTo(DAI);
        _rebalanceDaiInLender();
        uint256 _daiBalance = IERC20(DAI).balanceOf(address(this));
        if (_daiBalance != 0) {
            _safeSwap(DAI, address(collateralToken), _daiBalance, 1);
        }
        return collateralToken.balanceOf(address(this));
    }

    /**
     * @notice Calculate collateral loss from resurface, if any
     * @dev Difference of total debt of strategy in pool and collateral locked
     *      in Maker vault is the loss.
     * @return loss in collateral token
     */
    function _realizeLoss(uint256 _totalDebt) internal virtual override returns (uint256) {
        uint256 _collateralLocked = convertFrom18(cm.getVaultBalance(address(this)));
        return _totalDebt > _collateralLocked ? _totalDebt - _collateralLocked : 0;
    }

    /**
     * @notice Deposit collateral in Maker and rebalance collateral and debt in Maker.
     * @dev Based on defined risk parameter either borrow more DAI from Maker or
     * payback some DAI in Maker. It will try to mitigate risk of liquidation.
     */
    function _reinvest() internal virtual override {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance != 0) {
            cm.depositCollateral(_collateralBalance);
        }

        (
            uint256 _collateralLocked,
            uint256 _currentDebt,
            uint256 _collateralUsdRate,
            uint256 _collateralRatio,
            uint256 _minimumAllowedDebt
        ) = cm.getVaultInfo(address(this));
        uint256 _maxDebt = (_collateralLocked * _collateralUsdRate) / highWater;
        if (_maxDebt < _minimumAllowedDebt) {
            // Dusting Scenario:: Based on collateral locked, if our max debt is less
            // than Maker defined minimum debt then payback whole debt and wind up.
            _moveDaiToMaker(_currentDebt);
        } else {
            if (_collateralRatio > highWater) {
                require(!isUnderwater(), "pool-is-underwater");
                // Safe to borrow more DAI
                _moveDaiFromMaker(_maxDebt - _currentDebt);
            } else if (_collateralRatio < lowWater) {
                // Being below low water brings risk of liquidation in Maker.
                // Withdraw DAI from Lender and deposit in Maker
                _moveDaiToMaker(_currentDebt - _maxDebt);
            }
        }
    }

    function _resurface() internal virtual {
        require(isUnderwater(), "pool-is-above-water");
        uint256 _daiNeeded = cm.getVaultDebt(address(this)) - _getDaiBalance();
        (address[] memory _path, uint256 _collateralNeeded, uint256 rIdx) =
            swapManager.bestInputFixedOutput(address(collateralToken), DAI, _daiNeeded);
        if (_collateralNeeded != 0) {
            cm.withdrawCollateral(_collateralNeeded);
            swapManager.ROUTERS(rIdx).swapExactTokensForTokens(
                _collateralNeeded,
                1,
                _path,
                address(this),
                block.timestamp
            );
            cm.payback(IERC20(DAI).balanceOf(address(this)));
            IVesperPool(pool).reportLoss(_collateralNeeded);
        }
    }

    function _withdraw(uint256 _amount) internal override {
        _withdrawHere(_amount);
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    // TODO do we need a safe withdraw
    function _withdrawHere(uint256 _amount) internal {
        (
            uint256 collateralLocked,
            uint256 debt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        ) = cm.whatWouldWithdrawDo(address(this), _amount);
        if (debt != 0 && collateralRatio < lowWater) {
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
    }

    function _depositDaiToLender(uint256 _amount) internal virtual;

    function _rebalanceDaiInLender() internal virtual;

    function _withdrawDaiFromLender(uint256 _amount) internal virtual;

    function _getDaiBalance() internal view virtual returns (uint256);
}