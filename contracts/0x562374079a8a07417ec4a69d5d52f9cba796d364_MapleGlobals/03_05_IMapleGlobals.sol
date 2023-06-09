// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { INonTransparentProxied } from "../../modules/non-transparent-proxy/contracts/NonTransparentProxied.sol";

interface IMapleGlobals is INonTransparentProxied {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   A virtualized first mint that acts as as offset to `totalAssets` and `totalSupply`.
     *  @param asset_         The address of the pool asset.
     *  @param bootstrapMint_ The amount of shares that will offset `totalAssets` and `totalSupply`.
     */
    event BootstrapMintSet(address indexed asset_, uint256 bootstrapMint_);

    /**
     *  @dev   A time locked call has been scheduled.
     *  @param caller_     The address of the function caller.
     *  @param contract_   The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param dataHash_   The hash of the parameters to pass to the function.
     *  @param timestamp_  The timestamp of the schedule.
     */
    event CallScheduled(
        address indexed caller_,
        address indexed contract_,
        bytes32 indexed functionId_,
        bytes32         dataHash_,
        uint256         timestamp_
    );

    /**
     *  @dev   A time locked call has been unscheduled.
     *  @param caller_     The address of the function caller.
     *  @param contract_   The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param dataHash_   The hash of the parameters to pass to the function.
     *  @param timestamp_  The timestamp of the schedule.
     */
    event CallUnscheduled(
        address indexed caller_,
        address indexed contract_,
        bytes32 indexed functionId_,
        bytes32         dataHash_,
        uint256         timestamp_
    );

    /**
     *  @dev   An account has been allowed/disallowed from deploying an instance from a particular factory.
     *  @param factory_       The address of the factory.
     *  @param account_       The address of the account.
     *  @param canDeployFrom_ Whether the account can deploy from the factory.
     */
    event CanDeployFromSet(address indexed factory_, address indexed account_, bool canDeployFrom_);

    /**
     *  @dev   The paused state for a given protocol contract was set.
     *  @param caller_         The address of the security admin or governor that performed the action.
     *  @param contract_       The address of a contract in the protocol.
     *  @param contractPaused_ Whether the contract is uniquely paused.
     */
    event ContractPauseSet(address indexed caller_, address indexed contract_, bool contractPaused_);

    /**
     *  @dev   The default parameters for the time lock has been set.
     *  @param previousDelay_    The previous required delay.
     *  @param currentDelay_     The newly set required delay.
     *  @param previousDuration_ The previous required duration.
     *  @param currentDuration_  The newly set required duration.
     */
    event DefaultTimelockParametersSet(uint256 previousDelay_, uint256 currentDelay_, uint256 previousDuration_, uint256 currentDuration_);

    /**
     *  @dev   The paused state for a function of a given protocol contract was set.
     *  @param caller_           The address of the security admin or governor that performed the action.
     *  @param contract_         The address of a contract in the protocol.
     *  @param sig_              The function signature within the contract.
     *  @param functionUnpaused_ Whether the contract's function is uniquely unpaused.
     */
    event FunctionUnpauseSet(address indexed caller_, address indexed contract_, bytes4 indexed sig_, bool functionUnpaused_);

    /**
     *  @dev   The governorship has been accepted.
     *  @param previousGovernor_ The previous governor.
     *  @param currentGovernor_  The new governor.
     */
    event GovernorshipAccepted(address indexed previousGovernor_, address indexed currentGovernor_);

    /**
     *  @dev   The price for an asset has been set.
     *  @param asset_ The address of the asset.
     *  @param price_ The manually set price of the asset.
     */
    event ManualOverridePriceSet(address indexed asset_, uint256 price_);

    /**
     *  @dev   The address for the Maple treasury has been set.
     *  @param previousMapleTreasury_ The previous treasury.
     *  @param currentMapleTreasury_  The new treasury.
     */
    event MapleTreasurySet(address indexed previousMapleTreasury_, address indexed currentMapleTreasury_);

