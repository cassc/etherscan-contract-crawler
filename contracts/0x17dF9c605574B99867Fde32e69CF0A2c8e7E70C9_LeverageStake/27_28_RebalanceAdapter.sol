// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeMath} from '../dependencies/openzeppelin/contracts/SafeMath.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {IBpool} from '../interfaces/IBpool.sol';
import {Invoke} from '../dependencies/Invoke.sol';
import {IRebalanceAdapter} from '../interfaces/IRebalanceAdapter.sol';
import '../interfaces/IETF.sol';
import '../interfaces/IAggregationRouterV5.sol';

contract RebalanceAdapter is IRebalanceAdapter, Ownable {
  using SafeMath for uint256;
  using Invoke for IETF;

  modifier onlyManager(address _etf) {
    require(
      IETF(_etf).adminList(msg.sender) || msg.sender == IETF(_etf).getController(),
      'onlyAdmin'
    );
    _;
  }

  modifier validEtf(address _etf) {
    require(ICrpFactory(crpFactory).isCrp(_etf), 'NOT_VALID_ETF');
    _;
  }

  uint256 private constant _ONE_FOR_ZERO_MASK = 1 << 255;

  // swap router should be approved before using
  mapping(address => bool) public isRouterApproved;
  address public factory;
  address public crpFactory;

  // =========== events ===================
  event CrpFactoryUpdated(address old, address newCrp);
  event FactoryUpdated(address old, address newF);
  event RouterStateChange(address router, bool isApproved);
  event TokenApproved(address etf, address token, address spender, uint256 amount);
  /// @notice Event emited after rebalancing
  /// @param token0 The token to sell
  /// @param token1 The token to buy
  /// @param newWeight0 New weight of token0
  /// @param newWeight1 New weight of token1
  /// @param newBalance0 New balance of token0
  /// @param newBalance1 New balance of token1
  /// @param isSoldOut Is sold out token0
  event Rebalanced(
    address indexed token0,
    address indexed token1,
    uint newWeight0,
    uint newWeight1,
    uint newBalance0,
    uint newBalance1,
    bool isSoldOut
  );

  constructor(address _crpFactory, address _factory) public {
    crpFactory = _crpFactory;
    factory = _factory;
  }

  // =========== view functions ===================

  /// @notice Returns the new weight and balance of underlying tokens after rebalancing
  /// @param bPool The underlying pool of etf
  /// @param token The rebalanced token address
  /// @return tokenBalance The new balance of token
  /// @return tokenWeight The new weight of token
  function getUnderlyingInfo(
    IBpool bPool,
    address token
  ) external view override returns (uint256 tokenBalance, uint256 tokenWeight) {
    tokenBalance = bPool.getBalance(token);
    tokenWeight = bPool.getDenormalizedWeight(token);
  }

  /// @notice Returns the allowance the underlying token approved to the spender
  /// @param bPool The underlying pool of etf
  /// @param token The token which reside in the bPool
  /// @param spender The account the bPool gives allowance to
  /// @return allowance The remaining allowance
  function getUnderlyingAllowance(
    address bPool,
    address token,
    address spender
  ) external view returns (uint256 allowance) {
    allowance = IERC20(token).allowance(bPool, spender);
  }

  function getSig(bytes memory _data) private pure returns (bytes4 sig) {
    assembly {
      sig := mload(add(_data, 32))
    }
  }

  // =========== external functions ===================

  /// @notice Enable or disable a swap router to use across the adapter
  /// @param router The swap router address
  /// @param isApproved The state want to change to, true or false
  function approveSwapRouter(address router, bool isApproved) external override onlyOwner {
    require(router != address(0), '!ZERO');
    isRouterApproved[router] = isApproved;

    emit RouterStateChange(router, isApproved);
  }

  /// @notice Approve allowance for underlying token
  /// @param etf The etf which contains the token
  /// @param token The underlying token to approve
  /// @param spender The account to consume the allowance
  /// @param amount The allowance amount
  function approve(
    IETF etf,
    address token,
    address spender,
    uint256 amount
  ) external override validEtf(address(etf)) onlyManager(address(etf)) {
    require(isRouterApproved[spender], 'SPENDER_NOT_APPROVED');

    etf.invokeApprove(token, spender, amount, true);

    emit TokenApproved(address(etf), token, spender, amount);
  }

  /// @notice Rebalance the position of the underlying tokens in etf
  /// @param rebalanceInfo Key information to perform rebalance
  function rebalance(
    IRebalanceAdapter.RebalanceInfo calldata rebalanceInfo
  ) external override validEtf(rebalanceInfo.etf) onlyManager(rebalanceInfo.etf) {
    IETF etf = IETF(rebalanceInfo.etf);
    IBpool bPool = IBpool(etf.bPool());

    require(address(bPool) != address(0), 'ZERO_BPOOL');
    require(!IFactory(factory).isPaused(), 'PAUSED');

    etf._verifyWhiteToken(rebalanceInfo.token1);

    require(bPool.isBound(rebalanceInfo.token0), 'TOKEN_NOT_BOUND');

    (, uint256 collectEndTime, , uint256 closureEndTime, , , , , , , ) = etf.etfStatus();
    if (etf.etype() == 1) {
      require(etf.isCompletedCollect(), 'COLLECTION_FAILED');
      require(
        block.timestamp > collectEndTime && block.timestamp < closureEndTime,
        'NOT_REBALANCE_PERIOD'
      );
    }

    if (!bPool.isBound(rebalanceInfo.token1)) {
      IETF(rebalanceInfo.etf).invokeApprove(rebalanceInfo.token1, address(bPool), 0, false);
      IETF(rebalanceInfo.etf).invokeApprove(
        rebalanceInfo.token1,
        address(bPool),
        uint256(-1),
        false
      );
    }

    require(rebalanceInfo.token0 != rebalanceInfo.token1, 'TOKENS_SAME');

    uint256 receivedAmount = _makeSwap(rebalanceInfo, etf.bPool());

    _rebalance(etf, bPool, rebalanceInfo, receivedAmount);
  }

  function setFactory(address _factory) external onlyOwner {
    require(_factory != address(0), 'ZERO ADDRESS');

    emit FactoryUpdated(factory, _factory);

    factory = _factory;
  }

  function setCrpFactory(address _crpFactory) external onlyOwner {
    require(_crpFactory != address(0), 'ZERO ADDRESS');

    emit CrpFactoryUpdated(crpFactory, _crpFactory);

    crpFactory = _crpFactory;
  }

  struct RebalanceResult {
    uint256 newWeight0;
    uint256 newWeight1;
    uint256 newBalance0;
    uint256 newBalance1;
    bool isSoldOut;
  }

  /// @notice Internal function to perform rebalance
  /// @param etf The etf expected to rebalance
  /// @param bPool The underlying pool of the etf
  /// @param rebalanceInfo Key information to perform rebalance
  /// @param token1Received The amount received after exchange by a swap router
  function _rebalance(
    IETF etf,
    IBpool bPool,
    IRebalanceAdapter.RebalanceInfo calldata rebalanceInfo,
    uint256 token1Received
  ) internal {
    uint256 currentWeight0 = bPool.getDenormalizedWeight(rebalanceInfo.token0);
    uint256 currentBalance0 = bPool.getBalance(rebalanceInfo.token0);

    uint256 deltaWeight = currentWeight0.mul(rebalanceInfo.quantity).div(currentBalance0);

    require(deltaWeight <= currentWeight0, 'DELTA_WEIGHT_TOO_BIG');

    RebalanceResult memory vars;

    vars.isSoldOut = rebalanceInfo.quantity == currentBalance0;
    if (vars.isSoldOut) {
      etf.invokeUnbind(rebalanceInfo.token0);
    } else {
      vars.newWeight0 = currentWeight0.sub(deltaWeight);
      vars.newBalance0 = currentBalance0.sub(rebalanceInfo.quantity);
      require(vars.newWeight0 >= bPool.MIN_WEIGHT(), 'MIN_WEIGHT_WRONG');

      etf.invokeRebind(rebalanceInfo.token0, vars.newBalance0, vars.newWeight0, true);
    }

    if (bPool.isBound(rebalanceInfo.token1)) {
      // token1 alread exists
      uint256 currentWeight1 = bPool.getDenormalizedWeight(rebalanceInfo.token1);
      uint256 currentBalance1 = bPool.getBalance(rebalanceInfo.token1);
      vars.newWeight1 = currentWeight1.add(deltaWeight);
      vars.newBalance1 = currentBalance1.add(token1Received);

      require(vars.newWeight1 <= bPool.MAX_WEIGHT(), 'EXCEEDS_MAX_WEIGHT');
      etf.invokeRebind(rebalanceInfo.token1, vars.newBalance1, vars.newWeight1, true);
    } else {
      // token1 is out of the etf
      require(bPool.getNumTokens() < bPool.MAX_BOUND_TOKENS(), 'MAX_BOUND_TOKENS');

      require(deltaWeight >= bPool.MIN_WEIGHT(), 'MIN_WEIGHT_WRONG');

      vars.newWeight1 = deltaWeight;
      vars.newBalance1 = token1Received;

      etf.invokeRebind(rebalanceInfo.token1, vars.newBalance1, vars.newWeight1, false);
    }

    emit Rebalanced(
      rebalanceInfo.token0,
      rebalanceInfo.token1,
      vars.newWeight0,
      vars.newWeight1,
      vars.newBalance0,
      vars.newBalance1,
      vars.isSoldOut
    );
  }

  /// @notice Internal function to execute swap
  /// @param rebalanceInfo Key information to perform rebalance
  /// @param bPool Underlying pool of etf
  function _makeSwap(
    IRebalanceAdapter.RebalanceInfo calldata rebalanceInfo,
    address bPool
  ) internal returns (uint256 postSwap) {
    require(isRouterApproved[rebalanceInfo.aggregator], 'ROUTER_NOT_APPROVED');

    // approve first
    IETF(rebalanceInfo.etf).invokeApprove(
      rebalanceInfo.token0,
      rebalanceInfo.aggregator,
      rebalanceInfo.quantity,
      true
    );

    uint256 preSwap = IERC20(rebalanceInfo.token1).balanceOf(bPool);

    if (rebalanceInfo.swapType == IRebalanceAdapter.SwapType.UNISWAPV3) {
      (uint256 minReturn, uint256[] memory pools) = abi.decode(
        rebalanceInfo.data,
        (uint256, uint256[])
      );

      _checkPools(pools[pools.length - 1], rebalanceInfo.token1);

      bytes memory swapData = abi.encodeWithSignature(
        'uniswapV3Swap(uint256,uint256,uint256[])',
        rebalanceInfo.quantity,
        minReturn,
        pools
      );

      IETF(rebalanceInfo.etf).execute(rebalanceInfo.aggregator, 0, swapData, true);
    } else if (rebalanceInfo.swapType == IRebalanceAdapter.SwapType.UNISWAPV2) {
      (uint256 minReturn, address[] memory paths) = abi.decode(
        rebalanceInfo.data,
        (uint256, address[])
      );

      address output = paths[paths.length - 1];
      require(output == rebalanceInfo.token1, 'MALICIOUS_PATH');

      bytes memory swapData = abi.encodeWithSignature(
        'swapExactTokensForTokens(uint256,uint256,address[],address,uint256)',
        rebalanceInfo.quantity,
        minReturn,
        paths,
        bPool,
        block.timestamp.add(1800)
      );

      IETF(rebalanceInfo.etf).execute(rebalanceInfo.aggregator, 0, swapData, true);
    } else {
      _validateData(rebalanceInfo.quantity, rebalanceInfo.data, rebalanceInfo.token1, bPool);

      IETF(rebalanceInfo.etf).execute(rebalanceInfo.aggregator, 0, rebalanceInfo.data, true);
    }

    postSwap = IERC20(rebalanceInfo.token1).balanceOf(bPool).sub(preSwap);
  }

  function _checkPools(uint256 pool, address expectedOutput) internal view {
    bool zeroForOne = pool & _ONE_FOR_ZERO_MASK == 0;
    address output = zeroForOne
      ? IUniswapV3Pool(address(uint160(pool))).token1()
      : IUniswapV3Pool(address(uint160(pool))).token0();
    require(output == expectedOutput, 'MIS_OUTPUT');
  }

  /**
   * @notice Internal function to validate transaction data
   * @param quantity The token amount to consume
   * @param data The calldata to call the aggregator
   * @param expectedReceiver The expected account to receive the swapped asset
   **/
  function _validateData(
    uint256 quantity,
    bytes calldata data,
    address output,
    address expectedReceiver
  ) internal view {
    bytes4 selector = getSig(data);
    if (selector == IAggregationRouterV5.swap.selector) {
      (, GenericRouter.SwapDescription memory desc, , ) = abi.decode(
        data[4:],
        (address, GenericRouter.SwapDescription, bytes, bytes)
      );
      require(quantity == desc.amount, 'QUANTITY_MISMATCH');
      require(output == desc.dstToken, 'MIS_OUTPUT');
      require(expectedReceiver == desc.dstReceiver, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.unoswap.selector) {
      (, uint256 amount, , uint256[] memory pools) = abi.decode(
        data[4:],
        (address, uint256, uint256, uint256[])
      );

      _checkPools(pools[pools.length - 1], output);

      require(quantity == amount, 'QUANTITY_MISMATCH');
    } else if (selector == IAggregationRouterV5.unoswapTo.selector) {
      (address recipient, , uint256 amount, , uint256[] memory pools) = abi.decode(
        data[4:],
        (address, address, uint256, uint256, uint256[])
      );

      _checkPools(pools[pools.length - 1], output);

      require(quantity == amount, 'QUANTITY_MISMATCH');
      require(expectedReceiver == recipient, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.uniswapV3Swap.selector) {
      (uint256 amount, , uint256[] memory pools) = abi.decode(
        data[4:],
        (uint256, uint256, uint256[])
      );

      _checkPools(pools[pools.length - 1], output);

      require(quantity == amount, 'QUANTITY_MISMATCH');
    } else if (selector == IAggregationRouterV5.uniswapV3SwapTo.selector) {
      (address recipient, uint256 amount, , uint256[] memory pools) = abi.decode(
        data[4:],
        (address, uint256, uint256, uint256[])
      );

      _checkPools(pools[pools.length - 1], output);

      require(quantity == amount, 'QUANTITY_MISMATCH');
      require(expectedReceiver == recipient, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.clipperSwap.selector) {
      (, , address dstToken, uint256 inputAmount, , , , ) = abi.decode(
        data[4:],
        (address, address, address, uint256, uint256, uint256, bytes32, bytes32)
      );

      require(output == dstToken, 'MIS_OUTPUT');
      require(quantity == inputAmount, 'QUANTITY_MISMATCH');
    } else if (selector == IAggregationRouterV5.clipperSwapTo.selector) {
      (, address recipient, , address dstToken, uint256 inputAmount, , , , ) = abi.decode(
        data[4:],
        (address, address, address, address, uint256, uint256, uint256, bytes32, bytes32)
      );

      require(quantity == inputAmount, 'QUANTITY_MISMATCH');
      require(output == dstToken, 'MIS_OUTPUT');
      require(expectedReceiver == recipient, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.fillOrder.selector) {
      (OrderLib.Order memory order, , , , , ) = abi.decode(
        data[4:],
        (OrderLib.Order, bytes, bytes, uint256, uint256, uint256)
      );

      require(quantity == order.makingAmount, 'QUANTITY_MISMATCH');
      require(output == order.takerAsset, 'MIS_OUTPUT');
      require(expectedReceiver == order.receiver, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.fillOrderRFQ.selector) {
      (OrderRFQLib.OrderRFQ memory order, , ) = abi.decode(
        data[4:],
        (OrderRFQLib.OrderRFQ, bytes, uint256)
      );

      require(quantity == order.makingAmount, 'QUANTITY_MISMATCH');
    } else if (selector == IAggregationRouterV5.fillOrderRFQTo.selector) {
      (OrderRFQLib.OrderRFQ memory order, , , address target) = abi.decode(
        data[4:],
        (OrderRFQLib.OrderRFQ, bytes, uint256, address)
      );

      require(quantity == order.makingAmount, 'QUANTITY_MISMATCH');
      require(output == order.takerAsset, 'MIS_OUTPUT');
      require(expectedReceiver == target, 'WRONG_RECEIVE');
    } else if (selector == IAggregationRouterV5.fillOrderTo.selector) {
      (OrderLib.Order memory order, , , , , , address target) = abi.decode(
        data[4:],
        (OrderLib.Order, bytes, bytes, uint256, uint256, uint256, address)
      );

      require(quantity == order.makingAmount, 'QUANTITY_MISMATCH');
      require(output == order.takerAsset, 'MIS_OUTPUT');
      require(expectedReceiver == target, 'WRONG_RECEIVE');
    } else {
      revert('WRONG_METHOD');
    }
  }
}