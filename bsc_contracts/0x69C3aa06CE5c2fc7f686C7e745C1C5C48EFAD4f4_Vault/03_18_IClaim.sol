// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IClaim {
    function addressBook (  ) external view returns ( address );
    function claimNft ( uint256 quantity_, address address_, bool vault_ ) external returns ( bool );
    function getOwnerValue ( address owner_ ) external view returns ( uint256 );
    function getTokenValue ( uint256 tokenId_ ) external view returns ( uint256 );
    function initialize (  ) external;
    function owned ( address owner_ ) external view returns ( uint256[] memory );
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