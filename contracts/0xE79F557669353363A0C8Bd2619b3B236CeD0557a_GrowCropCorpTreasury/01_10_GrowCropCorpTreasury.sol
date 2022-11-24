// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Brewlabs
 * This treasury contract has been developed by brewlabs.info
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../libs/IUniFactory.sol";
import "../libs/IUniRouter02.sol";

interface IStaking {
  function performanceFee() external view returns (uint256);

  function setServiceInfo(address _addr, uint256 _fee) external;
}

interface IFarm {
  function setBuyBackWallet(address _addr) external;
}

contract GrowCropCorpTreasury is Ownable {
  using SafeERC20 for IERC20;

  bool private isInitialized;
  uint256 private constant TIME_UNIT = 1 days;
  uint256 private constant PERCENT_PRECISION = 10000;

  IERC20 public token;
  address public dividendToken;
  address public pair;
  address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  uint256 public period = 30; // 30 days
  uint256 public withdrawalLimit = 500; // 5% of total supply
  uint256 public liquidityWithdrawalLimit = 2000; // 20% of LP supply
  uint256 public buybackRate = 9500; // 95%
  uint256 public addLiquidityRate = 9400; // 94%

  uint256 private startTime;
  uint256 private sumWithdrawals = 0;
  uint256 private sumLiquidityWithdrawals = 0;

  uint256 public performanceFee = 100; // 1%
  uint256 public performanceLpFee = 200; // 2%
  address public feeWallet = 0x64961Ffd0d84b2355eC2B5d35B0d8D8825A774dc;

  address public uniRouterAddress;
  address[] public ethToTokenPath;
  address[] public ethToDividendPath;
  address[] public dividendToTokenPath;
  uint256 public slippageFactor = 8300; // 17%
  uint256 public constant slippageFactorUL = 9950;

  event Initialized(
    address token,
    address dividendToken,
    address router,
    address[] ethToTokenPath,
    address[] ethToDividendPath,
    address[] dividendToTokenPath
  );

  event TokenBuyBack(uint256 amountETH, uint256 amountToken);
  event TokenBuyBackFromDividend(uint256 amount, uint256 amountToken);
  event LiquidityAdded(uint256 amountETH, uint256 amountToken, uint256 liquidity);
  event LiquidityWithdrawn(uint256 amount);
  event Withdrawn(uint256 amount);
  event Harvested(address account, uint256 amount);
  event Swapped(address token, uint256 amountETH, uint256 amountToken);

  event EthHarvested(address to, uint256 amount);
  event EmergencyWithdrawn();
  event AdminTokenRecovered(address tokenRecovered, uint256 amount);
  event UsdcHarvested(address to, uint256[] amounts);

  event SetSwapConfig(
    address router,
    uint256 slipPage,
    address[] ethToTokenPath,
    address[] ethToDividendPath,
    address[] dividendToTokenPath
  );
  event TransferBuyBackWallet(address staking, address wallet);
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
    require(_uniRouter != address(0x0), "invalid address");
    require(address(_token) != address(0x0), "invalid token address");

    // Make this contract initialized
    isInitialized = true;

    token = _token;
    dividendToken = _dividendToken;
    pair = IUniV2Factory(IUniRouter02(_uniRouter).factory()).getPair(_ethToTokenPath[0], address(token));

    uniRouterAddress = _uniRouter;
    ethToTokenPath = _ethToTokenPath;
    ethToDividendPath = _ethToDividendPath;
    dividendToTokenPath = _dividendToTokenPath;

    emit Initialized(
      address(_token),
      _dividendToken,
      _uniRouter,
      _ethToTokenPath,
      _ethToDividendPath,
      _dividendToTokenPath
    );
  }

  /**
   * @notice Buy token from ETH
   */
  function buyBack() external onlyOwner {
    uint256 ethAmt = address(this).balance;
    uint256 _fee = (ethAmt * performanceFee) / PERCENT_PRECISION;
    if (_fee > 0) {
      payable(feeWallet).transfer(_fee);
      ethAmt = ethAmt - _fee;
    }
    ethAmt = (ethAmt * buybackRate) / PERCENT_PRECISION;

    if (ethAmt > 0) {
      uint256 _tokenAmt = _safeSwapEth(ethAmt, ethToTokenPath, address(this));
      emit TokenBuyBack(ethAmt, _tokenAmt);
    }
  }

  /**
   * @notice Buy token from reflections
   */
  function buyBackFromDividend() external onlyOwner {
    if (dividendToken == address(0x0) || dividendToken == address(token)) return;

    uint256 reflections = IERC20(dividendToken).balanceOf(address(this));
    if (reflections > 0) {
      uint256 _tokenAmt = _safeSwap(reflections, dividendToTokenPath, address(this));
      emit TokenBuyBackFromDividend(reflections, _tokenAmt);
    }
  }

  /**
   * @notice Add liquidity
   */
  function addLiquidity() external onlyOwner {
    uint256 ethAmt = address(this).balance;
    uint256 _fee = (ethAmt * performanceLpFee) / PERCENT_PRECISION;
    if (_fee > 0) {
      payable(feeWallet).transfer(_fee);
      ethAmt = ethAmt - _fee;
    }
    ethAmt = (ethAmt * addLiquidityRate) / PERCENT_PRECISION / 2;

    if (ethAmt > 0) {
      uint256 _tokenAmt = _safeSwapEth(ethAmt, ethToTokenPath, address(this));
      emit TokenBuyBack(ethAmt, _tokenAmt);

      (uint256 amountToken, uint256 amountETH, uint256 liquidity) = _addLiquidityEth(
        address(token),
        ethAmt,
        _tokenAmt,
        address(this)
      );
      emit LiquidityAdded(amountETH, amountToken, liquidity);
    }
  }

  /**
   * @notice Swap and harvest reflection for token
   * @param _to: receiver address
   */
  function harvest(address _to) external onlyOwner {
    uint256 ethAmt = address(this).balance;
    ethAmt = (ethAmt * buybackRate) / PERCENT_PRECISION;

    if (dividendToken == address(0x0)) {
      if (ethAmt > 0) {
        payable(_to).transfer(ethAmt);
        emit Harvested(_to, ethAmt);
      }
    } else {
      if (ethAmt > 0) {
        uint256 _tokenAmt = _safeSwapEth(ethAmt, ethToDividendPath, address(this));
        emit Swapped(dividendToken, ethAmt, _tokenAmt);
      }

      uint256 tokenAmt = IERC20(dividendToken).balanceOf(address(this));
      if (tokenAmt > 0) {
        IERC20(dividendToken).transfer(_to, tokenAmt);
        emit Harvested(_to, tokenAmt);
      }
    }
  }

  function harvestETH(address _to) external onlyOwner {
    require(_to != address(0x0), "invalid address");
    uint256 ethAmt = address(this).balance;
    payable(_to).transfer(ethAmt);
    emit EthHarvested(_to, ethAmt);
  }

  function harvestUSDC(address _to) external onlyOwner {
    require(_to != address(0x0), "invalid address");
    uint256 ethAmt = address(this).balance;
    ethAmt = (ethAmt * buybackRate) / PERCENT_PRECISION;

    if (ethAmt == 0) return;

    address[] memory path = new address[](2);
    path[0] = IUniRouter02(uniRouterAddress).WETH();
    path[1] = USDC;

    uint256[] memory amounts = IUniRouter02(uniRouterAddress).swapExactETHForTokens{ value: ethAmt }(
      0,
      path,
      _to,
      block.timestamp + 600
    );
    emit UsdcHarvested(_to, amounts);
  }

  /**
   * @notice Withdraw token as much as maximum 5% of total supply
   * @param _amount: amount to withdraw
   */
  function withdraw(uint256 _amount) external onlyOwner {
    uint256 tokenAmt = token.balanceOf(address(this));
    require(_amount > 0 && _amount <= tokenAmt, "Invalid Amount");

    if (block.timestamp - startTime > period * TIME_UNIT) {
      startTime = block.timestamp;
      sumWithdrawals = 0;
    }

    uint256 limit = (withdrawalLimit * (token.totalSupply())) / PERCENT_PRECISION;
    require(sumWithdrawals + _amount <= limit, "exceed maximum withdrawal limit for 30 days");

    token.safeTransfer(msg.sender, _amount);
    emit Withdrawn(_amount);
  }

  /**
   * @notice Withdraw liquidity
   * @param _amount: amount to withdraw
   */
  function withdrawLiquidity(uint256 _amount) external onlyOwner {
    uint256 tokenAmt = IERC20(pair).balanceOf(address(this));
    require(_amount > 0 && _amount <= tokenAmt, "Invalid Amount");

    if (block.timestamp - startTime > period * TIME_UNIT) {
      startTime = block.timestamp;
      sumLiquidityWithdrawals = 0;
    }

    uint256 limit = (liquidityWithdrawalLimit * (IERC20(pair).totalSupply())) / PERCENT_PRECISION;
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
    if (tokenAmt > 0) {
      token.transfer(msg.sender, tokenAmt);
    }

    tokenAmt = IERC20(pair).balanceOf(address(this));
    if (tokenAmt > 0) {
      IERC20(pair).transfer(msg.sender, tokenAmt);
    }

    uint256 ethAmt = address(this).balance;
    if (ethAmt > 0) {
      payable(msg.sender).transfer(ethAmt);
    }
    emit EmergencyWithdrawn();
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
    require(_percent < PERCENT_PRECISION, "Invalid percentage");

    liquidityWithdrawalLimit = _percent;
    emit LiquidityWithdrawLimitUpdated(_percent);
  }

  /**
   * @notice Set withdraw limit
   * @param _percent: percentage of total supply in point
   */
  function setWithdrawalLimit(uint256 _percent) external onlyOwner {
    require(_percent < PERCENT_PRECISION, "Invalid percentage");

    withdrawalLimit = _percent;
    emit WithdrawLimitUpdated(_percent);
  }

  /**
   * @notice Set buyback rate
   * @param _percent: percentage in point
   */
  function setBuybackRate(uint256 _percent) external onlyOwner {
    require(_percent < PERCENT_PRECISION, "Invalid percentage");

    buybackRate = _percent;
    emit BuybackRateUpdated(_percent);
  }

  function setServiceInfo(address _wallet, uint256 _fee) external {
    require(msg.sender == feeWallet, "Invalid setter");
    require(_wallet != feeWallet && _wallet != address(0x0), "Invalid new wallet");
    require(_fee < 1000, "invalid performance fee");

    feeWallet = _wallet;
    performanceFee = _fee;
    performanceLpFee = _fee * 2;

    emit ServiceInfoUpdated(_wallet, performanceFee, performanceLpFee);
  }

  /**
   * @notice Set addliquidy rate
   * @param _percent: percentage in point
   */
  function setAddLiquidityRate(uint256 _percent) external onlyOwner {
    require(_percent < PERCENT_PRECISION, "Invalid percentage");

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
    require(_uniRouter != address(0x0), "invalid address");
    require(_slipPage <= slippageFactorUL, "_slippage too high");

    uniRouterAddress = _uniRouter;
    slippageFactor = _slipPage;
    ethToTokenPath = _ethToTokenPath;
    ethToDividendPath = _ethToDividendPath;
    dividendToTokenPath = _dividendToTokenPath;

    emit SetSwapConfig(_uniRouter, _slipPage, _ethToTokenPath, _ethToDividendPath, _dividendToTokenPath);
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
    require(
      _token != address(token) && _token != dividendToken && _token != pair,
      "Cannot be token & dividend token, pair"
    );

    uint256 _tokenAmount;
    if (_token == address(0x0)) {
      _tokenAmount = address(this).balance;
      payable(msg.sender).transfer(_tokenAmount);
    } else {
      _tokenAmount = IERC20(_token).balanceOf(address(this));
      IERC20(_token).safeTransfer(msg.sender, _tokenAmount);
    }
    emit AdminTokenRecovered(_token, _tokenAmount);
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
    IUniRouter02(uniRouterAddress).swapExactETHForTokensSupportingFeeOnTransferTokens{ value: _amountIn }(
      (amountOut * slippageFactor) / PERCENT_PRECISION,
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
  ) internal returns (uint256) {
    uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
    uint256 amountOut = amounts[amounts.length - 1];

    IERC20(_path[0]).safeApprove(uniRouterAddress, _amountIn);

    address _token = _path[_path.length - 1];
    uint256 beforeAmt = IERC20(_token).balanceOf(address(this));
    IUniRouter02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
      _amountIn,
      (amountOut * slippageFactor) / PERCENT_PRECISION,
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
  )
    internal
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    )
  {
    IERC20(_token).safeIncreaseAllowance(uniRouterAddress, _tokenAmt);

    (amountToken, amountETH, liquidity) = IUniRouter02(uniRouterAddress).addLiquidityETH{ value: _ethAmt }(
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