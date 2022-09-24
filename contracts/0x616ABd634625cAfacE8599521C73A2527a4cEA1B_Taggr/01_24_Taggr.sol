// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/ITaggr.sol";
import "./interfaces/ITaggrSettings.sol";
import "./interfaces/ITaggrNft.sol";
import "./interfaces/ITaggrNftFactory.sol";
import "./lib/BlackholePrevention.sol";


/// @custom:security-contact [email protected]
contract Taggr is
  ITaggr,
  Initializable,
  AccessControlEnumerableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable,
  BlackholePrevention
{
  using SafeERC20Upgradeable for IERC20Upgradeable;

  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  ITaggrSettings internal _taggrSettings;
  mapping (uint256 => ITaggrNftFactory) internal _nftFactories;
  address internal _nftDistributor;

  // Customer Account => Plan Type
  mapping (address => uint256) internal _customerPlanType;

  // Customer Account => Is Self-Serve Enabled?
  mapping (address => bool) internal _customerSelfServe;

  // ProjectID => Customer Account
  mapping (bytes32 => address) internal _projectOwner;

  // ProjectID => Contract Address
  mapping (bytes32 => address) internal _projectContract;
  // Contract Address => ProjectID
  mapping (address => bytes32) internal _projectByContract;

  // ProjectID => User Account => Is Registered Manager
  mapping (bytes32 => mapping (address => bool)) internal _projectManagerAccounts;


  /***********************************|
  |          Initialization           |
  |__________________________________*/

  function initialize(address initiator) public initializer {
    __AccessControlEnumerable_init();
    __Pausable_init();
    __ReentrancyGuard_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(OWNER_ROLE, _msgSender());
    _setupRole(MANAGER_ROLE, _msgSender());
    _setupRole(PAUSER_ROLE, _msgSender());

    emit ContractReady(initiator);
  }


  /***********************************|
  |         Public Functions          |
  |__________________________________*/

  function isCustomer(address customer) external view override returns (bool) {
    return _customerPlanType[customer] > 0;
  }

  function isValidProjectId(string memory projectId) external view override returns (bool) {
    return _projectOwner[_hash(projectId)] != address(0x0);
  }

  function isProjectOwner(string memory projectId, address account) external view override returns (bool) {
    return _projectOwner[_hash(projectId)] == account;
  }

  function isProjectManager(string memory projectId, address account) external view override returns (bool) {
    return _projectManagerAccounts[_hash(projectId)][account];
  }

  function isProjectContract(string memory projectId, address contractAddress) external view override returns (bool) {
    return _projectContract[_hash(projectId)] == contractAddress;
  }

  function getCustomerPlanType(address customer) external view override returns (uint256) {
    return _customerPlanType[customer];
  }

  function getProjectOwner(string memory projectId) external view override returns (address) {
    return _projectOwner[_hash(projectId)];
  }

  function getProjectContract(string memory projectId) external view override returns (address) {
    return _projectContract[_hash(projectId)];
  }

  function getProjectByContract(address contractAddress) external view override returns (bytes32) {
    return _projectByContract[contractAddress];
  }


  function createCustomerAccount(uint256 planType) external override {
    address customer = _msgSender();
    require(_customerPlanType[customer] == 0, "T:E-003");
    require(_taggrSettings.isActivePlanType(planType), "T:E-202");

    // Collect Membership Fee for New Customers
    uint256 fee = _taggrSettings.getMembershipFee();
    if (fee > 0) {
      address feeToken = _taggrSettings.getMembershipFeeToken();
      _collectAssetToken(customer, feeToken, fee);
    }

    // Create Member
    _updateCustomerAccount(customer, planType);
  }


  function launchNewProject(
    string memory projectId,
    string memory projectName,
    string memory projectSymbol,
    string memory baseTokenUri,
    uint256 nftFactoryId,
    uint256 maxSupply,
    uint96 royaltiesPct
  ) public override returns (address contractAddress) {
    address customer = _msgSender();
    require(_customerSelfServe[customer], "T:E-203");

    // Collect Project Fee
    uint256 fee = _taggrSettings.getProjectLaunchFee();
    if (fee > 0) {
      address feeToken = _taggrSettings.getProjectLaunchFeeToken();
      _collectAssetToken(customer, feeToken, fee);
    }

    // Validate Customer/Project
    bytes32 projectIdHash = _hash(projectId);
    _validateCustomerProject(customer, projectIdHash);

    // Launch New Project
    contractAddress = _launchNewProject(
      customer,
      projectIdHash,
      projectName,
      projectSymbol,
      baseTokenUri,
      nftFactoryId,
      maxSupply,
      royaltiesPct
    );
  }


  function updateProjectManagers(string memory projectId, address[] memory managers, bool[] memory managerStates) public {
    bytes32 projectHash = _hash(projectId);
    require(_projectOwner[projectHash] == _msgSender(), "T:E-102");
    _updateProjectManagers(projectHash, managers, managerStates);
  }


  /***********************************|
  |       Permissioned Controls       |
  |__________________________________*/

  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function setTaggrSettings(address taggrSettings) external onlyRole(MANAGER_ROLE) {
    require(taggrSettings != address(0), "T:E-103");
    _taggrSettings = ITaggrSettings(taggrSettings);
    emit SettingsSet(taggrSettings);
  }

  function setNftDistributor(address distributor) external onlyRole(MANAGER_ROLE) {
    require(distributor != address(0), "T:E-103");
    _nftDistributor = distributor;
    emit NftDistributorSet(distributor);
  }

  function registerNftFactory(uint256 factoryId, address nftFactory) external onlyRole(MANAGER_ROLE) {
    require(nftFactory != address(0), "T:E-103");
    require(address(_nftFactories[factoryId]) == address(0), "T:E-003");
    _nftFactories[factoryId] = ITaggrNftFactory(nftFactory);
    emit NftFactoryRegistered(nftFactory, factoryId);
  }

  function managerUpdateCustomerAccount(address customer, uint256 planType) external onlyRole(MANAGER_ROLE) {
    // Create Member
    _updateCustomerAccount(customer, planType);
  }

  function toggleCustomerSelfServe(address customer, bool state) external onlyRole(MANAGER_ROLE) {
    _customerSelfServe[customer] = state;
  }


  function managerLaunchNewProject(
    address customerAccount,
    string memory projectId,
    string memory projectName,
    string memory projectSymbol,
    string memory baseTokenUri,
    uint256 nftFactoryId,
    uint256 maxSupply,
    uint96 royaltiesPct
  )
    external
    onlyRole(MANAGER_ROLE)
    returns (address contractAddress)
  {
    // Validate Customer/Project
    bytes32 projectIdHash = _hash(projectId);
    _validateCustomerProject(customerAccount, projectIdHash);

    // Launch New Project
    contractAddress = _launchNewProject(
      customerAccount,
      projectIdHash,
      projectName,
      projectSymbol,
      baseTokenUri,
      nftFactoryId,
      maxSupply,
      royaltiesPct
    );
  }

  function managerLaunchNewProjectWithContract(
    address customerAccount,
    string memory projectId,
    address contractAddress
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    // Validate Customer/Project
    bytes32 projectIdHash = _hash(projectId);
    _validateCustomerProject(customerAccount, projectIdHash);

    // Launch New Project
    _launchNewProjectWithContract(
      customerAccount,
      projectIdHash,
      contractAddress
    );
  }



  function collectFees(address receiver, address tokenAddress, uint256 tokenAmount) external onlyRole(OWNER_ROLE) {
    _sendAssetToken(receiver, tokenAddress, tokenAmount);
    emit FeesCollected(receiver, tokenAddress, tokenAmount);
  }


  /***********************************|
  |            Only Owner             |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external onlyRole(OWNER_ROLE) {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external onlyRole(OWNER_ROLE) {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external onlyRole(OWNER_ROLE) {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }

  function withdrawERC1155(address payable receiver, address tokenAddress, uint256 tokenId, uint256 amount) external onlyRole(OWNER_ROLE) {
    _withdrawERC1155(receiver, tokenAddress, tokenId, amount);
  }


  /***********************************|
  |         Private/Internal          |
  |__________________________________*/



  function _validateCustomerProject(address customerAccount, bytes32 projectIdHash) internal view {
    // Validate Customer
    require(_customerPlanType[customerAccount] > 0, "T:E-102");

    // Validate Project ID
    require(_projectOwner[projectIdHash] == address(0), "T:E-003");
  }



  function _updateCustomerAccount(address customerAccount, uint256 planType) internal {
    // Create Member
    _customerPlanType[customerAccount] = planType;
    emit CustomerAccountCreated(customerAccount);
  }


  function _launchNewProject(
    address customerAccount,
    bytes32 projectIdHash,
    string memory projectName,
    string memory projectSymbol,
    string memory baseTokenUri,
    uint256 nftFactoryId,
    uint256 maxSupply,
    uint96 royaltiesPct
  ) internal returns (address contractAddress) {
    // Deploy Contract Clone from Factory
    contractAddress = _nftFactories[nftFactoryId].deploy(
      customerAccount,
      _nftDistributor,
      projectName,
      projectSymbol,
      baseTokenUri,
      maxSupply,
      royaltiesPct
    );
    _launchNewProjectWithContract(customerAccount, projectIdHash, contractAddress);
  }


  function _launchNewProjectWithContract(
    address customerAccount,
    bytes32 projectIdHash,
    address contractAddress
  ) internal {
    // Add Project Owner + Manager
    _projectOwner[projectIdHash] = customerAccount;
    _projectManagerAccounts[projectIdHash][customerAccount] = true;

    // Register Contract with Project
    _projectContract[projectIdHash] = contractAddress;
    _projectByContract[contractAddress] = projectIdHash;

    emit CustomerProjectLaunched(customerAccount, contractAddress, projectIdHash);
  }


  function _updateProjectManagers(bytes32 projectIdHash, address[] memory managers, bool[] memory managerStates) internal {
    require(managers.length == managerStates.length, "T:E-204");
    uint256 count = managers.length;
    for (uint256 i = 0; i < count; i++) {
      _projectManagerAccounts[projectIdHash][managers[i]] = managerStates[i];
    }
    emit ProjectManagersUpdated(projectIdHash, managers, managerStates);
  }





  /// @dev Collects the Required ERC20 Token(s) from the users wallet
  ///   Be sure to Approve this Contract to transfer your Token(s)
  /// @param from         The owner address to collect the tokens from
  /// @param tokenAddress  The addres of the token to transfer
  /// @param tokenAmount  The amount of tokens to collect
  function _collectAssetToken(address from, address tokenAddress, uint256 tokenAmount) internal virtual {
    IERC20Upgradeable(tokenAddress).safeTransferFrom(from, address(this), tokenAmount);
  }

  function _sendAssetToken(address to, address tokenAddress, uint256 tokenAmount) internal virtual {
    IERC20Upgradeable(tokenAddress).safeTransferFrom(address(this), to, tokenAmount);
  }

  function _hash(string memory data) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(data));
  }
}