// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAddressBook
{
    function get (string memory name_) external view returns (address);
    function initialize () external;
    function owner () external view returns (address);
    function pause () external;
    function paused () external view returns (bool);
    function proxiableUUID () external view returns (bytes32);
    function renounceOwnership () external;
    function set (string memory name_, address address_) external;
    function transferOwnership (address newOwner) external;
    function unpause () external;
    function unset (string memory name_) external;
    function upgradeTo (address newImplementation) external;
    function upgradeToAndCall (address newImplementation, bytes memory data) external;
}