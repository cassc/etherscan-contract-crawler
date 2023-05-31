// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../Strategy.sol";
import "../../interfaces/compound/ICompound.sol";

/// @title This strategy will deposit collateral token in Compound and earn interest.
contract CompoundStrategy is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "4.0.0";

    CToken internal cToken;

    // solhint-disable-next-line var-name-mixedcase
    Comptroller public immutable COMPTROLLER;
    address public rewardToken;

    constructor(
        address _pool,
        address _swapManager,
        address _comptroller,
        address _rewardToken,
        address _receiptToken,
        string memory _name
    ) Strategy(_pool, _swapManager, _receiptToken) {
        require(_receiptToken != address(0), "cToken-address-is-zero");
        cToken = CToken(_receiptToken);
        swapSlippage = 10000; // disable oracles on reward swaps by default
        NAME = _name;

        // Either can be address(0), for example in Rari Strategy
        COMPTROLLER = Comptroller(_comptroller);
        rewardToken = _rewardToken;
    }

    /**
     * @notice Calculate total value using COMP accrued and cToken
     * @dev Report total value in collateral token
     */
    function totalValue() public view virtual override returns (uint256 _totalValue) {
        _totalValue = _calculateTotalValue((rewardToken != address(0)) ? _getRewardAccrued() : 0);
    }

    function totalValueCurrent() public virtual override returns (uint256 _totalValue) {
        if (rewardToken != address(0)) {
            _claimRewards();
            _totalValue = _calculateTotalValue(IERC20(rewardToken).balanceOf(address(this)));
        } else {
            _totalValue = _calculateTotalValue(0);
        }
    }

    function _calculateTotalValue(uint256 _rewardAccrued) internal view returns (uint256 _totalValue) {
        if (_rewardAccrued != 0) {
            (, _totalValue) = swapManager.bestPathFixedInput(rewardToken, address(collateralToken), _rewardAccrued, 0);
        }
        _totalValue += _convertToCollateral(cToken.balanceOf(address(this)));
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == address(cToken) || _token == rewardToken;
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(cToken), _amount);
        if (rewardToken != address(0)) {
            for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
                IERC20(rewardToken).safeApprove(address(swapManager.ROUTERS(i)), _amount);
            }
        }
    }

    //solhint-disable-next-line no-empty-blocks
    function _beforeMigration(address _newStrategy) internal virtual override {}

    /// @notice Claim comp
    function _claimRewards() internal virtual {
        address[] memory _markets = new address[](1);
        _markets[0] = address(cToken);
        COMPTROLLER.claimComp(address(this), _markets);
    }

    function _getRewardAccrued() internal view virtual returns (uint256 _rewardAccrued) {
        _rewardAccrued = COMPTROLLER.compAccrued(address(this));
    }

    /// @notice Claim COMP and convert COMP into collateral token.
    function _claimRewardsAndConvertTo(address _toToken) internal virtual override {
        if (rewardToken != address(0)) {
            _claimRewards();
            uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this));
            if (_rewardAmount != 0) {
                uint256 minAmtOut =
                    (swapSlippage != 10000)
                        ? _calcAmtOutAfterSlippage(
                            _getOracleRate(_simpleOraclePath(rewardToken, _toToken), _rewardAmount),
                            swapSlippage
                        )
                        : 1;
                _safeSwap(rewardToken, _toToken, _rewardAmount, minAmtOut);
            }
        }
    }

    /// @notice Withdraw collateral to payback excess debt
    function _liquidate(uint256 _excessDebt) internal override returns (uint256 _payback) {
        if (_excessDebt != 0) {
            _payback = _safeWithdraw(_excessDebt);
        }
    }

    /**
     * @notice Calculate earning and withdraw it from Compound.
     * @dev Claim COMP and convert into collateral
     * @dev If somehow we got some collateral token in strategy then we want to
     *  include those in profit. That's why we used 'return' outside 'if' condition.
     * @param _totalDebt Total collateral debt of this strategy
     * @return profit in collateral token
     */
    function _realizeProfit(uint256 _totalDebt) internal virtual override returns (uint256) {
        _claimRewardsAndConvertTo(address(collateralToken));
        uint256 _collateralBalance = _convertToCollateral(cToken.balanceOf(address(this)));
        if (_collateralBalance > _totalDebt) {
            uint256 _amountToWithdraw = _collateralBalance - _totalDebt;
            uint256 _expectedCToken = (_amountToWithdraw * 1e18) / cToken.exchangeRateStored();
            if (_expectedCToken > 0) {
                _withdrawHere(_amountToWithdraw);
            }
        }
        return collateralToken.balanceOf(address(this));
    }

    /**
     * @notice Calculate realized loss.
     * @return _loss Realized loss in collateral token
     */
    function _realizeLoss(uint256 _totalDebt) internal view virtual override returns (uint256 _loss) {
        uint256 _collateralBalance = _convertToCollateral(cToken.balanceOf(address(this)));
        if (_collateralBalance < _totalDebt) {
            _loss = _totalDebt - _collateralBalance;
        }
    }

    /// @notice Deposit collateral in Compound
    function _reinvest() internal virtual override {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance != 0) {
            require(cToken.mint(_collateralBalance) == 0, "deposit-to-compound-failed");
        }
    }

    /// @dev Withdraw collateral and transfer it to pool
    function _withdraw(uint256 _amount) internal override {
        _safeWithdraw(_amount);
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    /**
     * @notice Safe withdraw will make sure to check asking amount against available amount.
     * @param _amount Amount of collateral to withdraw.
     * @return Actual collateral withdrawn
     */
    function _safeWithdraw(uint256 _amount) internal returns (uint256) {
        uint256 _collateralBalance = _convertToCollateral(cToken.balanceOf(address(this)));
        // Get available liquidity from Compound
        uint256 _availableLiquidity = cToken.getCash();
        // Get minimum of _amount and _avaialbleLiquidity
        uint256 _withdrawAmount = _amount < _availableLiquidity ? _amount : _availableLiquidity;
        // Get minimum of _withdrawAmount and _collateralBalance
        return _withdrawHere(_withdrawAmount < _collateralBalance ? _withdrawAmount : _collateralBalance);
    }

    /// @dev Withdraw collateral here. Do not transfer to pool
    function _withdrawHere(uint256 _amount) internal returns (uint256) {
        if (_amount != 0) {
            require(cToken.redeemUnderlying(_amount) == 0, "withdraw-from-compound-failed");
            _afterRedeem();
        }
        return _amount;
    }

    function _setupOracles() internal virtual override {
        if (rewardToken != address(0))
            swapManager.createOrUpdateOracle(rewardToken, WETH, oraclePeriod, oracleRouterIdx);
        if (address(collateralToken) != WETH) {
            swapManager.createOrUpdateOracle(WETH, address(collateralToken), oraclePeriod, oracleRouterIdx);
        }
    }

    /**
     * @dev Compound support ETH as collateral not WETH. This hook will take
     * care of conversion from WETH to ETH and vice versa.
     * @dev This will be used in ETH strategy only, hence empty implementation
     */
    //solhint-disable-next-line no-empty-blocks
    function _afterRedeem() internal virtual {}

    function _convertToCollateral(uint256 _cTokenAmount) internal view returns (uint256) {
        return (_cTokenAmount * cToken.exchangeRateStored()) / 1e18;
    }
}