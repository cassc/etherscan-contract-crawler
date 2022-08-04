// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IOracleMaster.sol";
import "./IOracleRelay.sol";

import "../_external/Ownable.sol";

/// @title An addressbook for oracle relays
/// @notice the oraclemaster is simply an addressbook of address->relay
/// this is so that contracts may use the OracleMaster to call any registered relays.
contract OracleMaster is IOracleMaster, Ownable {
  // mapping of token to address
  mapping(address => address) public _relays;

  /// @notice empty constructor
  constructor() Ownable() {}

  /// @notice gets the current price of the oracle registered for a token
  /// @param token_address address of the token to get value for
  /// @return the value of the token
  function getLivePrice(address token_address) external view override returns (uint256) {
    require(_relays[token_address] != address(0x0), "token not enabled");
    IOracleRelay relay = IOracleRelay(_relays[token_address]);
    uint256 value = relay.currentValue();
    return value;
  }

  /// @notice admin only, sets relay for a token address to the relay addres
  /// @param token_address address of the token
  /// @param relay_address address of the relay
  function setRelay(address token_address, address relay_address) public override onlyOwner {
    _relays[token_address] = relay_address;
  }
}