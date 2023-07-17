/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* Proprietary License
*
* This code cannot be used without an explicit permission from the copyright holder.
* If you wish to use the Aktionariat Brokerbot, you can either use the open version
* named Brokerbot.sol that can be used under an MIT License with Automated License Fee Payments,
* or you can get in touch with use to negotiate a license to use LicensedBrokerbot.sol .
*
* Copyright (c) 2021 Aktionariat AG (aktionariat.com), All rights reserved.
*/
pragma solidity ^0.8.0;

import "./IBrokerbot.sol";
import "../ERC20/IERC20.sol";
import "../utils/Ownable.sol";

/// @title Brokerbot Registry
/// @notice Holds a registry from all deployed active brokerbots
contract BrokerbotRegistry is Ownable {
  /// @notice Returns the brokerbot address for a given pair base and share token, or address 0 if it does not exist
  /// @dev mapping is [base][token] = brokerbotAddress
  /// @return brokerbot The brokerbot address
  mapping(IERC20 => mapping(IERC20 => IBrokerbot)) public getBrokerbot;

  /// @notice Emitted when brokerbot is registered.
  /// @param brokerbot The address of the brokerbot
  /// @param base The address of the base currency
  /// @param token The address of the share token
  event RegisterBrokerbot(IBrokerbot brokerbot, IERC20 indexed base, IERC20 indexed token);

  /// @notice Emmitted when calling syncBrokerbot function
  /// @param brokerbot The brokerbot address that is synced
  event SyncBrokerbot(IBrokerbot indexed brokerbot);

  constructor(address _owner) Ownable(_owner) {}

  /// @notice Per network only one active brokerbot should exist per base/share pair
  /// @param _brokerbot The brokerbot contract that should be registered.
  /// @param _base The contract of the base currency of the brokerbot.
  /// @param _token The contract of the share token of the brokerbot.
  function registerBrokerbot(IBrokerbot _brokerbot, IERC20 _base, IERC20 _token ) external onlyOwner() {
    getBrokerbot[_base][_token] = _brokerbot;
    emit RegisterBrokerbot(_brokerbot, _base, _token);
  }

  /// @notice This event is usful for indexers/subgraphs to update token balances which are not tracked with other events
  /// @param _brokerbot The brokerbot that should be synced
  function syncBrokerbot(IBrokerbot _brokerbot) external {
    emit SyncBrokerbot(_brokerbot);
  }

}