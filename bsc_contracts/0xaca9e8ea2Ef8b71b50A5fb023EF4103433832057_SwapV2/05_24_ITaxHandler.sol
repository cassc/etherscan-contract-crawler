// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITaxHandler {
    function addTaxExemption ( address address_ ) external;
    function addressBook (  ) external view returns ( address );
    function distribute (  ) external;
    function initialize (  ) external;
    function isExempt ( address address_ ) external view returns ( bool );
    function owner (  ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}