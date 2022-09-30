// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './DCAHubConfigHandler.sol';

abstract contract DCAHubPlatformHandler is ReentrancyGuard, DCAHubConfigHandler, IDCAHubPlatformHandler {
  using SafeERC20 for IERC20Metadata;

  /// @inheritdoc IDCAHubPlatformHandler
  function withdrawFromPlatformBalance(IDCAHub.AmountOfToken[] calldata _amounts, address _recipient)
    external
    nonReentrant
    onlyRole(PLATFORM_WITHDRAW_ROLE)
  {
    for (uint256 i = 0; i < _amounts.length; ) {
      platformBalance[_amounts[i].token] -= _amounts[i].amount;
      _transfer(_amounts[i].token, _recipient, _amounts[i].amount);
      unchecked {
        i++;
      }
    }

    emit WithdrewFromPlatform(msg.sender, _recipient, _amounts);
  }
}