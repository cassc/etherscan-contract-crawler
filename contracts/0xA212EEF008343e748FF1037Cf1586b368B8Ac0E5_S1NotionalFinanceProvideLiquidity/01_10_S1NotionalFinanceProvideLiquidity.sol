// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapConnector.sol";
import "./interfaces/IBalancerVault.sol";
import "./interfaces/IS1NotionalFinanceProvideLiquidityProxy.sol";
import "./proxies/S1NotionalFinanceProvideLiquidityProxy.sol";
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


contract S1NotionalFinanceProvideLiquidity is Ownable {
    uint8 constant public strategyIndex = 21;
    address public feesAddress;
    address public uniswapConnector;
    address public balancerVault;
    address public wethAddress;

    // protocols
    address public notionalProxy;
    address public NOTE;
    bytes32 public NOTEPoolId;

    mapping(address => address) public depositors;

    constructor(
        address _feesAddress,
        address _uniswapConnector,
        address _balancerVault,
        address _wethAddress,
        address _notionalProxy,
        address _NOTE,
        bytes32 _NOTEPoolId
    ) {
        feesAddress = _feesAddress;
        uniswapConnector = _uniswapConnector;
        balancerVault = _balancerVault;
        wethAddress = _wethAddress;
        notionalProxy = _notionalProxy;
        NOTE = _NOTE;
        NOTEPoolId = _NOTEPoolId;
    }

    event Deposit(address indexed _depositor, address indexed _token, address indexed _yieldCurrency, uint256 _amountIn, uint256 _amountOut);

    event ProxyCreation(address indexed _depositor, address indexed _proxy);

    event Withdraw(address indexed _depositor, address indexed _token, address indexed _yieldCurrency, uint256 _amount, uint256 _fee);

    event ClaimAdditionalTokens(address indexed _depositor, uint256 _amount0, uint256 _amount1, address indexed _swappedTo);

    function setupNOTEPoolId(bytes32 _NOTEPoolId) external onlyOwner {
        NOTEPoolId = _NOTEPoolId;
    }

    function getPendingAdditionalTokenClaims(address _address) external view returns(uint256, uint256) {
        return (
            INotionalFinance(notionalProxy).nTokenGetClaimableIncentives(depositors[_address], block.timestamp),
            IERC20(NOTE).balanceOf(depositors[_address])
        );
    }

    function getAccountPortfolio(address _address) external view returns(INotionalFinance.PortfolioAsset[] memory) {
        return INotionalFinance(notionalProxy).getAccountPortfolio(depositors[_address]);
    }

    function getAccountBalance(address _address, uint8 _yieldCurrencyId) external view returns(int256, int256, uint256) {
        return INotionalFinance(notionalProxy).getAccountBalance(_yieldCurrencyId, depositors[_address]);
    }

    function nTokenPresentValueUnderlyingDenominated(uint16 currencyId) external view returns (int256) {
        return INotionalFinance(notionalProxy).nTokenPresentValueUnderlyingDenominated(currencyId);
    }

    function nTokenAddress(uint16 currencyId) external view returns (address) {
        return INotionalFinance(notionalProxy).nTokenAddress(currencyId);
    }

    function nTokenTotalSupply(address _nTokenAddress) external view returns (uint256) {
        return INotionalFinance(notionalProxy).nTokenTotalSupply(_nTokenAddress);
    }

    function depositETH(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amountOutMin, INotionalFinance.DepositActionType actionType) external payable {
        require(IFees(feesAddress).depositStatus(strategyIndex), "ERR: DEPOSITS_STOPPED");

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, msg.value, actionType);

            emit Deposit(msg.sender, wethAddress, _yieldCurrency, msg.value, msg.value);  
        } else {
            uint256 depositAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: msg.value}(
                _yieldCurrency, 
                0, 
                _amountOutMin, 
                address(this)
            );
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, actionType);

            emit Deposit(msg.sender, wethAddress, _yieldCurrency, msg.value, depositAmount);  
        }
    }

    function depositToken(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amount, uint256 _amountOutMin, INotionalFinance.DepositActionType actionType) external {
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
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, actionType);
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
            _yieldDeposit(_yieldCurrency, _yieldCurrencyId, depositAmount, actionType);
        }
 
        emit Deposit(msg.sender, _token, _yieldCurrency, _amount, depositAmount);
    }

    function _yieldDeposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, INotionalFinance.DepositActionType actionType) private {
        if (depositors[msg.sender] == address(0)) {
            // deploy new proxy contract
            S1NotionalFinanceProvideLiquidityProxy s1proxy = new S1NotionalFinanceProvideLiquidityProxy(
                address(this),
                notionalProxy,
                NOTE
            );
            depositors[msg.sender] = address(s1proxy);
            if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
                s1proxy.deposit{value: _amount}(_yieldCurrency, _yieldCurrencyId, _amount, actionType);
            } else {
                IERC20(_yieldCurrency).approve(depositors[msg.sender], 2**256 - 1);
                s1proxy.deposit(_yieldCurrency, _yieldCurrencyId, _amount, actionType);
            }

            emit ProxyCreation(msg.sender, address(s1proxy));
        } else {
            // send the deposit to the existing proxy contract
            if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
                IS1NotionalFinanceProvideLiquidityProxy(depositors[msg.sender]).deposit{value: _amount}(_yieldCurrency, _yieldCurrencyId, _amount, actionType);
            } else {
                if (IERC20(_yieldCurrency).allowance(address(this), depositors[msg.sender]) == 0) {
                    IERC20(_yieldCurrency).approve(depositors[msg.sender], 2**256 - 1); 
                }

                IS1NotionalFinanceProvideLiquidityProxy(depositors[msg.sender]).deposit(_yieldCurrency, _yieldCurrencyId, _amount, actionType);
            }
        }
    }

    // claim NOTE tokens and withdraw them
    function claimRaw() external {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 noteTokens = IS1NotionalFinanceProvideLiquidityProxy(depositors[msg.sender]).claimToDepositor(msg.sender); 

        emit ClaimAdditionalTokens(msg.sender, noteTokens, 0, address(0));
    }

    // claim NOTE tokens, swap them for ETH and withdraw
    function claimInETH(uint256 _amountOutMin) external {
        claimInToken(address(0), _amountOutMin, 0);  
    }

    // claim NOTE tokens, swap them for _token and withdraw
    function claimInToken(address _token, uint256 _wethAmountOutMin, uint256 _tokenAmountOutMin) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        uint256 noteTokens = IS1NotionalFinanceProvideLiquidityProxy(depositors[msg.sender]).claimToDeployer();

        uint256 swapResult;
        if (noteTokens > 0) {
            if (IERC20(NOTE).allowance(address(this), balancerVault) == 0) {
                IERC20(NOTE).approve(balancerVault, 2**256 - 1);
            }

            address recipient;
            if (_token == address(0)) {
                recipient = msg.sender;
            } else {
                recipient = address(this);
            }

            // swap NOTE to ETH at Balancer
            swapResult = IBalancerVault(balancerVault).swap(
                IBalancerVault.SingleSwap({
                    poolId: NOTEPoolId,
                    kind: IBalancerVault.SwapKind.GIVEN_IN,
                    assetIn: NOTE,
                    assetOut: address(0),
                    amount: noteTokens,
                    userData: "0x"
                }),
                IBalancerVault.FundManagement({
                    sender: address(this),
                    fromInternalBalance: false,
                    recipient: payable(recipient),
                    toInternalBalance: false
                }),
                _wethAmountOutMin,
                block.timestamp + 7200
            );

            // swap ETH to _token at Uniswap
            if (_token != address(0)) {
                swapResult = IUniswapConnector(uniswapConnector).swapETHForToken{value: swapResult}(
                    _token, 
                    0, 
                    _tokenAmountOutMin, 
                    msg.sender
                );
            }
        }

        emit ClaimAdditionalTokens(msg.sender, noteTokens, swapResult, _token);
    }

    function withdrawETH(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, uint256 _amountOutMin, address _feeToken, INotionalFinance.DepositActionType actionType) external {
        withdrawToken(_yieldCurrency, _yieldCurrencyId, wethAddress, _amount, _amountOutMin, _feeToken, actionType);
    }

    function withdrawToken(address _yieldCurrency, uint8 _yieldCurrencyId, address _token, uint256 _amount, uint256 _amountOutMin, address _feeToken, INotionalFinance.DepositActionType actionType) public {
        require(depositors[msg.sender] != address(0), "ERR: INVALID_DEPOSITOR");
        (uint256 yieldDeposit, uint256 fee) = _withdrawYieldDeposit(_yieldCurrency, _yieldCurrencyId, _amount, _feeToken, actionType);

        if (_yieldCurrency == address(0) && _yieldCurrencyId == 1) {
            if (_token == wethAddress) {
                // withdraw ETH
                (bool success, ) = payable(msg.sender).call{value: yieldDeposit - fee}("");
                require(success, "ERR: FAIL_SENDING_ETH");
                emit Withdraw(msg.sender, wethAddress, _yieldCurrency, yieldDeposit - fee, fee);
            } else {
                uint256 tokenAmount = IUniswapConnector(uniswapConnector).swapETHForToken{value: yieldDeposit - fee}(
                    _token, 
                    0, 
                    _amountOutMin, 
                    msg.sender
                );

                emit Withdraw(msg.sender, _token, _yieldCurrency, tokenAmount, fee);
            }
        } else {
            if (_token == _yieldCurrency) { 
                // withdraw USDC
                IERC20(_yieldCurrency).transfer(
                    msg.sender,
                    yieldDeposit - fee
                );

                emit Withdraw(msg.sender, _token, _yieldCurrency, yieldDeposit - fee, fee);
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
                    yieldDeposit - fee, 
                    _amountOutMin, 
                    receiver
                );

                if (_token == wethAddress) {
                    IWETH(wethAddress).withdraw(tokenAmount);
                    (bool success, ) = payable(msg.sender).call{value: tokenAmount}("");
                    require(success, "ERR: FAIL_SENDING_ETH");
                }

                emit Withdraw(msg.sender, _token, _yieldCurrency, tokenAmount, fee);
            }
        }
    }

    function _withdrawYieldDeposit(address _yieldCurrency, uint8 _yieldCurrencyId, uint256 _amount, address _feeToken, INotionalFinance.DepositActionType actionType) private returns(uint256, uint256) {
        uint256 amountToBeWithdrawn = IS1NotionalFinanceProvideLiquidityProxy(depositors[msg.sender]).withdraw(_yieldCurrency, _yieldCurrencyId, _amount, actionType); 
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

    receive() external payable {}
}

// MN bby ¯\_(ツ)_/¯