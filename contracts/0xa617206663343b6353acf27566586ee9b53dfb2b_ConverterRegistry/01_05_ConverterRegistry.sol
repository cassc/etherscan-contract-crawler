// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IConverterRegistry } from "./IConverterRegistry.sol";
import { ITokenConverter } from "./ITokenConverter.sol";

contract ConverterRegistry is Ownable, IConverterRegistry {
  /*************
   * Variables *
   *************/

  /// @dev Mapping from pool type to the address of converter.
  mapping(uint256 => address) private converters;

  /*************************
   * Public View Functions *
   *************************/

  /// @inheritdoc IConverterRegistry
  function getTokenPair(uint256 _route) external view override returns (address, address) {
    uint256 _poolType = _route & 255;
    return ITokenConverter(converters[_poolType]).getTokenPair(_route);
  }

  /// @inheritdoc IConverterRegistry
  function getConverter(uint256 _poolType) external view override returns (address) {
    return converters[_poolType];
  }

  /*******************************
   * Public Restricted Functions *
   *******************************/

  /// @notice Register a converter or update the converter.
  function register(uint256 _poolType, address _converter) external onlyOwner {
    converters[_poolType] = _converter;
  }

  /// @notice Withdraw dust assets from a converter contract.
  /// @param _converter The address of converter contract.
  /// @param _token The address of token to withdraw.
  /// @param _recipient The address of token receiver.
  function withdrawFund(
    address _converter,
    address _token,
    address _recipient
  ) external onlyOwner {
    ITokenConverter(_converter).withdrawFund(_token, _recipient);
  }
}