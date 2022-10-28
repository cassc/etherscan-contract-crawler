// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFurMax {
    function acceptedTerms ( address ) external view returns ( bool );
    function addressBook (  ) external view returns ( address );
    function distribute ( address participant_, uint256 amount_ ) external;
    function furBetPercent ( address ) external view returns ( uint256 );
    function furBotPercent ( address ) external view returns ( uint256 );
    function furMaxClaimed ( address ) external view returns ( uint256 );
    function furPoolPercent ( address ) external view returns ( uint256 );
    function initialize (  ) external;
    function isFurMax ( address ) external view returns ( bool );
    function join ( bool acceptTerms_, uint256 furBet_, uint256 furBot_, uint256 furPool_ ) external;
    function owner (  ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function setup (  ) external;
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function updateDistribution ( uint256 furBet_, uint256 furBot_, uint256 furPool_ ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}