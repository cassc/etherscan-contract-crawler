// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

interface IBetaBank {
  /// @dev Returns the address of BToken of the given underlying token, or 0 if not exists.
  function bTokens(address _underlying) external view returns (address);

  /// @dev Returns the address of the underlying of the given BToken, or 0 if not exists.
  function underlyings(address _bToken) external view returns (address);

  /// @dev Returns the address of the oracle contract.
  function oracle() external view returns (address);

  /// @dev Returns the address of the config contract.
  function config() external view returns (address);

  /// @dev Returns the interest rate model smart contract.
  function interestModel() external view returns (address);

  /// @dev Returns the position's collateral token and AmToken.
  function getPositionTokens(address _owner, uint _pid)
    external
    view
    returns (address _collateral, address _bToken);

  /// @dev Returns the debt of the given position. Can't be view as it needs to call accrue.
  function fetchPositionDebt(address _owner, uint _pid) external returns (uint);

  /// @dev Returns the LTV of the given position. Can't be view as it needs to call accrue.
  function fetchPositionLTV(address _owner, uint _pid) external returns (uint);

  /// @dev Opens a new position in the Beta smart contract.
  function open(
    address _owner,
    address _underlying,
    address _collateral
  ) external returns (uint pid);

  /// @dev Borrows tokens on the given position.
  function borrow(
    address _owner,
    uint _pid,
    uint _amount
  ) external;

  /// @dev Repays tokens on the given position.
  function repay(
    address _owner,
    uint _pid,
    uint _amount
  ) external;

  /// @dev Puts more collateral to the given position.
  function put(
    address _owner,
    uint _pid,
    uint _amount
  ) external;

  /// @dev Takes some collateral out of the position.
  function take(
    address _owner,
    uint _pid,
    uint _amount
  ) external;

  /// @dev Liquidates the given position.
  function liquidate(
    address _owner,
    uint _pid,
    uint _amount
  ) external;
}