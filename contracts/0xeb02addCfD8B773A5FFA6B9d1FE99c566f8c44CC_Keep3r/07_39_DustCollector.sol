// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../contracts/peripherals/Governable.sol';
import '../../interfaces/peripherals/IDustCollector.sol';

abstract contract DustCollector is IDustCollector, Governable {
  using SafeERC20 for IERC20;

  address internal constant _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function sendDust(
    address _token,
    uint256 _amount,
    address _to
  ) external override onlyGovernance {
    if (_to == address(0)) revert ZeroAddress();
    if (_token == _ETH_ADDRESS) {
      payable(_to).transfer(_amount);
    } else {
      IERC20(_token).safeTransfer(_to, _amount);
    }
    emit DustSent(_token, _amount, _to);
  }
}