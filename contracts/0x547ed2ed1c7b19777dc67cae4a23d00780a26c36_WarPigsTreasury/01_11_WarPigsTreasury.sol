// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Brewlabs
 * This treasury contract has been developed by brewlabs.info
 */
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import "../libs/IUniFactory.sol";
import "../libs/IUniRouter02.sol";
import "../libs/IWETH.sol";

interface IStaking {
    function performanceFee() external view returns(uint256);
    function setServiceInfo(address _addr, uint256 _fee) external;
}

interface IFarm {
    function setBuyBackWallet(address _addr) external;
}

contract WarPigsTreasury is Ownable {
    using SafeERC20 for IERC20;

    bool private isInitialized;
    uint256 private TIME_UNIT = 1 days;

    IERC20  public token;
    address public dividendToken;
    address public pair;

    address public tokenB;

    uint256 public period = 30;                         // 30 days
    uint256 public withdrawalLimit = 500;               // 5% of total supply
    uint256 public liquidityWithdrawalLimit = 2000;     // 20% of LP supply
    uint256 public buybackRate = 9500;                  // 95%
    uint256 public addLiquidityRate = 9400;             // 94%

    uint256 private startTime;
    uint256 private sumWithdrawals = 0;
    uint256 private sumLiquidityWithdrawals = 0;

    address public uniRouterAddress;
    address[] public ethToTokenPath;
    address[] public ethToDividendPath;
    address[] public dividendToTokenPath;
    address[] public ethToTokenBPath;
    uint256 public slippageFactor = 830;    // 17%
    uint256 public constant slippageFactorUL = 995;

    event TokenBuyBack(uint256 amountETH, uint256 amountToken);
    event TokenBuyBackForTokenB(uint256 amountETH, uint256 amountToken);
    event TokenBuyBackFromDividend(uint256 amount, uint256 amountToken);
    event LiquidityAdded(uint256 amountETH, uint256 amountToken, uint256 liquidity);
    event LiquidityAddedForTokenB(uint256 amountETH, uint256 amountToken, uint256 liquidity);
    event LiquidityWithdrawn(uint256 amount);
    event Withdrawn(uint256 amount);
    event Harvested(address account, uint256 amount);
    event Swapped(address token, uint256 amountETH, uint256 amountToken);

    event SetSwapConfig(address router, uint256 slipPage, address[] ethToTokenPath, address[] ethToDividendPath, address[] dividendToTokenPath);
    event SetSwapConfigForTokenB(address tokenB, address[] ethToTokenBPath);
    event TransferBuyBackWallet(address staking, address wallet);
    event AddLiquidityRateUpdated(uint256 percent);
    event BuybackRateUpdated(uint256 percent);
    event PeriodUpdated(uint256 duration);
    event LiquidityWithdrawLimitUpdated(uint256 percent);
    event WithdrawLimitUpdated(uint256 percent);

    constructor() {}
   
    /**
     * @notice Initialize the contract
     * @param _token: token address
     * @param _dividendToken: reflection token address
     * @param _uniRouter: uniswap router address for swap tokens
     * @param _ethToTokenPath: swap path to buy Token
     * @param _ethToDividendPath: swap path to buy dividend token 
     * @param _dividendToTokenPath: swap path to buy Token with dividend token
     */
    function initialize(
        IERC20 _token,
        address _dividendToken,
        address _uniRouter,
        address[] memory _ethToTokenPath,
        address[] memory _ethToDividendPath,
        address[] memory _dividendToTokenPath
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");

        // Make this contract initialized
        isInitialized = true;

        token = _token;
        dividendToken = _dividendToken;
        pair = IUniV2Factory(IUniRouter02(_uniRouter).factory()).getPair(_ethToTokenPath[0], address(token));

        uniRouterAddress = _uniRouter;
        ethToTokenPath = _ethToTokenPath;
        ethToDividendPath = _ethToDividendPath;
        dividendToTokenPath = _dividendToTokenPath;
    }

    /**
     * @notice Buy token from ETH
     */     
    function buyBack() external onlyOwner {
        uint256 ethAmt = address(this).balance;
        ethAmt = ethAmt * buybackRate / 10000;

        if(ethAmt > 0) {
            uint256 _tokenAmt = _safeSwapEth(ethAmt, ethToTokenPath, address(this));
            emit TokenBuyBack(ethAmt, _tokenAmt);
        }
    }

    /**
     * @notice Buy tokenB from ETH
     */     
    function buyBackTokenB() external onlyOwner {
        uint256 ethAmt = address(this).balance;
        ethAmt = ethAmt * buybackRate / 10000;

        if(ethAmt > 0) {
            uint256 _tokenAmt = _safeSwapEth(ethAmt, ethToTokenBPath, address(this));
            emit TokenBuyBackForTokenB(ethAmt, _tokenAmt);
        }
    }

    /**
     * @notice Buy token from reflections
     */
    function buyBackFromDividend() external onlyOwner {
        if(dividendToken == address(0x0)) return;

        uint256 reflections = IERC20(dividendToken).balanceOf(address(this));
        if(reflections > 0) {
            uint256 _tokenAmt = _safeSwap(reflections, dividendToTokenPath, address(this));
            emit TokenBuyBackFromDividend(reflections, _tokenAmt);
        }
    }
    
    /**
     * @notice Add liquidity
     */
    function addLiquidity() external onlyOwner {
        uint256 ethAmt = address(this).balance;
        ethAmt = ethAmt * addLiquidityRate / 10000 / 2;

        if(ethAmt > 0) {
            uint256 _tokenAmt = _safeSwapEth(ethAmt, ethToTokenPath, address(this));
            emit TokenBuyBack(ethAmt, _tokenAmt);
            
            (uint256 amountToken, uint256 amountETH, uint256 liquidity) = _addLiquidityEth(address(token), ethAmt, _tokenAmt, address(this));
            emit LiquidityAdded(amountETH, amountToken, liquidity);
        }
    }

    /**
     * @notice Add liquidity for tokenB
     */
    function addLiquidityForTokenB() external onlyOwner {
        uint256 ethAmt = address(this).balance;
        ethAmt = ethAmt * addLiquidityRate / 10000 / 2;

        if(ethAmt > 0) {
            uint256 _tokenAmt = _safeSwapEth(ethAmt, ethToTokenBPath, address(this));
            emit TokenBuyBackForTokenB(ethAmt, _tokenAmt);
            
            (uint256 amountToken, uint256 amountETH, uint256 liquidity) = _addLiquidityEth(address(tokenB), ethAmt, _tokenAmt, address(this));
            emit LiquidityAddedForTokenB(amountETH, amountToken, liquidity);
        }
    }
    
    /**
     * @notice Swap and harvest reflection for token
     * @param _to: receiver address
     */
    function harvest(address _to) external onlyOwner {
        uint256 ethAmt = address(this).balance;
        ethAmt = ethAmt * buybackRate / 10000;

        if(dividendToken == address(0x0)) {
            if(ethAmt > 0) {
                payable(_to).transfer(ethAmt);
                emit Harvested(_to, ethAmt);
            }
        } else {
            if(ethAmt > 0) {
                uint256 _tokenAmt = _safeSwapEth(ethAmt, ethToDividendPath, address(this));
                emit Swapped(dividendToken, ethAmt, _tokenAmt);
            }

            uint256 tokenAmt = IERC20(dividendToken).balanceOf(address(this));
            if(tokenAmt > 0) {
                IERC20(dividendToken).transfer(_to, tokenAmt);
                emit Harvested(_to, tokenAmt);
            }
        }
    }

    function harvestETH(address _to) external onlyOwner {
        uint256 ethAmt = address(this).balance;
        payable(_to).transfer(ethAmt);
    }

    /**
     * @notice Withdraw token as much as maximum 5% of total supply
     * @param _amount: amount to withdraw
     */
    function withdraw(uint256 _amount) external onlyOwner {
        uint256 tokenAmt = token.balanceOf(address(this));
        require(_amount > 0 && _amount <= tokenAmt, "Invalid Amount");

        if(block.timestamp - startTime > period * TIME_UNIT) {
            startTime = block.timestamp;
            sumWithdrawals = 0;
        }

        uint256 limit = withdrawalLimit * (token.totalSupply()) / 10000;
        require(sumWithdrawals + _amount <= limit, "exceed maximum withdrawal limit for 30 days");

        token.safeTransfer(msg.sender, _amount);
        emit Withdrawn(_amount);
    }

    /**
     * @notice Withdraw token as much as maximum 20% of lp supply
     * @param _amount: liquidity amount to withdraw
     */
    function withdrawLiquidity(uint256 _amount) external onlyOwner {
        uint256 tokenAmt = IERC20(pair).balanceOf(address(this));
        require(_amount > 0 && _amount <= tokenAmt, "Invalid Amount");

        if(block.timestamp - startTime > period * TIME_UNIT) {
            startTime = block.timestamp;
            sumLiquidityWithdrawals = 0;
        }

        uint256 limit = liquidityWithdrawalLimit * (IERC20(pair).totalSupply()) / 10000;
        require(sumLiquidityWithdrawals + _amount <= limit, "exceed maximum LP withdrawal limit for 30 days");

        IERC20(pair).safeTransfer(msg.sender, _amount);
        emit LiquidityWithdrawn(_amount);
    }
    
    /**
     * @notice Withdraw tokens
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 tokenAmt = token.balanceOf(address(this));
        if(tokenAmt > 0) {
            token.transfer(msg.sender, tokenAmt);
        }

        tokenAmt = IERC20(pair).balanceOf(address(this));
        if(tokenAmt > 0) {
            IERC20(pair).transfer(msg.sender, tokenAmt);
        }

        uint256 ethAmt = address(this).balance;
        if(ethAmt > 0) {
            payable(msg.sender).transfer(ethAmt);
        }
    }

    /**
     * @notice Set duration for withdraw limit
     * @param _period: duration
     */
    function setWithdrawalLimitPeriod(uint256 _period) external onlyOwner {
        require(_period >= 10, "small period");
        period = _period;
        emit PeriodUpdated(_period);
    }

    /**
     * @notice Set liquidity withdraw limit
     * @param _percent: percentage of LP supply in point
     */
    function setLiquidityWithdrawalLimit(uint256 _percent) external onlyOwner {
        require(_percent < 10000, "Invalid percentage");
        
        liquidityWithdrawalLimit = _percent;
        emit LiquidityWithdrawLimitUpdated(_percent);
    }

    /**
     * @notice Set withdraw limit
     * @param _percent: percentage of total supply in point
     */
    function setWithdrawalLimit(uint256 _percent) external onlyOwner {
        require(_percent < 10000, "Invalid percentage");
        
        withdrawalLimit = _percent;
        emit WithdrawLimitUpdated(_percent);
    }
    
    /**
     * @notice Set buyback rate
     * @param _percent: percentage in point
     */
    function setBuybackRate(uint256 _percent) external onlyOwner {
        require(_percent < 10000, "Invalid percentage");

        buybackRate = _percent;
        emit BuybackRateUpdated(_percent);
    }

    /**
     * @notice Set addliquidy rate
     * @param _percent: percentage in point
     */
    function setAddLiquidityRate(uint256 _percent) external onlyOwner {
        require(_percent < 10000, "Invalid percentage");

        addLiquidityRate = _percent;
        emit AddLiquidityRateUpdated(_percent);
    }
    
    /**
     * @notice Set buyback wallet of farm contract
     * @param _uniRouter: dex router address
     * @param _slipPage: slip page for swap
     * @param _ethToTokenPath: eth-token swap path
     * @param _ethToDividendPath: eth-token swap path
     * @param _dividendToTokenPath: eth-token swap path
     */
    function setSwapSettings(
        address _uniRouter, 
        uint256 _slipPage, 
        address[] memory _ethToTokenPath, 
        address[] memory _ethToDividendPath, 
        address[] memory _dividendToTokenPath
    ) external onlyOwner {
        require(_slipPage < 1000, "Invalid percentage");

        uniRouterAddress = _uniRouter;
        slippageFactor = _slipPage;
        ethToTokenPath = _ethToTokenPath;
        ethToDividendPath = _ethToDividendPath;
        dividendToTokenPath = _dividendToTokenPath;

        emit SetSwapConfig(_uniRouter, _slipPage, _ethToTokenPath, _ethToDividendPath, _dividendToTokenPath);
    }

    function setSwapSettingsForTokenB(
        address _tokenB,
        address[] memory _ethToTokenBPath
    ) external onlyOwner {
        tokenB = _tokenB;
        ethToTokenBPath = _ethToTokenBPath;

        emit SetSwapConfigForTokenB(_tokenB, _ethToTokenBPath);
    }

    /**
     * @notice set buyback wallet of farm contract
     * @param _farm: farm contract address
     * @param _addr: buyback wallet address
     */
    function setFarmServiceInfo(address _farm, address _addr) external onlyOwner {
        require(_farm != address(0x0) && _addr != address(0x0), "Invalid Address");
        IFarm(_farm).setBuyBackWallet(_addr);

        emit TransferBuyBackWallet(_farm, _addr);
    }

    /**
     * @notice set buyback wallet of staking contract 
     * @param _staking: staking contract address
     * @param _addr: buyback wallet address
     */
    function setStakingServiceInfo(address _staking, address _addr) external onlyOwner {
        require(_staking != address(0x0) && _addr != address(0x0), "Invalid Address");
        uint256 _fee = IStaking(_staking).performanceFee();
        IStaking(_staking).setServiceInfo(_addr, _fee);

        emit TransferBuyBackWallet(_staking, _addr);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _token: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function rescueTokens(address _token) external onlyOwner {
        require(_token != address(token) && _token != dividendToken && _token != pair, "Cannot be token & dividend token, pair");

        if(_token == address(0x0)) {
            uint256 _tokenAmount = address(this).balance;
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, _tokenAmount);
        }
    }


    /************************
    ** Internal Methods
    *************************/

    /**
     * @notice get token from ETH via swap.
     * @param _amountIn: eth amount to swap
     * @param _path: swap path
     * @param _to: receiver address
     */
    function _safeSwapEth(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal returns (uint256) {
        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length - 1];

        address _token = _path[_path.length - 1];
        uint256 beforeAmt = IERC20(_token).balanceOf(address(this));
        IUniRouter02(uniRouterAddress).swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amountIn}(
            amountOut * slippageFactor / 1000,
            _path,
            _to,
            block.timestamp + 600
        );
        uint256 afterAmt = IERC20(_token).balanceOf(address(this));

        return afterAmt - beforeAmt;
    }

    /**
     * @notice swap token based on path.
     * @param _amountIn: token amount to swap
     * @param _path: swap path
     * @param _to: receiver address
     */
    function _safeSwap(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal returns(uint256) {
        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length - 1];

        IERC20(_path[0]).safeApprove(uniRouterAddress, _amountIn);

        address _token = _path[_path.length - 1];
        uint256 beforeAmt = IERC20(_token).balanceOf(address(this));
        IUniRouter02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            amountOut * slippageFactor / 1000,
            _path,
            _to,
            block.timestamp + 600
        );
        uint256 afterAmt = IERC20(_token).balanceOf(address(this));

        return afterAmt - beforeAmt;
    }

    /**
     * @notice add token-ETH liquidity.
     * @param _token: token address
     * @param _ethAmt: eth amount to add liquidity
     * @param _tokenAmt: token amount to add liquidity
     * @param _to: receiver address
     */
    function _addLiquidityEth(
        address _token,
        uint256 _ethAmt,
        uint256 _tokenAmt,
        address _to
    ) internal returns(uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        IERC20(_token).safeIncreaseAllowance(uniRouterAddress, _tokenAmt);

        (amountToken, amountETH, liquidity) = IUniRouter02(uniRouterAddress).addLiquidityETH{value: _ethAmt}(
            address(_token),
            _tokenAmt,
            0,
            0,
            _to,
            block.timestamp + 600
        );

        IERC20(_token).safeApprove(uniRouterAddress, uint256(0));
    }


    receive() external payable {}
}