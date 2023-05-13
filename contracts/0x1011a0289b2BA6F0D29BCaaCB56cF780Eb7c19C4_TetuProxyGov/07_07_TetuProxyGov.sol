// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "./interfaces/IControllable.sol";
import "./interfaces/IControllableExtended.sol";
import "./interfaces/ITetuProxy.sol";
import "@tetu_io/tetu-contracts/contracts/base/UpgradeableProxy.sol";

/// @title EIP1967 Upgradable proxy implementation.
/// @dev Only Governance Wallet has access.
///      This Proxy should be used for non critical contracts only!
/// @author belbix
contract TetuProxyGov is UpgradeableProxy, ITetuProxy {

  constructor(address _logic) UpgradeableProxy(_logic) {
    //make sure that given logic is controllable and not inited
    require(IControllableExtended(_logic).created() == 0);
  }

  /// @notice Upgrade contract logic
  /// @dev Upgrade allowed only for Governance. No time-lock period
  /// @param _newImplementation Implementation address
  function upgrade(address _newImplementation) external override {
    require(IControllable(address(this)).isGovernance(msg.sender), "forbidden");
    _upgradeTo(_newImplementation);

    // the new contract must have the same ABI and you must have the power to change it again
    require(IControllable(address(this)).isGovernance(msg.sender), "wrong impl");
  }

  /// @notice Return current logic implementation
  function implementation() external override view returns (address) {
    return _implementation();
  }
}