// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Treasury is PaymentSplitter, AccessControl {
  constructor(
    address[] memory _accounts,
    uint256[] memory _allocation,
    address[] memory _admins
  ) PaymentSplitter(_accounts, _allocation) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    for (uint256 i = 0; i < _admins.length; i++) {
      _grantRole(DEFAULT_ADMIN_ROLE, _admins[i]);
    }
  }

  function releaseEth(address payable _payee)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    release(_payee);
  }

  function releaseErc20(IERC20 _token, address payable _payee)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    release(_token, _payee);
  }

  receive() external payable override(PaymentSplitter) {
    emit PaymentReceived(_msgSender(), msg.value);
  }
}