    /**
     *  @dev   The max liquidation percent for the given pool manager has been set.
     *  @param poolManager_                The address of the pool manager.
     *  @param maxCoverLiquidationPercent_ The new value for the cover liquidation percent.
     */
    event MaxCoverLiquidationPercentSet(address indexed poolManager_, uint256 maxCoverLiquidationPercent_);

    /**
     *  @dev   The migration admin has been set.
     *  @param previousMigrationAdmin_ The previous migration admin.
     *  @param nextMigrationAdmin_     The new migration admin.
     */
    event MigrationAdminSet(address indexed previousMigrationAdmin_, address indexed nextMigrationAdmin_);

    /**
     *  @dev   The minimum cover amount for the given pool manager has been set.
     *  @param poolManager_    The address of the pool manager.
     *  @param minCoverAmount_ The new value for the minimum cover amount.
     */
    event MinCoverAmountSet(address indexed poolManager_, uint256 minCoverAmount_);

    /**
     *  @dev   The pending governor has been set.
     *  @param pendingGovernor_ The new pending governor.
     */
    event PendingGovernorSet(address indexed pendingGovernor_);

    /**
     *  @dev   The platform management fee rate for the given pool manager has been set.
     *  @param poolManager_               The address of the pool manager.
     *  @param platformManagementFeeRate_ The new value for the platform management fee rate.
     */
    event PlatformManagementFeeRateSet(address indexed poolManager_, uint256 platformManagementFeeRate_);

    /**
     *  @dev   The platform origination fee rate for the given pool manager has been set.
     *  @param poolManager_                The address of the pool manager.
     *  @param platformOriginationFeeRate_ The new value for the origination fee rate.
     */
    event PlatformOriginationFeeRateSet(address indexed poolManager_, uint256 platformOriginationFeeRate_);

    /**
     *  @dev   The platform service fee rate for the given pool manager has been set.
     *  @param poolManager_            The address of the pool manager.
     *  @param platformServiceFeeRate_ The new value for the platform service fee rate.
     */
    event PlatformServiceFeeRateSet(address indexed poolManager_, uint256 platformServiceFeeRate_);

    /**
     *  @dev   The pool manager was activated.
     *  @param poolManager_  The address of the pool manager.
     *  @param poolDelegate_ The address of the pool delegate.
     */
    event PoolManagerActivated(address indexed poolManager_, address indexed poolDelegate_);

    /**
     *  @dev   The ownership of the pool manager was transferred.
     *  @param fromPoolDelegate_ The address of the previous pool delegate.
     *  @param toPoolDelegate_   The address of the new pool delegate.
     *  @param poolManager_      The address of the pool manager.
     */
    event PoolManagerOwnershipTransferred(address indexed fromPoolDelegate_, address indexed toPoolDelegate_, address indexed poolManager_);

    /**
     *  @dev   The oracle for an asset has been set.
     *  @param asset_  The address of the asset.
     *  @param oracle_ The address of the oracle.
     */
    event PriceOracleSet(address indexed asset_, address indexed oracle_);

    /**
     *  @dev   The protocol pause was set to a new state.
     *  @param caller_         The address of the security admin or governor that performed the action.
     *  @param protocolPaused_ The protocol paused state.
     */
    event ProtocolPauseSet(address indexed caller_, bool protocolPaused_);

    /**
     *  @dev   The security admin was set.
     *  @param previousSecurityAdmin_ The address of the previous security admin.
     *  @param currentSecurityAdmin_  The address of the new security admin.
     */
    event SecurityAdminSet(address indexed previousSecurityAdmin_, address indexed currentSecurityAdmin_);

    /**
     *  @dev   A new timelock window was set.
     *  @param contract_   The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param delay_      The delay of the timelock window.
     *  @param duration_   The duration of the timelock window.
     */
    event TimelockWindowSet(address indexed contract_, bytes32 indexed functionId_, uint128 delay_, uint128 duration_);

    /**
     *  @dev   A valid borrower was set.
     *  @param borrower_ The address of the borrower.
     *  @param isValid_  The validity of the borrower.
     */
    event ValidBorrowerSet(address indexed borrower_, bool isValid_);

    /**
     *  @dev   A valid asset was set.
     *  @param collateralAsset_ The address of the collateral asset.
     *  @param isValid_         The validity of the collateral asset.
     */
    event ValidCollateralAssetSet(address indexed collateralAsset_, bool isValid_);

