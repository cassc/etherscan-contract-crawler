//SPDX-ense-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "hardhat/console.sol";

import "./interfaces/IWineryPair.sol";
import "./interfaces/IWETH.sol";
// import "./CyclicLibrary.sol";
import "./libraries/Decimal.sol";
import "hardhat/console.sol";

struct Pool {
  address poolAddress;
  address token0;
  address token1;
  uint256 token0Reserve;
  uint256 token1Reserve;
  uint256 swapFee;
}

struct CallbackData {
  uint256 debtAmount;
  address debtToken;
  Pool[] poolPath;
}

contract FlashswapMultiPool is Ownable {
  using SafeERC20 for IERC20;

  receive() external payable {}

  fallback() external {
    (address sender, uint256 amount0, uint256 amount1, bytes memory data) = abi.decode(
      msg.data[4:],
      (address, uint256, uint256, bytes)
    );
    paybackLoans(sender, amount0, amount1, data);
  }

  // function calculateDebt(Pool[] memory poolPath, address baseToken)
  //   public
  //   view
  //   returns (uint256 debt)
  // {
  //   debt = CyclicLibrary.calcDebtForMaximumProfitFromMultiPoolByMergingRecursion(
  //     poolPath,
  //     baseToken
  //   );
  // }

  // function flashSwap(Pool[] memory poolPath, address baseToken) public {
  //   uint256 debtAmount = calculateDebt(poolPath, baseToken);
  //   startSwapInMultiPool(poolPath, baseToken, debtAmount);
  // }

  function startSwapInMultiPool(
    Pool[] memory poolPath,
    address baseToken,
    uint256 debtAmount
  ) public {
    uint256 balanceBefore = IERC20(baseToken).balanceOf(address(this));
    // console.log("Balance Before", balanceBefore);
    // address token0 = IWineryPair(poolPath[0].poolAddress).token0();
    // address token1 = IWineryPair(poolPath[0].poolAddress).token1();
    // uint256 balance0 = IERC20(token0).balanceOf(poolPath[0].poolAddress);
    // uint256 balance1 = IERC20(token1).balanceOf(poolPath[0].poolAddress);
    // console.log("balance 0 ", balance0);
    // console.log("balance 1 ", balance1);

    for (uint256 i = 0; i < poolPath.length; i++) {
      (poolPath[i].token0Reserve, poolPath[i].token1Reserve, ) = IWineryPair(
        poolPath[i].poolAddress
      ).getReserves();
    }
    // console.log("r0 ", poolPath[0].token0Reserve);
    // console.log("r1 ", poolPath[1].token0Reserve);
    {
      uint256 borrowIntermediaryTokenAmountInFirstPool = getAmountOut(
        debtAmount,
        (baseToken == poolPath[0].token0) ? poolPath[0].token0Reserve : poolPath[0].token1Reserve,
        (baseToken == poolPath[0].token0) ? poolPath[0].token1Reserve : poolPath[0].token0Reserve,
        poolPath[0].swapFee
      );

      // console.log("");
      // console.log("Debt amount ", debtAmount);
      // console.log("Borrow amount ", borrowIntermediaryTokenAmountInFirstPool);

      (uint256 swapAmountToken0Out, uint256 swapAmountToken1Out) = (baseToken == poolPath[0].token0)
        ? (uint256(0), borrowIntermediaryTokenAmountInFirstPool)
        : (borrowIntermediaryTokenAmountInFirstPool, uint256(0));

      // uint256 debt = getAmountIn(
      //   debtAmount,
      //   (baseToken == poolPath[0].token0) ? poolPath[0].token0Reserve : poolPath[0].token1Reserve,
      //   (baseToken == poolPath[0].token0) ? poolPath[0].token1Reserve : poolPath[0].token0Reserve,
      //   poolPath[0].swapFee
      // );

      // console.log("Swap amount on first pool: %s, %s", swapAmountToken0Out, swapAmountToken1Out);

      // console.log("Borrow Intermediary Token: ", debtAmount);
      // console.log("Debt: ", debtAmount);

      CallbackData memory callbackData;
      callbackData.debtAmount = debtAmount;
      callbackData.debtToken = baseToken;
      callbackData.poolPath = poolPath;

      bytes memory data = abi.encode(callbackData);
      IWineryPair(poolPath[0].poolAddress).swap(
        swapAmountToken0Out,
        swapAmountToken1Out,
        address(this),
        data
      );
    }

    uint256 balanceAfter = IERC20(baseToken).balanceOf(address(this));

    // console.log("Balance After", balanceAfter);

    require(balanceAfter > balanceBefore, "Losing money");
  }

  function paybackLoans(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes memory data
  ) internal {
    // console.log("Starting transfer cyclic");
    require(sender == address(this), "Not from this contract");
    uint256 currentTokenAmountInCyclicPool = amount0 > 0 ? amount0 : amount1;
    CallbackData memory info = abi.decode(data, (CallbackData));

    // console.log("Pool Length", info.poolPath.length);
    address currentTokenInCyclicPool = (info.poolPath[0].token0 == info.debtToken)
      ? info.poolPath[0].token1
      : info.poolPath[0].token0;

    IERC20(currentTokenInCyclicPool).transfer(
      info.poolPath[1].poolAddress,
      currentTokenAmountInCyclicPool
    );

    // uint256 currentbalance = IERC20(currentTokenInCyclicPool).balanceOf(address(this));
    // console.log("Balance ", currentbalance);
    // console.log("Cyclic amount ", currentTokenAmountInCyclicPool);

    for (uint256 i = 1; i < info.poolPath.length; i++) {
      // uint256 balance = IERC20(currentTokenInCyclicPool).balanceOf(address(this));
      // console.log("----------------------------------");
      // console.log("Transfer at ", i);
      // console.log("Token ", currentTokenInCyclicPool);
      // console.log("Balance ", balance);
      // console.log("Cyclic amount ", currentTokenAmountInCyclicPool);

      bool isToken0IsIntermediaryToken = info.poolPath[i].token0 == currentTokenInCyclicPool;

      currentTokenInCyclicPool = isToken0IsIntermediaryToken
        ? info.poolPath[i].token1
        : info.poolPath[i].token0;

      (uint256 reserveIn, uint256 reserveOut) = (isToken0IsIntermediaryToken)
        ? (info.poolPath[i].token0Reserve, info.poolPath[i].token1Reserve)
        : (info.poolPath[i].token1Reserve, info.poolPath[i].token0Reserve);

      currentTokenAmountInCyclicPool = getAmountOut(
        currentTokenAmountInCyclicPool,
        reserveIn,
        reserveOut,
        info.poolPath[i].swapFee
      );

      (uint256 amount0Out, uint256 amount1Out) = isToken0IsIntermediaryToken
        ? (uint256(0), currentTokenAmountInCyclicPool)
        : (currentTokenAmountInCyclicPool, uint256(0));

      // console.log("Swap amount on %s pool: %s, %s", i, amount0Out, amount1Out);

      // address to = i <

      IWineryPair(info.poolPath[i].poolAddress).swap(
        amount0Out,
        amount1Out,
        (i < info.poolPath.length - 1) ? info.poolPath[i + 1].poolAddress : address(this),
        new bytes(0)
      );
    }

    // TODO payback loans
    // provider

    // console.log("Payback loands");
    // console.log("debt token: ", info.debtToken);
    // console.log("debt amount: ", info.debtAmount);
    // console.log("balance: ", IERC20(info.debtToken).balanceOf(address(this)));
    // console.log("Pool Address: ", info.poolPath[0].poolAddress);
    IERC20(info.debtToken).safeTransfer(info.poolPath[0].poolAddress, info.debtAmount);
    // address token0 = IWineryPair(info.poolPath[0].poolAddress).token0();
    // address token1 = IWineryPair(info.poolPath[0].poolAddress).token1();
    // (uint256 r0, uint256 r1, ) = IWineryPair(info.poolPath[0].poolAddress).getReserves();
    // uint256 balance0 = IERC20(token0).balanceOf(info.poolPath[0].poolAddress);
    // uint256 balance1 = IERC20(token1).balanceOf(info.poolPath[0].poolAddress);
    // // uint256 amount0Out = (info.poolPath[0].token0 == info.debtToken) ?
    // uint256 amount0In = balance0 > r0 - amount0 ? balance0 - (r0 - amount0) : 0;
    // uint256 amount1In = balance1 > r1 - amount1 ? balance1 - (r1 - amount1) : 0;
    // uint256 balance0Adjusted = (balance0 * 10000) - (amount0In * info.poolPath[0].swapFee);
    // uint256 balance1Adjusted = (balance1 * 10000) - (amount1In * info.poolPath[0].swapFee);
    // console.log("token 0 ", token0);
    // console.log("token 1 ", token1);
    // console.log("r0 ", r0);
    // console.log("r1 ", r1);
    // console.log("balance 0 ", balance0);
    // console.log("balance 1 ", balance1);
    // console.log("amount0 in ", amount0In);
    // console.log("amount1 in ", amount1In);
    // console.log("balance0Adjusted ", balance0Adjusted);
    // console.log("balance1Adjusted ", balance1Adjusted);
    // console.log(balance0Adjusted * balance1Adjusted >= r0 * r1 * 10000**2);
    // // uint256 r0 = IERC20(token1).balanceOf(info.poolPath[0].poolAddress);
    // console.log("End payback loans ------------");
  }

  // function returnSomePoolStruct() public view returns (Pool memory pool) {
  //   return Pool(address(this), address(this), address(this), 10000, 10000, 17);
  // }

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut,
    uint256 swapFee
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");

    uint256 _swapFee = (swapFee == 0) ? 25 : swapFee;
    // console.log("Swap Fee: ", _swapFee);
    // console.log("amountIn: ", amountIn);
    // console.log("reserveIn: ", reserveIn);
    // console.log("reserveOut: ", reserveOut);
    uint256 amountInWithFee = amountIn * (10000 - _swapFee);
    uint256 numerator = amountInWithFee * (reserveOut);
    uint256 denominator = reserveIn * (10000) + amountInWithFee;
    amountOut = numerator / denominator;
  }

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut,
    uint256 swapFee
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
    uint256 numerator = reserveIn * amountOut * 10000;
    uint256 denominator = (reserveOut - amountOut) * (10000 - swapFee);
    amountIn = numerator / denominator + 1;
  }

  function withdrawFund(address erc20Address) public onlyOwner {
    uint256 balance = IERC20(erc20Address).balanceOf(address(this));
    if (balance > 0) {
      IERC20(erc20Address).transfer(owner(), balance);
    }
  }
}

// balance0 = 56101568390613070858
// balance1 = 7043812617315845931008
// r0 = 56195300666840899584
// r1 = 7043812617315845931008
// a0 = 93732276227828726
// a1 = 0
// amount0In = 0
// amount1In = 0