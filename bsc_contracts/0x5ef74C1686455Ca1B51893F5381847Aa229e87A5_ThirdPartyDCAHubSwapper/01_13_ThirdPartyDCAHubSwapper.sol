// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHubSwapCallee.sol';

contract ThirdPartyDCAHubSwapper is IDCAHubSwapCallee {
  /// @notice A target we want to give allowance to
  struct Allowance {
    IERC20 token;
    address spender;
    uint256 amount;
  }

  /// @notice The data necessary for a swap to be executed
  struct SwapExecution {
    address swapper;
    bytes swapData;
  }

  /// @notice Data used for the callback
  struct SwapWithDexesCallbackData {
    // Timestamp where the tx is no longer valid
    uint256 deadline;
    // Targets to set allowance to
    Allowance[] allowanceTargets;
    // The different swaps to execute
    SwapExecution[] executions;
    // A list of tokens to check for unspent balance (should not be reward/to provide)
    IERC20[] intermediateTokensToCheck;
    // The address that will receive the unspent tokens
    address leftoverRecipient;
    // This flag is just a way to make transactions cheaper. If Mean Finance is executing the swap, then it's the same for us
    // if the leftover tokens go to the hub, or to another address. But, it's cheaper in terms of gas to send them to the hub
    bool sendToProvideLeftoverToHub;
  }

  /// @notice Thrown when deadline has passed
  error TransactionTooOld();

  using SafeERC20 for IERC20;
  using Address for address;

  // solhint-disable-next-line func-name-mixedcase
  function DCAHubSwapCall(
    address,
    IDCAHub.TokenInSwap[] calldata _tokens,
    uint256[] calldata,
    bytes calldata _data
  ) external {
    SwapWithDexesCallbackData memory _callbackData = abi.decode(_data, (SwapWithDexesCallbackData));
    if (block.timestamp > _callbackData.deadline) revert TransactionTooOld();
    _approveAllowances(_callbackData.allowanceTargets);
    _executeSwaps(_callbackData.executions);
    _handleLeftoverTokens(_tokens, _callbackData.leftoverRecipient, _callbackData.sendToProvideLeftoverToHub);
    _handleIntermediateTokens(_callbackData.intermediateTokensToCheck, _callbackData.leftoverRecipient);
  }

  function _approveAllowances(Allowance[] memory _allowanceTargets) internal {
    for (uint256 i = 0; i < _allowanceTargets.length; ) {
      Allowance memory _target = _allowanceTargets[i];
      uint256 _currentAllowance = _target.token.allowance(address(this), _target.spender);
      if (_currentAllowance < _target.amount) {
        if (_currentAllowance > 0) {
          _target.token.approve(_target.spender, 0); // We do this because some tokens (like USDT) fail if we don't
        }
        _target.token.approve(_target.spender, type(uint256).max);
      }
      unchecked {
        ++i;
      }
    }
  }

  function _executeSwaps(SwapExecution[] memory _executions) internal {
    for (uint256 i = 0; i < _executions.length; ) {
      SwapExecution memory _execution = _executions[i];
      _execution.swapper.functionCall(_execution.swapData, 'Call to swapper failed');
      unchecked {
        ++i;
      }
    }
  }

  function _handleLeftoverTokens(
    IDCAHub.TokenInSwap[] calldata _tokens,
    address _leftoverRecipient,
    bool _sendToProvideLeftoverToHub
  ) internal {
    for (uint256 i = 0; i < _tokens.length; ) {
      IERC20 _token = IERC20(_tokens[i].token);
      uint256 _balance = _token.balanceOf(address(this));
      if (_balance > 0) {
        uint256 _toProvide = _tokens[i].toProvide;
        if (_toProvide > 0) {
          if (_sendToProvideLeftoverToHub) {
            // Send everything to hub (we assume the hub is msg.sender)
            _token.safeTransfer(msg.sender, _balance);
          } else {
            // Send necessary to hub (we assume the hub is msg.sender)
            _token.safeTransfer(msg.sender, _toProvide);
            if (_balance > _toProvide) {
              // If there is some left, send to leftover recipient
              _token.safeTransfer(_leftoverRecipient, _balance - _toProvide);
            }
          }
        } else {
          // Send reward to the leftover recipient
          _token.safeTransfer(_leftoverRecipient, _balance);
        }
      }
      unchecked {
        ++i;
      }
    }
  }

  function _handleIntermediateTokens(IERC20[] memory _intermediateTokens, address _leftoverRecipient) internal {
    for (uint256 i = 0; i < _intermediateTokens.length; ) {
      uint256 _balance = _intermediateTokens[i].balanceOf(address(this));
      if (_balance > 0) {
        _intermediateTokens[i].safeTransfer(_leftoverRecipient, _balance);
      }
      unchecked {
        ++i;
      }
    }
  }
}