// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
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

contract BlocVestTreasury is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Whether it is initialized
    bool private isInitialized;
    uint256 private TIME_UNIT = 1 days;

    IERC20  public token;
    address public dividendToken;
    address public pair;

    uint256 public period = 30;                         // 30 days
    uint256 public withdrawalLimit = 500;               // 5% of total supply
    uint256 public liquidityWithdrawalLimit = 2000;     // 20% of LP supply
    uint256 public buybackRate = 9500;                  // 95%
    uint256 public addLiquidityRate = 9400;             // 94%

    uint256 private startTime;
    uint256 private sumWithdrawals = 0;
    uint256 private sumLiquidityWithdrawals = 0;

    uint256 public performanceFee = 100;     // 1%
    uint256 public performanceLpFee = 200;   // 2%
    address public feeWallet = 0x408c4aDa67aE1244dfeC7D609dea3c232843189A;

    // swap router and path, slipPage
    address public uniRouterAddress;
    address[] public bnbToTokenPath;
    uint256 public slippageFactor = 830;    // 17%
    uint256 public constant slippageFactorUL = 995;

    event TokenBuyBack(uint256 amountETH, uint256 amountToken);
    event LiquidityAdded(uint256 amountETH, uint256 amountToken, uint256 liquidity);
    event SetSwapConfig(address router, uint256 slipPage, address[] path);
    event TransferBuyBackWallet(address staking, address wallet);
    event LiquidityWithdrawn(uint256 amount);
    event Withdrawn(uint256 amount);

    event AddLiquidityRateUpdated(uint256 percent);
    event BuybackRateUpdated(uint256 percent);
    event PeriodUpdated(uint256 duration);
    event LiquidityWithdrawLimitUpdated(uint256 percent);
    event WithdrawLimitUpdated(uint256 percent);
    event ServiceInfoUpdated(address wallet, uint256 performanceFee, uint256 liquidityFee);

    constructor() {}
   
    /**
     * @notice Initialize the contract
     * @param _token: token address
     * @param _dividendToken: reflection token address
     * @param _uniRouter: uniswap router address for swap tokens
     * @param _bnbToTokenPath: swap path to buy Token
     */
    function initialize(
        IERC20 _token,
        address _dividendToken,
        address _uniRouter,
        address[] memory _bnbToTokenPath
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");

        // Make this contract initialized
        isInitialized = true;

        token = _token;
        dividendToken = _dividendToken;
        pair = IUniV2Factory(IUniRouter02(_uniRouter).factory()).getPair(_bnbToTokenPath[0], address(token));

        uniRouterAddress = _uniRouter;
        bnbToTokenPath = _bnbToTokenPath;
    }

    /**
     * @notice Buy token from BNB
     */
    function buyBack() external onlyOwner nonReentrant {
        uint256 ethAmt = address(this).balance;
        uint256 _fee = ethAmt * performanceFee / 10000;
        if(_fee > 0) {
            payable(feeWallet).transfer(_fee);
            ethAmt = ethAmt - _fee;
        }
        ethAmt = ethAmt * buybackRate / 10000;

        if(ethAmt > 0) {
            uint256[] memory amounts = _safeSwapEth(ethAmt, bnbToTokenPath, address(this));
            emit TokenBuyBack(amounts[0], amounts[amounts.length - 1]);
        }
    }

    
    /**
     * @notice Add liquidity
     */
    function addLiquidity() external onlyOwner nonReentrant {
        uint256 ethAmt = address(this).balance;
        uint256 _fee = ethAmt * performanceLpFee / 10000;
        if(_fee > 0) {
            payable(feeWallet).transfer(_fee);
            ethAmt = ethAmt - _fee;
        }
        ethAmt = ethAmt * addLiquidityRate / 10000 / 2;

        if(ethAmt > 0) {
            uint256[] memory amounts = _safeSwapEth(ethAmt, bnbToTokenPath, address(this));
            uint256 _tokenAmt = amounts[amounts.length - 1];
            emit TokenBuyBack(amounts[0], _tokenAmt);
            
            (uint256 amountToken, uint256 amountETH, uint256 liquidity) = _addLiquidityEth(address(token), ethAmt, _tokenAmt, address(this));
            emit LiquidityAdded(amountETH, amountToken, liquidity);
        }
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
     * @notice Harvest reflection for token
     */
    function harvest() external onlyOwner {
        if(dividendToken == address(0x0)) {
            uint256 ethAmt = address(this).balance;
            if(ethAmt > 0) {
                payable(msg.sender).transfer(ethAmt);
            }
        } else {
            uint256 tokenAmt = IERC20(dividendToken).balanceOf(address(this));
            if(tokenAmt > 0) {
                IERC20(dividendToken).transfer(msg.sender, tokenAmt);
            }
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

    function setServiceInfo(address _wallet, uint256 _fee) external {
        require(msg.sender == feeWallet, "Invalid setter");
        require(_wallet != feeWallet && _wallet != address(0x0), "Invalid new wallet");
        require(_fee < 500, "invalid performance fee");
       
        feeWallet = _wallet;
        performanceFee = _fee;
        performanceLpFee = _fee * 2;

        emit ServiceInfoUpdated(_wallet, performanceFee, performanceLpFee);
    }
    
    /**
     * @notice Set buyback wallet of farm contract
     * @param _uniRouter: dex router address
     * @param _slipPage: slip page for swap
     * @param _path: bnb-token swap path
     */
    function setSwapSettings(address _uniRouter, uint256 _slipPage, address[] memory _path) external onlyOwner {
        require(_slipPage < 1000, "Invalid percentage");

        uniRouterAddress = _uniRouter;
        slippageFactor = _slipPage;
        bnbToTokenPath = _path;

        emit SetSwapConfig(_uniRouter, _slipPage, _path);
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
    function recoverWrongTokens(address _token) external onlyOwner {
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
    /*
     * @notice get token from ETH via swap.
     */
    function _safeSwapEth(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal returns (uint256[] memory amounts) {
        amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length - 1];

        IUniRouter02(uniRouterAddress).swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amountIn}(
            amountOut * slippageFactor / 1000,
            _path,
            _to,
            block.timestamp + 600
        );
    }

    /*
     * @notice Add liquidity for Token-BNB pair.
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