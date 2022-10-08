// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IControllable {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);

    function isController(address controller) external view returns (bool);

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;
}