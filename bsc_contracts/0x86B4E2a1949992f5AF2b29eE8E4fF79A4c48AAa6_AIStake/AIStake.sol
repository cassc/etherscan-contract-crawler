/**
 *Submitted for verification at BscScan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapRouterV2 {
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface ISwapRouter {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  function exactInputSingle(
    ExactInputSingleParams calldata params
  ) external payable returns (uint256 amountOut);
}

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);
}

interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint amount) external;
}

interface INonfungiblePositionManager {
  function positions(
    uint256 tokenId
  ) external view returns (
    uint96 nonce,
    address operator,
    address token0,
    address token1,
    uint24 fee,
    int24 tickLower,
    int24 tickUpper,
    uint128 liquidity,
    uint256 feeGrowthInside0LastX128,
    uint256 feeGrowthInside1LastX128,
    uint128 tokensOwed0,
    uint128 tokensOwed1
  );

  struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }

  function mint(
    MintParams calldata params
  ) external payable returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

  struct IncreaseLiquidityParams {
    uint tokenId;
    uint amount0Desired;
    uint amount1Desired;
    uint amount0Min;
    uint amount1Min;
    uint deadline;
  }

  function increaseLiquidity(
    IncreaseLiquidityParams calldata params
  ) external payable returns (uint128 liquidity, uint amount0, uint amount1);

  struct DecreaseLiquidityParams {
    uint tokenId;
    uint128 liquidity;
    uint amount0Min;
    uint amount1Min;
    uint deadline;
  }

  function decreaseLiquidity(
    DecreaseLiquidityParams calldata params
  ) external payable returns (uint amount0, uint amount1);

  struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface IPancakeV3Factory {
  function feeAmountTickSpacing(uint24 fee) external view returns (int24);
}

interface INonfungiblePositionManagerStruct {
  struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
  }
}

interface IMasterChefv3 is INonfungiblePositionManagerStruct {
  function decreaseLiquidity(
    DecreaseLiquidityParams memory params
  ) external payable returns (uint256 amount0, uint256 amount1);
  
  function increaseLiquidity(
    IncreaseLiquidityParams memory params
  ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

  function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

  function withdraw(uint256 _tokenId, address _to) external returns (uint256 reward);

  function harvest(uint256 _tokenId, address _to) external returns (uint256 reward);

  function pendingCake(uint256 _tokenId) external view returns (uint256 reward);
}

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

contract AIStake is IERC721Receiver {
  address public nftManager = 0x46A15B0b27311cedF172AB29E4f4766fbE7F4364;
  address public nftFactory = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;
  address public v3SmartRouter = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
  address public v2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  address public v3MasterChef = 0x556B9306565093C855AEA9AE92A594704c2Cd59e;
  address public WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

  int24 private constant MIN_TICK = -887272;
  int24 private constant MAX_TICK = -MIN_TICK;

  // token0 -> token1 -> fee -> nftId
  mapping (address => mapping(address => mapping(uint24 => uint256))) public stakePools;

  struct V3Path {
    address tokenIn;
    address tokenOut;
    uint24 fee;
  }

  event Stake(address account, uint256 usdAmount, uint256 tokenId, uint128 liquidity, uint256 timestamp);

  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function stake(
    address tokenIn,
    uint256 amountIn,
    address[] memory v2Path, // ?
    address token0,
    address token1,
    uint24 fee,
    V3Path[] memory v3Path // ?
  ) public payable returns(uint256) {
    if (tokenIn != address(0)) {  // If address is not null, send this amount to contract.
      IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
    }
    else {
      IWETH(WETH).deposit{value: msg.value}(); // Why choose WETH?
    }

    uint256 v3PathLen = v3Path.length;
    uint256 v3Amount = amountIn;
    for (uint256 x=0; x<v3PathLen; x++) {
      v3Amount = _swapExactInputSingle(v3Path[x].tokenIn, v3Path[x].tokenOut, v3Path[x].fee, v3Amount);
    }

    uint256[] memory toAddLpAmount = new uint256[](2);
    if (v3Path[v3PathLen-1].tokenOut == token0) {
      toAddLpAmount[0] = v3Amount / 2;
      toAddLpAmount[1] = _swapExactInputSingle(token0, token1, fee, v3Amount - toAddLpAmount[0]);
    }
    else {
      toAddLpAmount[1] = v3Amount / 2;
      toAddLpAmount[0] = _swapExactInputSingle(token1, token0, fee, v3Amount - toAddLpAmount[1]);
    }
    
    uint128 liquidity = 0;
    if (stakePools[token0][token1][fee] == 0) {
      (, liquidity, ,) = _mintNewPosition(token0, token1, fee, toAddLpAmount[0], toAddLpAmount[1]); // process liquidity amount later
    }
    else {
      (liquidity, ,) = _increaseLiquidity(stakePools[token0][token1][fee], toAddLpAmount[0], toAddLpAmount[1]);
    }

    uint256[] memory amounts = IUniswapRouterV2(v2Router).getAmountsOut(amountIn, v2Path);
    emit Stake(msg.sender, amounts[amounts.length-1], stakePools[token0][token1][fee], liquidity, block.timestamp);
    return amounts[amounts.length-1];
  }

  function unstake(uint256 tokenId, uint128 _liquidity, address tokenOut, V3Path[] memory v3Path) public {
    ( , , address token0, address token1, uint24 fee, , , uint128 liquidity, , , , ) = INonfungiblePositionManager(nftManager).positions(tokenId);
    uint256[2] memory amounts;
    if (_liquidity >= liquidity) {
      IMasterChefv3(v3MasterChef).withdraw(tokenId, address(this));
      (amounts[0], amounts[1]) = _decreaseLiquidityFromRouter(tokenId, _liquidity);
    }
    else {
      (amounts[0], amounts[1]) = _decreaseLiquidity(tokenId, _liquidity);
    }

    uint256 v3PathLen = v3Path.length;
    uint256 swappedAmount = 0;
    if (tokenOut == token0) {
      swappedAmount = _swapExactInputSingle(token1, token0, fee, amounts[1]);
      swappedAmount += amounts[0];
    }
    else {
      swappedAmount = _swapExactInputSingle(token0, token1, fee, amounts[0]);
      swappedAmount += amounts[1];
    }
    if (v3PathLen > 0) {
      for (uint256 x=0; x<v3PathLen; x++) {
        swappedAmount = _swapExactInputSingle(v3Path[x].tokenIn, v3Path[x].tokenOut, v3Path[x].fee, swappedAmount);
      }
    }
    IERC20(tokenOut).transfer(msg.sender, swappedAmount);
  }

  event test1(uint256, uint256);
  function unstake1(uint256 tokenId, uint128 _liquidity) public {
    ( , , address token0, address token1, uint24 fee, , , uint128 liquidity, , , , ) = INonfungiblePositionManager(nftManager).positions(tokenId);
    uint256[2] memory amounts;
    if (_liquidity >= liquidity) {
      IMasterChefv3(v3MasterChef).withdraw(tokenId, address(this));
      (amounts[0], amounts[1]) = _decreaseLiquidityFromRouter(tokenId, _liquidity);
    }
    else {
      (amounts[0], amounts[1]) = _decreaseLiquidity(tokenId, _liquidity);
    }
    emit test1(amounts[0], amounts[1]);

    INonfungiblePositionManagerStruct.CollectParams memory params = INonfungiblePositionManagerStruct
      .CollectParams({
        tokenId: tokenId,
        recipient: address(this),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      });
    (amounts[0], amounts[1]) = IMasterChefv3(v3MasterChef).collect(params);
    emit test1(amounts[0], amounts[1]);

    IMasterChefv3(v3MasterChef).harvest(tokenId, address(this));
  }

  function unstake2(uint256 tokenId, uint256[] memory amounts, address tokenOut, V3Path[] memory v3Path) public {
    ( , , address token0, address token1, uint24 fee, , , , , , , ) = INonfungiblePositionManager(nftManager).positions(tokenId);

    uint256 v3PathLen = v3Path.length;
    uint256 swappedAmount = 0;
    if (tokenOut == token0) {
      swappedAmount = _swapExactInputSingle(token1, token0, fee, amounts[1]);
      swappedAmount += amounts[0];
    }
    else {
      swappedAmount = _swapExactInputSingle(token0, token1, fee, amounts[0]);
      swappedAmount += amounts[1];
    }
    if (v3PathLen > 0) {
      for (uint256 x=0; x<v3PathLen; x++) {
        swappedAmount = _swapExactInputSingle(v3Path[x].tokenIn, v3Path[x].tokenOut, v3Path[x].fee, swappedAmount);
      }
    }
    IERC20(tokenOut).transfer(msg.sender, swappedAmount);
  }

  function _swapExactInputSingle(
    address tokenIn,
    address tokenOut,
    uint24 poolFee,
    uint256 amountIn
  ) internal returns (uint256) {
    _approveTokenIfNeeded(tokenIn, v3SmartRouter, amountIn);
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
      .ExactInputSingleParams({
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fee: poolFee,
        recipient: address(this),
        amountIn: amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });

    return ISwapRouter(v3SmartRouter).exactInputSingle{value:0}(params);
  }

  function _mintNewPosition(
    address token0,
    address token1,
    uint24 fee,
    uint amount0ToAdd,
    uint amount1ToAdd
  ) internal returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {
    _approveTokenIfNeeded(token0, nftManager, amount0ToAdd);
    _approveTokenIfNeeded(token1, nftManager, amount1ToAdd);

    int24 tickSpacing = IPancakeV3Factory(nftFactory).feeAmountTickSpacing(fee);

    INonfungiblePositionManager.MintParams
      memory params = INonfungiblePositionManager.MintParams({
        token0: token0,
        token1: token1,
        fee: fee,
        tickLower: (MIN_TICK / tickSpacing) * tickSpacing,
        tickUpper: (MAX_TICK / tickSpacing) * tickSpacing,
        amount0Desired: amount0ToAdd,
        amount1Desired: amount1ToAdd,
        amount0Min: 0,
        amount1Min: 0,
        recipient: address(this),
        deadline: block.timestamp
      });

    (tokenId, liquidity, amount0, amount1) = INonfungiblePositionManager(nftManager).mint(params);
    INonfungiblePositionManager(nftManager).safeTransferFrom(address(this), v3MasterChef, tokenId);
    stakePools[token0][token1][fee] = tokenId;

    if (amount0 < amount0ToAdd) {
      IERC20(token0).transfer(msg.sender, amount0ToAdd - amount0);
    }
    if (amount1 < amount1ToAdd) {
      IERC20(token1).transfer(msg.sender, amount1ToAdd - amount1);
    }
  }

  function _increaseLiquidity(
    uint tokenId,
    uint amount0ToAdd,
    uint amount1ToAdd
  ) internal returns (uint128 liquidity, uint amount0, uint amount1) {
    ( , , address token0, address token1, , , , , , , , ) = INonfungiblePositionManager(nftManager).positions(tokenId);

    _approveTokenIfNeeded(token0, v3MasterChef, amount0ToAdd);
    _approveTokenIfNeeded(token1, v3MasterChef, amount1ToAdd);

    INonfungiblePositionManagerStruct.IncreaseLiquidityParams memory params = INonfungiblePositionManagerStruct
      .IncreaseLiquidityParams({
        tokenId: tokenId,
        amount0Desired: amount0ToAdd,
        amount1Desired: amount1ToAdd,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp
      });

    (liquidity, amount0, amount1) = IMasterChefv3(v3MasterChef).increaseLiquidity(params);
  }

  function _decreaseLiquidity(
    uint tokenId,
    uint128 liquidity
  ) internal returns (uint amount0, uint amount1) {
    INonfungiblePositionManagerStruct.DecreaseLiquidityParams
      memory params = INonfungiblePositionManagerStruct
        .DecreaseLiquidityParams({
          tokenId: tokenId,
          liquidity: liquidity,
          amount0Min: 0,
          amount1Min: 0,
          deadline: block.timestamp
        });

    (amount0, amount1) = IMasterChefv3(v3MasterChef).decreaseLiquidity(params);
  }

  function _decreaseLiquidityFromRouter(
    uint tokenId,
    uint128 liquidity
  ) internal returns (uint amount0, uint amount1) {
    INonfungiblePositionManager.DecreaseLiquidityParams
      memory params = INonfungiblePositionManager
        .DecreaseLiquidityParams({
          tokenId: tokenId,
          liquidity: liquidity,
          amount0Min: 0,
          amount1Min: 0,
          deadline: block.timestamp
        });

    (amount0, amount1) = INonfungiblePositionManager(nftManager).decreaseLiquidity(params);
  }

  function _approveTokenIfNeeded(address token, address spender, uint256 amount) private {
    if (IERC20(token).allowance(address(this), spender) < amount) {
      IERC20(token).approve(spender, amount);
    }
  }
}