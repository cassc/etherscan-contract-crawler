// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

error ContractFactory_Only_Callable_By_Factory_Contract(address contractFactory);
error ContractFactory_Factory_Is_Not_A_Contract();

/**
 * @title Stores a reference to the factory which is used to create contract proxies.
 * @author batu-inal & HardlyDifficult
 */
abstract contract ContractFactory {
  using AddressUpgradeable for address;

  /**
   * @notice The address of the factory which was used to create this contract.
   * @return The factory contract address.
   */
  address public immutable contractFactory;

  modifier onlyContractFactory() {
    if (msg.sender != contractFactory) {
      revert ContractFactory_Only_Callable_By_Factory_Contract(contractFactory);
    }
    _;
  }

  /**
   * @notice Initialize the template's immutable variables.
   * @param _contractFactory The factory which will be used to create these contracts.
   */
  constructor(address _contractFactory) {
    if (!_contractFactory.isContract()) {
      revert ContractFactory_Factory_Is_Not_A_Contract();
    }
    contractFactory = _contractFactory;
  }
}