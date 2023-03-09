// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IBalancerVault.sol";
import "./interfaces/IS1NotionalFinanceLendProxy.sol";
import "./proxies/S1NotionalFinanceLendProxy.sol";
import "./Ownable.sol";


interface IFees {
    function feeCollector(uint256 _index) external view returns (address);
    function depositStatus(uint256 _index) external view returns (bool);
    function calcFee(
        uint256 _strategyId,
        address _user,
        address _feeToken
    ) external view returns (uint256);
    function whitelistedDepositCurrencies(uint256 _index, address _token) external view returns(bool);
}


contract S1NotionalFinanceLend is Ownable {
    bool public enableEarlyWithdraw = false;
    bool public enableRollToNewMaturity = false;
    uint8 constant public strategyIndex = 20;
    address public feesAddress;
    address public uniswapConnector;
    address public wethAddress;

    // protocols
    address public notionalProxy;

    mapping(address => address) public depositors;

    constructor(
        address _feesAddress,
        address _uniswapConnector,
        address _wethAddress,
        address _notionalProxy
    ) {
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        wethAddress = _wethAddress;
        notionalProxy = _notionalProxy;
    }

    event Deposit(address indexed _depositor, address indexed _token, address indexed _yieldCurrency, uint256 _amountIn, uint256 _amountOut);

    event ProxyCreation(address indexed _depositor, address indexed _proxy);

    event Withdraw(address indexed _depositor, address indexed _token, address indexed _yieldCurrency, uint256 _amount, uint256 _fee, bool _beforeMaturityDate);

    event RollToNewMaturity(address indexed _depositor, address indexed _yieldCurrency, uint88 _amount, uint8 _ethMarketIndex, uint256 _maturity);

    /*
    * ADMIN METHODS
    */
    function setEarlyWithdraw(bool _bool) external onlyOwner {
        enableEarlyWithdraw = _bool;
    }

    function setRollToNewMaturity(bool _bool) external onlyOwner {
        enableRollToNewMaturity = _bool;
    }

    function getfCashNotional(
        address account,
        uint16 currencyId,
        uint256 maturity
    ) public view returns(int256) {
        return INotionalFinance(notionalProxy).getfCashNotional(account, currencyId, maturity);
    }

    function getActiveMarkets(uint16 currencyId) public view returns(INotionalFinance.MarketParameters[] memory) {
        return INotionalFinance(notionalProxy).getActiveMarkets(currencyId);
    }

    function getAccountPortfolio(address _address) public view returns(INotionalFinance.PortfolioAsset[] memory) {
        return INotionalFinance(notionalProxy).getAccountPortfolio(depositors[_address]);
    }

    function getAccountBalance(address _address, uint8 _yieldCurrencyId) public view returns(int256, int256, uint256) {
        if (depositors[_address] != address(0)) {
            return INotionalFinance(notionalProxy).getAccountBalance(_yieldCurrencyId, depositors[_address]);
        } else {
            return (0, 0, 0);
        }
    }

    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex
    ) external view returns (int256, int256) {
        return INotionalFinance(notionalProxy).getCashAmountGivenfCashAmount(
            currencyId,
            fCashAmount,
            marketIndex,
            block.timestamp
        );
    }

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        bool riskAdjusted
    ) external view returns (int256 presentValue) {
        return INotionalFinance(notionalProxy).getPresentfCashValue(
            currencyId,
            maturity, 
            notional,
            block.timestamp,
            riskAdjusted
        );
    }

    function depositETH(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amountOutMin, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) external payable {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, msg.value, _actionType, _maturity, _minLendRate);

            emit Deposit(msg.sender, wethAddress, _yieldCurrency, msg.value, msg.value);  
        } else {
            uint256 depositAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: msg.value}(
                _yieldCurrency, 
                0, 
                _amountOutMin, 
                address(this)
            );
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, _actionType, _maturity, _minLendRate);

            emit Deposit(msg.sender, wethAddress, _yieldCurrency, msg.value, depositAmount);  
        }
    }

    function depositToken(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amount, uint256 _amountOutMin, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) external {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");
        require(IFees(feesAddress).whitelistedDepositCurrencies(strategyIndex, _token), "ERR: INVALID_DEPOSIT_TOKEN");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        uint256 depositAmount;
        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            if (IERC20(_token).allowance(address(this), uniswapConnector) == 0) {
                IERC20(_token).approve(uniswapConnector, 2**256 - 1);
            }
            
            depositAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                _token,
                wethAddress, 
                _amount, 
                _amountOutMin, 
                address(this)
            );
            IWETH(wethAddress).withdraw(depositAmount);
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, _actionType, _maturity, _minLendRate);
        } else {
            if (_token != _yieldCurrency) {
                if (IERC20(_token).allowance(address(this), uniswapConnector) == 0) {
                    IERC20(_token).approve(uniswapConnector, 2**256 - 1);
                }

                depositAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                    _token,
                    _yieldCurrency, 
                    _amount, 
                    _amountOutMin, 
                    address(this)
                );
            } else {
                depositAmount = _amount;
            }
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, _actionType, _maturity, _minLendRate);
        }
 
        emit Deposit(msg.sender, _token, _yieldCurrency, _amount, depositAmount);
    }

    function _yieldDeposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) private {
        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S1NotionalFinanceLendProxy s1proxy = new S1NotionalFinanceLendProxy(
                address(this),
                notionalProxy
            );
            depositors[msg.sender] = address(s1proxy);
            if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
                s1proxy.deposit{value: _amount}(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate);
            } else {
                IERC20(_yieldCurrency).approve(depositors[msg.sender], 2**256 - 1);
                s1proxy.deposit(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate);
            }

            emit ProxyCreation(msg.sender, address(s1proxy));
        } else {
            // send the deposit to the existing proxy contract
            if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
                IS1NotionalFinanceLendProxy(depositors[msg.sender]).deposit{value: _amount}(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate);
            } else {
                if (IERC20(_yieldCurrency).allowance(address(this), depositors[msg.sender]) == 0) {
                    IERC20(_yieldCurrency).approve(depositors[msg.sender], 2**256 - 1); 
                }

                IS1NotionalFinanceLendProxy(depositors[msg.sender]).deposit(_yieldCurrency, _yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate);
            }
        }
    }

    function lendMaturedBalance(uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType _actionType, uint256 _maturity, uint32 _minLendRate) external {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (int256 cashBalance, , ) = getAccountBalance(msg.sender, _yieldCurrencyId);
        require(cashBalance > 0 && uint256(cashBalance) >= _amount, "ERR: INVALID_CASH_BALANCE");
        
        IS1NotionalFinanceLendProxy(depositors[msg.sender]).lendMaturedBalance(_yieldCurrencyId, _amount, _actionType, _maturity, _minLendRate);
    }

    function withdrawETH(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, uint256 _amountOutMin, address _feeToken, uint256 _withdrawAmountInternalPrecision, bool _withdrawEntireCashBalance, bool _redeemToUnderlying, INotionalFinance.DepositActionType _actionType) external {
        withdrawToken(_yieldCurrency, _yieldCurrencyId, wethAddress, _amount, _amountOutMin, _feeToken, _withdrawAmountInternalPrecision, _withdrawEntireCashBalance, _redeemToUnderlying, _actionType);
    }

    function withdrawToken(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amount, uint256 _amountOutMin, address _feeToken, uint256 _withdrawAmountInternalPrecision, bool _withdrawEntireCashBalance, bool _redeemToUnderlying, INotionalFinance.DepositActionType _actionType) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        
        uint256 amountToBeWithdrawn = IS1NotionalFinanceLendProxy(depositors[msg.sender]).withdraw(_yieldCurrency, _yieldCurrencyId, _amount, _withdrawAmountInternalPrecision, _withdrawEntireCashBalance, _redeemToUnderlying, _actionType);
        (uint256 deposit, uint256 fee) = _splitYieldDepositAndFee(amountToBeWithdrawn, _yieldCurrency, _yieldCurrencyId, _feeToken);
        
        _proceedWithWithdraw(_yieldCurrency, _yieldCurrencyId, _token, _amountOutMin, deposit, fee, false);
    }

    function withdrawETHBeforeMaturityDate(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, uint256 _amountOutMin, address _feeToken, INotionalFinance.DepositActionType _actionType, uint8 _ethMarketIndex, uint32 _maxImpliedRate) external {
        withdrawTokenBeforeMaturityDate(_yieldCurrency, _yieldCurrencyId, wethAddress, _amount, _amountOutMin, _feeToken, _actionType, _ethMarketIndex, _maxImpliedRate);
    }

    function withdrawTokenBeforeMaturityDate(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amount, uint256 _amountOutMin, address _feeToken, INotionalFinance.DepositActionType _actionType, uint8 _ethMarketIndex, uint32 _maxImpliedRate) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        require(enableEarlyWithdraw == true, "ERR: EARLY_WITHDRAW_STOPPED");

        uint256 amountToBeWithdrawn = IS1NotionalFinanceLendProxy(depositors[msg.sender]).withdrawBeforeMaturityDate(_yieldCurrency, _yieldCurrencyId, uint88(_amount), _actionType, _ethMarketIndex, _maxImpliedRate);
        (uint256 deposit, uint256 fee) = _splitYieldDepositAndFee(amountToBeWithdrawn, _yieldCurrency, _yieldCurrencyId, _feeToken);
        
        _proceedWithWithdraw(_yieldCurrency, _yieldCurrencyId, _token, _amountOutMin, deposit, fee, true);
    }

    function _splitYieldDepositAndFee(uint256 amountToBeWithdrawn, address _yieldCurrency, uint8 _yieldCurrencyId,  address _feeToken) private returns(uint256, uint256) {
        uint256 fee = (amountToBeWithdrawn * IFees(feesAddress).calcFee(strategyIndex, msg.sender, _feeToken)) / 1000;
        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            if (fee > 0) {
                (bool success, ) = payable(IFees(feesAddress).feeCollector(strategyIndex)).call{value: fee}("");
                require(success, "ERR: FAIL_SENDING_ETH");
            }
        } else {
            IERC20(_yieldCurrency).transferFrom(depositors[msg.sender], address(this), amountToBeWithdrawn);
            
            if (fee > 0) {
                IERC20(_yieldCurrency).transfer(
                    IFees(feesAddress).feeCollector(strategyIndex),
                    fee
                );
            }
        }
        return (amountToBeWithdrawn, fee);
    }

    function _proceedWithWithdraw(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amountOutMin, uint256 _deposit, uint256 _fee, bool _beforeMaturityDate) private {
        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            if (_token == wethAddress) {
                // withdraw ETH
                (bool success, ) = payable(msg.sender).call{value: _deposit - _fee}("");
                require(success, "ERR: FAIL_SENDING_ETH");
                emit Withdraw(msg.sender, wethAddress, _yieldCurrency, _deposit - _fee, _fee, _beforeMaturityDate);
            } else {
                uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: _deposit - _fee}(
                    _token, 
                    0, 
                    _amountOutMin,
                    msg.sender
                );

                emit Withdraw(msg.sender, _token, _yieldCurrency, tokenAmount, _fee, _beforeMaturityDate);
            }
        } else {
            if (_token == _yieldCurrency) {
                IERC20(_yieldCurrency).transfer(
                    msg.sender,
                    _deposit - _fee
                );

                emit Withdraw(msg.sender, _token, _yieldCurrency, _deposit - _fee, _fee, _beforeMaturityDate);
            } else {
                if (IERC20(_yieldCurrency).allowance(address(this), uniswapConnector) == 0) {
                    IERC20(_yieldCurrency).approve(uniswapConnector, 2**256 - 1);
                }

                address receiver;
                if (_token == wethAddress) {
                    receiver = address(this);
                } else {
                    receiver = msg.sender;
                }

                uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapTokenForToken(
                    _yieldCurrency,
                    _token, 
                    _deposit - _fee, 
                    _amountOutMin, 
                    receiver
                );

                if (_token == wethAddress) {
                    IWETH(wethAddress).withdraw(tokenAmount);
                    (bool success, ) = payable(msg.sender).call{value: tokenAmount}("");
                    require(success, "ERR: FAIL_SENDING_ETH");
                }

                emit Withdraw(msg.sender, _token, _yieldCurrency, tokenAmount, _fee, _beforeMaturityDate);
            }
        }
    }

    function rollToNewMaturity(address _yieldCurrency, uint8 _yieldCurrencyId, uint88 _amount, uint8 _ethMarketIndex, uint32 _maxImpliedRate, uint256 _maturity, uint32 _minLendRate) external {
        require(enableRollToNewMaturity == true, "ERR: NEW_ROLL_STOPPED");
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");

        IS1NotionalFinanceLendProxy(depositors[msg.sender]).rollToNewMaturity(_yieldCurrency, _yieldCurrencyId, _amount, _ethMarketIndex, _maxImpliedRate, _maturity, _minLendRate);
        emit RollToNewMaturity(msg.sender, _yieldCurrency, _amount, _ethMarketIndex, _maturity);
    }

    receive() external payable {}
}

// MN bby ¯\_(ツ)_/¯