// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../project/ICoCreateProject.sol";
import "../project/CoCreateProjectFactory.sol";
import "./ICoCreateLaunch.sol";
import "./UpgradeGate.sol";
import "../project/CoCreateProject.sol";

/// This contract contains the logic for the root co:create
// solhint-disable-next-line max-states-count
contract CoCreateLaunch is ICoCreateLaunch, Initializable, OwnableUpgradeable, UUPSUpgradeable {
  CoCreateProjectFactory private projectFactory;
  UpgradeGate private upgradeGate;
  IWETH9 private weth9;
  address private protocolFeeRecipient;
  uint32 private protocolFeePercent;
  string[] private components;
  mapping(address => bool) private existingCreateProjects;
  mapping(address => bool) private existingComponentContracts;
  mapping(string => address) private componentContracts;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address _upgradeGate,
    address _owner,
    address _coCreateProjectFactory,
    address _weth9
  ) public initializer {
    require(_upgradeGate != address(0), "Invalid Upgrade Gate address");
    require(_owner != address(0), "Invalid Owner address");
    require(_coCreateProjectFactory != address(0), "Invalid CoCreate project Factory address");

    __UUPSUpgradeable_init();
    __Ownable_init();
    transferOwnership(_owner);
    upgradeGate = UpgradeGate(_upgradeGate);
    require(upgradeGate.owner() == _owner, "Owner of ProtocolUpgrade should be governance address");
    projectFactory = CoCreateProjectFactory(_coCreateProjectFactory);
    weth9 = IWETH9(_weth9);
  }

  function _authorizeUpgrade(address newImpl) internal view override onlyOwner {
    upgradeGate.validateUpgrade(newImpl, _getImplementation());
  }

  function name() public pure override returns (string memory) {
    return "Co:Create";
  }

  function getWeth9() external view override returns (IWETH9) {
    return weth9;
  }

  function getCoCreateProjectFactory() external view override returns (address) {
    return address(projectFactory);
  }

  function setCoCreateProjectFactory(address _projectFactory) external onlyOwner {
    projectFactory = CoCreateProjectFactory(_projectFactory);
  }

  function getUpgradeGate() external view override returns (UpgradeGate) {
    return upgradeGate;
  }

  function deployCoCreateProject(
    string memory _name,
    string memory _description,
    address admin
  ) external override returns (ICoCreateProject) {
    CoCreateProject project = projectFactory.deployCoCreateProject(this, admin, _name, _description);
    existingCreateProjects[address(project)] = true;
    emit CoCreateProjectDeployed(address(project), _name, _description, admin);
    return project;
  }

  function isCoCreateProject(address coCreateProject) external view override returns (bool) {
    return existingCreateProjects[coCreateProject];
  }

  function setCoCreateFeePercent(uint32 protocolFeePercent_) external onlyOwner {
    protocolFeePercent = protocolFeePercent_;
  }

  // Takes in an address which is unused right now. We might want to return different
  // value for swap percent based on the address
  function getCoCreateFeePercent(address) external view returns (uint32) {
    return protocolFeePercent;
  }

  function setProtocolFeeRecipient(address protocolFeeRecipient_) external onlyOwner {
    protocolFeeRecipient = protocolFeeRecipient_;
  }

  function getProtocolFeeRecipient() external view returns (address) {
    return protocolFeeRecipient;
  }

  function addComponentContract(string memory componentType, address implementationAddress)
    public
    override
    onlyOwner
    returns (bool)
  {
    if (!existingComponentContracts[implementationAddress]) {
      require(componentContracts[componentType] == address(0), "duplicate componentType");
      existingComponentContracts[implementationAddress] = true;
      componentContracts[componentType] = implementationAddress;
      return true;
    }
    return false;
  }

  function removeComponentContract(string memory componentType, address implementationAddress)
    public
    override
    onlyOwner
    returns (bool)
  {
    if (existingComponentContracts[implementationAddress]) {
      require(componentContracts[componentType] == implementationAddress, "invalid componentType and contract address");
      existingComponentContracts[implementationAddress] = false;
      componentContracts[componentType] = address(0);
      return true;
    }
    return false;
  }

  function updateComponentContract(string memory componentType, address implementationAddress)
    public
    override
    onlyOwner
    returns (bool)
  {
    bool removed = removeComponentContract(componentType, componentContracts[componentType]);
    bool added = addComponentContract(componentType, implementationAddress);
    return removed && added;
  }

  function getImplementationForType(string memory componentType) external view returns (address) {
    return componentContracts[componentType];
  }

  function getComponents() external view override returns (string[] memory) {
    return components;
  }
}