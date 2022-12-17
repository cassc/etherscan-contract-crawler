pragma solidity >=0.8.13;

import {OrderParameters} from "../lib/OrderParameters.sol";

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
  /// @param parameters the order parameters
  event OrdersCreated(address account, address owner, OrderParameters[] parameters);

  /// @notice Emitted when a list of orders is updated
  /// @param account the account that updated the orders
  /// @param owner the owner of the listings (not the account!)
  /// @param existingParameters the old order parameters
  /// @param newParameters the new order parameters
  event OrdersUpdated(
    address account,
    address owner,
    OrderParameters[] existingParameters,
    OrderParameters[] newParameters
  );

  /// @notice Emitted when a list of orders is withdrawn
  /// @param account the account that withdrew the orders
  /// @param owner the owner of the listings (not the account!)
  /// @param parameters the order parameters
  event OrdersWithdrawn(address account, address owner, OrderParameters[] parameters);

  /// @notice Create new orders
  /// @param parameters the order parameters
  function createOrder(OrderParameters[] memory parameters) external;

  /// @notice Update existing orders
  /// @param existingParameters the existing order parameters
  /// @param newParameters the new order parameters
  function updateOrder(OrderParameters[] calldata existingParameters, OrderParameters[] calldata newParameters)
    external;

  /// @notice Withdraw orders
  /// @param parameters the order parameters
  function withdraw(OrderParameters[] calldata parameters) external;
}