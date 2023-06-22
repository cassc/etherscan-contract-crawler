// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IAlloyxManager.sol";
import "../interfaces/IAlloyxVault.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../utils/AdminUpgradeable.sol";

/**
 * @title AlloyxManager
 * @notice This manager contract takes charge of controlling the key phases of vault lifecycle including vault commencement, liquidation, fee collection, etc
 * @author AlloyX
 */
contract AlloyxManager is IAlloyxManager, IAlloyx, AdminUpgradeable {
  using SafeMath for uint256;
  using ConfigHelper for AlloyxConfig;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  AlloyxConfig public config;
  bool internal locked;
  // Mapping(proposalId=>Mapping(permanentStaker=>usdcAmountInvested))
  mapping(string => mapping(address => uint256)) internal usdcPermanentStakerMap;
  // Mapping(proposalId=>Mapping(permanentStaker=>alyxAmountStaked))
  mapping(string => mapping(address => uint256)) internal alyxPermanentStakerMap;
  // Mapping(proposalId=>permanentStakerAddresses)
  mapping(string => EnumerableSet.AddressSet) internal permanentStakersMap;
  // Mapping(proposalId=>allowWithdrawal)
  mapping(string => bool) internal allowWithdrawalMap;
  // Mapping(proposalId=>Components)
  mapping(string => Component[]) internal componentsMap;
  // Mapping(proposalId=>processed)
  mapping(string => bool) internal processedProposalMap;

  mapping(address => address) public governorMap;
  mapping(address => address) public timelockMap;
  mapping(address => address) public govTokenMap;

  EnumerableSet.AddressSet vaultAddresses;

  event AlloyxConfigUpdated(address indexed who, address configAddress);
  event SetComponent(string indexed proposalId, address indexed creatorAddress, address poolAddress, uint256 proportion, uint256 tranche, Source source);

  /**
   * @notice Initialize the contract
   * @param _configAddress the address of configuration contract
   */
  function initialize(address _configAddress) external initializer {
    __AdminUpgradeable_init(msg.sender);
    config = AlloyxConfig(_configAddress);
  }

  /**
   * @notice If user operation is paused
   */
  modifier isPaused() {
    require(config.isPaused(), "all user operations should be paused");
    _;
  }

  /**
   * @notice If user operation is not paused
   */
  modifier notPaused() {
    require(!config.isPaused(), "the user operation should be unpaused first");
    _;
  }

  /**
   * @notice If address is whitelisted
   */
  modifier isWhitelisted() {
    require(config.getWhitelist().isUserWhitelisted(msg.sender), "not whitelisted");
    _;
  }

  /**
   * @notice Ensure no reentrant for token transfer functions
   */
  modifier nonReentrant() {
    require(!locked);
    locked = true;
    _;
    locked = false;
  }

  /**
   * @notice Update configuration contract address
   */
  function updateConfig() external onlyAdmin isPaused {
    config = AlloyxConfig(config.configAddress());
    emit AlloyxConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Check if the vault is a vault created by the manager
   * @param _vault the address of the vault
   * @return true if it is a vault otherwise false
   */
  function isVault(address _vault) external view override returns (bool) {
    return vaultAddresses.contains(_vault);
  }

  /**
   * @notice Get all the addresses of vaults
   * @return the addresses of vaults
   */
  function getVaults() external view override returns (address[] memory) {
    return vaultAddresses.values();
  }

  /**
   * @notice Deposit for the proposal with certain USDC and ALYX
   * @param _proposalId the proposal ID
   * @param _usdcAmount the USDC amount to deposit
   * @param _alyxAmount the ALYX amount to deposit
   */
  function depositForProposal(string calldata _proposalId, uint256 _usdcAmount, uint256 _alyxAmount) external notPaused nonReentrant isWhitelisted {
    _transferERC20From(msg.sender, config.usdcAddress(), address(this), _usdcAmount);
    _transferERC20From(msg.sender, config.alyxAddress(), address(this), _alyxAmount);
    usdcPermanentStakerMap[_proposalId][msg.sender] = usdcPermanentStakerMap[_proposalId][msg.sender].add(_usdcAmount);
    alyxPermanentStakerMap[_proposalId][msg.sender] = alyxPermanentStakerMap[_proposalId][msg.sender].add(_alyxAmount);
    permanentStakersMap[_proposalId].add(msg.sender);
  }

  /**
   * @notice Withdraw from the proposal, it will withdraw all the ALYX and USDC for that depositor
   * @param _proposalId the proposal ID
   */
  function withdrawFromProposal(string calldata _proposalId) public notPaused {
    if (allowWithdrawalMap[_proposalId] && permanentStakersMap[_proposalId].contains(msg.sender) && !processedProposalMap[_proposalId]) {
      _transferERC20(config.usdcAddress(), msg.sender, usdcPermanentStakerMap[_proposalId][msg.sender]);
      _transferERC20(config.alyxAddress(), msg.sender, alyxPermanentStakerMap[_proposalId][msg.sender]);
      usdcPermanentStakerMap[_proposalId][msg.sender] = 0;
      alyxPermanentStakerMap[_proposalId][msg.sender] = 0;
      permanentStakersMap[_proposalId].remove(msg.sender);
    }
  }

  /**
   * @notice Allow the depositors to withdraw from a proposal ID, restricted to admin
   * @param _proposalId the proposal ID
   * @param _allowed whether to allow withdrawal
   */
  function setAllowWithdraw(string calldata _proposalId, bool _allowed) external onlyAdmin notPaused {
    allowWithdrawalMap[_proposalId] = _allowed;
  }

  /**
   * @notice Get number of all the USDC tokens deposited to the proposal
   * @param _proposalId the proposal ID
   */
  function totalUsdcDepositedForProposal(string calldata _proposalId) public view returns (uint256) {
    uint256 result = 0;
    EnumerableSet.AddressSet storage creators = permanentStakersMap[_proposalId];
    for (uint256 i = 0; i < creators.length(); i++) {
      result += usdcPermanentStakerMap[_proposalId][creators.at(i)];
    }
    return result;
  }

  /**
   * @notice Get number of all the ALYX tokens deposited to the proposal
   * @param _proposalId the proposal ID
   */
  function totalAlyxDepositedForProposal(string memory _proposalId) public view returns (uint256) {
    uint256 result = 0;
    EnumerableSet.AddressSet storage creators = permanentStakersMap[_proposalId];
    for (uint256 i = 0; i < creators.length(); i++) {
      result += alyxPermanentStakerMap[_proposalId][creators.at(i)];
    }
    return result;
  }

  /**
   * @notice Get the proposal configuration
   * @param _proposalId the proposal ID
   */
  function getComponents(string calldata _proposalId) external view returns (Component[] memory) {
    return componentsMap[_proposalId];
  }

  /**
   * @notice Set the proposal configuration, restricted to admin and permanent stakers
   * @param _proposalId the proposal ID
   * @param _components the investment compositions
   */
  function setProposalConfiguration(string memory _proposalId, Component[] memory _components) external onlyAdmin {
    verifyComponents(_components);
    delete componentsMap[_proposalId];
    for (uint256 i = 0; i < _components.length; i++) {
      componentsMap[_proposalId].push(Component(_components[i].proportion, _components[i].poolAddress, _components[i].tranche, _components[i].source));
      emit SetComponent(_proposalId, msg.sender, _components[i].poolAddress, _components[i].proportion, _components[i].tranche, _components[i].source);
    }
  }

  /**
   * @notice Start the vault from proposal and link up with governance contracts, restricted to admin
   * @param _proposalId the proposal ID
   * @param _vaultAddress the vault contract which has been deployed at INIT status
   * @param _govTokenAddress an empty GovernanceToken contract which has been just deployed
   * @param _govTimeLockAddress an empty GovernanceTimeLock contract which has been just deployed
   * @param _governorAddress an empty Governor contract which has been just deployed
   */
  function startAlloyxVault(string calldata _proposalId, address _vaultAddress, address _govTokenAddress, address _govTimeLockAddress, address _governorAddress) external onlyAdmin {
    require(componentsMap[_proposalId].length > 0, "there are no components for proposal");
    uint256 totalUsdcForProposal = totalUsdcDepositedForProposal(_proposalId);
    uint256 totalAlyxForProposal = totalAlyxDepositedForProposal(_proposalId);
    require(totalUsdcForProposal >= config.getThresholdUsdcForVaultCreation() && totalAlyxForProposal >= config.getThresholdAlyxForVaultCreation(), "not meet minimum deposit");

    _transferERC20(config.usdcAddress(), _vaultAddress, totalUsdcForProposal);
    _transferERC20(config.alyxAddress(), _vaultAddress, totalAlyxForProposal);

    governorMap[_vaultAddress] = _governorAddress;
    govTokenMap[_vaultAddress] = _govTokenAddress;
    timelockMap[_vaultAddress] = _govTimeLockAddress;

    config.getStakeDesk().setGovTokenForVault(_vaultAddress, _govTokenAddress);

    EnumerableSet.AddressSet storage depositors = permanentStakersMap[_proposalId];
    mapping(address => uint256) storage usdcMap = usdcPermanentStakerMap[_proposalId];
    mapping(address => uint256) storage alyxMap = alyxPermanentStakerMap[_proposalId];
    Component[] storage components = componentsMap[_proposalId];

    IAlloyxVault vault = IAlloyxVault(_vaultAddress);
    // add to vaultAddresses before start the vault
    vaultAddresses.add(_vaultAddress);
    vault.startVault(components, convertMapToDepositAmount(usdcMap, depositors), convertMapToDepositAmount(alyxMap, depositors), totalUsdcForProposal);
    processedProposalMap[_proposalId] = true;
  }

  /**
   * @notice Reinstate the governance by depositing the ALYX tokens from the new permanent stakers into the vault and mint govTokens for them, restricted to admin
   * @param _vaultAddress the vault to reinstate governance for
   * @param _proposalId the proposal
   */
  function reinstateGovernanceForVault(string calldata _proposalId, address _vaultAddress) external onlyAdmin {
    uint256 totalAlyxForProposal = totalAlyxDepositedForProposal(_proposalId);
    require(totalAlyxForProposal >= config.getThresholdAlyxForVaultCreation(), "not meet minimum deposit");
    _transferERC20(config.alyxAddress(), _vaultAddress, totalAlyxForProposal);
    IAlloyxVault vault = IAlloyxVault(_vaultAddress);
    vault.reinstateGovernance(convertMapToDepositAmount(alyxPermanentStakerMap[_proposalId], permanentStakersMap[_proposalId]));
  }

  /**
   * @notice Liquidate the vault, restricted to admin
   * @param _vaultAddress the vault to liquidate
   */
  function liquidate(address _vaultAddress) external onlyAdmin {
    IAlloyxVault vault = IAlloyxVault(_vaultAddress);
    vault.liquidate();
  }

  /**
   * @notice Accrue the protocol fee from all vaults, restricted to admin
   */
  function accrueAllProtocolFee() external onlyAdmin {
    address[] memory addresses = vaultAddresses.values();
    for (uint256 i = 0; i < addresses.length; i++) {
      IAlloyxVault vault = IAlloyxVault(addresses[i]);
      vault.accrueProtocolFee();
    }
  }

  /**
   * @notice Accrue the protocol fee from all vaults, restricted to admin
   * @param _vaultAddress the vault address to collect fee
   */
  function accrueProtocolFee(address _vaultAddress) external onlyAdmin {
    IAlloyxVault vault = IAlloyxVault(_vaultAddress);
    vault.accrueProtocolFee();
  }

  /**
   * @notice Withdraw the protocol fee from one vault, restricted to admin
   * @param _vaultAddress the vault address to collect fee
   */
  function withdrawProtocolFee(address _vaultAddress) external onlyAdmin {
    config.getTreasury().withdrawProtocolFee(_vaultAddress);
  }

  /**
   * @notice Migrate certain ERC20 to an address, restricted to admin
   * @param _tokenAddress the token address to migrate
   * @param _to the address to transfer tokens to
   */
  function migrateERC20(address _tokenAddress, address _to) external onlyAdmin {
    uint256 balance = IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
    IERC20Upgradeable(_tokenAddress).safeTransfer(_to, balance);
  }

  /**
   * @notice Convenient internal function to convert depositor amount and map to Struct array, internal
   * @param _map map of depositor address to amount
   * @param _depositors the address of depositors
   * @return array of DepositAmount struct
   */
  function convertMapToDepositAmount(mapping(address => uint256) storage _map, EnumerableSet.AddressSet storage _depositors) internal view returns (DepositAmount[] memory) {
    DepositAmount[] memory result = new DepositAmount[](_depositors.length());
    for (uint256 i = 0; i < _depositors.length(); i++) {
      result[i] = DepositAmount(_depositors.at(i), _map[_depositors.at(i)]);
    }
    return result;
  }

  /**
   * @notice Verify the validity of the components, by adding up the proportion to see if it exceeds 100%, internal
   * @param _components the components of this vault, including the address of the vault to invest
   */
  function verifyComponents(Component[] memory _components) internal pure {
    uint256 sumOfProportion = 0;
    for (uint256 i = 0; i < _components.length; i++) {
      sumOfProportion += _components[i].proportion;
    }
    require(sumOfProportion == 10000, "the sum of the proportions in given components not equal to 100%");
  }

  /**
   * @notice Transfer certain amount token of certain address to some other account, internal
   * @param _from the address to transfer from
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function _transferERC20From(address _from, address _tokenAddress, address _account, uint256 _amount) internal {
    IERC20Upgradeable(_tokenAddress).safeTransferFrom(_from, _account, _amount);
  }

  /**
   * @notice Transfer certain amount token of certain address to some other account, internal
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function _transferERC20(address _tokenAddress, address _account, uint256 _amount) internal {
    IERC20Upgradeable(_tokenAddress).safeTransfer(_account, _amount);
  }
}