// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IToken {
    function addressBook (  ) external view returns ( address );
    function allowance ( address owner, address spender ) external view returns ( uint256 );
    function approve ( address spender, uint256 amount ) external returns ( bool );
    function balanceOf ( address account ) external view returns ( uint256 );
    function decimals (  ) external view returns ( uint8 );
    function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
    function getLastSell ( address address_ ) external view returns ( uint256 );
    function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
    function initialize (  ) external;
    function mint ( address to_, uint256 quantity_ ) external;
    function name (  ) external view returns ( string memory );
    function onCooldown ( address address_ ) external view returns ( bool );
    function owner (  ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function setPumpAndDumpRate ( uint256 pumpAndDumpRate_ ) external;
    function setPumpAndDumpTax ( uint256 pumpAndDumpTax_ ) external;
    function setSellCooldown ( uint256 sellCooldown_ ) external;
    function setTax ( uint256 tax_ ) external;
    function setVaultTax ( uint256 vaultTax_ ) external;
    function symbol (  ) external view returns ( string memory );
    function totalSupply (  ) external view returns ( uint256 );
    function transfer ( address to, uint256 amount ) external returns ( bool );
    function transferFrom ( address from, address to, uint256 amount ) external returns ( bool );
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function updateAddresses (  ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}