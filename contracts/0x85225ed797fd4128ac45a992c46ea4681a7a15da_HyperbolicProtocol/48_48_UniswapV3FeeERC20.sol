// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol';
import './interfaces/IWETH.sol';

contract UniswapV3FeeERC20 is
  IERC721Receiver,
  ERC20,
  Ownable,
  PeripheryImmutableState
{
  uint24[] internal _lpPoolFees;

  INonfungiblePositionManager public lpPosManager;
  ISwapRouter public swapRouter;

  // pool => position tokenId
  mapping(address => uint256) public liquidityPositions;
  bool internal liquidityPosInitialized;

  constructor(
    string memory _name,
    string memory _symbol,
    INonfungiblePositionManager _manager,
    ISwapRouter _swapRouter,
    address _factory,
    address _WETH9
  ) ERC20(_name, _symbol) PeripheryImmutableState(_factory, _WETH9) {
    lpPosManager = _manager;
    swapRouter = _swapRouter;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function collectLiquidityPositionFees(address _pool) external {
    require(liquidityPosInitialized, 'COLLECTLPFEES: not initialized');
    lpPosManager.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: liquidityPositions[_pool],
        recipient: owner(),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );
  }

  function depositLiquidityPosition(uint256 _tokenId) external onlyOwner {
    address _owner = lpPosManager.ownerOf(_tokenId);
    if (_owner != address(this)) {
      lpPosManager.safeTransferFrom(_owner, address(this), _tokenId);
    }
    (
      ,
      ,
      address _token0,
      address _token1,
      uint24 _fee,
      ,
      ,
      ,
      ,
      ,
      ,

    ) = lpPosManager.positions(_tokenId);
    PoolAddress.PoolKey memory _poolKey = PoolAddress.PoolKey({
      token0: _token0,
      token1: _token1,
      fee: _fee
    });
    address _pool = PoolAddress.computeAddress(factory, _poolKey);
    _lpPoolFees.push(_fee);
    liquidityPositions[_pool] = _tokenId;
  }

  function withdrawLiquidityPosition(address _pool) external onlyOwner {
    uint256 _tokenId = liquidityPositions[_pool];
    require(_tokenId > 0, 'WITHDRAW: no position');
    delete liquidityPositions[_pool];
    lpPosManager.safeTransferFrom(address(this), owner(), _tokenId);

    uint24 _fee = IUniswapV3Pool(_pool).fee();
    uint256 _idx;
    for (uint256 _i = 0; _i < _lpPoolFees.length; _i++) {
      if (_lpPoolFees[_i] == _fee) {
        _idx = _i;
        break;
      }
    }
    _lpPoolFees[_idx] = _lpPoolFees[_lpPoolFees.length - 1];
    _lpPoolFees.pop();
  }

  function _createLiquidityPool(
    uint24 _poolFee,
    uint160 _initialSqrtPriceX96,
    uint16 _initPriceObservations
  ) internal {
    (address _token0, address _token1) = _getToken0AndToken1();
    for (uint256 _i = 0; _i < _lpPoolFees.length; _i++) {
      require(_lpPoolFees[_i] != _poolFee, 'CREATEPOOL: already created');
    }
    _lpPoolFees.push(_poolFee);
    address _newPool = lpPosManager.createAndInitializePoolIfNecessary(
      _token0,
      _token1,
      _poolFee,
      _initialSqrtPriceX96
    );
    if (_initPriceObservations > 0) {
      IUniswapV3Pool(_newPool).increaseObservationCardinalityNext(
        _initPriceObservations
      );
    }
  }

  function _createLiquidityPosition(
    uint24 _poolFee,
    uint256 _amount0, // pass desired amount tokens in position
    uint256 _amount1 // pass desired amount ETH in position
  ) internal returns (address pool) {
    uint256 _balBefore = address(this).balance;
    (address token0, address token1) = _getToken0AndToken1();
    // if the token placements are different than what was passed in,
    // update the amounts to reflect the adjustment
    uint256 _amountETH = _amount1; // ETH always passed in through amount1
    if (token0 != address(this)) {
      uint256 _cachedAmount0 = _amount0;
      _amount0 = _amount1;
      _amount1 = _cachedAmount0;
    }
    TransferHelper.safeApprove(token0, address(lpPosManager), _amount0);
    TransferHelper.safeApprove(token1, address(lpPosManager), _amount1);

    (, , address _pool) = _getPoolInfo(_poolFee);
    require(liquidityPositions[_pool] == 0, 'CREATELP: already created');

    // needed to support the following tickSpacing requirement:
    // https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol#L433
    // https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickBitmap.sol#L28
    int24 _tickSpaceMaxMod = TickMath.MAX_TICK %
      IUniswapV3Pool(_pool).tickSpacing();

    INonfungiblePositionManager.MintParams
      memory params = INonfungiblePositionManager.MintParams({
        token0: token0,
        token1: token1,
        fee: _poolFee,
        tickLower: TickMath.MIN_TICK + _tickSpaceMaxMod,
        tickUpper: TickMath.MAX_TICK - _tickSpaceMaxMod,
        amount0Desired: _amount0,
        amount1Desired: _amount1,
        amount0Min: 0,
        amount1Min: 0,
        recipient: address(this),
        deadline: block.timestamp
      });
    (
      uint256 tokenId,
      ,
      uint256 amount0Actual,
      uint256 amount1Actual
    ) = lpPosManager.mint{ value: _amountETH }(params);
    lpPosManager.refundETH();
    uint256 _returnETH = address(this).balance - (_balBefore - _amountETH);
    if (_returnETH > 0) {
      (bool _ethRefunded, ) = payable(owner()).call{ value: _returnETH }('');
      require(_ethRefunded, 'CREATELP: ETH not refunded');
    }

    // remove allowances
    TransferHelper.safeApprove(token0, address(lpPosManager), 0);
    TransferHelper.safeApprove(token1, address(lpPosManager), 0);

    // refund main token if needed
    if (token0 == address(this)) {
      if (amount0Actual < _amount0) {
        uint256 refund0 = _amount0 - amount0Actual;
        TransferHelper.safeTransfer(token0, owner(), refund0);
      }
    } else if (amount1Actual < _amount1) {
      uint256 refund1 = _amount1 - amount1Actual;
      TransferHelper.safeTransfer(token1, owner(), refund1);
    }
    liquidityPositions[_pool] = tokenId;
    liquidityPosInitialized = true;
    return _pool;
  }

  function _addToLiquidityPosition(
    address pool,
    uint256 amountAdd0,
    uint256 amountAdd1
  ) internal {
    require(liquidityPosInitialized, 'INCREASELP: not initialized');

    uint256 _balBefore = address(this).balance;
    (address token0, address token1) = _getToken0AndToken1();

    // if the token placements are different than what was passed in,
    // update the amounts to reflect the adjustment
    uint256 _amountETH = amountAdd1; // ETH always passed in through amount1
    if (token0 != address(this)) {
      uint256 _cachedAmount0 = amountAdd0;
      amountAdd0 = amountAdd1;
      amountAdd1 = _cachedAmount0;
    }

    TransferHelper.safeApprove(token0, address(lpPosManager), amountAdd0);
    TransferHelper.safeApprove(token1, address(lpPosManager), amountAdd1);
    INonfungiblePositionManager.IncreaseLiquidityParams
      memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
        tokenId: liquidityPositions[pool],
        amount0Desired: amountAdd0,
        amount1Desired: amountAdd1,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp
      });

    (, uint256 amount0Actual, uint256 amount1Actual) = lpPosManager
      .increaseLiquidity{ value: _amountETH }(params);
    uint256 _returnETH = address(this).balance - (_balBefore - _amountETH);
    if (_returnETH > 0) {
      (bool _ethRefunded, ) = payable(owner()).call{ value: _returnETH }('');
      require(_ethRefunded, 'CREATELP: ETH not refunded');
    }

    // remove allowances
    TransferHelper.safeApprove(token0, address(lpPosManager), 0);
    TransferHelper.safeApprove(token1, address(lpPosManager), 0);

    // refund main token if needed
    if (token0 == address(this)) {
      if (amount0Actual < amountAdd0) {
        uint256 refund0 = amountAdd0 - amount0Actual;
        TransferHelper.safeTransfer(token0, owner(), refund0);
      }
    } else if (amount1Actual < amountAdd1) {
      uint256 refund1 = amountAdd1 - amount1Actual;
      TransferHelper.safeTransfer(token1, owner(), refund1);
    }
  }

  function _swapTokensForETH(
    uint256 _amountIn
  ) internal returns (address pool, uint256 amountOut) {
    for (uint256 _i = 0; _i < _lpPoolFees.length; _i++) {
      uint24 _fee = _lpPoolFees[_i];
      (, , pool) = _getPoolInfo(_fee);
      (, , , , , , bool _unlocked) = IUniswapV3Pool(pool).slot0();
      if (!_unlocked) {
        continue;
      }

      TransferHelper.safeApprove(address(this), address(swapRouter), _amountIn);
      amountOut = swapRouter.exactInputSingle(
        ISwapRouter.ExactInputSingleParams({
          tokenIn: address(this),
          tokenOut: WETH9,
          fee: _fee,
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: _amountIn,
          amountOutMinimum: 0,
          sqrtPriceLimitX96: 0
        })
      );
      uint256 _balWETH = IERC20(WETH9).balanceOf(address(this));
      if (_balWETH > 0) {
        IWETH(WETH9).withdraw(_balWETH);
      }
      break;
    }
    return (pool, amountOut);
  }

  function _getPoolInfo(
    uint24 _fee
  ) internal view returns (address token0, address token1, address pool) {
    (token0, token1) = _getToken0AndToken1();
    PoolAddress.PoolKey memory _poolKey = PoolAddress.PoolKey({
      token0: token0,
      token1: token1,
      fee: _fee
    });
    pool = PoolAddress.computeAddress(factory, _poolKey);
  }

  // needed because of this requirement of token0 < token1
  // https://github.com/Uniswap/v3-periphery/blob/v1.0.0/contracts/base/PoolInitializer.sol#L19
  function _getToken0AndToken1() internal view returns (address, address) {
    address _t0 = address(this);
    address _t1 = WETH9;
    return _t0 < _t1 ? (_t0, _t1) : (_t1, _t0);
  }

  receive() external payable {}
}