// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './library/UtilLib.sol';

import './interfaces/IStaderConfig.sol';

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract StaderConfig is IStaderConfig, AccessControlUpgradeable {
    // staked ETH per node on beacon chain i.e. 32 ETH
    bytes32 public constant ETH_PER_NODE = keccak256('ETH_PER_NODE');
    //amount of ETH for pre-deposit on beacon chain i.e 1 ETH
    bytes32 public constant PRE_DEPOSIT_SIZE = keccak256('PRE_DEPOSIT_SIZE');
    //amount of ETH for full deposit on beacon chain i.e 31 ETH
    bytes32 public constant FULL_DEPOSIT_SIZE = keccak256('FULL_DEPOSIT_SIZE');
    // ETH to WEI ratio i.e 1e18
    bytes32 public constant DECIMALS = keccak256('DECIMALS');
    //Total fee bips
    bytes32 public constant TOTAL_FEE = keccak256('TOTAL_FEE');
    //maximum length of operator name string
    bytes32 public constant OPERATOR_MAX_NAME_LENGTH = keccak256('OPERATOR_MAX_NAME_LENGTH');

    bytes32 public constant SOCIALIZING_POOL_CYCLE_DURATION = keccak256('SOCIALIZING_POOL_CYCLE_DURATION');
    bytes32 public constant SOCIALIZING_POOL_OPT_IN_COOLING_PERIOD =
        keccak256('SOCIALIZING_POOL_OPT_IN_COOLING_PERIOD');
    bytes32 public constant REWARD_THRESHOLD = keccak256('REWARD_THRESHOLD');
    bytes32 public constant MIN_DEPOSIT_AMOUNT = keccak256('MIN_DEPOSIT_AMOUNT');
    bytes32 public constant MAX_DEPOSIT_AMOUNT = keccak256('MAX_DEPOSIT_AMOUNT');
    bytes32 public constant MIN_WITHDRAW_AMOUNT = keccak256('MIN_WITHDRAW_AMOUNT');
    bytes32 public constant MAX_WITHDRAW_AMOUNT = keccak256('MAX_WITHDRAW_AMOUNT');
    //minimum delay between user requesting withdraw and request finalization
    bytes32 public constant MIN_BLOCK_DELAY_TO_FINALIZE_WITHDRAW_REQUEST =
        keccak256('MIN_BLOCK_DELAY_TO_FINALIZE_WITHDRAW_REQUEST');
    bytes32 public constant WITHDRAWN_KEYS_BATCH_SIZE = keccak256('WITHDRAWN_KEYS_BATCH_SIZE');

    bytes32 public constant ADMIN = keccak256('ADMIN');
    bytes32 public constant STADER_TREASURY = keccak256('STADER_TREASURY');

    bytes32 public constant override POOL_UTILS = keccak256('POOL_UTILS');
    bytes32 public constant override POOL_SELECTOR = keccak256('POOL_SELECTOR');
    bytes32 public constant override SD_COLLATERAL = keccak256('SD_COLLATERAL');
    bytes32 public constant override OPERATOR_REWARD_COLLECTOR = keccak256('OPERATOR_REWARD_COLLECTOR');
    bytes32 public constant override VAULT_FACTORY = keccak256('VAULT_FACTORY');
    bytes32 public constant override STADER_ORACLE = keccak256('STADER_ORACLE');
    bytes32 public constant override AUCTION_CONTRACT = keccak256('AuctionContract');
    bytes32 public constant override PENALTY_CONTRACT = keccak256('PENALTY_CONTRACT');
    bytes32 public constant override PERMISSIONED_POOL = keccak256('PERMISSIONED_POOL');
    bytes32 public constant override STAKE_POOL_MANAGER = keccak256('STAKE_POOL_MANAGER');
    bytes32 public constant override ETH_DEPOSIT_CONTRACT = keccak256('ETH_DEPOSIT_CONTRACT');
    bytes32 public constant override PERMISSIONLESS_POOL = keccak256('PERMISSIONLESS_POOL');
    bytes32 public constant override USER_WITHDRAW_MANAGER = keccak256('USER_WITHDRAW_MANAGER');
    bytes32 public constant override STADER_INSURANCE_FUND = keccak256('STADER_INSURANCE_FUND');
    bytes32 public constant override PERMISSIONED_NODE_REGISTRY = keccak256('PERMISSIONED_NODE_REGISTRY');
    bytes32 public constant override PERMISSIONLESS_NODE_REGISTRY = keccak256('PERMISSIONLESS_NODE_REGISTRY');
    bytes32 public constant override PERMISSIONED_SOCIALIZING_POOL = keccak256('PERMISSIONED_SOCIALIZING_POOL');
    bytes32 public constant override PERMISSIONLESS_SOCIALIZING_POOL = keccak256('PERMISSIONLESS_SOCIALIZING_POOL');
    bytes32 public constant override NODE_EL_REWARD_VAULT_IMPLEMENTATION =
        keccak256('NODE_EL_REWARD_VAULT_IMPLEMENTATION');
    bytes32 public constant override VALIDATOR_WITHDRAWAL_VAULT_IMPLEMENTATION =
        keccak256('VALIDATOR_WITHDRAWAL_VAULT_IMPLEMENTATION');

    //POR Feed Proxy
    bytes32 public constant override ETH_BALANCE_POR_FEED = keccak256('ETH_BALANCE_POR_FEED');
    bytes32 public constant override ETHX_SUPPLY_POR_FEED = keccak256('ETHX_SUPPLY_POR_FEED');

    //Roles
    bytes32 public constant override MANAGER = keccak256('MANAGER');
    bytes32 public constant override OPERATOR = keccak256('OPERATOR');

    bytes32 public constant SD = keccak256('SD');
    bytes32 public constant ETHx = keccak256('ETHx');

    mapping(bytes32 => uint256) private constantsMap;
    mapping(bytes32 => uint256) private variablesMap;
    mapping(bytes32 => address) private accountsMap;
    mapping(bytes32 => address) private contractsMap;
    mapping(bytes32 => address) private tokensMap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _ethDepositContract) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        UtilLib.checkNonZeroAddress(_ethDepositContract);
        __AccessControl_init();
        setConstant(ETH_PER_NODE, 32 ether);
        setConstant(PRE_DEPOSIT_SIZE, 1 ether);
        setConstant(FULL_DEPOSIT_SIZE, 31 ether);
        setConstant(TOTAL_FEE, 10000);
        setConstant(DECIMALS, 1e18);
        setConstant(OPERATOR_MAX_NAME_LENGTH, 255);
        setVariable(MIN_DEPOSIT_AMOUNT, 1e14);
        setVariable(MAX_DEPOSIT_AMOUNT, 10000 ether);
        setVariable(MIN_WITHDRAW_AMOUNT, 1e14);
        setVariable(MAX_WITHDRAW_AMOUNT, 10000 ether);
        setVariable(WITHDRAWN_KEYS_BATCH_SIZE, 50);
        setVariable(MIN_BLOCK_DELAY_TO_FINALIZE_WITHDRAW_REQUEST, 600);
        setContract(ETH_DEPOSIT_CONTRACT, _ethDepositContract);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    //Variables Setters

    function updateSocializingPoolCycleDuration(uint256 _socializingPoolCycleDuration) external onlyRole(MANAGER) {
        setVariable(SOCIALIZING_POOL_CYCLE_DURATION, _socializingPoolCycleDuration);
    }

    function updateSocializingPoolOptInCoolingPeriod(uint256 _SocializePoolOptInCoolingPeriod)
        external
        onlyRole(MANAGER)
    {
        setVariable(SOCIALIZING_POOL_OPT_IN_COOLING_PERIOD, _SocializePoolOptInCoolingPeriod);
    }

    function updateRewardsThreshold(uint256 _rewardsThreshold) external onlyRole(MANAGER) {
        setVariable(REWARD_THRESHOLD, _rewardsThreshold);
    }

    /**
     * @dev update the minimum deposit amount
     * @param _minDepositAmount minimum deposit amount
     */
    function updateMinDepositAmount(uint256 _minDepositAmount) external onlyRole(MANAGER) {
        setVariable(MIN_DEPOSIT_AMOUNT, _minDepositAmount);
        verifyDepositAndWithdrawLimits();
    }

    /**
     * @dev update the maximum deposit amount
     * @param _maxDepositAmount maximum deposit amount
     */
    function updateMaxDepositAmount(uint256 _maxDepositAmount) external onlyRole(MANAGER) {
        setVariable(MAX_DEPOSIT_AMOUNT, _maxDepositAmount);
        verifyDepositAndWithdrawLimits();
    }

    /**
     * @dev update the minimum withdraw amount
     * @param _minWithdrawAmount minimum withdraw amount
     */
    function updateMinWithdrawAmount(uint256 _minWithdrawAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setVariable(MIN_WITHDRAW_AMOUNT, _minWithdrawAmount);
        verifyDepositAndWithdrawLimits();
    }

    /**
     * @dev update the maximum withdraw amount
     * @param _maxWithdrawAmount maximum withdraw amount
     */
    function updateMaxWithdrawAmount(uint256 _maxWithdrawAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setVariable(MAX_WITHDRAW_AMOUNT, _maxWithdrawAmount);
        verifyDepositAndWithdrawLimits();
    }

    function updateMinBlockDelayToFinalizeWithdrawRequest(uint256 _minBlockDelay)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        setVariable(MIN_BLOCK_DELAY_TO_FINALIZE_WITHDRAW_REQUEST, _minBlockDelay);
    }

    /**
     * @notice update the max number of withdrawn validator keys reported by oracle in single tx
     * @dev only `OPERATOR` can call
     * @param _withdrawnKeysBatchSize updated maximum withdrawn key limit in the oracle input
     */
    function updateWithdrawnKeysBatchSize(uint256 _withdrawnKeysBatchSize) external onlyRole(OPERATOR) {
        setVariable(WITHDRAWN_KEYS_BATCH_SIZE, _withdrawnKeysBatchSize);
    }

    //Accounts Setters

    function updateAdmin(address _admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldAdmin = accountsMap[ADMIN];

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        setAccount(ADMIN, _admin);

        _revokeRole(DEFAULT_ADMIN_ROLE, oldAdmin);
    }

    function updateStaderTreasury(address _staderTreasury) external onlyRole(MANAGER) {
        setAccount(STADER_TREASURY, _staderTreasury);
    }

    // Contracts Setters

    function updatePoolUtils(address _poolUtils) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(POOL_UTILS, _poolUtils);
    }

    function updatePoolSelector(address _poolSelector) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(POOL_SELECTOR, _poolSelector);
    }

    function updateSDCollateral(address _sdCollateral) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(SD_COLLATERAL, _sdCollateral);
    }

    function updateOperatorRewardsCollector(address _operatorRewardsCollector) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(OPERATOR_REWARD_COLLECTOR, _operatorRewardsCollector);
    }

    function updateVaultFactory(address _vaultFactory) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(VAULT_FACTORY, _vaultFactory);
    }

    function updateAuctionContract(address _auctionContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(AUCTION_CONTRACT, _auctionContract);
    }

    function updateStaderOracle(address _staderOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(STADER_ORACLE, _staderOracle);
    }

    function updatePenaltyContract(address _penaltyContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(PENALTY_CONTRACT, _penaltyContract);
    }

    function updatePermissionedPool(address _permissionedPool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(PERMISSIONED_POOL, _permissionedPool);
    }

    function updateStakePoolManager(address _stakePoolManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(STAKE_POOL_MANAGER, _stakePoolManager);
    }

    function updatePermissionlessPool(address _permissionlessPool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(PERMISSIONLESS_POOL, _permissionlessPool);
    }

    function updateUserWithdrawManager(address _userWithdrawManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(USER_WITHDRAW_MANAGER, _userWithdrawManager);
    }

    function updateStaderInsuranceFund(address _staderInsuranceFund) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(STADER_INSURANCE_FUND, _staderInsuranceFund);
    }

    function updatePermissionedNodeRegistry(address _permissionedNodeRegistry) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(PERMISSIONED_NODE_REGISTRY, _permissionedNodeRegistry);
    }

    function updatePermissionlessNodeRegistry(address _permissionlessNodeRegistry)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        setContract(PERMISSIONLESS_NODE_REGISTRY, _permissionlessNodeRegistry);
    }

    function updatePermissionedSocializingPool(address _permissionedSocializePool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        setContract(PERMISSIONED_SOCIALIZING_POOL, _permissionedSocializePool);
    }

    function updatePermissionlessSocializingPool(address _permissionlessSocializePool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        setContract(PERMISSIONLESS_SOCIALIZING_POOL, _permissionlessSocializePool);
    }

    function updateNodeELRewardImplementation(address _nodeELRewardVaultImpl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(NODE_EL_REWARD_VAULT_IMPLEMENTATION, _nodeELRewardVaultImpl);
    }

    function updateValidatorWithdrawalVaultImplementation(address _validatorWithdrawalVaultImpl)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        setContract(VALIDATOR_WITHDRAWAL_VAULT_IMPLEMENTATION, _validatorWithdrawalVaultImpl);
    }

    function updateETHBalancePORFeedProxy(address _ethBalanceProxy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(ETH_BALANCE_POR_FEED, _ethBalanceProxy);
    }

    function updateETHXSupplyPORFeedProxy(address _ethXSupplyProxy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setContract(ETHX_SUPPLY_POR_FEED, _ethXSupplyProxy);
    }

    function updateStaderToken(address _staderToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setToken(SD, _staderToken);
    }

    function updateETHxToken(address _ethX) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setToken(ETHx, _ethX);
    }

    //Constants Getters

    function getStakedEthPerNode() external view override returns (uint256) {
        return constantsMap[ETH_PER_NODE];
    }

    function getPreDepositSize() external view override returns (uint256) {
        return constantsMap[PRE_DEPOSIT_SIZE];
    }

    function getFullDepositSize() external view override returns (uint256) {
        return constantsMap[FULL_DEPOSIT_SIZE];
    }

    function getDecimals() external view override returns (uint256) {
        return constantsMap[DECIMALS];
    }

    function getTotalFee() external view override returns (uint256) {
        return constantsMap[TOTAL_FEE];
    }

    function getOperatorMaxNameLength() external view override returns (uint256) {
        return constantsMap[OPERATOR_MAX_NAME_LENGTH];
    }

    //Variables Getters

    function getSocializingPoolCycleDuration() external view override returns (uint256) {
        return variablesMap[SOCIALIZING_POOL_CYCLE_DURATION];
    }

    function getSocializingPoolOptInCoolingPeriod() external view override returns (uint256) {
        return variablesMap[SOCIALIZING_POOL_OPT_IN_COOLING_PERIOD];
    }

    function getRewardsThreshold() external view override returns (uint256) {
        return variablesMap[REWARD_THRESHOLD];
    }

    function getMinDepositAmount() external view override returns (uint256) {
        return variablesMap[MIN_DEPOSIT_AMOUNT];
    }

    function getMaxDepositAmount() external view override returns (uint256) {
        return variablesMap[MAX_DEPOSIT_AMOUNT];
    }

    function getMinWithdrawAmount() external view override returns (uint256) {
        return variablesMap[MIN_WITHDRAW_AMOUNT];
    }

    function getMaxWithdrawAmount() external view override returns (uint256) {
        return variablesMap[MAX_WITHDRAW_AMOUNT];
    }

    function getMinBlockDelayToFinalizeWithdrawRequest() external view override returns (uint256) {
        return variablesMap[MIN_BLOCK_DELAY_TO_FINALIZE_WITHDRAW_REQUEST];
    }

    function getWithdrawnKeyBatchSize() external view override returns (uint256) {
        return variablesMap[WITHDRAWN_KEYS_BATCH_SIZE];
    }

    //Account Getters

    function getAdmin() external view returns (address) {
        return accountsMap[ADMIN];
    }

    function getStaderTreasury() external view override returns (address) {
        return accountsMap[STADER_TREASURY];
    }

    //Contracts Getters

    function getPoolUtils() external view override returns (address) {
        return contractsMap[POOL_UTILS];
    }

    function getPoolSelector() external view override returns (address) {
        return contractsMap[POOL_SELECTOR];
    }

    function getSDCollateral() external view override returns (address) {
        return contractsMap[SD_COLLATERAL];
    }

    function getOperatorRewardsCollector() external view override returns (address) {
        return contractsMap[OPERATOR_REWARD_COLLECTOR];
    }

    function getVaultFactory() external view override returns (address) {
        return contractsMap[VAULT_FACTORY];
    }

    function getStaderOracle() external view override returns (address) {
        return contractsMap[STADER_ORACLE];
    }

    function getAuctionContract() external view override returns (address) {
        return contractsMap[AUCTION_CONTRACT];
    }

    function getPenaltyContract() external view override returns (address) {
        return contractsMap[PENALTY_CONTRACT];
    }

    function getPermissionedPool() external view override returns (address) {
        return contractsMap[PERMISSIONED_POOL];
    }

    function getStakePoolManager() external view override returns (address) {
        return contractsMap[STAKE_POOL_MANAGER];
    }

    function getETHDepositContract() external view override returns (address) {
        return contractsMap[ETH_DEPOSIT_CONTRACT];
    }

    function getPermissionlessPool() external view override returns (address) {
        return contractsMap[PERMISSIONLESS_POOL];
    }

    function getUserWithdrawManager() external view override returns (address) {
        return contractsMap[USER_WITHDRAW_MANAGER];
    }

    function getStaderInsuranceFund() external view override returns (address) {
        return contractsMap[STADER_INSURANCE_FUND];
    }

    function getPermissionedNodeRegistry() external view override returns (address) {
        return contractsMap[PERMISSIONED_NODE_REGISTRY];
    }

    function getPermissionlessNodeRegistry() external view override returns (address) {
        return contractsMap[PERMISSIONLESS_NODE_REGISTRY];
    }

    function getPermissionedSocializingPool() external view override returns (address) {
        return contractsMap[PERMISSIONED_SOCIALIZING_POOL];
    }

    function getPermissionlessSocializingPool() external view override returns (address) {
        return contractsMap[PERMISSIONLESS_SOCIALIZING_POOL];
    }

    function getNodeELRewardVaultImplementation() external view override returns (address) {
        return contractsMap[NODE_EL_REWARD_VAULT_IMPLEMENTATION];
    }

    function getValidatorWithdrawalVaultImplementation() external view override returns (address) {
        return contractsMap[VALIDATOR_WITHDRAWAL_VAULT_IMPLEMENTATION];
    }

    //POR Feed Proxy Getters
    function getETHBalancePORFeedProxy() external view override returns (address) {
        return contractsMap[ETH_BALANCE_POR_FEED];
    }

    function getETHXSupplyPORFeedProxy() external view override returns (address) {
        return contractsMap[ETHX_SUPPLY_POR_FEED];
    }

    //Token Getters

    function getStaderToken() external view override returns (address) {
        return tokensMap[SD];
    }

    function getETHxToken() external view returns (address) {
        return tokensMap[ETHx];
    }

    // SETTER HELPERS
    function setConstant(bytes32 key, uint256 val) internal {
        constantsMap[key] = val;
        emit SetConstant(key, val);
    }

    function setVariable(bytes32 key, uint256 val) internal {
        variablesMap[key] = val;
        emit SetConstant(key, val);
    }

    function setAccount(bytes32 key, address val) internal {
        UtilLib.checkNonZeroAddress(val);
        accountsMap[key] = val;
        emit SetAccount(key, val);
    }

    function setContract(bytes32 key, address val) internal {
        UtilLib.checkNonZeroAddress(val);
        contractsMap[key] = val;
        emit SetContract(key, val);
    }

    function setToken(bytes32 key, address val) internal {
        UtilLib.checkNonZeroAddress(val);
        tokensMap[key] = val;
        emit SetToken(key, val);
    }

    //only stader protocol contract check
    function onlyStaderContract(address _addr, bytes32 _contractName) external view returns (bool) {
        return (_addr == contractsMap[_contractName]);
    }

    function onlyManagerRole(address account) external view override returns (bool) {
        return hasRole(MANAGER, account);
    }

    function onlyOperatorRole(address account) external view override returns (bool) {
        return hasRole(OPERATOR, account);
    }

    function verifyDepositAndWithdrawLimits() internal view {
        if (
            !(variablesMap[MIN_DEPOSIT_AMOUNT] != 0 &&
                variablesMap[MIN_WITHDRAW_AMOUNT] != 0 &&
                variablesMap[MIN_DEPOSIT_AMOUNT] <= variablesMap[MAX_DEPOSIT_AMOUNT] &&
                variablesMap[MIN_WITHDRAW_AMOUNT] <= variablesMap[MAX_WITHDRAW_AMOUNT] &&
                variablesMap[MIN_WITHDRAW_AMOUNT] <= variablesMap[MIN_DEPOSIT_AMOUNT] &&
                variablesMap[MAX_WITHDRAW_AMOUNT] >= variablesMap[MAX_DEPOSIT_AMOUNT])
        ) {
            revert InvalidLimits();
        }
    }
}