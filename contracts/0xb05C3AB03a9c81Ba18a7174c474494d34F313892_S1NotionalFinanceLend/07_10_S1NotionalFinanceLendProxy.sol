// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/INotionalFinance.sol";


contract S1NotionalFinanceLendProxy {
    address private deployer;
    address private notionalProxy;

    constructor(
        address _deployer,
        address _notionalProxy
    ) {
        deployer = _deployer;
        notionalProxy = _notionalProxy;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function deposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) external payable onlyDeployer {
        if (_yieldCurrency != address(0) && _yieldCurrencyId != 1) {
            if (IERC20(_yieldCurrency).allowance(address(this), deployer) == 0) {
                IERC20(_yieldCurrency).approve(deployer, 2**256 - 1);
            }

            if (IERC20(_yieldCurrency).allowance(address(this), notionalProxy) == 0) {
                IERC20(_yieldCurrency).approve(notionalProxy, 2**256 - 1);
            }

            IERC20(_yieldCurrency).transferFrom(deployer, address(this), _amount);
        }

        _deposit(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate, true);
    }

    function _deposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate, bool _useUnderlying) private {
        (/* fCashAmount */, /* marketIndex*/, bytes32 encodedLendTrade) = INotionalFinance(notionalProxy).getfCashLendFromDeposit({
            currencyId: _yieldCurrencyId,
            depositAmountExternal: _amount,
            maturity: _maturity,
            minLendRate: _minLendRate,
            blockTime: block.timestamp,
            useUnderlying: _useUnderlying
        });

        INotionalFinance.BalanceActionWithTrades[] memory actions = new INotionalFinance.BalanceActionWithTrades[](1);
        actions[0] = INotionalFinance.BalanceActionWithTrades({
            actionType: _actionType,
            currencyId: _yieldCurrencyId,
            depositActionAmount: _amount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: true,
            redeemToUnderlying: true,
            trades: new bytes32[](1)
        });
        actions[0].trades[0] = encodedLendTrade;

        if (_useUnderlying == true && _yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            INotionalFinance(notionalProxy).batchBalanceAndTradeAction{value: _amount}(address(this), actions);
        } else {
            INotionalFinance(notionalProxy).batchBalanceAndTradeAction(address(this), actions);
        }
    }

    function lendMaturedBalance(uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) external onlyDeployer {
        _deposit(address(0), _yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate, false);
    }

    function withdraw(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, uint256 _withdrawAmountInternalPrecision, bool _withdrawEntireCashBalance, bool _redeemToUnderlying, INotionalFinance.DepositActionType _actionType) external onlyDeployer returns(uint256) {
        INotionalFinance.BalanceAction[] memory actions = new INotionalFinance.BalanceAction[](1);
        actions[0] = INotionalFinance.BalanceAction({
            actionType: _actionType,
            currencyId: _yieldCurrencyId,
            depositActionAmount: _amount,
            withdrawAmountInternalPrecision: _withdrawAmountInternalPrecision,
            withdrawEntireCashBalance: _withdrawEntireCashBalance,
            redeemToUnderlying: _redeemToUnderlying
        });
        INotionalFinance(notionalProxy).batchBalanceAction(address(this), actions);

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            uint256 ethBalance = address(this).balance;
            (bool success, ) = payable(deployer).call{value: ethBalance}("");
            require(success, "ERR: FAIL_SENDING_ETH");

            return ethBalance;
        } else {
            return IERC20(_yieldCurrency).balanceOf(address(this));
        }
    }

    function withdrawBeforeMaturityDate(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, INotionalFinance.DepositActionType _actionType, uint8 _ethMarketIndex, uint32 _maxImpliedRate) external onlyDeployer returns(uint256) {
        uint256 amount = _withdrawBeforeMaturityDate(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _ethMarketIndex, _maxImpliedRate);

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            (bool success, ) = payable(deployer).call{value: amount}("");
            require(success, "ERR: FAIL_SENDING_ETH");
        }
        return amount;
    }

    function _withdrawBeforeMaturityDate(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, INotionalFinance.DepositActionType _actionType, uint8 _ethMarketIndex, uint32 _maxImpliedRate) private returns(uint256) {
        INotionalFinance.BalanceActionWithTrades[] memory actions = new INotionalFinance.BalanceActionWithTrades[](1);
        actions[0] = INotionalFinance.BalanceActionWithTrades({
            actionType: _actionType,
            currencyId: _yieldCurrencyId,
            depositActionAmount: 0,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: true,
            redeemToUnderlying: true,
            trades: new bytes32[](1)
        });
        actions[0].trades[0] = _encodeBorrowTrade(
            _ethMarketIndex, _amount, _maxImpliedRate
        );
        INotionalFinance(notionalProxy).batchBalanceAndTradeAction(address(this), actions);

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            return address(this).balance;
        } else {
            return IERC20(_yieldCurrency).balanceOf(address(this));
        }
    }

    function rollToNewMaturity(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, uint8 _ethMarketIndex, uint32 _maxImpliedRate, uint256 _maturity, uint32 _minLendRate) external onlyDeployer {
        _withdrawBeforeMaturityDate(_yieldCurrency, _yieldCurrencyId, _amount, INotionalFinance.DepositActionType.None, _ethMarketIndex, _maxImpliedRate);

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            _deposit(_yieldCurrency, _yieldCurrencyId, address(this).balance, INotionalFinance.DepositActionType.DepositUnderlying, _maturity, _minLendRate, true);
        } else {
            _deposit(_yieldCurrency, _yieldCurrencyId, IERC20(_yieldCurrency).balanceOf(address(this)), INotionalFinance.DepositActionType.DepositUnderlying, _maturity, _minLendRate, true);
        }
    }
    
    function _encodeBorrowTrade(
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 maxImpliedRate
    ) internal pure returns (bytes32) {
        return bytes32(
            (uint256(uint8(INotionalFinance.TradeActionType.Borrow)) << 248) |
            (uint256(marketIndex) << 240) |
            (uint256(fCashAmount) << 152) |
            (uint256(maxImpliedRate) << 120)
        );
    }

    receive() external payable {}
}

// MN bby ¯\_(ツ)_/¯