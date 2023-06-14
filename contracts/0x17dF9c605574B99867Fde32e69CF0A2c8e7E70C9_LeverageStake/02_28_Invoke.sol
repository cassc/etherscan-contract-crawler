// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeMath} from '../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IETF} from '../interfaces/IETF.sol';

/**
 * @title Invoke
 * @author Desyn Protocol
 *
 * A collection of common utility functions for interacting with the Etf's invoke function
 */
library Invoke {
  using SafeMath for uint256;

  /* ============ Internal ============ */

  /**
   * Instructs the Etf to set approvals of the ERC20 token to a spender.
   *
   * @param _etf        Etf instance to invoke
   * @param _token           ERC20 token to approve
   * @param _spender         The account allowed to spend the Etf's balance
   * @param _quantity        The quantity of allowance to allow
   */
  function invokeApprove(
    IETF _etf,
    address _token,
    address _spender,
    uint256 _quantity,
    bool isUnderlying
  ) internal {
    bytes memory callData = abi.encodeWithSignature(
      'approve(address,uint256)',
      _spender,
      _quantity
    );
    _etf.execute(_token, 0, callData, isUnderlying);
  }

  /**
   * Instructs the Etf to transfer the ERC20 token to a recipient.
   *
   * @param _etf        Etf instance to invoke
   * @param _token           ERC20 token to transfer
   * @param _to              The recipient account
   * @param _quantity        The quantity to transfer
   */
  function invokeTransfer(
    IETF _etf,
    address _token,
    address _to,
    uint256 _quantity,
    bool isUnderlying
  ) internal {
    if (_quantity > 0) {
      bytes memory callData = abi.encodeWithSignature('transfer(address,uint256)', _to, _quantity);
      _etf.execute(_token, 0, callData, isUnderlying);
    }
  }

  /**
   * Instructs the Etf to transfer the ERC20 token to a recipient.
   * The new Etf balance must equal the existing balance less the quantity transferred
   *
   * @param _etf        Etf instance to invoke
   * @param _token           ERC20 token to transfer
   * @param _to              The recipient account
   * @param _quantity        The quantity to transfer
   */
  function strictInvokeTransfer(
    IETF _etf,
    address _token,
    address _to,
    uint256 _quantity
  ) internal {
    if (_quantity > 0) {
      // Retrieve current balance of token for the Etf
      uint256 existingBalance = IERC20(_token).balanceOf(address(_etf));

      Invoke.invokeTransfer(_etf, _token, _to, _quantity, false);

      // Get new balance of transferred token for Etf
      uint256 newBalance = IERC20(_token).balanceOf(address(_etf));

      // Verify only the transfer quantity is subtracted
      require(newBalance == existingBalance.sub(_quantity), 'Invalid post transfer balance');
    }
  }

  /**
   * Instructs the Etf to unwrap the passed quantity of WETH
   *
   * @param _etf        Etf instance to invoke
   * @param _weth            WETH address
   * @param _quantity        The quantity to unwrap
   */
  function invokeUnwrapWETH(IETF _etf, address _weth, uint256 _quantity) internal {
    bytes memory callData = abi.encodeWithSignature('withdraw(uint256)', _quantity);
    _etf.execute(_weth, 0, callData, true);
  }

  /**
   * Instructs the Etf to wrap the passed quantity of ETH
   *
   * @param _etf        Etf instance to invoke
   * @param _weth            WETH address
   * @param _quantity        The quantity to unwrap
   */
  function invokeWrapWETH(IETF _etf, address _weth, uint256 _quantity) internal {
    bytes memory callData = abi.encodeWithSignature('deposit()');
    _etf.execute(_weth, _quantity, callData, true);
  }

  function invokeMint(IETF _etf, address _token, address _referral, uint256 value) internal {
    bytes memory callData = abi.encodeWithSignature('submit(address)', _referral);
    _etf.execute(_token, value, callData, true);
  }

  function invokeUnbind(IETF _etf, address _token) internal {
    bytes memory callData = abi.encodeWithSignature('unbindPure(address)', _token);
    _etf.execute(_etf.bPool(), 0, callData, false);
  }

  function invokeRebind(
    IETF _etf,
    address _token,
    uint256 _balance,
    uint256 _weight,
    bool _isBound
  ) internal {
    bytes memory callData = abi.encodeWithSignature(
      'rebindPure(address,uint256,uint256,bool)',
      _token,
      _balance,
      _weight,
      _isBound
    );
    _etf.execute(_etf.bPool(), 0, callData, false);
  }
}