    /**
     *  @dev   A valid instance was set.
     *  @param instanceKey_ The key of the instance.
     *  @param instance_    The address of the instance.
     *  @param isValid_     The validity of the instance.
     */
    event ValidInstanceSet(bytes32 indexed instanceKey_, address indexed instance_, bool isValid_);

    /**
     *  @dev   A valid asset was set.
     *  @param poolAsset_ The address of the asset.
     *  @param isValid_   The validity of the asset.
     */
    event ValidPoolAssetSet(address indexed poolAsset_, bool isValid_);

    /**
     *  @dev   A valid pool delegate was set.
     *  @param account_ The address the account.
     *  @param isValid_ The validity of the asset.
     */
    event ValidPoolDelegateSet(address indexed account_, bool isValid_);

    /**
     *  @dev   A valid pool deployer was set.
     *  @param poolDeployer_ The address the account.
     *  @param isValid_      The validity of the asset.
     */
    event ValidPoolDeployerSet(address indexed poolDeployer_, bool isValid_);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Gets the virtualized first mint that acts as as offset to `totalAssets` and `totalSupply` for a given pool asset.
     *  @param  asset_         The address of the pool asset to query
     *  @return bootstrapMint_ The amount of shares that will offset `totalAssets` and `totalSupply`.
     */
    function bootstrapMint(address asset_) external view returns (uint256 bootstrapMint_);

    /**
     *  @dev    Gets whether a caller account can deploy from the factory calling this function.
     *  @param  caller_    The address of the account calling the factory.
     *  @return canDeploy_ Whether the account can deploy from the factory.
     */
    function canDeploy(address caller_) external view returns (bool canDeploy_);

    /**
     *  @dev    Gets whether a caller account can deploy from a factory.
     *  @param  factory_       The address of the factory.
     *  @param  caller_        The address of the account calling the factory.
     *  @return canDeployFrom_ Whether the account can deploy from the factory.
     */
    function canDeployFrom(address factory_, address caller_) external view returns (bool canDeployFrom_);

    /**
     *  @dev    Gets the default timelock parameters.
     *  @return delay    The default timelock delay.
     *  @return duration The default timelock duration.
     */
    function defaultTimelockParameters() external view returns (uint128 delay, uint128 duration);

    /**
     *  @dev    Gets the latest price for an asset.
     *  @param  asset_       The address of the asset to query.
     *  @return latestPrice_ The latest price for the asset.
     */
    function getLatestPrice(address asset_) external view returns (uint256 latestPrice_);

    /**
     *  @dev    Gets governor address.
     *  @return governor_ The address of the governor.
     */
    function governor() external view returns (address governor_);

    /**
     *  @dev    Gets the validity of a borrower.
     *  @param  borrower_   The address of the borrower to query.
     *  @return isBorrower_ A boolean indicating the validity of the borrower.
     */
    function isBorrower(address borrower_) external view returns (bool isBorrower_);

    /**
     *  @dev    Gets the validity of a collateral asset.
     *  @param  collateralAsset_   The address of the collateralAsset to query.
     *  @return isCollateralAsset_ A boolean indicating the validity of the collateral asset.
     */
    function isCollateralAsset(address collateralAsset_) external view returns (bool isCollateralAsset_);

    /**
     *  @dev    Gets whether a contract is uniquely paused.
     *  @param  contract_         The address of a contract in the protocol.
     *  @return isContractPaused_ Whether the contract is uniquely paused.
     */
    function isContractPaused(address contract_) external view returns (bool isContractPaused_);

    /**
     *  @dev    Gets the validity of a factory.
     *  @param  factoryId_ The address of the factory to query.
     *  @param  factory_   The address of the factory to query.
     *  @return isFactory_ A boolean indicating the validity of the factory.
     */
    function isFactory(bytes32 factoryId_, address factory_) external view returns (bool isFactory_);

