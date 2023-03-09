// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../../interfaces/utils/ICollectableDust.sol';
import './Governable.sol';

abstract contract CollectableDust is Governable, ICollectableDust {
  using SafeERC20 for IERC20;
  using Address for address payable;

  /// @inheritdoc ICollectableDust
  address public constant PROTOCOL_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @inheritdoc ICollectableDust
  function getBalances(address[] calldata _tokens) external view returns (TokenBalance[] memory _balances) {
    _balances = new TokenBalance[](_tokens.length);
    for (uint256 i; i < _tokens.length; i++) {
      uint256 _balance = _tokens[i] == PROTOCOL_TOKEN ? address(this).balance : IERC20(_tokens[i]).balanceOf(address(this));
      _balances[i] = TokenBalance({token: _tokens[i], balance: _balance});
    }
  }

  /// @inheritdoc ICollectableDust
  function sendDust(
    address _token,
    uint256 _amount,
    address _recipient
  ) external onlyGovernor {
    if (_recipient == address(0)) revert DustRecipientIsZeroAddress();
    if (_token == PROTOCOL_TOKEN) {
      payable(_recipient).sendValue(_amount);
    } else {
      IERC20(_token).safeTransfer(_recipient, _amount);
    }
    emit DustSent(_token, _amount, _recipient);
  }
}