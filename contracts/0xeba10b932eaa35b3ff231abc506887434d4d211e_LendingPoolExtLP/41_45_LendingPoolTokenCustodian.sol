// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import './RewardsTracker.sol';

contract LendingPoolTokenCustodian is Ownable, RewardsTracker {
  using SafeERC20 for IERC20;

  address public hype;

  constructor(address _hype) RewardsTracker(_hype) {
    hype = _hype;
  }

  function process(
    IERC20 _token,
    address _user,
    uint256 _balanceUpdate,
    bool _isWithdrawing
  ) external onlyOwner {
    if (_isWithdrawing) {
      _token.safeTransfer(msg.sender, _balanceUpdate);
    } else {
      _token.safeTransferFrom(msg.sender, address(this), _balanceUpdate);
    }
    if (address(_token) == hype) {
      _setShare(_user, _balanceUpdate, _isWithdrawing);
    }
  }

  receive() external payable {
    uint256 _hypeTokens = IERC20(hype).balanceOf(address(this));
    if (_hypeTokens > 0) {
      _depositRewards(msg.value);
    } else {
      (bool _success, ) = payable(owner()).call{ value: msg.value }('');
      require(_success, 'RECEIVE: did not send to owner');
    }
  }
}