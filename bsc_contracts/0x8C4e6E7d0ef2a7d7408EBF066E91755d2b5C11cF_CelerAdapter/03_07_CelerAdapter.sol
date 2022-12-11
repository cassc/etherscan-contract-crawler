// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

// interfaces
import {IBridgeAdapter} from '../interfaces/IBridgeAdapter.sol';

// contracts
import {AdapterBase} from './AdapterBase.sol';

/**
 * @title The Celer Adapter Contract
 * @author Plug Exchange
 * @notice Implemented celer bridge contract
 * @dev Plug users can deposit the bridge token into the celer bridge directly
 */
contract CelerAdapter is IBridgeAdapter, AdapterBase {
  /// @dev The contract address of cbridge router
  address private _cBridgeRouter;

  /**
   * @notice Initialization of celer adapter contract
   * @param _plugRouter The plug router contract address
   * @param _bridgeRouter The bridge router contract address
   */
  constructor(address _plugRouter, address _bridgeRouter) AdapterBase(_plugRouter) {
    require(_bridgeRouter != address(0), 'INVALID_BRDIGE_ROUTER');
    _cBridgeRouter = _bridgeRouter;
  }

  /**
   * @notice Set new Cbridge router contract address
   * @dev Execute by only owner
   * @param _newCBridgeRouter The new celer bridge contract address
   */
  function setCbridgeRouter(address _newCBridgeRouter) external onlyOwner {
    require(_newCBridgeRouter != address(0), 'INVALID_BRDIGE_ROUTER');
    _cBridgeRouter = _newCBridgeRouter;
  }

  /**
   * @inheritdoc IBridgeAdapter
   */
  function deposit(
    uint256 amount,
    address recipient,
    address token,
    bytes calldata data
  ) external payable onlyPlugRouter returns (uint256 toChainId) {
    // decode
    bool success;
    bytes memory result;

    (uint64 _dstChainId, uint64 _nonce, uint32 _maxSlippage) = abi.decode(data, (uint64, uint64, uint32));
    toChainId = uint256(_dstChainId);

    if (token == NATIVE_TOKEN_ADDRESS) {
      (success, result) = _cBridgeRouter.call{value: msg.value}(
        abi.encodeWithSignature(
          'sendNative(address,uint256,uint64,uint64,uint32)',
          recipient,
          amount,
          _dstChainId,
          _nonce,
          _maxSlippage
        )
      );
    } else {
      // approve this tokens
      _approve(_cBridgeRouter, token);

      (success, result) = _cBridgeRouter.call(
        abi.encodeWithSignature(
          'send(address,address,uint256,uint64,uint64,uint32)',
          recipient,
          token,
          amount,
          _dstChainId,
          _nonce,
          _maxSlippage
        )
      );
    }

    require(success, _getRevertMsg(result));
  }

  /**
   * @notice Withdraw tokens from celer bridge
   * @dev Execute by only owner
   * @param _wcD The withdraw call data
   * @return _status The sucess status
   */
  function withdraw(bytes memory _wcD) external onlyOwner returns (bool) {
    (bool success, bytes memory returnData) = _cBridgeRouter.call(_wcD);
    require(success, _getRevertMsg(returnData));
    return true;
  }
}