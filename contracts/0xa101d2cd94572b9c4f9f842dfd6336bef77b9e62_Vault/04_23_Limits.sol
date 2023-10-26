// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/Ownable.sol";


contract Limits is Ownable {
  error ExceededLimit(uint256 _amount, uint256 _limit);

  uint256 public ERC20Limit;

  event UpdateERC20Limit(uint256 _limit);

  modifier underLimit(uint256 _amount) {
    if (!isUnderLimit(_amount)) {
      revert ExceededLimit(_amount, ERC20Limit);
    }

    _;
  }

  function isUnderLimit(uint256 _amount) public view returns (bool) {
    return _amount <= ERC20Limit;
  }

  function updateERC20Limit(uint256 _limit) external virtual onlyOwner {
    _updateERC20Limit(_limit);
  }

  function _updateERC20Limit(uint256 _limit) internal {
    ERC20Limit = _limit;
    emit UpdateERC20Limit(_limit);
  }
}