// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStrategyHandler {

    struct LiquidityDirection {
      address strategyAddress; 
      address entryToken; 
      uint256 assetId;
      uint256 chainId;
      bytes entryData;
      bytes exitData;
      bytes rewardsData;
      uint256 latestAmount;
  }

  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function UPGRADER_ROLE (  ) external view returns ( bytes32 );
  function addLiquidityDirection ( string memory _codeName, address _strategyAddress, address _entryToken, uint256 _assetId, uint256 _chainId, bytes memory _entryData, bytes memory _exitData, bytes memory _rewardsData ) external;
  function addToActiveDirections ( uint256 _directionId ) external;
  function adjustTreasury ( int256 _delta ) external;
  function booster (  ) external view returns ( address );
  function calculateAll (  ) external;
  function calculateOnlyLp (  ) external;
  function changeAssetInfo ( uint256 _assetId, uint256[] memory _chainIds, address[] memory _chainIdToPrimaryToken, address _ibAlluo ) external;
  function changeNumberOfAssets ( uint8 _newNumber ) external;
  function changeUpgradeStatus ( bool _status ) external;
  function directionNameToId ( string memory ) external view returns ( uint256 );
  function exchangeAddress (  ) external view returns ( address );
  function executor (  ) external view returns ( address );
  function getAllAssetActiveIds (  ) external view returns ( uint256[] memory );
  function getAssetActiveIds ( uint256 _assetId ) external view returns ( uint256[] memory );
  function getAssetAmount ( uint256 _id ) external view returns ( uint256 );
  function getAssetIdByDirectionId ( uint256 _id ) external view returns ( uint256 );
  function getCurrentDeployed (  ) external view returns ( uint256[] memory amounts );
  function getDirectionFullInfoById ( uint256 _id ) external view returns ( address, LiquidityDirection memory );
  function getDirectionIdByName ( string memory _codeName ) external view returns ( uint256 );
  function getDirectionLatestAmount ( uint256 _id ) external view returns ( uint256 );
  function getLatestDeployed (  ) external view returns ( uint256[] memory amounts );
  function getLiquidityDirectionById ( uint256 _id ) external view returns ( LiquidityDirection memory );
  function getLiquidityDirectionByName ( string memory _codeName ) external view returns ( uint256, address, LiquidityDirection memory );
  function getPrimaryTokenByAssetId ( uint256 _id, uint256 _chainId ) external view returns ( address );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function gnosis (  ) external view returns ( address );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function initialize ( address _multiSigWallet, address _priceFeed, address _executor ) external;
  function lastDirectionId (  ) external view returns ( uint256 );
  function lastTimeCalculated (  ) external view returns ( uint256 );
  function liquidityDirection ( uint256 ) external view returns ( address strategyAddress, address entryToken, uint256 assetId, uint256 chainId, bytes memory entryData, bytes memory exitData, bytes memory rewardsData, uint256 latestAmount );
  function numberOfAssets (  ) external view returns ( uint8 );
  function priceFeed (  ) external view returns ( address );
  function proxiableUUID (  ) external view returns ( bytes32 );
  function removeFromActiveDirections ( uint256 _directionId ) external;
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function setAssetAmount ( uint256 _id, uint256 amount ) external;
  function setBoosterAddress ( address _newBooster ) external;
  function setExchangeAddress ( address _newExchange ) external;
  function setExecutorAddress ( address _newExecutor ) external;
  function setGnosis ( address _gnosisAddress ) external;
  function setLastDirectionId ( uint256 _newNumber ) external;
  function setLiquidityDirection ( string memory _codeName, uint256 _directionId, address _strategyAddress, address _entryToken, uint256 _assetId, uint256 _chainId, bytes memory _entryData, bytes memory _exitData, bytes memory _rewardsData ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function updateLastTime (  ) external;
  function upgradeStatus (  ) external view returns ( bool );
  function upgradeTo ( address newImplementation ) external;
  function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}