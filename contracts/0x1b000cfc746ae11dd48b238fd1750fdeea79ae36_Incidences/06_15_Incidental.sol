/// SPDX-License-Identifier CC0-1.0
pragma solidity ^0.8.13;

/// @title Incidental.sol
/// @author b4874dacb54e1a15c3616a785b3ed3ac0dcdc0b46afc5439652f3efe782e1641
/// @notice The incidental contract exports a single public function which
///         concrete instances use to accept transactions in the form of
///         etherscriptions.
/// @custom:warning Incidentals expose etherscription minters to smart contract
///                 risk.
/// @dev The incidental function has a 4byte signature which corresponds to
///      the hexadecimal equivalent of "data", which is the prefix for all
///      ethscription contentURIs. The following bytes of transaction
///      calldata yield the original contentURI, which is contained in msg.data.
///      This does NOT guarantee that the contentURI is a valid etherscription
///      as it is not guaranteed to be unique or valid.
abstract contract Incidental {

  /// @notice The incidental function permits a smart contract to accept,
  ///         interpret and react to ethscriptions. This function is not
  ///         payable, since ethscription transactions must explicitly carry
  ///         a value of zero ether.
  /// @dev For implementors, msg.data should be interpreted as the
  ///      ethscription's contentURI. However, care must be taken to ensure
  ///      it is both unique and valid.
  function ethsGEGzXlymji3hvTyjQnpYo() external virtual;

}