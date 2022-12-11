// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

// interfaces
import {IBridgeAdapter} from '../interfaces/IBridgeAdapter.sol';
// contracts
import {AdapterBase} from './AdapterBase.sol';

/**
 * @title The Multichain Adapter Contract
 * @author Plug Exchange
 * @notice Implemented multichain (previously anySwap) bridge contract
 * @dev Plug users can deposit the bridge token into the multichain bridge directly
 */
contract MultichainAdapter is IBridgeAdapter, AdapterBase {
  /// @dev The multi chain V4 router
  address private _multiChainV4Router;

  /**
   * @notice Initialization of multichain adapter contract
   * @param _plugRouter The plug router contract address
   */
  constructor(address _plugRouter, address multiChainV4Router_) AdapterBase(_plugRouter) {
    _multiChainV4Router = multiChainV4Router_;
  }

  /**
   * @notice Sets multichain v4 router contract address
   * @dev Called by only owner
   * @param multiChainV4Router_ The multi chain V4 router
   */
  function setMultichainV4Router(address multiChainV4Router_) external onlyOwner {
    _multiChainV4Router = multiChainV4Router_;
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
    (address router, address anyToken, uint256 chainId) = abi.decode(data, (address, address, uint256));

    toChainId = chainId;
    bool success;
    bytes memory result;
    if (token == NATIVE_TOKEN_ADDRESS) {
      require(router != address(0), 'INVALID_MULTICHAIN_ROUTER');
      (success, result) = router.call{value: msg.value}(
        abi.encodeWithSignature('anySwapOutNative(address,address,uint256)', anyToken, recipient, chainId)
      );
    } else {
      _approve(_multiChainV4Router, token);
      (success, result) = _multiChainV4Router.call(
        abi.encodeWithSignature(
          'anySwapOutUnderlying(address,address,uint256,uint256)',
          anyToken,
          recipient,
          amount,
          chainId
        )
      );
    }

    require(success, _getRevertMsg(result));
  }
}