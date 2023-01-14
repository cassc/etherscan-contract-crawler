// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {Address} from '../../../@openzeppelin/contracts/utils/Address.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ISynthereumDeployment} from '../../common/interfaces/IDeployment.sol';
import {IBalancerVault} from '../interfaces/IBalancerVault.sol';
import {IJRTSwapModule} from '../interfaces/IJrtSwapModule.sol';

contract BalancerJRTSwapModule is IJRTSwapModule {
  using SafeERC20 for IERC20;

  struct SwapInfo {
    bytes32 poolId;
    address routerAddress;
    uint256 minTokensOut; // anti slippage
    uint256 expiration;
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

    // build params
    IBalancerVault.SingleSwap memory singleSwap =
      IBalancerVault.SingleSwap(
        swapInfo.poolId,
        IBalancerVault.SwapKind.GIVEN_IN,
        _collateral,
        _jarvisToken,
        _amountIn,
        '0x00'
      );

    IBalancerVault.FundManagement memory funds =
      IBalancerVault.FundManagement(
        address(this),
        false,
        payable(_recipient),
        false
      );

    // swap to JRT to final recipient
    IBalancerVault router = IBalancerVault(swapInfo.routerAddress);

    IERC20(_collateral).safeIncreaseAllowance(address(router), _amountIn);
    amountOut = router.swap(
      singleSwap,
      funds,
      swapInfo.minTokensOut,
      swapInfo.expiration
    );
  }
}