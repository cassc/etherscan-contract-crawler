// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IConnext} from "connext-interfaces/core/IConnext.sol";
import {SwapAdapter} from "../../shared/Swap/SwapAdapter.sol";

contract SwapAndXCall is SwapAdapter {
  // Connext address on this domain
  IConnext connext;

  constructor(address _connext) SwapAdapter() {
    connext = IConnext(_connext);
  }

  // EXTERNAL FUNCTIONS
  /**
   * @notice Calls a swapper contract and then calls xcall on connext
   * @dev Data for the swap is generated offchain to call to the appropriate swapper contract
   * Function is payable since it uses the relayer fee in native asset
   * @param _fromAsset Address of the asset to swap from
   * @param _toAsset Address of the asset to swap to
   * @param _amountIn Amount of the asset to swap from
   * @param _swapper Address of the swapper contract
   * @param _swapData Data to call the swapper contract with
   * @param _destination Destination of the xcall
   * @param _to Address to send the asset and call with the calldata on the destination
   * @param _delegate Delegate address
   * @param _slippage Total slippage amount accepted
   * @param _callData Calldata to call the destination with
   */
  function swapAndXCall(
    address _fromAsset,
    address _toAsset,
    uint256 _amountIn,
    address _swapper,
    bytes calldata _swapData,
    uint32 _destination,
    address _to,
    address _delegate,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable {
    uint256 amountOut = _setupAndSwap(_fromAsset, _toAsset, _amountIn, _swapper, _swapData);

    connext.xcall{value: _fromAsset == address(0) ? msg.value - _amountIn : msg.value}(
      _destination,
      _to,
      _toAsset,
      _delegate,
      amountOut,
      _slippage,
      _callData
    );
  }

  /**
   * @notice Calls a swapper contract and then calls xcall on connext
   * @dev Data for the swap is generated offchain to call to the appropriate swapper contract
   * Pays relayer fee from the input asset
   * @param _fromAsset Address of the asset to swap from
   * @param _toAsset Address of the asset to swap to
   * @param _amountIn Amount of the asset to swap from
   * @param _swapper Address of the swapper contract
   * @param _swapData Data to call the swapper contract with
   * @param _destination Destination of the xcall
   * @param _to Address to send the asset and call with the calldata on the destination
   * @param _delegate Delegate address
   * @param _slippage Total slippage amount accepted
   * @param _callData Calldata to call the destination with
   * @param _relayerFee Relayer fee to pay in the input asset
   */
  function swapAndXCall(
    address _fromAsset,
    address _toAsset,
    uint256 _amountIn,
    address _swapper,
    bytes calldata _swapData,
    uint32 _destination,
    address _to,
    address _delegate,
    uint256 _slippage,
    bytes calldata _callData,
    uint256 _relayerFee
  ) external payable {
    uint256 amountOut = _setupAndSwap(_fromAsset, _toAsset, _amountIn, _swapper, _swapData);

    connext.xcall(_destination, _to, _toAsset, _delegate, amountOut - _relayerFee, _slippage, _callData, _relayerFee);
  }

  // INTERNAL FUNCTIONS

  /**
   * @notice Sets up the swap and returns the amount out
   * @dev Handles approvals to the connext contract and the swapper contract
   * @param _fromAsset Address of the asset to swap from
   * @param _toAsset Address of the asset to swap to
   * @param _amountIn Amount of the asset to swap from
   * @param _swapper Address of the swapper contract
   * @param _swapData Data to call the swapper contract with
   * @return amountOut Amount of the asset after swap
   */
  function _setupAndSwap(
    address _fromAsset,
    address _toAsset,
    uint256 _amountIn,
    address _swapper,
    bytes calldata _swapData
  ) internal returns (uint256 amountOut) {
    if (_fromAsset != address(0)) {
      TransferHelper.safeTransferFrom(_fromAsset, msg.sender, address(this), _amountIn);
    } else {
      require(msg.value >= _amountIn, "SwapAndXCall: msg.value != _amountIn");
    }

    if (_fromAsset != _toAsset) {
      require(_swapper != address(0), "SwapAndXCall: zero swapper!");

      if (IERC20(_fromAsset).allowance(address(this), _swapper) < _amountIn) {
        IERC20(_fromAsset).approve(_swapper, type(uint256).max);
      }

      amountOut = this.directSwapperCall{value: _fromAsset == address(0) ? _amountIn : 0}(_swapper, _swapData);
    } else {
      amountOut = _amountIn;
    }

    if (IERC20(_toAsset).allowance(address(this), address(connext)) < _amountIn) {
      IERC20(_toAsset).approve(address(connext), type(uint256).max);
    }
  }
}