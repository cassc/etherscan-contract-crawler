// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IExecutorHelper1} from './interfaces/kyberswap/IExecutorHelper1.sol';
import {IExecutorHelper2} from './interfaces/kyberswap/IExecutorHelper2.sol';
import {IMetaAggregationRouterV2} from './interfaces/kyberswap/IMetaAggregationRouterV2.sol';
import {IMetaAggregationRouter} from './interfaces/kyberswap/IMetaAggregationRouter.sol';
import {ScaleDataHelper1} from './libraries/kyberswap/ScaleDataHelper1.sol';

contract KyberswapPatcher {
  uint256 private constant _PARTIAL_FILL = 0x01;
  uint256 private constant _REQUIRES_EXTRA_ETH = 0x02;
  uint256 private constant _SHOULD_CLAIM = 0x04;
  uint256 private constant _BURN_FROM_MSG_SENDER = 0x08;
  uint256 private constant _BURN_FROM_TX_ORIGIN = 0x10;
  uint256 private constant _SIMPLE_SWAP = 0x20;

  struct Swap {
    bytes data;
    bytes4 functionSelector;
  }

  struct SimpleSwapData {
    address[] firstPools;
    uint256[] firstSwapAmounts;
    bytes[] swapDatas;
    uint256 deadline;
    bytes destTokenFeeData;
  }

  struct SwapExecutorDescription {
    Swap[][] swapSequences;
    address tokenIn;
    address tokenOut;
    uint256 minTotalAmountOut;
    address to;
    uint256 deadline;
    bytes destTokenFeeData;
  }

  struct Data {
    address router;
    bytes inputData;
    uint256 newAmount;
  }

  error CallFailed(string message, bytes reason);

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    if (value == 0) return;
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'safeTransferFrom: Transfer from fail');
  }

  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    if (value == 0) return;
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'safeApprove: Approve fail');
  }

  function scaleAndSwap(uint256 newAmount, address router, bytes calldata inputData) external payable {
    bytes4 selector = bytes4(inputData[:4]);
    bytes memory dataToDecode = new bytes(inputData.length - 4);
    bytes memory callData;

    for (uint256 i = 0; i < inputData.length - 4; ++i) {
      dataToDecode[i] = inputData[i + 4];
    }

    if (
      selector == IMetaAggregationRouter.swap.selector || selector == IMetaAggregationRouter.swapSimpleMode.selector
    ) {
      (
        address callTarget,
        IMetaAggregationRouter.SwapDescription memory desc,
        bytes memory targetData,
        bytes memory clientData
      ) = abi.decode(dataToDecode, (address, IMetaAggregationRouter.SwapDescription, bytes, bytes));

      (desc, targetData) = _getScaledInputDataV1(
        desc,
        targetData,
        newAmount,
        selector == IMetaAggregationRouter.swapSimpleMode.selector || _flagsChecked(desc.flags, _SIMPLE_SWAP)
      );
      callData = abi.encodeWithSelector(selector, callTarget, desc, targetData, clientData);

      safeTransferFrom(address(desc.srcToken), msg.sender, address(this), newAmount);
      safeApprove(address(desc.srcToken), router, newAmount);
    } else if (selector == IMetaAggregationRouterV2.swap.selector) {
      IMetaAggregationRouterV2.SwapExecutionParams memory params = abi.decode(
        dataToDecode,
        (IMetaAggregationRouterV2.SwapExecutionParams)
      );

      (params.desc, params.targetData) = _getScaledInputDataV2(
        params.desc,
        params.targetData,
        newAmount,
        _flagsChecked(params.desc.flags, _SIMPLE_SWAP)
      );
      callData = abi.encodeWithSelector(selector, params);
      
      safeTransferFrom(address(params.desc.srcToken), msg.sender, address(this), newAmount);
      safeApprove(address(params.desc.srcToken), router, newAmount);
    } else if (selector == IMetaAggregationRouterV2.swapSimpleMode.selector) {
      (
        address callTarget,
        IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
        bytes memory targetData,
        bytes memory clientData
      ) = abi.decode(dataToDecode, (address, IMetaAggregationRouterV2.SwapDescriptionV2, bytes, bytes));

      (desc, targetData) = _getScaledInputDataV2(desc, targetData, newAmount, true);
      callData = abi.encodeWithSelector(selector, callTarget, desc, targetData, clientData);

      safeTransferFrom(address(desc.srcToken), msg.sender, address(this), newAmount);
      safeApprove(address(desc.srcToken), router, newAmount);
    } else revert('KyberswapPatcher: Invalid selector');

    (bool success, bytes memory data) = router.call(callData);
    if (!success) revert CallFailed('KyberswapPatcher: call failed', data);
  }

  function _getScaledInputDataV1(
    IMetaAggregationRouter.SwapDescription memory desc,
    bytes memory executorData,
    uint256 newAmount,
    bool isSimpleMode
  ) internal pure returns (IMetaAggregationRouter.SwapDescription memory, bytes memory) {
    uint256 oldAmount = desc.amount;
    if (oldAmount == newAmount) {
      return (desc, executorData);
    }

    // simple mode swap
    if (isSimpleMode) {
      return (
        _scaledSwapDescriptionV1(desc, oldAmount, newAmount),
        _scaledSimpleSwapData(executorData, oldAmount, newAmount)
      );
    }

    //normal mode swap
    return (
      _scaledSwapDescriptionV1(desc, oldAmount, newAmount),
      _scaledExecutorCallBytesData(executorData, oldAmount, newAmount)
    );
  }

  function _getScaledInputDataV2(
    IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
    bytes memory executorData,
    uint256 newAmount,
    bool isSimpleMode
  ) internal pure returns (IMetaAggregationRouterV2.SwapDescriptionV2 memory, bytes memory) {
    uint256 oldAmount = desc.amount;
    if (oldAmount == newAmount) {
      return (desc, executorData);
    }

    // simple mode swap
    if (isSimpleMode) {
      return (
        _scaledSwapDescriptionV2(desc, oldAmount, newAmount),
        _scaledSimpleSwapData(executorData, oldAmount, newAmount)
      );
    }

    //normal mode swap
    return (
      _scaledSwapDescriptionV2(desc, oldAmount, newAmount),
      _scaledExecutorCallBytesData(executorData, oldAmount, newAmount)
    );
  }

  function _scaledSwapDescriptionV1(
    IMetaAggregationRouter.SwapDescription memory desc,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (IMetaAggregationRouter.SwapDescription memory) {
    desc.minReturnAmount = (desc.minReturnAmount * newAmount) / oldAmount;
    if (desc.minReturnAmount == 0) desc.minReturnAmount = 1;
    desc.amount = newAmount;
    for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
      desc.srcAmounts[i] = (desc.srcAmounts[i] * newAmount) / oldAmount;
    }
    return desc;
  }

  function _scaledSwapDescriptionV2(
    IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (IMetaAggregationRouterV2.SwapDescriptionV2 memory) {
    desc.minReturnAmount = (desc.minReturnAmount * newAmount) / oldAmount;
    if (desc.minReturnAmount == 0) desc.minReturnAmount = 1;
    desc.amount = newAmount;
    for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
      desc.srcAmounts[i] = (desc.srcAmounts[i] * newAmount) / oldAmount;
    }
    return desc;
  }

  function _scaledSimpleSwapData(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    SimpleSwapData memory swapData = abi.decode(data, (SimpleSwapData));
    for (uint256 i = 0; i < swapData.firstPools.length; i++) {
      swapData.firstSwapAmounts[i] = (swapData.firstSwapAmounts[i] * newAmount) / oldAmount;
    }
    return abi.encode(swapData);
  }

  function _scaledExecutorCallBytesData(
    bytes memory data,
    uint256 oldAmount,
    uint256 newAmount
  ) internal pure returns (bytes memory) {
    SwapExecutorDescription memory executorDesc = abi.decode(data, (SwapExecutorDescription));
    executorDesc.minTotalAmountOut = (executorDesc.minTotalAmountOut * newAmount) / oldAmount;
    for (uint256 i = 0; i < executorDesc.swapSequences.length; i++) {
      Swap memory swap = executorDesc.swapSequences[i][0];
      bytes4 functionSelector = swap.functionSelector;

      if (functionSelector == IExecutorHelper1.executeUniSwap.selector) {
        swap.data = ScaleDataHelper1.newUniSwap(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeStableSwap.selector) {
        swap.data = ScaleDataHelper1.newStableSwap(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeCurveSwap.selector) {
        swap.data = ScaleDataHelper1.newCurveSwap(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeKyberDMMSwap.selector) {
        swap.data = ScaleDataHelper1.newKyberDMM(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeUniV3ProMMSwap.selector) {
        swap.data = ScaleDataHelper1.newUniV3ProMM(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeRfqSwap.selector) {
        revert('KyberswapPatcher: Can not scale RFQ swap');
      } else if (functionSelector == IExecutorHelper1.executeBalV2Swap.selector) {
        swap.data = ScaleDataHelper1.newBalancerV2(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeDODOSwap.selector) {
        swap.data = ScaleDataHelper1.newDODO(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeVelodromeSwap.selector) {
        swap.data = ScaleDataHelper1.newVelodrome(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeGMXSwap.selector) {
        swap.data = ScaleDataHelper1.newGMX(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeSynthetixSwap.selector) {
        swap.data = ScaleDataHelper1.newSynthetix(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper1.executeHashflowSwap.selector) {
        revert('KyberswapPatcher: Can not scale RFQ swap');
      } else if (functionSelector == IExecutorHelper1.executeCamelotSwap.selector) {
        swap.data = ScaleDataHelper1.newCamelot(swap.data, oldAmount, newAmount);
      } else if (functionSelector == IExecutorHelper2.executeKyberLimitOrder.selector) {
        revert('KyberswapPatcher: Can not scale RFQ swap');
      } else revert('AggregationExecutor: Dex type not supported');
    }
    return abi.encode(executorDesc);
  }

  function _flagsChecked(uint256 number, uint256 flag) internal pure returns (bool) {
    return number & flag != 0;
  }
}