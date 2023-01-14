// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {Address} from '../../../@openzeppelin/contracts/utils/Address.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IJRTSwapModule} from '../interfaces/IJrtSwapModule.sol';
import {
  IUniswapV2Router02
} from '../../../@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract UniV2JRTSwapModule is IJRTSwapModule {
  using SafeERC20 for IERC20;

  struct SwapInfo {
    address routerAddress;
    address[] tokenSwapPath;
    uint256 expiration;
    uint256 minTokensOut;
  }

  function swapToJRT(
    address _recipient,
    address _collateral,
    address _jarvisToken,
    uint256 _amountIn,
    bytes calldata _params
  ) external override returns (uint256 amountOut) {
    // decode swapInfo
    SwapInfo memory swapInfo = abi.decode(_params, (SwapInfo));
    uint256 pathLength = swapInfo.tokenSwapPath.length;
    require(
      swapInfo.tokenSwapPath[pathLength - 1] == _jarvisToken,
      'Wrong token swap path'
    );

    // swap to JRT to final recipient
    IUniswapV2Router02 router = IUniswapV2Router02(swapInfo.routerAddress);

    IERC20(_collateral).safeIncreaseAllowance(address(router), _amountIn);
    amountOut = router.swapExactTokensForTokens(
      _amountIn,
      swapInfo.minTokensOut,
      swapInfo.tokenSwapPath,
      _recipient,
      swapInfo.expiration
    )[pathLength - 1];
  }
}