    /**
     *  @dev    Gets whether a calling contract's function is paused.
     *  @param  sig_              The function signature within the contract.
     *  @return isFunctionPaused_ Whether the contract's function is paused.
     */
    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    /**
     *  @dev    Gets whether a contract's function is paused.
     *  @param  contract_         The address of a contract in the protocol.
     *  @param  sig_              The function signature within the contract.
     *  @return isFunctionPaused_ Whether the contract's function is paused.
     */
    function isFunctionPaused(address contract_, bytes4 sig_) external view returns (bool isFunctionPaused_);

    /**
     *  @dev    Gets whether a contract's function is uniquely unpaused. A false does not imply it is paused.
     *  @param  contract_           The address of a contract in the protocol.
     *  @param  sig_                The function signature within the contract.
     *  @return isFunctionUnpaused_ Whether the contract's function is uniquely unpaused.
     */
    function isFunctionUnpaused(address contract_, bytes4 sig_) external view returns (bool isFunctionUnpaused_);

    /**
     *  @dev    Gets wether an instance is of some instance key.
     *  @param  instanceKey_ The key of some instance type.
     *  @param  instance_    The address of an instance.
     *  @return isInstance_  A boolean indicating whether the instance is of the instance key.
     */
    function isInstanceOf(bytes32 instanceKey_, address instance_) external view returns (bool isInstance_);

    /**
     *  @dev    Gets the validity of a pool asset.
     *  @param  poolAsset_   The address of the poolAsset to query.
     *  @return isPoolAsset_ A boolean indicating the validity of the pool asset.
     */
    function isPoolAsset(address poolAsset_) external view returns (bool isPoolAsset_);

    /**
     *  @dev    Gets the validity of a pool delegate.
     *  @param  account_        The address of the account to query.
     *  @return isPoolDelegate_ A boolean indicating the validity of the pool delegate.
     */
    function isPoolDelegate(address account_) external view returns (bool isPoolDelegate_);

    /**
     *  @dev    Gets the validity of a pool deployer.
     *  @param  account_        The address of the account to query.
     *  @return isPoolDeployer_ A boolean indicating the validity of the pool deployer.
     */
    function isPoolDeployer(address account_) external view returns (bool isPoolDeployer_);

    /**
     *  @dev    Gets the manual override price for an asset.
     *  @param  asset_               The address of the asset to query.
     *  @return manualOverridePrice_ The manual override price for the asset.
     */
    function manualOverridePrice(address asset_) external view returns (uint256 manualOverridePrice_);

    /**
     *  @dev    Gets maple treasury address.
     *  @return mapleTreasury_ The address of the maple treasury.
     */
    function mapleTreasury() external view returns (address mapleTreasury_);

    /**
     *  @dev    Gets the maximum cover liquidation percent for a given pool manager.
     *  @param  poolManager_                The address of the pool manager to query.
     *  @return maxCoverLiquidationPercent_ The maximum cover liquidation percent.
     */
    function maxCoverLiquidationPercent(address poolManager_) external view returns (uint256 maxCoverLiquidationPercent_);

    /**
     *  @dev    Gets migration admin address.
     *  @return migrationAdmin_ The address of the migration admin.
     */
    function migrationAdmin() external view returns (address migrationAdmin_);

    /**
     *  @dev    Gets the minimum cover amount for a given pool manager.
     *  @param  poolManager_    The address of the pool manager to query.
     *  @return minCoverAmount_ The minimum cover amount.
     */
    function minCoverAmount(address poolManager_) external view returns (uint256 minCoverAmount_);

    /**
     *  @dev    Gets the address of the oracle for the given asset.
     *  @param  asset_  The address of the asset to query.
     *  @return oracle_ The address of the oracle.
     */
    function oracleFor(address asset_) external view returns (address oracle_);

    /**
     *  @dev    Gets the address of the owner pool manager.
     *  @param  account_     The address of the account to query.
     *  @return poolManager_ The address of the pool manager.
     */
    function ownedPoolManager(address account_) external view returns (address poolManager_);

    /**
     *  @dev    Gets the pending governor address.
     *  @return pendingGovernor_ The address of the pending governor.
     */
    function pendingGovernor() external view returns (address pendingGovernor_);

