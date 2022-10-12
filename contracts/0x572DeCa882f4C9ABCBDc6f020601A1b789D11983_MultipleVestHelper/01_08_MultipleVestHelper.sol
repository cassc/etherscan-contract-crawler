// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./Vesting.sol";

// solhint-disable not-rely-on-time

contract MultipleVestHelper is Ownable {
  using SafeERC20 for IERC20;

  function call(
    Vesting _vesting,
    address[] memory _recipients,
    uint128[] memory _amounts,
    uint64[] memory _startTimes,
    uint64[] memory _endTimes
  ) external onlyOwner {
    address _token = _vesting.token();
    uint256 _total = 0;
    for (uint256 i = 0; i < _amounts.length; i++) {
      _total += _amounts[i];
    }
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _total);
    IERC20(_token).safeApprove(address(_vesting), _total);
    for (uint256 i = 0; i < _recipients.length; i++) {
      _vesting.newVesting(_recipients[i], _amounts[i], _startTimes[i], _endTimes[i]);
    }
  }
}