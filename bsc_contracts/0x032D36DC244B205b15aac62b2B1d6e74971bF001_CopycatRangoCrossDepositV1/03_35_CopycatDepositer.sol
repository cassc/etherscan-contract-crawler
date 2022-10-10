// SPDX-License-Identifier: BUSL-1.1-COPYCAT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./lib/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICopycatAdapter.sol";
import "./interfaces/ICopycatPlugin.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IWETH.sol";

import "./CopycatLeaderFactory.sol";
import "./CopycatLeaderStorage.sol";
import "./lib/CopycatEmergency.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Deposit and withdrawal of single token
contract CopycatDepositer is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  CopycatLeaderStorage public immutable S;
  IERC20 public immutable copycatToken;
  IWETH public immutable WETH;
  uint256 constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  event ReceiveBnb(address indexed payer, uint256 value);

  fallback() external payable {
    emit ReceiveBnb(msg.sender, msg.value);
  }

  receive() external payable {
    emit ReceiveBnb(msg.sender, msg.value);
  }

  constructor(CopycatLeaderStorage _S, IWETH _WETH) {
    S = _S;
    WETH = _WETH;
    copycatToken = S.copycatToken();
  }

  function buyToken(address token, uint256 amount) internal {
    if (token != address(WETH) && amount > 0) {
      if (amount < 100000) amount = 100000;
      
      IUniswapV2Router02 router = IUniswapV2Router02(S.getTradingRouteRouter(token));
      
      uint256 amountIn = router.getAmountsIn(amount, S.getTradingRouteBuy(token))[0];

      WETH.approve(address(router), amountIn);

      router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        amountIn,
        0,
        S.getTradingRouteBuy(token),
        address(this),
        block.timestamp
      );
    }
  }

  function sellToken(address token, uint256 amount) internal {
    if (token != address(WETH) && amount > 100000) {
      IUniswapV2Router02 router = IUniswapV2Router02(S.getTradingRouteRouter(token));

      IERC20(token).safeApproveNew(address(router), amount);

      router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        amount,
        0,
        S.getTradingRouteSell(token),
        address(this),
        block.timestamp
      );
    }
  }

  function getLPReserves(IUniswapV2Pair lpToken, uint256 amount) public view returns(IUniswapV2Router02, address, uint256, address, uint256) {
    uint256 totalSupply = lpToken.totalSupply();
    (uint256 reserve0, uint256 reserve1, ) = lpToken.getReserves();
    uint256 percentage = amount * 1e18 / totalSupply;
    return (
      IUniswapV2Router02(S.factory2router(lpToken.factory())),
      lpToken.token0(),
      reserve0 * percentage / 1e18,
      lpToken.token1(),
      reserve1 * percentage / 1e18
    );
  }

  function buyLP(address lpToken, uint256 amount) internal returns (
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
  ) {
    if (amount > 0) {
      if (amount < 100000) amount = 100000;

      (IUniswapV2Router02 router, address token0, uint256 amount0, address token1, uint256 amount1) = getLPReserves(IUniswapV2Pair(lpToken), amount);
      
      buyToken(token0, amount0);
      buyToken(token1, amount1);

      IERC20(token0).safeApproveNew(address(router), amount0);
      IERC20(token1).safeApproveNew(address(router), amount1);

      (amountA, amountB, liquidity) = router.addLiquidity(
        token0,
        token1,
        amount0,
        amount1,
        0,
        0,
        address(this),
        block.timestamp
      );
    }
  }

  function sellLP(address lpToken, uint256 amount) internal {
    if (amount > 100000) {
      (IUniswapV2Router02 router, address token0, uint256 amount0, address token1, uint256 amount1) = getLPReserves(IUniswapV2Pair(lpToken), amount);

      IERC20(lpToken).safeApproveNew(address(router), amount);

      (uint256 amountA, uint256 amountB) = router.removeLiquidity(
        token0,
        token1,
        amount,
        0,
        0,
        address(this),
        block.timestamp
      );

      sellToken(token0, amountA);
      sellToken(token1, amountB);
    }
  }

  event Buy(address indexed buyer, address indexed leader, uint256 percentage, uint256 share);
  function _buy(address to, CopycatLeader leader, uint256 percentage, uint256 finalPercentage) internal returns(uint256 share) {
    // Prevent leader injection
    require(S.getLeaderId(address(leader)) != 0, "N");

    // Collect CPC fee
    uint256 depositCopycatFee = S.getLeaderDepositCopycatFee(address(leader));
    if (depositCopycatFee > 0 && to != leader.owner()) {
      copycatToken.transferFrom(msg.sender, address(this), depositCopycatFee);
      copycatToken.approve(address(S), depositCopycatFee);
    }

    IERC20[] memory tokens = leader.getTokens();

    for (uint256 i = 1; i < tokens.length; i++) {
      address token = address(tokens[i]);
      uint256 amount = leader.getTokenBalance(IERC20(token)) * percentage / 1e18;
      uint256 tokenType = leader.tokensType(token);

      if (tokenType == 1) {
        buyToken(token, amount);
      } else {
        buyLP(token, amount);
      }

      IERC20(token).safeApproveNew(address(leader), amount);
    }

    // Reserve WBNB for depositing
    {
      uint256 amount = leader.getTokenBalance(WETH) * percentage / 1e18;
      require(WETH.balanceOf(address(this)) >= amount, "Not enough BNB");
      WETH.approve(address(leader), amount);
    }

    share = leader.depositTo(to, finalPercentage, WETH, MAX_INT);

    // emit Buy(to, address(leader), percentage, share);
  }

  event Sell(address indexed buyer, address indexed leader, uint256 shareAmount, uint256 totalBnb);
  function _sell(CopycatLeader leader, uint256 shareAmount) internal returns(uint256 totalBnb) {
    // Prevent leader injection
    require(S.getLeaderId(address(leader)) != 0, "N");
    
    uint256 beforeBnb = WETH.balanceOf(address(this));
    IERC20[] memory tokens = leader.getTokens();
    uint256[] memory beforeTokens = new uint256[](tokens.length);
    
    for (uint256 i = 0; i < tokens.length; i++) {
      beforeTokens[i] = tokens[i].balanceOf(address(this));
    }

    leader.withdrawTo(address(this), shareAmount, tokens[0], 0, true);

    for (uint256 i = 0; i < tokens.length; i++) {
      address token = address(tokens[i]);
      uint256 amount = IERC20(token).balanceOf(address(this)) - beforeTokens[i];
      uint256 tokenType = leader.tokensType(token);

      if (tokenType == 1) {
        sellToken(token, amount);
      } else {
        sellLP(token, amount);
      }
    }

    totalBnb = WETH.balanceOf(address(this)) - beforeBnb;

    // emit Sell(to, address(leader), shareAmount, totalBnb);
  }

  function buy(address to, CopycatLeader leader, uint256 percentage, uint256 finalPercentage, uint256 minShare) payable external nonReentrant returns(uint256 share) {
    WETH.deposit{value: msg.value}();
    share = _buy(to, leader, percentage, finalPercentage);
    require(share >= minShare, "I");
    emit Buy(to, address(leader), finalPercentage, share);
  }

  function buyOtherToken(address to, CopycatLeader leader, IERC20 token, uint256 amount, uint256 percentage, uint256 finalPercentage, uint256 minShare) external nonReentrant returns(uint256 share) {
    token.safeTransferFrom(msg.sender, address(this), amount);
    sellToken(address(token), amount);
    share = _buy(to, leader, percentage, finalPercentage);
    require(share >= minShare, "I");
    emit Buy(to, address(leader), finalPercentage, share);
  }

  function sell(address to, CopycatLeader leader, uint256 shareAmount, uint256 minBnb) external nonReentrant returns(uint256 totalBnb) {
    leader.transferFrom(msg.sender, address(this), shareAmount);
    totalBnb = _sell(leader, shareAmount);
    WETH.withdraw(totalBnb);
    payable(to).transfer(totalBnb);
    require(totalBnb >= minBnb, "I");
    emit Sell(to, address(leader), shareAmount, totalBnb);
  }

  function sellOtherToken(address to, CopycatLeader leader, IERC20 token, uint256 shareAmount, uint256 minToken) external nonReentrant returns(uint256 totalBnb) {
    leader.transferFrom(msg.sender, address(this), shareAmount);
    totalBnb = _sell(leader, shareAmount);
    if (address(token) != address(WETH)) {
      IUniswapV2Router02 router = IUniswapV2Router02(S.getTradingRouteRouter(address(token)));

      uint256 balanceBefore = token.balanceOf(address(this));

      WETH.approve(address(router), totalBnb);

      router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        totalBnb,
        0,
        S.getTradingRouteBuy(address(token)),
        address(this),
        block.timestamp
      );

      require(token.balanceOf(address(this)) - balanceBefore >= minToken, "I");
    } else {
      require(totalBnb >= minToken, "I");
    }
    emit Sell(to, address(leader), shareAmount, totalBnb);
  }

  event AdminRecoverToken(address indexed caller, address indexed token, address indexed to, uint256 amount);
  function adminRecoverToken(IERC20 token, address to, uint256 amount) external onlyOwner {
    token.safeTransfer(to, amount);
    emit AdminRecoverToken(msg.sender, address(token), to, amount);
  }

  event AdminRecoverBnb(address indexed caller, address indexed to, uint256 amount);
  function adminRecoverBnb(address to, uint256 amount) external onlyOwner {
    payable(to).transfer(amount);
    emit AdminRecoverBnb(msg.sender, to, amount);
  }
}