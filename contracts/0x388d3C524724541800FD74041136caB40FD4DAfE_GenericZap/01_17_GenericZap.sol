pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "./ZapBase.sol";
import "./libs/Swap.sol";
import "./interfaces/IBalancerVault.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/ICurvePool.sol";
import "./interfaces/ICurveFactory.sol";


contract GenericZap is ZapBase {

  IUniswapV2Router public immutable uniswapV2Router;
  ICurveFactory private immutable curveFactory = ICurveFactory(0xB9fC157394Af804a3578134A6585C0dc9cc990d4);
  IBalancerVault private immutable balancerVault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

  struct ZapLiquidityRequest {
    uint248 firstSwapMinAmountOut;
    bool useAltFunction;
    uint248 poolSwapMinAmountOut;
    bool isOneSidedLiquidityAddition;
    address otherToken;
    bool shouldTransferResidual;
    uint256 minLiquidityOut;
    uint256 uniAmountAMin;
    uint256 uniAmountBMin;
    bytes poolSwapData;
  }

  event ZappedIn(address indexed sender, address fromToken, uint256 fromAmount, address toToken, uint256 amountOut);
  event ZappedLPUniV2(address indexed recipient, address token0, address token1, uint256 amountA, uint256 amountB);
  event TokenRecovered(address token, address to, uint256 amount);
  event ZappedLPCurve(address indexed recipient, address fromToken, uint256 liquidity, uint256[] amounts);
  event ZappedLiquidityBalancerPool(address indexed recipient, address fromToken, uint256 fromAmount, uint256[] maxAmountsIn);

  constructor (
    address _router
  ) {
    uniswapV2Router = IUniswapV2Router(_router);
  }

  /**
   * @notice recover token or ETH
   * @param _token token to recover
   * @param _to receiver of recovered token
   * @param _amount amount to recover
   */
  function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
    require(_to != address(0), "Invalid receiver");
    if (_token == address(0)) {
      // this is effectively how OpenZeppelin transfers eth
      require(address(this).balance >= _amount, "Address: insufficient balance");
      (bool success,) = _to.call{value: _amount}(""); 
      require(success, "Address: unable to send value");
    } else {
      _transferToken(IERC20(_token), _to, _amount);
    }
    
    emit TokenRecovered(_token, _to, _amount);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to another ERC20 token
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _toToken Exit token
   * @param _amountOutMin The minimum acceptable quantity of exit ERC20 token to receive
   * @param _swapTarget Execution target for the swap
   * @param _swapData DEX data
   * @return amountOut Amount of exit tokens received
   */
  function zapIn(
    address _fromToken,
    uint256 _fromAmount,
    address _toToken,
    uint256 _amountOutMin,
    address _swapTarget,
    bytes memory _swapData
  ) external payable returns (uint256) {
    return zapInFor(_fromToken, _fromAmount, _toToken, _amountOutMin, msg.sender, _swapTarget, _swapData);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into a balancer liquidity pool (one-sided or two-sided)
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _poolId Target balancer pool id
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   * @param _request Params for liquidity addition in balancer pool
   */
  function zapLiquidityBalancerPool(
    address _fromToken,
    uint256 _fromAmount,
    bytes32 _poolId,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest,
    IBalancerVault.JoinPoolRequest memory _request
  ) external payable {
    zapLiquidityBalancerPoolFor(_fromToken, _fromAmount, _poolId, msg.sender, _swapTarget, _swapData, _zapLiqRequest, _request);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into a curve liquidity pool (one-sided or two-sided)
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _pool Target curve pool
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   */
  function zapLiquidityCurvePool(
    address _fromToken,
    uint256 _fromAmount,
    address _pool,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest
  ) external payable {
    zapLiquidityCurvePoolFor(_fromToken, _fromAmount, _pool, msg.sender, _swapTarget, _swapData, _zapLiqRequest);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into adding liquidity into a uniswap v2 liquidity pool
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _pair Target uniswap v2 pair
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   */
  function zapLiquidityUniV2(
    address _fromToken,
    uint256 _fromAmount,
    address _pair,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest
  ) external payable {
    zapLiquidityUniV2For(_fromToken, _fromAmount, _pair, msg.sender, _swapTarget, _swapData, _zapLiqRequest);
  }

  /**
   * @dev Helper function to calculate swap in amount of a token before adding liquidit to uniswap v2 pair
   * @param _token Token to swap in
   * @param _pair Uniswap V2 Pair token
   * @param _amount Amount of token
   * @return uint256 Amount to swap
   */
  function getAmountToSwap(
    address _token,
    address _pair,
    uint256 _amount
  ) external view returns (uint256) {
    return Swap.getAmountToSwap(_token, _pair, _amount);
  }

  /**
   * @dev Helper function to calculate swap in amount of a token before adding liquidit to uniswap v2 pair.
   * Alternative version
   * @param _reserveIn Pair reserve of incoming token
   * @param _userIn Amount of token
   */
  function getSwapInAmount(
    uint256 _reserveIn,
    uint256 _userIn
  ) external pure returns (uint256) {
    return Swap.calculateSwapInAmount(_reserveIn, _userIn);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to another ERC20 token
   * @param fromToken The token used for entry (address(0) if ether)
   * @param fromAmount The amount of fromToken to zap
   * @param toToken Exit token
   * @param amountOutMin The minimum acceptable quantity of exit ERC20 token to receive
   * @param recipient Recipient of exit tokens
   * @param swapTarget Execution target for the swap
   * @param swapData DEX data
   * @return amountOut Amount of exit tokens received
   */
  function zapInFor(
    address fromToken,
    uint256 fromAmount,
    address toToken,
    uint256 amountOutMin,
    address recipient,
    address swapTarget,
    bytes memory swapData
  ) public payable whenNotPaused returns (uint256 amountOut) {
    require(approvedTargets[fromToken][swapTarget] == true, "GenericZaps: Unsupported token/target");

    _pullTokens(fromToken, fromAmount);

    amountOut = Swap.fillQuote(
      fromToken,
      fromAmount,
      toToken,
      swapTarget,
      swapData
    );
    require(amountOut >= amountOutMin, "GenericZaps: Not enough tokens out");
    
    emit ZappedIn(msg.sender, fromToken, fromAmount, toToken, amountOut);

    // transfer token to recipient
    SafeERC20.safeTransfer(
      IERC20(toToken),
      recipient,
      amountOut
    );
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into a balancer liquidity pool (one-sided or two-sided)
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _poolId Target balancer pool id
   * @param _recipient Recipient of LP tokens
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   * @param _request Params for liquidity addition in balancer pool
   */
  function zapLiquidityBalancerPoolFor(
    address _fromToken,
    uint256 _fromAmount,
    bytes32 _poolId,
    address _recipient,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest,
    IBalancerVault.JoinPoolRequest memory _request
  ) public payable whenNotPaused {
    require(approvedTargets[_fromToken][_swapTarget] == true, "GenericZaps: Unsupported token/target");

    _pullTokens(_fromToken, _fromAmount);

    uint256 tokenBoughtIndex;
    uint256 amountBought;
    (address[] memory poolTokens,,) = balancerVault.getPoolTokens(_poolId);
    bool fromTokenIsPoolAsset = false;
    uint i = 0;
    for (; i<poolTokens.length;) {
      if (_fromToken == poolTokens[i]) {
        fromTokenIsPoolAsset = true;
        tokenBoughtIndex = i;
        break;
      }
      unchecked { i++; }
    }
    // fill order and execute swap
    if (!fromTokenIsPoolAsset) {
      (tokenBoughtIndex, amountBought) = _fillQuotePool(
        _fromToken,
        _fromAmount,
        poolTokens,
        _swapTarget,
        _swapData
      );
      require(amountBought >= _zapLiqRequest.firstSwapMinAmountOut, "Insufficient tokens out");
    }

    // swap token into 2 parts. use data from func call args, if not one-sided liquidity addition
    if (!_zapLiqRequest.isOneSidedLiquidityAddition) {
      uint256 toSwap;
      unchecked {
        toSwap = amountBought / 2;
        amountBought -= toSwap;
      }
      // use vault as target
      SafeERC20.safeIncreaseAllowance(IERC20(poolTokens[tokenBoughtIndex]), address(balancerVault), toSwap);
      Executable.execute(address(balancerVault), 0, _zapLiqRequest.poolSwapData);
      // ensure min amounts out swapped for other token
      require(_zapLiqRequest.poolSwapMinAmountOut <= IERC20(_zapLiqRequest.otherToken).balanceOf(address(this)),
        "Insufficient swap output for other token");
    }

    // approve tokens iteratively, ensuring contract has right balance each time
    for (i=0; i<poolTokens.length;) {
      if (_request.maxAmountsIn[i] > 0) {
        require(IERC20(poolTokens[i]).balanceOf(address(this)) >= _request.maxAmountsIn[i], 
          "Insufficient asset tokens");
        SafeERC20.safeIncreaseAllowance(IERC20(poolTokens[i]), address(balancerVault), _request.maxAmountsIn[i]);
      }
      unchecked { i++; }
    }
    // address(this) cos zaps sending the tokens
    balancerVault.joinPool(_poolId, address(this), _recipient, _request);

    emit ZappedLiquidityBalancerPool(_recipient, _fromToken, _fromAmount, _request.maxAmountsIn);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into a curve liquidity pool (one-sided or two-sided)
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _pool Target curve pool
   * @param _recipient Recipient of LP tokens
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   */
  function zapLiquidityCurvePoolFor(
    address _fromToken,
    uint256 _fromAmount,
    address _pool,
    address _recipient,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest
  ) public payable whenNotPaused {

    require(approvedTargets[_fromToken][_swapTarget] == true, "GenericZaps: Unsupported token/target");

    // pull tokens
    _pullTokens(_fromToken, _fromAmount);
    uint256 nCoins;
    if (_zapLiqRequest.useAltFunction) {
      (nCoins,) = curveFactory.get_meta_n_coins(_pool);
    } else {
      nCoins = curveFactory.get_n_coins(_pool);
    }
    address[] memory coins = new address[](nCoins);
    uint256 fromTokenIndex = nCoins; // set wrong index as initial
    uint256 otherTokenIndex = nCoins;
    uint256 i;
    for (i=0; i<nCoins;) {
      coins[i] = ICurvePool(_pool).coins(i);
      if (_fromToken == coins[i]) {
        fromTokenIndex = i;
      } else if (coins[i] == _zapLiqRequest.otherToken) {
        otherTokenIndex = i;
      }
      unchecked { ++i; }
    }
    require(fromTokenIndex != otherTokenIndex && otherTokenIndex != nCoins, "Invalid token indices");
    // fromtoken not a pool coin
    if (fromTokenIndex == nCoins) {
      // reuse fromTokenIndex as coin bought index and fromAmount as amount bought
      (fromTokenIndex, _fromAmount) = 
        _fillQuotePool(
          _fromToken, 
          _fromAmount,
          coins,
          _swapTarget,
          _swapData
        );
        require(_fromAmount >= _zapLiqRequest.firstSwapMinAmountOut, "FillQuote: Insufficient tokens out");
    }
    // to populate coin amounts for liquidity addition
    uint256[] memory coinAmounts = new uint256[](nCoins);
    // if one-sided liquidity addition
    if (_zapLiqRequest.isOneSidedLiquidityAddition) {
      coinAmounts[fromTokenIndex] = _fromAmount;
      require(approvedTargets[coins[fromTokenIndex]][_pool] == true, "Pool not approved");
      SafeERC20.safeIncreaseAllowance(IERC20(coins[fromTokenIndex]), _pool, _fromAmount);
    } else {
      // swap coins
      // add coins in equal parts. assumes two coins
      uint256 amountToSwap;
      unchecked {
        amountToSwap = _fromAmount / 2;
        _fromAmount -= amountToSwap;
      }
      require(approvedTargets[coins[fromTokenIndex]][_pool] == true, "Pool not approved");
      SafeERC20.safeIncreaseAllowance(IERC20(coins[fromTokenIndex]), _pool, amountToSwap);
      uint256 otherTokenBalanceBefore = IERC20(coins[otherTokenIndex]).balanceOf(address(this));
      bytes memory result = Executable.execute(_pool, 0, _zapLiqRequest.poolSwapData);
      // reuse amountToSwap variable for amountReceived
      amountToSwap = abi.decode(result, (uint256));
      require(_zapLiqRequest.poolSwapMinAmountOut <= amountToSwap, 
        "Insufficient swap output for other token");
      require(IERC20(coins[otherTokenIndex]).balanceOf(address(this)) - otherTokenBalanceBefore <= amountToSwap, 
        "Insufficient tokens");
      
      // reinit variable to avoid stack too deep
      uint256 fromAmount = _fromAmount;
      address pool = _pool;
      SafeERC20.safeIncreaseAllowance(IERC20(coins[fromTokenIndex]), pool, fromAmount);
      SafeERC20.safeIncreaseAllowance(IERC20(coins[otherTokenIndex]), pool, amountToSwap);

      coinAmounts[fromTokenIndex] = fromAmount;
      coinAmounts[otherTokenIndex] = amountToSwap;
    }

    uint256 liquidity = _addLiquidityCurvePool(
      _pool,
      _recipient,
      _zapLiqRequest.minLiquidityOut,
      _zapLiqRequest.useAltFunction,
      coinAmounts
    );
    
    emit ZappedLPCurve(_recipient, _fromToken, liquidity, coinAmounts);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into adding liquidity into a uniswap v2 liquidity pool
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _pair Target uniswap v2 pair
   * @param _for Recipient of LP tokens
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   */
  function zapLiquidityUniV2For(
    address _fromToken,
    uint256 _fromAmount,
    address _pair,
    address _for,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest
  ) public payable whenNotPaused {
    require(approvedTargets[_fromToken][_swapTarget] == true, "GenericZaps: Unsupported token/target");

    // pull tokens
    _pullTokens(_fromToken, _fromAmount);

    address intermediateToken;
    uint256 intermediateAmount;
    (address token0, address token1) = Swap.getPairTokens(_pair);

    if (_fromToken != token0 && _fromToken != token1) {
      // swap to intermediate
      intermediateToken = _zapLiqRequest.otherToken == token0 ? token1 : token0;
      intermediateAmount = Swap.fillQuote(
        _fromToken,
        _fromAmount,
        intermediateToken,
        _swapTarget,
        _swapData
      );
      require(intermediateAmount >= _zapLiqRequest.firstSwapMinAmountOut, "Not enough tokens out");
    } else {
      intermediateToken = _fromToken;
      intermediateAmount = _fromAmount;
    }
    
    (uint256 amountA, uint256 amountB) = _swapTokens(_pair, intermediateToken, intermediateAmount, _zapLiqRequest.poolSwapMinAmountOut);

    SafeERC20.safeIncreaseAllowance(IERC20(token1), address(uniswapV2Router), amountB);
    SafeERC20.safeIncreaseAllowance(IERC20(token0), address(uniswapV2Router), amountA);

    _addLiquidityUniV2(_pair, _for, amountA, amountB, _zapLiqRequest.uniAmountAMin, _zapLiqRequest.uniAmountBMin, _zapLiqRequest.shouldTransferResidual);
  }

  /**
   * @dev Get minimum amounts fo token0 and token1 to tolerate when adding liquidity to uniswap v2 pair
   * @param amountADesired Input desired amount of token0
   * @param amountBDesired Input desired amount of token1
   * @param pair Target uniswap v2 pair
   * @return amountA Minimum amount of token0 to use when adding liquidity
   * @return amountB Minimum amount of token1 to use when adding liquidity
   */
  function addLiquidityGetMinAmounts(
    uint amountADesired,
    uint amountBDesired,
    IUniswapV2Pair pair
  ) public view returns (uint amountA, uint amountB) {
    (uint reserveA, uint reserveB,) = pair.getReserves();
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint amountBOptimal = Swap.quote(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
          //require(amountBOptimal >= amountBMin, 'TempleStableAMMRouter: INSUFFICIENT_STABLE');
          (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
          uint amountAOptimal = Swap.quote(amountBDesired, reserveB, reserveA);
          assert(amountAOptimal <= amountADesired);
          //require(amountAOptimal >= amountAMin, 'TempleStableAMMRouter: INSUFFICIENT_TEMPLE');
          (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }

  function _addLiquidityCurvePool(
    address _pool,
    address _recipient,
    uint256 _minLiquidityOut,
    bool _useAltFunction,
    uint256[] memory _amounts
  ) internal returns (uint256 liquidity) {
    bool success;
    bytes memory data;
    if (_useAltFunction) {
      //liquidity = ICurvePool(_pool).add_liquidity(_amounts, _minLiquidityOut, false, _recipient);
      data = abi.encodeWithSelector(0x0b4c7e4d, _amounts, _minLiquidityOut, false, _recipient);
      // reuse data
      (success, data) = _pool.call{value:0}(data);
    } else {
      //liquidity = ICurvePool(_pool).add_liquidity(_amounts, _minLiquidityOut, _recipient);
      data = abi.encodeWithSelector(0xad6d8c4a, _amounts, _minLiquidityOut, _recipient);
      // reuse data
      (success, data) = _pool.call{value:0}(data);
    }
    require(success, "Failed adding liquidity");
    liquidity = abi.decode(data, (uint256));
  }

  function _addLiquidityUniV2(
    address _pair,
    address _recipient,
    uint256 _amountA,
    uint256 _amountB,
    uint256 _amountAMin,
    uint256 _amountBMin,
    bool _shouldTransferResidual
  ) internal {
    address tokenA = IUniswapV2Pair(_pair).token0();
    address tokenB = IUniswapV2Pair(_pair).token1();
    // avoid stack too deep
    {
      // reuse vars. _amountAMin and _amountBMin below are actually amountA and amountB added to liquidity after external call
      (_amountAMin, _amountBMin,) = uniswapV2Router.addLiquidity(
        tokenA,
        tokenB,
        _amountA,
        _amountB,
        _amountAMin,
        _amountBMin,
        _recipient,
        DEADLINE
      );

      emit ZappedLPUniV2(_recipient, tokenA, tokenB, _amountAMin, _amountBMin);

      // transfer residual
      if (_shouldTransferResidual) {
        _transferResidual(_recipient, tokenA, tokenB, _amountA, _amountB, _amountAMin, _amountBMin);
      }
    }    
  }

  function _transferResidual(
    address _recipient,
    address _tokenA,
    address _tokenB,
    uint256 _amountA,
    uint256 _amountB,
    uint256 _amountAActual,
    uint256 _amountBActual
  ) internal {
    if (_amountA > _amountAActual) {
      _transferToken(IERC20(_tokenA), _recipient, _amountA - _amountAActual);
    }

    if (_amountB > _amountBActual) {
      _transferToken(IERC20(_tokenB), _recipient, _amountB - _amountBActual);
    }
  }

  function _swapTokens(
    address _pair,
    address _fromToken,
    uint256 _fromAmount,
    uint256 _amountOutMin
  ) internal returns (uint256 amountA, uint256 amountB) {
    IUniswapV2Pair pair = IUniswapV2Pair(_pair);
    address token0 = pair.token0();
    address token1 = pair.token1();

    (uint256 res0, uint256 res1,) = pair.getReserves();
    if (_fromToken == token0) {
      uint256 amountToSwap = Swap.calculateSwapInAmount(res0, _fromAmount);
      //if no reserve or a new pair is created
      if (amountToSwap == 0) amountToSwap = _fromAmount / 2;

      amountB = _swapErc20ToErc20(
        _fromToken,
        token1,
        amountToSwap,
        _amountOutMin
      );
      amountA = _fromAmount - amountToSwap;
    } else {
      uint256 amountToSwap = Swap.calculateSwapInAmount(res1, _fromAmount);
      //if no reserve or a new pair is created
      if (amountToSwap == 0) amountToSwap = _fromAmount / 2;

      amountA = _swapErc20ToErc20(
        _fromToken,
        token0,
        amountToSwap,
        _amountOutMin
      );
      amountB = _fromAmount - amountToSwap;
    }
  }

  function _fillQuotePool(
    address _fromToken, 
    uint256 _fromAmount,
    address[] memory _coins,
    address _swapTarget,
    bytes memory _swapData
  ) internal returns (uint256, uint256){
    uint256 valueToSend;
    if (_fromToken == address(0)) {
      require(
          _fromAmount > 0 && msg.value == _fromAmount,
          "Invalid _amount: Input ETH mismatch"
      );
      valueToSend = _fromAmount;
    } else {
      SafeERC20.safeIncreaseAllowance(IERC20(_fromToken), _swapTarget, _fromAmount);
    }
    uint256 nCoins = _coins.length;
    uint256[] memory balancesBefore = new uint256[](nCoins);
    uint256 i = 0;
    for (; i<nCoins;) {
      balancesBefore[i] = IERC20(_coins[i]).balanceOf(address(this));
      unchecked { i++; }
    }

    Executable.execute(_swapTarget, valueToSend, _swapData);

    uint256 tokenBoughtIndex = nCoins;
    uint256 bal;
    // reuse vars
    for (i=0; i<nCoins;) {
      bal = IERC20(_coins[i]).balanceOf(address(this));
      if (bal > balancesBefore[i]) {
        tokenBoughtIndex = i;
        break;
      }
      unchecked { i++; }
    }
    require(tokenBoughtIndex != nCoins, "Invalid swap");

    return (tokenBoughtIndex, bal - balancesBefore[tokenBoughtIndex]);
  }

  /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _fromToken The token address to swap from.
    @param _toToken The token address to swap to. 
    @param _amountIn The amount of tokens to swap
    @param _amountOutMin Minimum amount of tokens out
    @return tokenBought The amount of tokens bought
    */
  function _swapErc20ToErc20(
    address _fromToken,
    address _toToken,
    uint256 _amountIn,
    uint256 _amountOutMin
  ) internal returns (uint256 tokenBought) {
    if (_fromToken == _toToken) {
        return _amountIn;
    }

    SafeERC20.safeIncreaseAllowance(IERC20(_fromToken), address(uniswapV2Router), _amountIn);

    IUniswapV2Factory uniV2Factory = IUniswapV2Factory(
      uniswapV2Router.factory()
    );
    address pair = uniV2Factory.getPair(
      _fromToken,
      _toToken
    );
    require(pair != address(0), "No Swap Available");
    address[] memory path = new address[](2);
    path[0] = _fromToken;
    path[1] = _toToken;

    tokenBought = uniswapV2Router
      .swapExactTokensForTokens(
          _amountIn,
          _amountOutMin,
          path,
          address(this),
          DEADLINE
      )[path.length - 1];

    require(tokenBought >= _amountOutMin, "Error Swapping Tokens 2");
  }
}