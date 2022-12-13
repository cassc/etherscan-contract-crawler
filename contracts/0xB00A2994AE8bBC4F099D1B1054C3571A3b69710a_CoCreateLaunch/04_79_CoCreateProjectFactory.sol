// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./CoCreateProject.sol";

/**
 * @dev Factory to deploy a new Co:Create Instance
 *
 * The factory will deploy a UUPS CoCreateProject proxy that is set to it as implementation
 */
contract CoCreateProjectFactory {
  address public immutable coCreateProjectImpl;

  constructor() {
    coCreateProjectImpl = address(new CoCreateProject());
  }

  /**
   * Deploys a UUPS CoCreateProject Proxy
   */
  function deployCoCreateProject(
    ICoCreateLaunch coCreate,
    address instanceAdmin,
    string memory name,
    string memory description
  ) external returns (CoCreateProject) {
    ERC1967Proxy newCoCreateInstance = new ERC1967Proxy(coCreateProjectImpl, "");
    address payable newCoCreateInstanceAddress = payable(address(newCoCreateInstance));
    CoCreateProject(newCoCreateInstanceAddress).initialize(coCreate, instanceAdmin, name, description);
    return CoCreateProject(newCoCreateInstanceAddress);
  }
}