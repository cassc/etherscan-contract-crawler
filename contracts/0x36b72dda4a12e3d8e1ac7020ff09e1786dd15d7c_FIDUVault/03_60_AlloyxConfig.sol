// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IAlloyxConfig.sol";
import "../utils/AdminUpgradeable.sol";

/**
 * @title AlloyX Configuration
 * @notice The config information which contains all the relevant smart contracts and numeric and boolean configuration
 * @author AlloyX
 */

contract AlloyxConfig is IAlloyxConfig, AdminUpgradeable {
  mapping(uint256 => address) private addresses;
  mapping(uint256 => uint256) private numbers;
  mapping(uint256 => bool) private booleans;

  event AddressUpdated(address owner, uint256 index, address oldValue, address newValue);
  event NumberUpdated(address owner, uint256 index, uint256 oldValue, uint256 newValue);
  event BooleanUpdated(address owner, uint256 index, bool oldValue, bool newValue);

  function initialize() external initializer {
    __AdminUpgradeable_init(msg.sender);
  }

  /**
   * @notice Set the bool of certain index
   * @param booleanIndex the index to set
   * @param newBoolean new address to set
   */
  function setBoolean(uint256 booleanIndex, bool newBoolean) public override onlyAdmin {
    emit BooleanUpdated(msg.sender, booleanIndex, booleans[booleanIndex], newBoolean);
    booleans[booleanIndex] = newBoolean;
  }

  /**
   * @notice Set the address of certain index
   * @param addressIndex the index to set
   * @param newAddress new address to set
   */
  function setAddress(uint256 addressIndex, address newAddress) public override onlyAdmin {
    require(newAddress != address(0));
    emit AddressUpdated(msg.sender, addressIndex, addresses[addressIndex], newAddress);
    addresses[addressIndex] = newAddress;
  }

  /**
   * @notice Set the number of certain index
   * @param index the index to set
   * @param newNumber new number to set
   */
  function setNumber(uint256 index, uint256 newNumber) public override onlyAdmin {
    emit NumberUpdated(msg.sender, index, numbers[index], newNumber);
    numbers[index] = newNumber;
  }

  /**
   * @notice Copy from other config
   * @param _initialConfig the configuration to copy from
   * @param numbersLength the length of the numbers to copy from
   * @param addressesLength the length of the addresses to copy from
   * @param boolsLength the length of the bools to copy from
   */
  function copyFromOtherConfig(
    address _initialConfig,
    uint256 numbersLength,
    uint256 addressesLength,
    uint256 boolsLength
  ) external onlyAdmin {
    IAlloyxConfig initialConfig = IAlloyxConfig(_initialConfig);
    for (uint256 i = 0; i < numbersLength; i++) {
      setNumber(i, initialConfig.getNumber(i));
    }

    for (uint256 i = 0; i < addressesLength; i++) {
      setAddress(i, initialConfig.getAddress(i));
    }

    for (uint256 i = 0; i < boolsLength; i++) {
      setBoolean(i, initialConfig.getBoolean(i));
    }
  }

  /**
   * @notice Get address for index
   * @param index the index to get address from
   */
  function getAddress(uint256 index) external view override returns (address) {
    return addresses[index];
  }

  /**
   * @notice Get number for index
   * @param index the index to get number from
   */
  function getNumber(uint256 index) external view override returns (uint256) {
    return numbers[index];
  }

  /**
   * @notice Get bool for index
   * @param index the index to get bool from
   */
  function getBoolean(uint256 index) external view override returns (bool) {
    return booleans[index];
  }
}