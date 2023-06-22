// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../../../interfaces/HegicPool/V3/IHegicPoolV3Withdrawable.sol';

import './HegicPoolV3ProtocolParameters.sol';

abstract
contract HegicPoolV3Withdrawable is HegicPoolV3ProtocolParameters, IHegicPoolV3Withdrawable {

  using SafeERC20 for IERC20;

  function _withdraw(uint256 _shares) internal returns (uint256 _underlyingToWithdraw) {
    _underlyingToWithdraw = (totalUnderlying().mul(_shares)).div(zToken.totalSupply());
    zToken.burn(msg.sender, _shares);

    // Check balance
    uint256 _unusedUnderlyingBalance = unusedUnderlyingBalance();
    if (_unusedUnderlyingBalance < _underlyingToWithdraw) {
      uint256 _missingUnderlying = _underlyingToWithdraw.sub(_unusedUnderlyingBalance);

      // Check if we can close enough lots to repay withdraw
      lotManager.unwind(_missingUnderlying);

      // Revert if we still haven't got enough underlying.
      require(unusedUnderlyingBalance() >= _underlyingToWithdraw, 'HegicPoolV3Withdrawable::_withdraw::not-enough-to-unwind');
    }

    token.safeTransfer(msg.sender, _underlyingToWithdraw);
    emit Withdrew(msg.sender, _shares, _underlyingToWithdraw);
  }

  function _withdrawAll() internal returns (uint256 _underlyingToWithdraw) {
    return _withdraw(zToken.balanceOf(msg.sender));
  }
}