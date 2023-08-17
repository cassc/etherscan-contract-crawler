// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Errors} from '../protocol/libraries/helpers/Errors.sol';
import {IYieldDistributorAdapter} from '../interfaces/IYieldDistributorAdapter.sol';

/**
 * @title YieldDistributorAdapter
 * @notice ReserveToYieldDistributors mapping adapter
 * @author Sturdy
 **/

contract YieldDistributorAdapter is IYieldDistributorAdapter {
  modifier onlyEmissionManager() {
    require(msg.sender == EMISSION_MANAGER, Errors.CALLER_NOT_EMISSION_MANAGER);
    _;
  }

  address public immutable EMISSION_MANAGER;

  // reserve internal asset -> stable yield distributors
  mapping(address => address[]) private _reserveToSDistributors;
  // reserve internal asset -> yield distributor count
  mapping(address => uint256) private _reserveToSDistributorCount;
  // reserve internal asset -> variable yield distributors
  mapping(address => address) private _reserveToVDistributor;

  /**
   * @dev Emitted on addStableYieldDistributor()
   * @param _reserve The address of the internal asset
   * @param _distributor The address of the stable yield distributor
   **/
  event AddStableYieldDistributor(address _reserve, address _distributor);

  /**
   * @dev Emitted on removeStableYieldDistributor()
   * @param _reserve The address of the internal asset
   * @param _distributor The address of the stable yield distributor
   **/
  event RemoveStableYieldDistributor(address _reserve, address _distributor);

  /**
   * @dev Emitted on setVariableYieldDistributor()
   * @param _reserve The address of the internal asset
   * @param _distributor The address of the variable yield distributor
   **/
  event SetVariableYieldDistributor(address _reserve, address _distributor);

  constructor(address emissionManager) {
    EMISSION_MANAGER = emissionManager;
  }

  /**
   * @dev add stable yield distributor
   * - Caller is only EmissionManager who manage yield distribution
   * @param _reserve The address of the internal asset
   * @param _distributor The address of the stable yield distributor
   **/
  function addStableYieldDistributor(
    address _reserve,
    address _distributor
  ) external payable onlyEmissionManager {
    require(_reserve != address(0), Errors.YD_INVALID_CONFIGURATION);
    require(_distributor != address(0), Errors.YD_INVALID_CONFIGURATION);

    _reserveToSDistributors[_reserve].push(_distributor);
    unchecked {
      _reserveToSDistributorCount[_reserve]++;
    }

    emit AddStableYieldDistributor(_reserve, _distributor);
  }

  /**
   * @dev remove stable yield distributor
   * - Caller is only EmissionManager who manage yield distribution
   * @param _reserve The address of the internal asset
   * @param _index The index of stable yield distributors array
   **/
  function removeStableYieldDistributor(
    address _reserve,
    uint256 _index
  ) external payable onlyEmissionManager {
    require(_reserve != address(0), Errors.YD_INVALID_CONFIGURATION);

    uint256 length = _reserveToSDistributorCount[_reserve];
    require(_index < length, Errors.YD_INVALID_CONFIGURATION);

    length = length - 1;
    address removing = _reserveToSDistributors[_reserve][_index];

    if (_index != length)
      _reserveToSDistributors[_reserve][_index] = _reserveToSDistributors[_reserve][length];

    delete _reserveToSDistributors[_reserve][length];
    _reserveToSDistributorCount[_reserve] = length;

    emit RemoveStableYieldDistributor(_reserve, removing);
  }

  /**
   * @dev Get the stable yield distributor array
   * @param _reserve The address of the internal asset
   * @return The address array of stable yield distributor
   **/
  function getStableYieldDistributors(address _reserve) external view returns (address[] memory) {
    return _reserveToSDistributors[_reserve];
  }

  /**
   * @dev set variable yield distributor
   * - Caller is only EmissionManager who manage yield distribution
   * @param _reserve The address of the internal asset
   * @param _distributor The address of the variable yield distributor
   **/
  function setVariableYieldDistributor(
    address _reserve,
    address _distributor
  ) external payable onlyEmissionManager {
    require(_reserve != address(0), Errors.YD_INVALID_CONFIGURATION);
    require(_distributor != address(0), Errors.YD_INVALID_CONFIGURATION);

    _reserveToVDistributor[_reserve] = _distributor;

    emit SetVariableYieldDistributor(_reserve, _distributor);
  }

  /**
   * @dev Get the variable yield distributor
   * @param _reserve The address of the internal asset
   * @return The address of variable yield distributor
   **/
  function getVariableYieldDistributor(address _reserve) external view returns (address) {
    return _reserveToVDistributor[_reserve];
  }
}