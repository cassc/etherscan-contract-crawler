// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

// interfaces
import {IBridgeAdapter} from '../interfaces/IBridgeAdapter.sol';

// contracts
import {AdapterBase} from './AdapterBase.sol';

/**
 * @title The Wormhole Adapter Contract
 * @author Plug Exchange
 * @notice Implemented wormhole bridge contract
 * @dev Plug users can deposit the bridge token into the wormhole bridge directly
 */
contract WormholeAdapter is IBridgeAdapter, AdapterBase {
  /// @dev The wormhole token bridge contract address
  address private _wormholeTokenBridge;

  /**
   * @notice Initialization of wormhole adapter contract
   * @param _plugRouter The plug router contract address
   */
  constructor(address _plugRouter, address _bridgeRouter) AdapterBase(_plugRouter) {
    _wormholeTokenBridge = _bridgeRouter;
  }

  /**
   * @notice Sets wormhole token bridge address
   * @dev Called by only owner
   * @param wormholeTokenBridge_ The wormhole token bridge contract address
   */
  function setWormholeTokenBridge(address wormholeTokenBridge_) external onlyOwner {
    _wormholeTokenBridge = wormholeTokenBridge_;
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
    (uint16 recipientChain, uint256 arbiterFee, uint32 nonce) = abi.decode(data, (uint16, uint256, uint32));
    toChainId = uint256(recipientChain);

    bool success;
    bytes memory result;
    bytes32 _recipient = bytes32(uint256(uint160(recipient)));

    if (token == NATIVE_TOKEN_ADDRESS) {
      (success, result) = _wormholeTokenBridge.call{value: msg.value}(
        abi.encodeWithSignature(
          'wrapAndTransferETH(uint16,bytes32,uint256,uint32)',
          recipientChain,
          _recipient,
          arbiterFee,
          nonce
        )
      );
    } else {
      _approve(_wormholeTokenBridge, token);
      (success, result) = _wormholeTokenBridge.call(
        abi.encodeWithSignature(
          'transferTokens(address,uint256,uint16,bytes32,uint256,uint32)',
          token,
          amount,
          recipientChain,
          _recipient,
          arbiterFee,
          nonce
        )
      );
    }

    require(success, _getRevertMsg(result));
  }

  /**
   * @notice Complete force transfers of token
   * @dev Called by only owner
   * @param _ctcD The complete transfer calldata
   * @return _status The sucess status
   */
  function completeTransfer(bytes calldata _ctcD) external onlyOwner returns (bool) {
    (bool success, bytes memory returnData) = _wormholeTokenBridge.call(_ctcD);
    require(success, _getRevertMsg(returnData));
    return true;
  }
}