// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/compatibility/GovernorCompatibilityBravoUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../cocreate/UpgradeGate.sol";
import "../project/ICoCreateProject.sol";

/**
 * @dev Governor module for CoCreate based on {GovernorUpgradeable}
 *
 * - The Governor module uses the following extensions
 * - {GovernorSettingsUpgradeable} for voting configurations for delay,voting period and thresholds
 * - {GovernorVotesUpgradeable} for determining voting power
 * - {GovernorTimelockControlUpgradeable} for time-lock functionality
 * - governor module also provides compatibility with Compound governance through {GovernorCompatibilityBravoUpgradeable}
 * - The governor module follows UUPS for upgrade-ability
 */
contract Governor is
  Initializable,
  GovernorUpgradeable,
  GovernorSettingsUpgradeable,
  GovernorCompatibilityBravoUpgradeable,
  GovernorVotesUpgradeable,
  GovernorVotesQuorumFractionUpgradeable,
  GovernorTimelockControlUpgradeable,
  OwnableUpgradeable,
  UUPSUpgradeable
{
  UpgradeGate private upgradeGate;
  string public description;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    string memory name,
    string memory _description,
    ICoCreateProject _coCreateProject,
    IVotesUpgradeable _token,
    TimelockControllerUpgradeable _timelock,
    uint256 initialVotingDelay,
    uint256 initialVotingPeriod,
    uint256 initialProposalThreshold,
    uint256 initialQuorumThreshold
  ) public initializer {
    __Governor_init(name);
    __GovernorSettings_init(initialVotingDelay, initialVotingPeriod, initialProposalThreshold);
    __GovernorCompatibilityBravo_init();
    __GovernorVotes_init(_token);
    __GovernorVotesQuorumFraction_init(initialQuorumThreshold);
    __GovernorTimelockControl_init(_timelock);
    __Ownable_init();
    __UUPSUpgradeable_init();
    description = _description;
    upgradeGate = _coCreateProject.getCoCreate().getUpgradeGate();
    _transferOwnership(_coCreateProject.getContractOwner());
  }

  function _authorizeUpgrade(address newImpl) internal view override onlyOwner {
    upgradeGate.validateUpgrade(newImpl, _getImplementation());
  }

  function votingDelay() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
    return super.votingDelay();
  }

  function votingPeriod() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
    return super.votingPeriod();
  }

  function quorum(uint256 blockNumber)
    public
    view
    override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
    returns (uint256)
  {
    return super.quorum(blockNumber);
  }

  function state(uint256 proposalId)
    public
    view
    override(GovernorUpgradeable, IGovernorUpgradeable, GovernorTimelockControlUpgradeable)
    returns (ProposalState)
  {
    return super.state(proposalId);
  }

  function propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory _description
  )
    public
    override(GovernorUpgradeable, GovernorCompatibilityBravoUpgradeable, IGovernorUpgradeable)
    returns (uint256)
  {
    return super.propose(targets, values, calldatas, _description);
  }

  function proposalThreshold()
    public
    view
    override(GovernorUpgradeable, GovernorSettingsUpgradeable)
    returns (uint256)
  {
    return super.proposalThreshold();
  }

  function _execute(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) {
    super._execute(proposalId, targets, values, calldatas, descriptionHash);
  }

  function _cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (uint256) {
    return super._cancel(targets, values, calldatas, descriptionHash);
  }

  function _executor()
    internal
    view
    override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
    returns (address)
  {
    return super._executor();
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(GovernorUpgradeable, IERC165Upgradeable, GovernorTimelockControlUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}