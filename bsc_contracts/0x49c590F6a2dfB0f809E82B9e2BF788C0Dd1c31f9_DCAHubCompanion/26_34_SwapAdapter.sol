// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/ISwapAdapter.sol';

abstract contract SwapAdapter is ISwapAdapter {
  using SafeERC20 for IERC20;
  using Address for address;
  using Address for address payable;

  /// @inheritdoc ISwapAdapter
  address public constant PROTOCOL_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  /// @inheritdoc ISwapAdapter
  ISwapperRegistry public immutable SWAPPER_REGISTRY;

  constructor(address _swapperRegistry) {
    if (_swapperRegistry == address(0)) revert ZeroAddress();
    SWAPPER_REGISTRY = ISwapperRegistry(_swapperRegistry);
  }

  receive() external payable {}

  /**
   * @notice Takes the given amount of tokens from the caller
   * @param _token The token to check
   * @param _amount The amount to take
   */
  function _takeFromMsgSender(IERC20 _token, uint256 _amount) internal virtual {
    _token.safeTransferFrom(msg.sender, address(this), _amount);
  }

  /**
   * @notice Checks if the given spender has enough allowance, and approves the max amount
   *         if it doesn't
   * @param _token The token to check
   * @param _spender The spender to check
   * @param _minAllowance The min allowance. If the spender has over this amount, then no extra approve is needed
   */
  function _maxApproveSpenderIfNeeded(
    IERC20 _token,
    address _spender,
    bool _alreadyValidatedSpender,
    uint256 _minAllowance
  ) internal virtual {
    if (_spender != address(0)) {
      uint256 _allowance = _token.allowance(address(this), _spender);
      if (_allowance < _minAllowance) {
        if (!_alreadyValidatedSpender && !SWAPPER_REGISTRY.isValidAllowanceTarget(_spender)) {
          revert InvalidAllowanceTarget(_spender);
        }
        if (_allowance > 0) {
          _token.approve(_spender, 0); // We do this because some tokens (like USDT) fail if we don't
        }
        _token.approve(_spender, type(uint256).max);
      }
    }
  }

  /**
   * @notice Executes a swap for the given swapper
   * @param _swapper The actual swapper
   * @param _swapData The swap execution data
   */
  function _executeSwap(
    address _swapper,
    bytes calldata _swapData,
    uint256 _value
  ) internal virtual {
    _swapper.functionCallWithValue(_swapData, _value);
  }

  /**
   * @notice Checks if the contract has any balance of the given token, and if it does,
   *         it sends it to the given recipient
   * @param _token The token to check
   * @param _recipient The recipient of the token balance
   */
  function _sendBalanceOnContractToRecipient(address _token, address _recipient) internal virtual {
    uint256 _balance = _token == PROTOCOL_TOKEN ? address(this).balance : IERC20(_token).balanceOf(address(this));
    if (_balance > 0) {
      _sendToRecipient(_token, _balance, _recipient);
    }
  }

  /**
   * @notice Transfers the given amount of tokens from the contract to the recipient
   * @param _token The token to check
   * @param _amount The amount to send
   * @param _recipient The recipient
   */
  function _sendToRecipient(
    address _token,
    uint256 _amount,
    address _recipient
  ) internal virtual {
    if (_recipient == address(0)) _recipient = msg.sender;
    if (_token == PROTOCOL_TOKEN) {
      payable(_recipient).sendValue(_amount);
    } else {
      IERC20(_token).safeTransfer(_recipient, _amount);
    }
  }

  /**
   * @notice Checks if given swapper is allowlisted, and fails if it isn't
   * @param _swapper The swapper to check
   */
  function _assertSwapperIsAllowlisted(address _swapper) internal view {
    if (!SWAPPER_REGISTRY.isSwapperAllowlisted(_swapper)) revert SwapperNotAllowlisted(_swapper);
  }

  /**
   * @notice Revokes ERC20 allowances for the given spenders
   * @dev If exposed, then it should be permissioned
   * @param _revokeActions The spenders and tokens to revoke
   */
  function _revokeAllowances(RevokeAction[] calldata _revokeActions) internal virtual {
    for (uint256 i = 0; i < _revokeActions.length; ) {
      RevokeAction memory _action = _revokeActions[i];
      for (uint256 j = 0; j < _action.tokens.length; ) {
        _action.tokens[j].approve(_action.spender, 0);
        unchecked {
          j++;
        }
      }
      unchecked {
        i++;
      }
    }
  }

  modifier onlyAllowlisted(address _swapper) {
    _assertSwapperIsAllowlisted(_swapper);
    _;
  }
}