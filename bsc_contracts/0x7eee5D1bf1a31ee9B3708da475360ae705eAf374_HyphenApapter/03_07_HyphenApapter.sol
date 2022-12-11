// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

// interfaces
import {IBridgeAdapter} from '../interfaces/IBridgeAdapter.sol';
// contracts
import {AdapterBase} from './AdapterBase.sol';

/**
 * @title The Hyphen Apapter Contract
 * @author Plug Exchange
 * @notice Implemented hyphen bridge contract
 * @dev Plug users can deposit the bridge token into the hyphen bridge directly
 */
contract HyphenApapter is IBridgeAdapter, AdapterBase {
  /// @dev Hyphen Liquidity Pool to intract with Bridge
  address private _hyphenLiquidityPool;

  /**
   * @notice Initialization of hyphen adapter
   * @param _plugRouter The plug router contract address
   * @param hyphenLiquidityPool_ The Hyphen Liquidity Pool contract address
   */
  constructor(address _plugRouter, address hyphenLiquidityPool_) AdapterBase(_plugRouter) {
    _hyphenLiquidityPool = hyphenLiquidityPool_;
  }

  /**
   * @notice Sets hyphen liquidity pool contract
   * @dev Called by only owner
   * @param hyphenLiquidityPool_ The hyphen liquidity pool contract address
   */
  function setHyphenLiquidityPool(address hyphenLiquidityPool_) external onlyOwner {
    _hyphenLiquidityPool = hyphenLiquidityPool_;
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
    (uint256 chainId, string memory tag) = abi.decode(data, (uint256, string));
    toChainId = chainId;

    bool success;
    bytes memory result;

    if (token == NATIVE_TOKEN_ADDRESS) {
      (success, result) = _hyphenLiquidityPool.call{value: msg.value}(
        abi.encodeWithSignature('depositNative(address,uint256,string)', recipient, toChainId, tag)
      );
    } else {
      _approve(_hyphenLiquidityPool, token);
      (success, result) = _hyphenLiquidityPool.call(
        abi.encodeWithSignature(
          'depositErc20(uint256,address,address,uint256,string)',
          toChainId,
          token,
          recipient,
          amount,
          tag
        )
      );
    }
    require(success, _getRevertMsg(result));
  }
}