    /**
     *  @dev    Gets the platform management fee rate for a given pool manager.
     *  @param  poolManager_               The address of the pool manager to query.
     *  @return platformManagementFeeRate_ The platform management fee rate.
     */
    function platformManagementFeeRate(address poolManager_) external view returns (uint256 platformManagementFeeRate_);

    /**
     *  @dev    Gets the platform origination fee rate for a given pool manager.
     *  @param  poolManager_                The address of the pool manager to query.
     *  @return platformOriginationFeeRate_ The platform origination fee rate.
     */
    function platformOriginationFeeRate(address poolManager_) external view returns (uint256 platformOriginationFeeRate_);

    /**
     *  @dev    Gets the platform service fee rate for a given pool manager.
     *  @param  poolManager_            The address of the pool manager to query.
     *  @return platformServiceFeeRate_ The platform service fee rate.
     */
    function platformServiceFeeRate(address poolManager_) external view returns (uint256 platformServiceFeeRate_);

    /**
     *  @dev    Gets pool delegate address information.
     *  @param  poolDelegate_    The address of the pool delegate to query.
     *  @return ownedPoolManager The address of the pool manager owned by the pool delegate.
     *  @return isPoolDelegate   A boolean indication weather or not the address passed is a current pool delegate.
     */
    function poolDelegates(address poolDelegate_) external view returns (address ownedPoolManager, bool isPoolDelegate);

    /**
     *  @dev    Gets the status of the protocol pause.
     *  @return protocolPaused_ A boolean indicating the status of the protocol pause.
     */
    function protocolPaused() external view returns (bool protocolPaused_);

    /**
     *  @dev    Gets the schedule calls for the parameters.
     *  @param  caller_     The address of the caller.
     *  @param  contract_   The address of the contract.
     *  @param  functionId_ The id function to call.
     *  @return timestamp   The timestamp of the next scheduled call.
     *  @return dataHash    The hash of data fot the scheduled call.
     */
    function scheduledCalls(
        address caller_,
        address contract_,
        bytes32 functionId_
    ) external view returns (uint256 timestamp, bytes32 dataHash);

    /**
     *  @dev    Gets security admin address.
     *  @return securityAdmin_ The address of the security admin.
     */
    function securityAdmin() external view returns (address securityAdmin_);

    /**
     *  @dev    Gets the time lock parameters for a given contract and function.
     *  @param  contract_   The address of the contract to query.
     *  @param  functionId_ The id of the function to query.
     *  @return delay       The time lock delay.
     *  @return duration    The time lock duration.
     */
    function timelockParametersOf(address contract_, bytes32 functionId_) external view returns (uint128 delay, uint128 duration);

    /**************************************************************************************************************************************/
    /*** Governor Transfer Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev Accepts the governorship if the caller is the `pendingGovernor`.
     */
    function acceptGovernor() external;

    /**
     *  @dev   Sets the pending governor.
     *  @param pendingGovernor_ The new pending governor.
     */
    function setPendingGovernor(address pendingGovernor_) external;

    /**************************************************************************************************************************************/
    /*** Global Setters                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Activates the pool manager.
     *  @param poolManager_ The address of the pool manager to activate.
     */
    function activatePoolManager(address poolManager_) external;

    /**
     *  @dev   Sets the virtualized first mint that acts as as offset to `totalAssets` and `totalSupply`
     *         to prevent an MEV-exploit vector against the first pool depositor.
     *  @param asset_         The address of the pool asset.
     *  @param bootstrapMint_ The amount of shares that will offset `totalAssets` and `totalSupply`.
     */
    function setBootstrapMint(address asset_, uint256 bootstrapMint_) external;

    /**
     *  @dev   Sets the default time lock parameters.
     *  @param defaultTimelockDelay_    The default time lock delay.
     *  @param defaultTimelockDuration_ The default time lock duration.
     */
    function setDefaultTimelockParameters(uint128 defaultTimelockDelay_, uint128 defaultTimelockDuration_) external;

    /**
     *  @dev   Sets the address of the Maple treasury.
     *  @param mapleTreasury_ The address of the Maple treasury.
     */
    function setMapleTreasury(address mapleTreasury_) external;

