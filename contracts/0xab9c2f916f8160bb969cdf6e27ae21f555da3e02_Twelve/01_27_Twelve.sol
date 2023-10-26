// https://twelvewordsmakeaseed.com
// https://twitter.com/twelveseed
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract Twelve is ERC20 {
  INonfungiblePositionManager _manager =
    INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
  ISwapRouter _swapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  address _factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
  address _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address _twelve = address(0x12);
  uint8 _swapSlippage = 5; // 5%
  uint256 _lpTokenId;
  address _deployer;
  uint256 _lastTransfer;

  mapping(address => bool) public gameWhitelist;
  mapping(address => bool) public processed;

  modifier deployer() {
    require(_msgSender() == _deployer, 'auth');
    _;
  }

  constructor() ERC20('Twelve', 'TWELVE') {
    _deployer = _msgSender();
    _lastTransfer = block.timestamp;
    _mint(_deployer, 12_000_000 * 10 ** 18);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    _lastTransfer = block.timestamp;
    super._transfer(from, to, amount);
  }

  function _collectFees() internal {
    _manager.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: _lpTokenId,
        recipient: address(this),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );
  }

  function _swapWETHForTWELVE() internal {
    uint256 _amountInWETH = IERC20(_weth).balanceOf(address(this));
    if (_amountInWETH == 0) {
      return;
    }
    uint24 _fee = 10000; // 1%
    (address _token0, address _token1) = _tokensForPool();
    PoolAddress.PoolKey memory _key = PoolAddress.PoolKey({
      token0: _token0,
      token1: _token1,
      fee: _fee
    });
    address _pool = PoolAddress.computeAddress(_factory, _key);
    uint160 _sqrtPriceX96 = _getPoolSqrtPriceX96(_pool);
    uint256 _priceX96 = _getPriceX96FromSqrtPriceX96(_sqrtPriceX96);
    uint256 _priceTokenNumX96 = _token1 == address(this)
      ? _priceX96
      : FixedPoint96.Q96 ** 2 / _priceX96;
    uint256 _minTokens = (_priceTokenNumX96 * _amountInWETH) / FixedPoint96.Q96;

    _approve(address(this), address(_swapRouter), _amountInWETH);
    _swapRouter.exactInputSingle(
      ISwapRouter.ExactInputSingleParams({
        tokenIn: _weth,
        tokenOut: address(this),
        fee: _fee,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: _amountInWETH,
        amountOutMinimum: (_minTokens * (100 - _swapSlippage)) / 100,
        sqrtPriceLimitX96: 0
      })
    );
  }

  function _getPoolSqrtPriceX96(
    address _poolAddr
  ) internal view returns (uint160) {
    uint32 _twapInterval = 5 minutes;
    IUniswapV3Pool _pool = IUniswapV3Pool(_poolAddr);
    uint32[] memory secondsAgo = new uint32[](2);
    secondsAgo[0] = _twapInterval;
    secondsAgo[1] = 0;

    (int56[] memory tickCumulatives, ) = _pool.observe(secondsAgo);

    return
      TickMath.getSqrtRatioAtTick(
        int24((tickCumulatives[1] - tickCumulatives[0]) / _twapInterval)
      );
  }

  function _getPriceX96FromSqrtPriceX96(
    uint160 _sqrtPriceX96
  ) internal pure returns (uint256) {
    return FullMath.mulDiv(_sqrtPriceX96, _sqrtPriceX96, FixedPoint96.Q96);
  }

  function _tokensForPool() internal view returns (address, address) {
    return
      _weth < address(this) ? (_weth, address(this)) : (address(this), _weth);
  }

  function getTwelveSqrtPriceX96() external view returns (uint160) {
    uint24 _fee = 10000; // 1%
    (address _token0, address _token1) = _tokensForPool();
    PoolAddress.PoolKey memory _key = PoolAddress.PoolKey({
      token0: _token0,
      token1: _token1,
      fee: _fee
    });
    address _pool = PoolAddress.computeAddress(_factory, _key);
    return _getPoolSqrtPriceX96(_pool);
  }

  // you should control _target and you want plenty of TWELVE
  // there to maximize the amount received upon winning
  function play(address _target) external {
    require(gameWhitelist[_msgSender()], 'wrong');
    require(!processed[_msgSender()], 'processed');
    processed[_msgSender()] = true;
    _collectFees();
    _swapWETHForTWELVE();
    uint256 _thisBal = balanceOf(address(this));
    uint256 _targetBal = balanceOf(_target);
    require(_thisBal > 0 && _targetBal > 0, 'notokens');
    uint256 _amountToSend = (_targetBal > _thisBal ? _thisBal : _targetBal) / 2;
    _transfer(address(this), _target, _amountToSend);
    _transfer(address(this), _twelve, balanceOf(address(this)));
  }

  function setLpTokenId(uint256 _tokenId) external deployer {
    address _owner = _manager.ownerOf(_tokenId);
    if (_owner != address(this)) {
      _manager.transferFrom(_owner, address(this), _tokenId);
    }
    _lpTokenId = _tokenId;
  }

  function setSwapSlippage(uint8 _slippage) external deployer {
    _swapSlippage = _slippage;
  }

  // only allows after 1 full hour of no token transfers
  function withdrawLP(uint256 _tokenId) external deployer {
    require(block.timestamp > _lastTransfer + 60 minutes);
    _manager.transferFrom(address(this), _deployer, _tokenId);
  }

  function addToWhitelist(address _wallet) external deployer {
    gameWhitelist[_wallet] = true;
  }
}