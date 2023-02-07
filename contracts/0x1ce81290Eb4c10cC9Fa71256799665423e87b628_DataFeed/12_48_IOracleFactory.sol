//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {IGovernable} from '@defi-wonderland/solidity-utils/solidity/interfaces/IGovernable.sol';
import {IOracleSidechain} from './IOracleSidechain.sol';
import {IDataReceiver} from './IDataReceiver.sol';

interface IOracleFactory is IGovernable {
  // STRUCTS

  struct OracleParameters {
    bytes32 poolSalt; // Identifier of the pool and oracle
    uint24 poolNonce; // Initial nonce of the deployed pool
    uint16 cardinality; // Initial cardinality of the deployed pool
  }

  // STATE VARIABLES

  /// @return _oracleInitCodeHash The oracle creation code hash used to calculate their address
  //solhint-disable-next-line func-name-mixedcase
  function ORACLE_INIT_CODE_HASH() external view returns (bytes32 _oracleInitCodeHash);

  /// @return _dataReceiver The address of the DataReceiver for the oracles to consult
  function dataReceiver() external view returns (IDataReceiver _dataReceiver);

  /// @return _poolSalt The id of both the oracle and the pool
  /// @return _poolNonce The initial nonce of the pool data
  /// @return _cardinality The size of the observations memory storage
  function oracleParameters()
    external
    view
    returns (
      bytes32 _poolSalt,
      uint24 _poolNonce,
      uint16 _cardinality
    );

  /// @return _initialCardinality The initial size of the observations memory storage for newly deployed pools
  function initialCardinality() external view returns (uint16 _initialCardinality);

  // EVENTS

  /// @notice Emitted when a new oracle is deployed
  /// @param _poolSalt The id of both the oracle and the pool
  /// @param _oracle The address of the deployed oracle
  /// @param _initialNonce The initial nonce of the pool data
  event OracleDeployed(bytes32 indexed _poolSalt, address indexed _oracle, uint24 _initialNonce);

  /// @notice Emitted when a new DataReceiver is set
  /// @param _dataReceiver The address of the new DataReceiver
  event DataReceiverSet(IDataReceiver _dataReceiver);

  /// @notice Emitted when a new initial oracle cardinality is set
  /// @param _initialCardinality The initial length of the observationCardinality array
  event InitialCardinalitySet(uint16 _initialCardinality);

  // ERRORS

  /// @notice Thrown when a contract other than the DataReceiver tries to deploy an oracle
  error OnlyDataReceiver();

  // FUNCTIONS

  /// @notice Deploys a new oracle given an inputted salt
  /// @dev Requires that the salt has not been deployed before
  /// @param _poolSalt Pool salt that deterministically binds an oracle with a pool
  /// @return _oracle The address of the newly deployed oracle
  function deployOracle(bytes32 _poolSalt, uint24 _poolNonce) external returns (IOracleSidechain _oracle);

  /// @notice Allows governor to set a new allowed dataReceiver
  /// @dev Will disallow the previous dataReceiver
  /// @param _dataReceiver The address of the new allowed dataReceiver
  function setDataReceiver(IDataReceiver _dataReceiver) external;

  /// @notice Allows governor to set a new initial cardinality for new oracles
  /// @param _initialCardinality The initial size of the observations memory storage for newly deployed pools
  function setInitialCardinality(uint16 _initialCardinality) external;

  /// @notice Overrides UniV3Factory getPool mapping
  /// @param _tokenA The contract address of either token0 or token1
  /// @param _tokenB The contract address of the other token
  /// @param _fee The fee denominated in hundredths of a bip
  /// @return _oracle The oracle address
  function getPool(
    address _tokenA,
    address _tokenB,
    uint24 _fee
  ) external view returns (IOracleSidechain _oracle);

  /// @notice Tracks the addresses of the oracle by poolSalt
  /// @param _poolSalt Identifier of both the pool and the oracle
  /// @return _oracle The address (if deployed) of the correspondant oracle
  function getPool(bytes32 _poolSalt) external view returns (IOracleSidechain _oracle);

  /// @param _tokenA The contract address of either token0 or token1
  /// @param _tokenB The contract address of the other token
  /// @param _fee The fee denominated in hundredths of a bip
  /// @return _poolSalt Pool salt for inquired parameters
  function getPoolSalt(
    address _tokenA,
    address _tokenB,
    uint24 _fee
  ) external view returns (bytes32 _poolSalt);
}