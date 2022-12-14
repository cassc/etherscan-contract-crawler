// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFurfiPresale {
    function addressBook (  ) external view returns ( address );
    function balance ( address ) external view returns ( uint256 );
    function buy (  ) external;
    function buyWithUsdc ( uint256 amount_ ) external;
    function buyWithUsdcFor ( address participant_, uint256 amount_ ) external;
    function endTime (  ) external view returns ( uint256 );
    function initialize (  ) external;
    function owner (  ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function setup (  ) external;
    function startTime (  ) external view returns ( uint256 );
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}