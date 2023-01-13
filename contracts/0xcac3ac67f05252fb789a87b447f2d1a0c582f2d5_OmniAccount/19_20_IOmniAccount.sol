pragma solidity >=0.8.13;

import {TokenIdentifier} from "../lib/TokenIdentifier.sol";

interface IOmniAccount {
  error InvalidOrder();
  error Unauthorized();
  error MismatchedInputLength();

  /// @notice Emitted when an account is created
  /// @param account the account that's been created
  /// @param owner the owner of the account
  event AccountCreated(address account, address owner);

  /// @notice Emitted when a list of orders is created
  /// @param account the account that created the orders
  /// @param owner the owner of the listings (not the account!)
  /// @param tokens tokens deposited
  event OrdersCreated(address account, address owner, TokenIdentifier[] tokens);

  /// @notice Emitted when a list of orders is withdrawn
  /// @param account the account that withdrew the orders
  /// @param owner the owner of the listings (not the account!)
  /// @param tokens the tokens that were withdrawn
  event OrdersWithdrawn(address account, address owner, TokenIdentifier[] tokens);

  /// @notice Create new orders
  /// @param tokens tokens deposited
  function createOrder(TokenIdentifier[] memory tokens) external;

  /// @notice Withdraw orders
  /// @param tokens tokens withdrawn
  function withdraw(TokenIdentifier[] calldata tokens) external;
}