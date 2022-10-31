// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFurMax {
    function acceptedLoanTerms ( address ) external view returns ( bool );
    function addressBook (  ) external view returns ( address );
    function availableDividends ( address participant_ ) external view returns ( uint256 );
    function claim (  ) external;
    function depositFurbotDividends ( uint256 amount_ ) external;
    function distribute ( address participant_, uint256 amount_ ) external;
    function furbetPercent ( address ) external view returns ( uint256 );
    function furbotDividendsClaimed ( address ) external view returns ( uint256 );
    function furbotInvestment ( address ) external view returns ( uint256 );
    function furbotPercent ( address ) external view returns ( uint256 );
    function furpoolDividendsClaimed ( address ) external view returns ( uint256 );
    function furpoolInvestment ( address ) external view returns ( uint256 );
    function furpoolPercent ( address ) external view returns ( uint256 );
    function initialize (  ) external;
    function isAdmin ( address ) external view returns ( bool );
    function isDistributor ( address ) external view returns ( bool );
    function isFurmax ( address ) external view returns ( bool );
    function join ( bool acceptTerms_, uint256 furbet_, uint256 furbot_, uint256 furpool_ ) external;
    function owner (  ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function runFurpool (  ) external;
    function setAddressBook ( address address_ ) external;
    function setAdmin ( address participant_, bool isAdmin_ ) external;
    function setup (  ) external;
    function totalFurbotDividends (  ) external view returns ( uint256 );
    function totalFurbotInvestment (  ) external view returns ( uint256 );
    function totalFurbotPendingInvestment (  ) external view returns ( uint256 );
    function totalFurpoolDividends (  ) external view returns ( uint256 );
    function totalFurpoolInvestment (  ) external view returns ( uint256 );
    function totalFurpoolPendingInvestment (  ) external view returns ( uint256 );
    function totalParticipants (  ) external view returns ( uint256 );
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function updateDistribution ( uint256 furbet_, uint256 furbot_, uint256 furpool_ ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
    function withdrawFurbotPendingInvestment (  ) external;
}