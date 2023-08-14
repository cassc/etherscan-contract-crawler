// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "../Strategy.sol";
import "../../interfaces/compound/ICompound.sol";

/// @title This strategy will deposit collateral token in Compound and earn interest.
abstract contract CompoundStrategy is Strategy {
    using SafeERC20 for IERC20;

    CToken internal cToken;
    address internal constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    Comptroller internal constant COMPTROLLER = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken
    ) Strategy(_pool, _swapManager, _receiptToken) {
        require(_receiptToken != address(0), "cToken-address-is-zero");
        cToken = CToken(_receiptToken);
        swapSlippage = 10000; // disable oracles on reward swaps by default
    }

    /**
     * @notice Calculate total value using COMP accrued and cToken
     * @dev Report total value in collateral token
     */
    function totalValue() public view virtual override returns (uint256 _totalValue) {
        _totalValue = _calculateTotalValue(COMPTROLLER.compAccrued(address(this)));
    }

    function totalValueCurrent() external virtual override returns (uint256 _totalValue) {
        _claimComp();
        _totalValue = _calculateTotalValue(IERC20(COMP).balanceOf(address(this)));
    }

    function _calculateTotalValue(uint256 _compAccrued) internal view returns (uint256 _totalValue) {
        if (_compAccrued != 0) {
            (, _totalValue) = swapManager.bestPathFixedInput(COMP, address(collateralToken), _compAccrued, 0);
        }
        _totalValue += _convertToCollateral(cToken.balanceOf(address(this)));
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == address(cToken) || _token == COMP;
    }

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(cToken), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(COMP).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /**
     * @notice Claim COMP and transfer to new strategy
     * @param _newStrategy Address of new strategy.
     */
    function _beforeMigration(address _newStrategy) internal virtual override {
        _claimComp();
        IERC20(COMP).safeTransfer(_newStrategy, IERC20(COMP).balanceOf(address(this)));
    }

    /// @notice Claim comp
    function _claimComp() internal {
        address[] memory _markets = new address[](1);
        _markets[0] = address(cToken);
        COMPTROLLER.claimComp(address(this), _markets);
    }

    /// @notice Claim COMP and convert COMP into collateral token.
    function _claimRewardsAndConvertTo(address _toToken) internal virtual override {
        _claimComp();
        uint256 _compAmount = IERC20(COMP).balanceOf(address(this));
        if (_compAmount != 0) {
            uint256 minAmtOut =
                (swapSlippage != 10000)
                    ? _calcAmtOutAfterSlippage(
                        _getOracleRate(_simpleOraclePath(COMP, _toToken), _compAmount),
                        swapSlippage
                    )
                    : 1;
            _safeSwap(COMP, _toToken, _compAmount, minAmtOut);
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
            _withdrawHere(_collateralBalance - _totalDebt);
        }
        return collateralToken.balanceOf(address(this));
    }

    /**
     * @notice Calculate realized loss.
     * @return _loss Realized loss in collateral token
     */
    function _realizeLoss(uint256 _totalDebt) internal view override returns (uint256 _loss) {
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
        swapManager.createOrUpdateOracle(COMP, WETH, oraclePeriod, oracleRouterIdx);
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