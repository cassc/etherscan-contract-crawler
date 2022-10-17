// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract TrustForwarderAccessControl is AccessControl {

  bytes32 public constant TRUSTEE_ROLE = keccak256("TRUSTEE_ROLE");

}