    /**
     *  @dev   Sets the address of the migration admin.
     *  @param migrationAdmin_ The address of the migration admin.
     */
    function setMigrationAdmin(address migrationAdmin_) external;

    /**
     *  @dev   Sets the price oracle for the given asset.
     *  @param asset_       The address of the asset to set the oracle for.
     *  @param priceOracle_ The address of the oracle to set for the asset.
     */
    function setPriceOracle(address asset_, address priceOracle_) external;

    /**
     *  @dev   Sets the address of the security admin.
     *  @param securityAdmin_ The address of the security admin.
     */
    function setSecurityAdmin(address securityAdmin_) external;

    /**************************************************************************************************************************************/
    /*** Boolean Setters                                                                                                                ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Sets whether a contract is uniquely paused.
     *  @param contract_       The address of a contract in the protocol.
     *  @param contractPaused_ Whether the contract is uniquely paused.
     */
    function setContractPause(address contract_, bool contractPaused_) external;

    /**
     *  @dev   Sets whether a contract's function is uniquely unpaused. A false does not imply it is paused.
     *  @param contract_         The address of a contract in the protocol.
     *  @param sig_              The function signature within the contract.
     *  @param functionUnpaused_ Whether the contract's function is uniquely unpaused.
     */
    function setFunctionUnpause(address contract_, bytes4 sig_, bool functionUnpaused_) external;

    /**
     *  @dev   Sets the protocol pause.
     *  @param protocolPaused_ A boolean indicating the status of the protocol pause.
     */
    function setProtocolPause(bool protocolPaused_) external;

    /**************************************************************************************************************************************/
    /*** Allowlist Setters                                                                                                              ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Sets whether an account can deploying an instance from a particular factory.
     *  @param factory_       The address of the factory.
     *  @param account_       The address of the account.
     *  @param canDeployFrom_ Whether the account can deploy or not from the factory.
     */
    function setCanDeployFrom(address factory_, address account_, bool canDeployFrom_) external;

    /**
     *  @dev   Sets the validity of the borrower.
     *  @param borrower_ The address of the borrower to set the validity for.
     *  @param isValid_  A boolean indicating the validity of the borrower.
     */
    function setValidBorrower(address borrower_, bool isValid_) external;

    /**
     *  @dev   Sets the validity of a collateral asset.
     *  @param collateralAsset_ The address of the collateral asset to set the validity for.
     *  @param isValid_         A boolean indicating the validity of the collateral asset.
     */
    function setValidCollateralAsset(address collateralAsset_, bool isValid_) external;

    /**
     *  @dev   Sets the validity of the instance.
     *  @param instanceKey_ The key of the instance to set the validity for.
     *  @param instance_    The address of the instance to set the validity for.
     *  @param isValid_     Boolean indicating the validity of the instance.
     */
    function setValidInstanceOf(bytes32 instanceKey_, address instance_, bool isValid_) external;

    /**
     *  @dev   Sets the validity of the pool asset.
     *  @param poolAsset_ The address of the pool asset to set the validity for.
     *  @param isValid_   A boolean indicating the validity of the pool asset.
     */
    function setValidPoolAsset(address poolAsset_, bool isValid_) external;

    /**
     *  @dev   Sets the validity of the pool delegate.
     *  @param poolDelegate_ The address of the pool delegate to set the validity for.
     *  @param isValid_      A boolean indicating the validity of the pool delegate.
     */
    function setValidPoolDelegate(address poolDelegate_, bool isValid_) external;

    /**
     *  @dev   Sets the validity of the pool deployer.
     *  @param account_        The address of the pool deployer to set the validity for.
     *  @param isPoolDeployer_ A boolean indicating the validity of the pool deployer.
     */
    function setValidPoolDeployer(address account_, bool isPoolDeployer_) external;

    /**************************************************************************************************************************************/
    /*** Price Setters                                                                                                                  ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Sets the manual override price of the asset.
     *  @param asset_ The address of the asset to set the price for.
     *  @param price_ The price of the asset.
     */
    function setManualOverridePrice(address asset_, uint256 price_) external;

