// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/INotionalFinance.sol";


contract S1NotionalFinanceProvideLiquidityProxy {
    address private deployer;
    address public notionalProxy;
    address public NOTE;

    constructor(
        address _deployer,
        address _notionalProxy,
        address _NOTE
    ) {
        deployer = _deployer;
        notionalProxy = _notionalProxy;
        NOTE = _NOTE;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "ERR: WRONG_DEPLOYER");
        _;
    } 

    function deposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType actionType) external payable onlyDeployer {
        if (_yieldCurrency != address(0) && _yieldCurrencyId != 1) {
            if (IERC20(_yieldCurrency).allowance(address(this), deployer) == 0) {
                IERC20(_yieldCurrency).approve(deployer, 2**256 - 1);
            }

            if (IERC20(_yieldCurrency).allowance(address(this), notionalProxy) == 0) {
                IERC20(_yieldCurrency).approve(notionalProxy, 2**256 - 1);
            }
            
            IERC20(_yieldCurrency).transferFrom(deployer, address(this), _amount);
        }

        INotionalFinance.BalanceAction[] memory actions = new INotionalFinance.BalanceAction[](1);
        actions[0] = INotionalFinance.BalanceAction({
            actionType: actionType,
            currencyId: _yieldCurrencyId,
            depositActionAmount: _amount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: false,
            redeemToUnderlying: false
        });

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            INotionalFinance(notionalProxy).batchBalanceAction{value: _amount}(address(this), actions);
        } else {
            INotionalFinance(notionalProxy).batchBalanceAction(address(this), actions);
        }
    }

    function withdraw(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType actionType) external onlyDeployer returns(uint256) {
        INotionalFinance.BalanceAction[] memory actions = new INotionalFinance.BalanceAction[](1);
        actions[0] = INotionalFinance.BalanceAction({
            actionType: actionType,
            currencyId: _yieldCurrencyId,
            depositActionAmount: _amount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: true,
            redeemToUnderlying: true
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

    function claimToDepositor(address _depositor) external onlyDeployer returns(uint256) {
        return _claim(_depositor);
    }

    function claimToDeployer() external onlyDeployer returns(uint256) {
        return _claim(deployer);
    }

    function _claim(address _address) private returns(uint256) {
        INotionalFinance(notionalProxy).nTokenClaimIncentives();

        uint256 noteBalance = IERC20(NOTE).balanceOf(address(this));
        if (noteBalance > 0) {
            IERC20(NOTE).transfer(
                _address,
                noteBalance
            );
        }

        return noteBalance;
    }

    receive() external payable {}
}

// MN bby ¯\_(ツ)_/¯