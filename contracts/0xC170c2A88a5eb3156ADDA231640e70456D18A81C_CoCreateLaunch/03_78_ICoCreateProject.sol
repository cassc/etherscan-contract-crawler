// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";
import "../token/ProjectToken.sol";
import "./revenue/IRevenueManager.sol";
import "../cocreate/ICoCreateLaunch.sol";

/**
 * @title Co:Create Project
 * @dev Contract that deploys all the components for each create instance for Co:Create
 */
interface ICoCreateProject {
  event GovernanceDeployed(
    string name,
    string description,
    address indexed coCreateProject,
    address indexed governor,
    address executor,
    uint256 minDelay,
    uint256 initialVotingDelay,
    uint256 initialVotingPeriod,
    uint256 initialProposalThreshold,
    uint256 initialQuorumThreshold
  );

  event ProjectTokenDeployed(
    address indexed project,
    address token,
    string name,
    string description,
    string symbol,
    bool isFixedSupply,
    bool isTransferAllowlisted,
    uint224 maxSupply,
    address[] mintRecipients,
    uint224[] mintAmounts
  );

  event TreasuryDeployed(
    string name,
    string description,
    address indexed coCreateProject,
    address treasury,
    address admin
  );

  event ProxyDeployed(string componentType, address indexed proxy, address impl);

  event ContractOwnerChanged(address prevOwner, address newOwner);

  /**
   * @dev deploys governance for the create instance. Need to deploy the governance contract before deploying governance
   *
   * @param name for the governor
   * @param description for the governor
   * @param minDelay minimum delay in blocks for executor
   * @param initialVotingDelay initial voting delay in blocks for governor
   * @param initialVotingPeriod initial voting period in blocks for the governor
   * @param initialProposalThreshold initial proposal threshold in percentage. Should be between 0 and 100
   * @param initialQuorumThreshold initial quorum threshold in number of votes
   */
  function deployGovernance(
    string memory name,
    string memory description,
    uint256 minDelay,
    uint256 initialVotingDelay,
    uint256 initialVotingPeriod,
    uint256 initialProposalThreshold,
    uint256 initialQuorumThreshold
  ) external returns (address);

  /**
   * @dev Deploys instance ERC20 token for the create instance
   *
   * @param name of the ERC20 token
   * @param description of the ERC20 token
   * @param symbol of the ERC20 token
   * @param maxSupply for the ERC20 token
   * @param isFixedSupply is the token supply fixed
   * @param isTransferAllowlisted is the token transfer allow-listed
   * @param mintRecipients Addresses which receives the minted tokens. If vestingRecipientsStartTimestamps is a non-empty array, first k of these recipients are subject to vesting (k is length of vestingRecipientsStartTimestamps)
   * @param mintAmounts The mint amounts received by these addresses
   */
  function deployProjectToken(
    string memory name,
    string memory description,
    string memory symbol,
    uint224 maxSupply,
    bool isFixedSupply,
    bool isTransferAllowlisted,
    address[] memory mintRecipients,
    uint224[] memory mintAmounts
  ) external returns (address);

  /**
   * @dev Deploys instance of Co:Create Treasury contract
   *
   * @param name for the treasury
   * @param description for the treasury
   * @param admin Treasury admin who can operate and distribute funds from the treasury
   */
  function deployTreasury(
    string memory name,
    string memory description,
    address admin
  ) external returns (address);

  function getGovernor() external view returns (address);

  function getExecutor() external view returns (address);

  function getCoCreate() external view returns (ICoCreateLaunch);

  function getProjectToken() external view returns (ProjectToken);

  function getTreasuries() external view returns (address[] memory);

  function name() external view returns (string memory);

  function getContractOwner() external view returns (address);

  function isExistingComponent(address component) external view returns (bool);

  function deployProxy(string memory componentType, bytes memory data) external returns (address);

  function deployUUPSProxy(string memory componentType, bytes memory data) external returns (address);

  function transferContractOwner(address newOwner) external returns (bool);
}