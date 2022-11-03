// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISwapFurbet {
    function addressBook (  ) external view returns ( address );
    function buy ( address payment_, uint256 amount_ ) external;
    function buyOutput ( address payment_, uint256 amount_ ) external view returns ( uint256 );
    function cooldownPeriod (  ) external view returns ( uint256 );
    function depositBuy ( address payment_, uint256 amount_, address referrer_ ) external;
    function depositBuy ( address payment_, uint256 amount_ ) external;
    function disableLiquidtyManager (  ) external;
    function enableLiquidityManager (  ) external;
    function exemptFromCooldown ( address participant_, bool value_ ) external;
    function factory (  ) external view returns ( address );
    function fur (  ) external view returns ( address );
    function initialize (  ) external;
    function lastSell ( address ) external view returns ( uint256 );
    function liquidityManager (  ) external view returns ( address );
    function liquidityManagerEnabled (  ) external view returns ( bool );
    function onCooldown ( address participant_ ) external view returns ( bool );
    function owner (  ) external view returns ( address );
    function pair (  ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function pumpAndDumpMultiplier (  ) external view returns ( uint256 );
    function pumpAndDumpRate (  ) external view returns ( uint256 );
    function renounceOwnership (  ) external;
    function router (  ) external view returns ( address );
    function sell ( uint256 amount_ ) external;
    function sellOutput ( uint256 amount_ ) external view returns ( uint256 );
    function setAddressBook ( address address_ ) external;
    function setup (  ) external;
    function tax (  ) external view returns ( uint256 );
    function taxHandler (  ) external view returns ( address );
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
    function usdc (  ) external view returns ( address );
    function vault (  ) external view returns ( address );
}