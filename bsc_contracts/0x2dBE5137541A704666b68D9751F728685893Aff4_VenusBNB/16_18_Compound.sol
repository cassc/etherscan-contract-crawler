// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../Strategy.sol";
import "../../interfaces/compound/ICompound.sol";

/// @title This strategy will deposit collateral token in Compound and earn interest.
contract Compound is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    CToken internal cToken;

    // solhint-disable-next-line var-name-mixedcase
    Comptroller public immutable COMPTROLLER;
    address public rewardToken;

    constructor(
        address _pool,
        address _swapper,
        address _comptroller,
        address _rewardToken,
        address _receiptToken,
        string memory _name
    ) Strategy(_pool, _swapper, _receiptToken) {
        require(_receiptToken != address(0), "cToken-address-is-zero");
        cToken = CToken(_receiptToken);
        NAME = _name;

        // Either can be address(0), for example in Rari Strategy
        COMPTROLLER = Comptroller(_comptroller);
        rewardToken = _rewardToken;
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == address(cToken);
    }

    function tvl() external view override returns (uint256) {
        return
            ((cToken.balanceOf(address(this)) * cToken.exchangeRateStored()) / 1e18) +
            collateralToken.balanceOf(address(this));
    }

    //solhint-disable-next-line no-empty-blocks
    function _afterRedeem() internal virtual {}

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(cToken), _amount);
        IERC20(rewardToken).safeApprove(address(swapper), _amount);
    }

    //solhint-disable-next-line no-empty-blocks
    function _beforeMigration(address _newStrategy) internal virtual override {}

    /// @notice Claim comp
    function _claimRewards() internal virtual {
        address[] memory _markets = new address[](1);
        _markets[0] = address(cToken);
        COMPTROLLER.claimComp(address(this), _markets);
    }

    /// @notice Claim COMP and convert COMP into collateral token.
    function _claimRewardsAndConvertTo(address _toToken) internal virtual {
        if (rewardToken != address(0)) {
            _claimRewards();
            uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this));
            if (_rewardAmount > 0) {
                _safeSwapExactInput(rewardToken, _toToken, _rewardAmount);
            }
        }
    }

    /**
     * @notice Deposit collateral in Compound.
     * @dev cETH works differently so ETH strategy will override this function.
     */
    function _deposit(uint256 _amount) internal virtual {
        if (_amount > 0) {
            require(cToken.mint(_amount) == 0, "deposit-to-compound-failed");
        }
    }

    /**
     * @dev Generate profit, loss and payback statement. Also claim rewards.
     */
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
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        _claimRewardsAndConvertTo(address(collateralToken));

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _collateralHere + cToken.balanceOfUnderlying(address(this));
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
     * @dev Generate report for pools accounting and also send profit and any payback to pool.
     */
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
        // After reportEarning strategy may get more collateral from pool. Deposit those in Compound.
        _deposit(collateralToken.balanceOf(address(this)));
    }

    /// @dev Withdraw collateral here. Do not transfer to pool
    function _withdrawHere(uint256 _amount) internal override {
        // If _amount is very small and equivalent to 0 cToken then skip withdraw.
        uint256 _expectedCToken = (_amount * 1e18) / cToken.exchangeRateStored();
        if (_expectedCToken > 0) {
            // Get minimum of _amount and _available collateral and _availableLiquidity
            uint256 _withdrawAmount = Math.min(
                _amount,
                Math.min(cToken.balanceOfUnderlying(address(this)), cToken.getCash())
            );
            require(cToken.redeemUnderlying(_withdrawAmount) == 0, "withdraw-from-compound-failed");
            _afterRedeem();
        }
    }
}