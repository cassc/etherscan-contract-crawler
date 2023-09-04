// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

interface IGaugeFactory {
  /**
   * @dev Emitted when LendingGauge is created.
   * @param addressesProvider The address of the registered PoolAddressesProvider
   * @param assset The address of the underlying asset of the reserve
   * @param lendingGauge The address of the created lending gauge
   * @param gaugesNumber Represents the number of LendingGauges created
   */
  event LendingGaugeCreated(address indexed addressesProvider, address indexed assset, address lendingGauge, uint256 gaugesNumber);

  /**
   * @dev Emitted when update lending gauge logic.
   * @param addressesProvider The address of the registered PoolAddressesProvider
   * @param impl The address of the new lending gauge logic
   */
  event SetLendingGaugeImplementation(address indexed addressesProvider, address impl);

  function OPERATOR_ROLE() external view returns (bytes32);

  function isOperator(address operator) external view returns (bool);

  function addOperator(address operator) external;

  function removeOperator(address operator) external;
}