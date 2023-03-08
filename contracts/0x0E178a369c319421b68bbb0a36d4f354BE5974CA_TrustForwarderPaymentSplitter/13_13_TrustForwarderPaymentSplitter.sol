// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract TrustForwarderPaymentSplitter is PaymentSplitter, AccessControl {

  bytes32 public constant TRUSTEE_ROLE = keccak256("TRUSTEE_ROLE");

  constructor(
    address[] memory _payees,
    uint256[] memory _shares
  )
    payable
    PaymentSplitter(_payees, _shares)
  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    for(uint256 i = 0; i < _payees.length; i++) {
      _setupRole(TRUSTEE_ROLE, _payees[i]);
    }
  }

  function release(
    address payable _account
  )
    public
    override
    onlyRole(TRUSTEE_ROLE)
  {
    super.release(_account);
  }

  function release(
    IERC20 _token,
    address _account
  )
    public
    override
    onlyRole(TRUSTEE_ROLE)
  {
    super.release(_token, _account);
  }
}