// SPDX-License-Identifier: ISC

pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

interface IFraxlendPairDeployer {
  function CIRCUIT_BREAKER_ADDRESS (  ) external view returns ( address );
  function COMPTROLLER_ADDRESS (  ) external view returns ( address );
  function DEFAULT_LIQ_FEE (  ) external view returns ( uint256 );
  function DEFAULT_MAX_LTV (  ) external view returns ( uint256 );
  function GLOBAL_MAX_LTV (  ) external view returns ( uint256 );
  function TIME_LOCK_ADDRESS (  ) external view returns ( address );
  function deploy ( bytes memory _configData ) external returns ( address _pairAddress );
  function deployCustom ( string memory _name, bytes memory _configData, uint256 _maxLTV, uint256 _liquidationFee, uint256 _maturityDate, uint256 _penaltyRate, address[] memory _approvedBorrowers, address[] memory _approvedLenders ) external returns ( address _pairAddress );
  function deployedPairCustomStatusByAddress ( address ) external view returns ( bool );
  function deployedPairsArray ( uint256 ) external view returns ( string memory );
  function deployedPairsByName ( string memory ) external view returns ( address );
  function deployedPairsBySalt ( bytes32 ) external view returns ( address );
  function deployedPairsLength (  ) external view returns ( uint256 );
  function getAllPairAddresses (  ) external view returns ( address[] memory );
  function getCustomStatuses ( address[] calldata _addresses ) external view returns ( address[] memory _pairCustomStatuses );
  function globalPause ( address[] memory _addresses ) external returns ( address[] memory _updatedAddresses );
  function owner (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function setCreationCode ( bytes calldata _creationCode ) external;
  function transferOwnership ( address newOwner ) external;
}