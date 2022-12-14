// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../project/revenue/IRevenueManager.sol";
import "../project/ICoCreateProject.sol";
import "../project/revenue/IWETH9.sol";
import "../token/ITokenClaim.sol";
import "./UpgradeGate.sol";

/**
 * @title Co:Create Launch
 * @dev Main contract for Co:Create protocol. Contains all factories and deploys Create Instances
 */
interface ICoCreateLaunch {
  event CoCreateProjectDeployed(address indexed project, string name, string description, address admin);

  function name() external view returns (string memory);

  function getComponents() external view returns (string[] memory);

  function getWeth9() external view returns (IWETH9);

  function getCoCreateProjectFactory() external view returns (address);

  function getUpgradeGate() external view returns (UpgradeGate);

  function isCoCreateProject(address coCreateProject) external view returns (bool);

  function getCoCreateFeePercent(address) external view returns (uint32);

  function getProtocolFeeRecipient() external view returns (address);

  function getImplementationForType(string memory componentType) external view returns (address);

  function addComponentContract(string memory componentType, address implementationAddress) external returns (bool);

  function removeComponentContract(string memory componentType, address implementationAddress) external returns (bool);

  function updateComponentContract(string memory componentType, address implementationAddress) external returns (bool);

  /**
   * @dev Deploys create instance
   *
   * @param name of the Create Instance
   * @param admin for the Create Instance
   */
  function deployCoCreateProject(
    string memory name,
    string memory description,
    address admin
  ) external returns (ICoCreateProject);
}