    /**************************************************************************************************************************************/
    /*** Cover Setters                                                                                                                  ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Sets the maximum cover liquidation percent for the given pool manager.
     *  @param poolManager_                The address of the pool manager to set the maximum cover liquidation percent for.
     *  @param maxCoverLiquidationPercent_ The maximum cover liquidation percent.
     */
    function setMaxCoverLiquidationPercent(address poolManager_, uint256 maxCoverLiquidationPercent_) external;

    /**
     *  @dev   Sets the minimum cover amount for the given pool manager.
     *  @param poolManager_    The address of the pool manager to set the minimum cover amount  for.
     *  @param minCoverAmount_ The minimum cover amount.
     */
    function setMinCoverAmount(address poolManager_, uint256 minCoverAmount_) external;

    /**************************************************************************************************************************************/
    /*** Fee Setters                                                                                                                    ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Sets the platform management fee rate for the given pool manager.
     *  @param poolManager_               The address of the pool manager to set the fee for.
     *  @param platformManagementFeeRate_ The platform management fee rate.
     */
    function setPlatformManagementFeeRate(address poolManager_, uint256 platformManagementFeeRate_) external;

    /**
     *  @dev   Sets the platform origination fee rate for the given pool manager.
     *  @param poolManager_                The address of the pool manager to set the fee for.
     *  @param platformOriginationFeeRate_ The platform origination fee rate.
     */
    function setPlatformOriginationFeeRate(address poolManager_, uint256 platformOriginationFeeRate_) external;

    /**
     *  @dev   Sets the platform service fee rate for the given pool manager.
     *  @param poolManager_            The address of the pool manager to set the fee for.
     *  @param platformServiceFeeRate_ The platform service fee rate.
     */
    function setPlatformServiceFeeRate(address poolManager_, uint256 platformServiceFeeRate_) external;

    /**************************************************************************************************************************************/
    /*** Contact Control Functions                                                                                                      ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Sets the timelock for the given contract.
     *  @param contract_   The address of the contract to add.
     *  @param functionId_ The id of the function.
     *  @param delay_      The delay for the timelock window.
     *  @param duration_   The duration for the timelock window.
     */
    function setTimelockWindow(address contract_, bytes32 functionId_, uint128 delay_, uint128 duration_) external;

    /**
     *  @dev   Sets the timelock for the many function ids in a contract.
     *  @param contract_    The address of the contract to add.
     *  @param functionIds_ The ids of the functions.
     *  @param delays_      The delays for the timelock window.
     *  @param durations_   The durations for the timelock window.
     */
    function setTimelockWindows(
        address            contract_,
        bytes32[] calldata functionIds_,
        uint128[] calldata delays_,
        uint128[] calldata durations_
    ) external;

    /**
     *  @dev   Transfer the ownership of the pool manager.
     *  @param fromPoolDelegate_ The address of the pool delegate to transfer ownership from.
     *  @param toPoolDelegate_   The address of the pool delegate to transfer ownership to.
     */
    function transferOwnedPoolManager(address fromPoolDelegate_, address toPoolDelegate_) external;

    /**************************************************************************************************************************************/
    /*** Schedule Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Checks if a call is scheduled.
     *  @param  caller_     The contract to execute the call on.
     *  @param  contract_   The contract to execute the call on.
     *  @param  functionId_ The id of the function to execute.
     *  @param  callData_   The of the parameters to pass to the function.
     *  @return isValid_    True if the call is scheduled, false otherwise.
     */
    function isValidScheduledCall(
        address          caller_,
        address          contract_,
        bytes32          functionId_,
        bytes   calldata callData_
    ) external view returns (bool isValid_);

    /**
     *  @dev   Schedules a call to be executed.
     *  @param contract_   The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param callData_   The of the parameters to pass to the function.
     */
    function scheduleCall(address contract_, bytes32 functionId_, bytes calldata callData_) external;

    /**
     *  @dev   Unschedules a call to be executed.
     *  @param caller_     The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param callData_   The of the parameters to pass to the function.
     */
    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

    /**
     *  @dev   Unschedules a call to be executed.
     *  @param caller_     The contract to execute the call on.
     *  @param contract_   The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param callData_   The of the parameters to pass to the function.
     */
    function unscheduleCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) external;

}