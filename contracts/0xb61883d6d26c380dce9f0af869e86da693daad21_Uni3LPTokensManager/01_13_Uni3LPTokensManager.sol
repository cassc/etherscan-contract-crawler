// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../../Storage.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IPool.sol";
import "../../interfaces/NativeWrapper/IWrap.sol";

contract Uni3LPTokensManager is Ownable {
  using SafeERC20 for IERC20;

  /// @notice Storage contract
  Storage public info;

  struct Swap {
    bytes path;
    uint256 outMin;
  }

  struct BuyLiquidityParams {
    address positionManager; // Position manager address
    address router; // Swap router address
    address from; // Input token address
    uint256 amount; // Input token amount
    Swap swap; // Swap path from input token to token0 or token1
    address to; // Liquidity pool address
    int24 tickLower; // Tick lower
    int24 tickUpper; // Tick upper
    uint256 deadline; // Deadline timestamp
  }

  struct SellLiquidityParams {
    address positionManager; // Position manager address
    address router; // Swap router address
    uint256 from; // Liquidity token ID
    Swap swap; // Swap path from token0 or token1 to output token
    address to; // Output token address
    uint256 deadline; // Deadline timestamp
  }

  event StorageChanged(address indexed info);

  event BuyLiquidity(address buyer, address pool, uint128 liquidity, uint256 tokenId);

  event SellLiquidity(address seller, address pool, uint128 liquidity);

  constructor(address _info) {
    require(_info != address(0), "LPTokensManager::constructor: invalid storage contract address");
    info = Storage(_info);
  }

  receive() external payable {}

  fallback() external payable {}

  function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  /**
   * @notice Change storage contract address.
   * @param _info New storage contract address.
   */
  function changeStorage(address _info) external onlyOwner {
    require(_info != address(0), "LPTokensManager::changeStorage: invalid storage contract address");
    info = Storage(_info);
    emit StorageChanged(_info);
  }

  /**
   * @return Current call commission.
   */
  function fee() public view returns (uint256) {
    uint256 feeUSD = info.getUint(keccak256("DFH:Fee:Automate:Uni3:LPTokensManager"));
    if (feeUSD == 0) return 0;

    (, int256 answer, , , ) = AggregatorV3Interface(info.getAddress(keccak256("DFH:Fee:PriceFeed"))).latestRoundData();
    require(answer > 0, "LPTokensManager::fee: invalid price feed response");

    return (feeUSD * 1e18) / uint256(answer);
  }

  function _payCommission() internal {
    uint256 payFee = fee();
    if (payFee == 0) return;
    require(msg.value >= payFee, "LPTokensManager::_payCommission: insufficient funds to pay commission");
    address treasury = info.getAddress(keccak256("DFH:Contract:Treasury"));
    require(treasury != address(0), "LPTokensManager::_payCommission: invalid treasury contract address");

    // solhint-disable-next-line avoid-low-level-calls
    (bool sentTreasury, ) = payable(treasury).call{value: payFee}("");
    require(sentTreasury, "LPTokensManager::_payCommission: transfer fee to the treasury failed");
    if (msg.value > payFee) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool sentRemained, ) = payable(msg.sender).call{value: msg.value - payFee}("");
      require(sentRemained, "LPTokensManager::_payCommission: transfer of remained tokens to the sender failed");
    }
  }

  function _approve(IERC20 token, address spender, uint256 amount) internal {
    uint256 allowance = token.allowance(address(this), spender);
    if (allowance > amount) return;
    if (allowance != 0) {
      token.safeApprove(spender, 0);
    }
    token.safeApprove(spender, type(uint256).max);
  }

  function _returnRemainder(address[3] memory tokens) internal {
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] == address(0)) continue;
      uint256 tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
      if (tokenBalance == 0) continue;
      IERC20(tokens[i]).safeTransfer(msg.sender, tokenBalance);
    }
  }

  function _buyLiquidity(BuyLiquidityParams calldata params) internal {
    address token0 = IPool(params.to).token0();
    address token1 = IPool(params.to).token1();
    uint24 _fee = IPool(params.to).fee();

    if (params.from != token0 && params.from != token1) {
      _approve(IERC20(params.from), params.router, params.amount);
      ISwapRouter(params.router).exactInput(
        ISwapRouter.ExactInputParams({
          path: params.swap.path,
          recipient: address(this),
          amountIn: params.amount,
          amountOutMinimum: params.swap.outMin
        })
      );
    }

    uint256 token0Balance = IERC20(token0).balanceOf(address(this));
    uint256 token1Balance = IERC20(token1).balanceOf(address(this));
    address tokenIn = token0Balance > token1Balance ? token0 : token1;
    address tokenOut = token0Balance > token1Balance ? token1 : token0;
    uint256 amountIn = (token0Balance > token1Balance ? token0Balance : token1Balance) / 2;
    _approve(IERC20(tokenIn), params.router, amountIn);
    ISwapRouter(params.router).exactInputSingle(
      ISwapRouter.ExactInputSingleParams({
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fee: _fee,
        recipient: address(this),
        amountIn: amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      })
    );

    token0Balance = IERC20(token0).balanceOf(address(this));
    token1Balance = IERC20(token1).balanceOf(address(this));
    _approve(IERC20(token0), params.positionManager, token0Balance);
    _approve(IERC20(token1), params.positionManager, token1Balance);
    (uint256 tokenId, uint128 liquidity, , ) = INonfungiblePositionManager(params.positionManager).mint(
      INonfungiblePositionManager.MintParams({
        token0: token0,
        token1: token1,
        fee: _fee,
        tickLower: params.tickLower,
        tickUpper: params.tickUpper,
        amount0Desired: token0Balance,
        amount1Desired: token1Balance,
        amount0Min: 0,
        amount1Min: 0,
        recipient: address(this),
        deadline: params.deadline
      })
    );

    INonfungiblePositionManager(params.positionManager).safeTransferFrom(address(this), msg.sender, tokenId);
    _returnRemainder([token0, token1, params.from]);

    emit BuyLiquidity(msg.sender, params.to, liquidity, tokenId);
  }

  function buyLiquidity(BuyLiquidityParams calldata params) public payable {
    _payCommission();
    IERC20(params.from).safeTransferFrom(msg.sender, address(this), params.amount);
    _buyLiquidity(params);
  }

  function buyLiquidityETH(BuyLiquidityParams calldata params) external payable {
    uint256 amountIn = msg.value;

    uint256 payFee = fee();
    if (payFee > 0) {
      amountIn -= payFee;
      address treasury = info.getAddress(keccak256("DFH:Contract:Treasury"));
      require(treasury != address(0), "LPTokensManager::buyLiquidityETH: invalid treasury contract address");
      // solhint-disable-next-line avoid-low-level-calls
      (bool sentTreasury, ) = payable(treasury).call{value: payFee}("");
      require(sentTreasury, "LPTokensManager::buyLiquidityETH: transfer fee to the treasury failed");
    }

    IWrap wrapper = IWrap(info.getAddress(keccak256("NativeWrapper:Contract")));
    wrapper.deposit{value: amountIn}();

    _buyLiquidity(params);
  }

  function _sellLiquidity(SellLiquidityParams calldata params) internal returns (address[3] memory) {
    INonfungiblePositionManager pm = INonfungiblePositionManager(params.positionManager);
    pm.safeTransferFrom(msg.sender, address(this), params.from);

    (, , address token0, address token1, uint24 _fee, , , uint128 liquidity, , , , ) = pm.positions(params.from);
    if (liquidity > 0) {
      pm.decreaseLiquidity(
        INonfungiblePositionManager.DecreaseLiquidityParams({
          tokenId: params.from,
          liquidity: liquidity,
          amount0Min: 0,
          amount1Min: 0,
          deadline: params.deadline
        })
      );
    }
    pm.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: params.from,
        recipient: address(this),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );
    pm.safeTransferFrom(address(this), msg.sender, params.from);

    uint256 token0Balance = IERC20(token0).balanceOf(address(this));
    uint256 token1Balance = IERC20(token1).balanceOf(address(this));
    address tokenIn = token0Balance > token1Balance ? token1 : token0;
    address tokenOut = token0Balance > token1Balance ? token0 : token1;
    uint256 amountIn = token0Balance > token1Balance ? token1Balance : token0Balance;
    _approve(IERC20(tokenIn), params.router, amountIn);
    ISwapRouter(params.router).exactInputSingle(
      ISwapRouter.ExactInputSingleParams({
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fee: _fee,
        recipient: address(this),
        amountIn: amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      })
    );

    if (token0 != params.to && token1 != params.to) {
      _approve(IERC20(tokenOut), params.router, amountIn);
      ISwapRouter(params.router).exactInput(
        ISwapRouter.ExactInputParams({
          path: params.swap.path,
          recipient: address(this),
          amountIn: IERC20(tokenOut).balanceOf(address(this)),
          amountOutMinimum: params.swap.outMin
        })
      );
    }

    emit SellLiquidity(msg.sender, params.to, liquidity);

    return [token0, token1, params.to];
  }

  function sellLiquidity(SellLiquidityParams calldata params) external payable {
    _payCommission();
    _returnRemainder(_sellLiquidity(params));
  }

  function sellLiquidityETH(SellLiquidityParams calldata params) external payable {
    _payCommission();
    address[3] memory tokens = _sellLiquidity(params);

    IWrap wrapper = IWrap(info.getAddress(keccak256("NativeWrapper:Contract")));
    wrapper.withdraw(wrapper.balanceOf(address(this)));

    // solhint-disable-next-line avoid-low-level-calls
    (bool sentRecipient, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(sentRecipient, "LPTokensManager::sellLiquidityETH: transfer ETH to recipeint failed");
    _returnRemainder(tokens);
  }
}