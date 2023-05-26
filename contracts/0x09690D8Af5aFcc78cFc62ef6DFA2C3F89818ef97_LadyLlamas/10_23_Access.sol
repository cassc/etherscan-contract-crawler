/***
 *     █████╗  ██████╗ ██████╗███████╗███████╗███████╗
 *    ██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝
 *    ███████║██║     ██║     █████╗  ███████╗███████╗
 *    ██╔══██║██║     ██║     ██╔══╝  ╚════██║╚════██║
 *    ██║  ██║╚██████╗╚██████╗███████╗███████║███████║
 *    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝
 * @title Access
 * @author @MaxFlowO2
 * @dev Library function for EIP 173 Ownable standards in EVM, this is useful
 *  for granting role based modifiers, and by using this blah blah blah.
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Access {

  event AccessTransferred(address indexed newAddress, address indexed oldAddress);

  struct Role {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    address _active; // who's the active role
    address _pending; // who's the pending role
    address[] _historical; // array of addresses with the role (useful for "reclaiming" roles)
  }

  function active(Role storage role) internal view returns (address) {
    return role._active;
  }

  function pending(Role storage role) internal view returns (address) {
    return role._pending;
  }

  function historical(Role storage role) internal view returns (address[] storage) {
    return role._historical;
  }

  function transfer(Role storage role, address newAddress) internal {
    role._pending = newAddress;
  }

  function modifyArray(Role storage role) internal {
    role._historical.push(role._active);
  }

  function accept(Role storage role) internal {
    address oldAddy = role._active;
    role._active = role._pending;
    role._pending = address(0);
    emit AccessTransferred(
      role._active
    , oldAddy
    );
  }

  function decline(Role storage role) internal {
    role._pending = address(0);
  }

  function push(Role storage role, address newAddress) internal {
    address oldAddy = role._active;
    role._active = newAddress;
    role._pending = address(0);
    emit AccessTransferred(
      role._active
    , oldAddy
    );
  }
}