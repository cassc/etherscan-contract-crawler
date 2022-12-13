// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../governance/Governor.sol";
import "../token/ProjectToken.sol";
import "../treasury/Treasury.sol";
import "../cocreate/ICoCreateLaunch.sol";
import "../cocreate/UpgradeGate.sol";
import "./ICoCreateProject.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../governance/GovernanceExecution.sol";

/// @title CoCreateProject
/// The CoCreateProject contract is the main interface to deploy and manage other contracts inside your project. It is a "container" for all the contracts that make up your project.
/// It has a bunch of methods which allow you to deploy other contracts. The main contracts are:
/// - ProjectToken: the token that represents your project
/// - Treasury: the treasury contract that holds the funds of your project
/// - Governor: the governance contract that allows you to vote on proposals
/// It also has generic methods to deploy other contracts using the deployProxy and deployUUPSProxy methods.
contract CoCreateProject is ICoCreateProject, Initializable, AccessControlUpgradeable, UUPSUpgradeable {
  bytes32 public constant PROJECT_ADMIN_ROLE = keccak256("PROJECT_ADMIN_ROLE");
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

  // Whether the project token has been deployed
  bool private projectTokenDeployed;
  // address of the admin of the project
  address private admin;
  // address of the governor of the project
  address private governor;
  // address of the executor of the project
  address private executor;
  // address of the CoCreateLaunch contract
  ICoCreateLaunch private coCreate;
  // address of the project token
  ProjectToken private projectToken;
  // address of the UpgradeGate contract
  UpgradeGate private upgradeGate;
  // list of all the treasuries deployed
  address[] private treasuries;
  // name of the project
  string public name;
  // description of the project
  string public description;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev initialize the contract
   * @param _coCreate address of the CoCreateLaunch contract
   * @param _admin address of the admin / owner of this contract
   * @param _name name of the project
   * @param _description description of the project
   */
  function initialize(
    ICoCreateLaunch _coCreate,
    address _admin,
    string memory _name,
    string memory _description
  ) public initializer {
    //inits
    __UUPSUpgradeable_init();
    __AccessControl_init();
    //initialize contract
    coCreate = _coCreate;
    name = _name;
    description = _description;
    require(_admin != address(0), "Invalid admin address");
    admin = _admin;
    _setRoleAdmin(PROJECT_ADMIN_ROLE, PROJECT_ADMIN_ROLE);
    _setRoleAdmin(GOVERNANCE_ROLE, PROJECT_ADMIN_ROLE);
    _setupRole(PROJECT_ADMIN_ROLE, admin);
    _setupRole(GOVERNANCE_ROLE, admin);
    _deployTreasury(_name, "", admin);
    upgradeGate = _coCreate.getUpgradeGate();
  }

  /**
   * @dev only allow upgrades which are approved by the UpgradeGate contract. Only PROJECT_ADMIN_ROLE
   * can call this function.
   */
  function _authorizeUpgrade(address newImpl) internal view override onlyRole(PROJECT_ADMIN_ROLE) {
    upgradeGate.validateUpgrade(newImpl, _getImplementation());
  }

  // Deploys a GovernanceExecution contract and a Governor contract using deployUUPSProxy
  function deployGovernance(
    string memory _name,
    string memory _description,
    uint256 minDelay,
    uint256 initialVotingDelay,
    uint256 initialVotingPeriod,
    uint256 initialProposalThreshold,
    uint256 initialQuorumThreshold
  ) external override onlyRole(GOVERNANCE_ROLE) returns (address) {
    require(projectTokenDeployed, "CoCreateProject: project token not deployed");
    require(governor == address(0), "CoCreateProject: Governor deployed");
    // Since this is a UUPS Upgradable contract, use deployUUPSProxy
    executor = deployUUPSProxy(
      "GovernanceExecution",
      abi.encodeWithSelector(
        GovernanceExecution(payable(0)).initialize.selector,
        minDelay,
        new address[](0),
        new address[](0)
      )
    );

    // Since this is a UUPS Upgradable contract, use deployUUPSProxy
    governor = deployUUPSProxy(
      "Governor",
      abi.encodeWithSelector(
        Governor(payable(0)).initialize.selector,
        _name,
        _description,
        this,
        projectToken,
        executor,
        initialVotingDelay,
        initialVotingPeriod,
        initialProposalThreshold,
        initialQuorumThreshold
      )
    );
    GovernanceExecution(payable(executor)).grantRole(keccak256("EXECUTOR_ROLE"), governor);
    GovernanceExecution(payable(executor)).grantRole(keccak256("PROPOSER_ROLE"), governor);

    emit GovernanceDeployed(
      _name,
      _description,
      address(this),
      governor,
      address(executor),
      minDelay,
      initialVotingDelay,
      initialVotingPeriod,
      initialProposalThreshold,
      initialQuorumThreshold
    );

    return address(governor);
  }

  /// Deploys a ProjectToken contract using the deployProxy helper
  function deployProjectToken(
    string memory name_,
    string memory description_,
    string memory symbol_,
    uint224 maxSupply_,
    bool isFixedSupply_,
    bool isTransferAllowlisted_,
    address[] memory mintRecipients_,
    uint224[] memory mintAmounts_
  ) external override onlyRole(PROJECT_ADMIN_ROLE) returns (address) {
    require(
      address(projectToken) == (address(0)) && !projectTokenDeployed,
      "CoCreateProject: Project token already deployed"
    );
    projectTokenDeployed = true;
    projectToken = ProjectToken(
      // Since this is a UUPS Upgradable contract, use deployUUPSProxy
      deployUUPSProxy(
        "ProjectToken",
        abi.encodeWithSelector(
          ProjectToken.initialize.selector,
          this,
          name_,
          description_,
          symbol_,
          maxSupply_,
          isFixedSupply_,
          isTransferAllowlisted_,
          mintRecipients_,
          mintAmounts_
        )
      )
    );
    emit ProjectTokenDeployed(
      address(this),
      address(projectToken),
      name_,
      description_,
      symbol_,
      isFixedSupply_,
      isTransferAllowlisted_,
      maxSupply_,
      mintRecipients_,
      mintAmounts_
    );
    return address(projectToken);
  }

  /// Deploys a Treasury contract
  /// @param _name name of the treasury
  /// @param _description description of the treasury
  /// @param _admin address of the admin of the treasury
  function deployTreasury(
    string memory _name,
    string memory _description,
    address _admin
  ) external override onlyRole(PROJECT_ADMIN_ROLE) returns (address) {
    return _deployTreasury(_name, _description, _admin);
  }

  function _deployTreasury(
    string memory _name,
    string memory _description,
    address _admin
  ) internal returns (address) {
    // Since this not a UUPS Upgradable contract, use _deployProxy
    address treasury = _deployProxy(
      "Treasury",
      abi.encodeWithSelector(Treasury.initialize.selector, _name, _description, _admin, address(this))
    );
    treasuries.push(treasury);
    emit TreasuryDeployed(_name, _description, address(this), treasury, _admin);
    return treasury;
  }

  /// Deploys a new proxy (minimal proxy contract) for the given component.
  /// Components are defined in CoCreateLaunch
  function deployProxy(string memory componentType, bytes memory data)
    public
    override
    onlyRole(PROJECT_ADMIN_ROLE)
    returns (address)
  {
    return _deployProxy(componentType, data);
  }

  function _deployProxy(string memory componentType, bytes memory data) internal returns (address) {
    address implementation = coCreate.getImplementationForType(componentType);
    require(implementation != address(0), "Invalid implementation address");
    address deployedComponent = ClonesUpgradeable.clone(implementation);
    if (data.length > 0) {
      AddressUpgradeable.functionCall(deployedComponent, data);
    }
    emit ProxyDeployed(componentType, deployedComponent, implementation);
    return deployedComponent;
  }

  /// Deploys a new UUPS proxy (ERC1967 proxy contract) for the given component.
  function deployUUPSProxy(string memory componentType, bytes memory data)
    public
    override
    onlyRole(PROJECT_ADMIN_ROLE)
    returns (address)
  {
    address implementation = coCreate.getImplementationForType(componentType);
    require(implementation != address(0), "Invalid implementation address");
    address deployedComponent = address(new ERC1967Proxy(implementation, data));
    emit ProxyDeployed(componentType, deployedComponent, implementation);
    return deployedComponent;
  }

  function getGovernor() external view override returns (address) {
    return governor;
  }

  function getExecutor() external view override returns (address) {
    return executor;
  }

  function getCoCreate() external view override returns (ICoCreateLaunch) {
    return coCreate;
  }

  function getProjectToken() external view override returns (ProjectToken) {
    return projectToken;
  }

  function getTreasuries() external view override returns (address[] memory) {
    return treasuries;
  }

  function getAdmin() external view override returns (address) {
    return admin;
  }
}