// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ITaggr {
  event ContractReady(address indexed intializer);
  event SettingsSet(address indexed taggrSettings);
  event NftDistributorSet(address indexed distributor);
  event NftFactoryRegistered(address indexed nftFactory, uint256 factoryId);
  event CustomerAccountCreated(address indexed customerAccount);
  event CustomerProjectLaunched(address indexed customerAccount, address indexed contractAddress, bytes32 projectIdHash);
  event FeesCollected(address indexed receiver, address indexed tokenAddress, uint256 tokenAmount);
  event ProjectManagersUpdated(bytes32 projectIdHash, address[] managers, bool[] managerStates);

  function isCustomer(address customer) external view returns (bool);
  function isValidProjectId(string memory projectId) external view returns (bool);
  function isProjectOwner(string memory projectId, address account) external view returns (bool);
  function isProjectManager(string memory projectId, address account) external view returns (bool);
  function isProjectContract(string memory projectId, address contractAddress) external view returns (bool);
  function getCustomerPlanType(address customer) external view returns (uint256);
  function getProjectOwner(string memory projectId) external view returns (address);
  function getProjectContract(string memory projectId) external view returns (address);
  function getProjectByContract(address contractAddress) external view returns (bytes32);

  function createCustomerAccount(uint256 planType) external;
  function launchNewProject(
    string memory projectId,
    string memory projectName,
    string memory projectSymbol,
    string memory baseTokenUri,
    uint256 contractType,
    uint256 maxSupply,
    uint96 royaltiesPct
  ) external returns (address contractAddress);
}