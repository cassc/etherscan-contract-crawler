// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title IYieldDistributorAdapter
 * @author Sturdy
 * @notice Defines the relation between reserve and yield distributors
 **/
interface IYieldDistributorAdapter {
  /**
   * @dev add stable yield distributor
   * - Caller is only EmissionManager who manage yield distribution
   * @param _reserve The address of the internal asset
   * @param _distributor The address of the stable yield distributor
   **/
  function addStableYieldDistributor(address _reserve, address _distributor) external payable;

  /**
   * @dev remove stable yield distributor
   * - Caller is only EmissionManager who manage yield distribution
   * @param _reserve The address of the internal asset
   * @param _index The index of stable yield distributors array
   **/
  function removeStableYieldDistributor(address _reserve, uint256 _index) external payable;

  /**
   * @dev Get the stable yield distributor array
   * @param _reserve The address of the internal asset
   * @return The address array of stable yield distributor
   **/
  function getStableYieldDistributors(address _reserve) external view returns (address[] memory);

  /**
   * @dev set variable yield distributor
   * - Caller is only EmissionManager who manage yield distribution
   * @param _reserve The address of the internal asset
   * @param _distributor The address of the variable yield distributor
   **/
  function setVariableYieldDistributor(address _reserve, address _distributor) external payable;

  /**
   * @dev Get the variable yield distributor
   * @param _reserve The address of the internal asset
   * @return The address of variable yield distributor
   **/
  function getVariableYieldDistributor(address _reserve) external view returns (address);
}