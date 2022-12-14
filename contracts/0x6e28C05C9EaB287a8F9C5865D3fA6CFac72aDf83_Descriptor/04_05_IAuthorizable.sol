// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

interface IAuthorizable {
  error Unauthorized();

  function grantAuthorization(address account) external;

  function revokeAuthorization(address account) external;
}