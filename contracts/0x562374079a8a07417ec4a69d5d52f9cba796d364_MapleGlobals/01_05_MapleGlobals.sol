// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { NonTransparentProxied } from "../modules/non-transparent-proxy/contracts/NonTransparentProxied.sol";

import { IMapleGlobals } from "./interfaces/IMapleGlobals.sol";

import { IChainlinkAggregatorV3Like, IPoolManagerLike, IProxyLike, IProxyFactoryLike } from "./interfaces/Interfaces.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗     ██████╗ ██╗      ██████╗ ██████╗  █████╗ ██╗     ███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝    ██╔════╝ ██║     ██╔═══██╗██╔══██╗██╔══██╗██║     ██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗      ██║  ███╗██║     ██║   ██║██████╔╝███████║██║     ███████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝      ██║   ██║██║     ██║   ██║██╔══██╗██╔══██║██║     ╚════██║
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗    ╚██████╔╝███████╗╚██████╔╝██████╔╝██║  ██║███████╗███████║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝     ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝

*/

contract MapleGlobals is IMapleGlobals, NonTransparentProxied {

    /**************************************************************************************************************************************/
    /*** Structs                                                                                                                        ***/
    /**************************************************************************************************************************************/

    struct PoolDelegate {
        address ownedPoolManager;
        bool    isPoolDelegate;
    }

    struct ScheduledCall {
        uint256 timestamp;
        bytes32 dataHash;
    }

    struct TimelockParameters {
        uint128 delay;
        uint128 duration;
    }

    /**************************************************************************************************************************************/
    /*** Storage                                                                                                                        ***/
    /**************************************************************************************************************************************/

    uint256 public constant HUNDRED_PERCENT = 100_0000;

    address public override mapleTreasury;
    address public override migrationAdmin;
    address public override pendingGovernor;
    address public override securityAdmin;

    bool public override protocolPaused;

    TimelockParameters public override defaultTimelockParameters;

    mapping(address => address) public override oracleFor;

    mapping(address => bool) public override isBorrower;
    mapping(address => bool) public override isCollateralAsset;
    mapping(address => bool) public override isPoolAsset;

    mapping(address => bool) internal _isPoolDeployer;  // NOTE: Deprecated, but currently allowing only disabling.

    mapping(address => uint256) public override manualOverridePrice;
    mapping(address => uint256) public override maxCoverLiquidationPercent;
    mapping(address => uint256) public override minCoverAmount;
    mapping(address => uint256) public override bootstrapMint;
    mapping(address => uint256) public override platformManagementFeeRate;
    mapping(address => uint256) public override platformOriginationFeeRate;
    mapping(address => uint256) public override platformServiceFeeRate;

    mapping(address => mapping(bytes32 => TimelockParameters)) public override timelockParametersOf;

    mapping(bytes32 => mapping(address => bool)) public override isInstanceOf;

    // Timestamp and call data hash for a caller, on a contract, for a function id.
    mapping(address => mapping(address => mapping(bytes32 => ScheduledCall))) public override scheduledCalls;

    mapping(address => PoolDelegate) public override poolDelegates;

    mapping(address => bool) public override isContractPaused;

    mapping(address => mapping(bytes4 => bool)) public override isFunctionUnpaused;

    mapping(address => mapping(address => bool)) internal _canDeployFrom;

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    modifier onlyGovernor() {
        _revertIfNotGovernor();
        _;
    }

    modifier onlyGovernorOrSecurityAdmin() {
        _revertIfNotGovernorOrSecurityAdmin();
        _;
    }

    /**************************************************************************************************************************************/
    /*** Governor Transfer Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    function acceptGovernor() external override {
        require(msg.sender == pendingGovernor, "MG:NOT_PENDING_GOV");
        emit GovernorshipAccepted(admin(), msg.sender);
        _setAddress(ADMIN_SLOT, msg.sender);
        pendingGovernor = address(0);
    }

    function setPendingGovernor(address pendingGovernor_) external override onlyGovernor {
        emit PendingGovernorSet(pendingGovernor = pendingGovernor_);
    }

    /**************************************************************************************************************************************/
    /*** Global Setters                                                                                                                 ***/
    /**************************************************************************************************************************************/

    // NOTE: `minCoverAmount` is not enforced at activation time.
    function activatePoolManager(address poolManager_) external override onlyGovernor {
        address factory_  = IPoolManagerLike(poolManager_).factory();
        address delegate_ = IPoolManagerLike(poolManager_).poolDelegate();

        require(isInstanceOf["POOL_MANAGER_FACTORY"][factory_],          "MG:APM:INVALID_FACTORY");
        require(IProxyFactoryLike(factory_).isInstance(poolManager_),    "MG:APM:INVALID_POOL_MANAGER");
        require(poolDelegates[delegate_].isPoolDelegate,                 "MG:APM:INVALID_DELEGATE");
        require(poolDelegates[delegate_].ownedPoolManager == address(0), "MG:APM:ALREADY_OWNS");

        emit PoolManagerActivated(poolManager_, delegate_);

        poolDelegates[delegate_].ownedPoolManager = poolManager_;

        IPoolManagerLike(poolManager_).setActive(true);
    }

    function setBootstrapMint(address asset_, uint256 amount_) external override onlyGovernor {
        emit BootstrapMintSet(asset_, bootstrapMint[asset_] = amount_);
    }

    function setDefaultTimelockParameters(uint128 defaultTimelockDelay_, uint128 defaultTimelockDuration_) external override onlyGovernor {
        emit DefaultTimelockParametersSet(
            defaultTimelockParameters.delay,
            defaultTimelockDelay_,
            defaultTimelockParameters.duration,
            defaultTimelockDuration_
        );

        defaultTimelockParameters = TimelockParameters(defaultTimelockDelay_, defaultTimelockDuration_);
    }

    function setMapleTreasury(address mapleTreasury_) external override onlyGovernor {
        require(mapleTreasury_ != address(0), "MG:SMT:ZERO_ADDR");
        emit MapleTreasurySet(mapleTreasury, mapleTreasury_);
        mapleTreasury = mapleTreasury_;
    }

    function setMigrationAdmin(address migrationAdmin_) external override onlyGovernor {
        emit MigrationAdminSet(migrationAdmin, migrationAdmin_);
        migrationAdmin = migrationAdmin_;
    }

    function setPriceOracle(address asset_, address oracle_) external override onlyGovernor {
        require(oracle_ != address(0) && asset_ != address(0), "MG:SPO:ZERO_ADDR");
        oracleFor[asset_] = oracle_;
        emit PriceOracleSet(asset_, oracle_);
    }

    function setSecurityAdmin(address securityAdmin_) external override onlyGovernor {
        require(securityAdmin_ != address(0), "MG:SSA:ZERO_ADDR");
        emit SecurityAdminSet(securityAdmin, securityAdmin_);
        securityAdmin = securityAdmin_;
    }

    /**************************************************************************************************************************************/
    /*** Boolean Setters                                                                                                                ***/
    /**************************************************************************************************************************************/

    function setContractPause(address contract_, bool contractPaused_) external override onlyGovernorOrSecurityAdmin {
        emit ContractPauseSet(
            msg.sender,
            contract_,
            isContractPaused[contract_] = contractPaused_
        );
    }

    function setFunctionUnpause(address contract_, bytes4 sig_, bool functionUnpaused_) external override onlyGovernorOrSecurityAdmin {
        emit FunctionUnpauseSet(
            msg.sender,
            contract_,
            sig_,
            isFunctionUnpaused[contract_][sig_] = functionUnpaused_
        );
    }

    function setProtocolPause(bool protocolPaused_) external override onlyGovernorOrSecurityAdmin {
        emit ProtocolPauseSet(
            msg.sender,
            protocolPaused = protocolPaused_
        );
    }

    /**************************************************************************************************************************************/
    /*** Allowlist Setters                                                                                                              ***/
    /**************************************************************************************************************************************/

    function setCanDeployFrom(address factory_, address account_, bool canDeployFrom_) external override onlyGovernor {
        emit CanDeployFromSet(factory_, account_, _canDeployFrom[factory_][account_] = canDeployFrom_);
    }

    function setValidBorrower(address borrower_, bool isValid_) external override onlyGovernor {
        isBorrower[borrower_] = isValid_;
        emit ValidBorrowerSet(borrower_, isValid_);
    }

    function setValidCollateralAsset(address collateralAsset_, bool isValid_) external override onlyGovernor {
        isCollateralAsset[collateralAsset_] = isValid_;
        emit ValidCollateralAssetSet(collateralAsset_, isValid_);
    }

    function setValidInstanceOf(bytes32 instanceKey_, address instance_, bool isValid_) external override onlyGovernor {
        isInstanceOf[instanceKey_][instance_] = isValid_;
        emit ValidInstanceSet(instanceKey_, instance_, isValid_);
    }

    function setValidPoolAsset(address poolAsset_, bool isValid_) external override onlyGovernor {
        isPoolAsset[poolAsset_] = isValid_;
        emit ValidPoolAssetSet(poolAsset_, isValid_);
    }

    function setValidPoolDelegate(address account_, bool isValid_) external override onlyGovernor {
        require(account_ != address(0), "MG:SVPD:ZERO_ADDR");

        // Cannot remove pool delegates that own a pool manager.
        require(isValid_ || poolDelegates[account_].ownedPoolManager == address(0), "MG:SVPD:OWNS_POOL_MANAGER");

        poolDelegates[account_].isPoolDelegate = isValid_;
        emit ValidPoolDelegateSet(account_, isValid_);
    }

    function setValidPoolDeployer(address account_, bool isPoolDeployer_) external override onlyGovernor {
        // NOTE: Explicit PoolDeployers via mapping are deprecated in favour of generalized canDeployFrom mapping.
        require(!isPoolDeployer_, "MG:SVPD:ONLY_DISABLING");

        emit ValidPoolDeployerSet(account_, _isPoolDeployer[account_] = isPoolDeployer_);
    }

    /**************************************************************************************************************************************/
    /*** Price Setters                                                                                                                  ***/
    /**************************************************************************************************************************************/

    function setManualOverridePrice(address asset_, uint256 price_) external override onlyGovernor {
        manualOverridePrice[asset_] = price_;
        emit ManualOverridePriceSet(asset_, price_);
    }

    /**************************************************************************************************************************************/
    /*** Cover Setters                                                                                                                  ***/
    /**************************************************************************************************************************************/

    function setMaxCoverLiquidationPercent(address poolManager_, uint256 maxCoverLiquidationPercent_) external override onlyGovernor {
        require(maxCoverLiquidationPercent_ <= HUNDRED_PERCENT, "MG:SMCLP:GT_100");
        maxCoverLiquidationPercent[poolManager_] = maxCoverLiquidationPercent_;
        emit MaxCoverLiquidationPercentSet(poolManager_, maxCoverLiquidationPercent_);
    }

    function setMinCoverAmount(address poolManager_, uint256 minCoverAmount_) external override onlyGovernor {
        minCoverAmount[poolManager_] = minCoverAmount_;
        emit MinCoverAmountSet(poolManager_, minCoverAmount_);
    }

    /**************************************************************************************************************************************/
    /*** Fee Setters                                                                                                                    ***/
    /**************************************************************************************************************************************/

    function setPlatformManagementFeeRate(address poolManager_, uint256 platformManagementFeeRate_) external override onlyGovernor {
        require(platformManagementFeeRate_ <= HUNDRED_PERCENT, "MG:SPMFR:RATE_GT_100");
        platformManagementFeeRate[poolManager_] = platformManagementFeeRate_;
        emit PlatformManagementFeeRateSet(poolManager_, platformManagementFeeRate_);
    }

    function setPlatformOriginationFeeRate(address poolManager_, uint256 platformOriginationFeeRate_) external override onlyGovernor {
        require(platformOriginationFeeRate_ <= HUNDRED_PERCENT, "MG:SPOFR:RATE_GT_100");
        platformOriginationFeeRate[poolManager_] = platformOriginationFeeRate_;
        emit PlatformOriginationFeeRateSet(poolManager_, platformOriginationFeeRate_);
    }

    function setPlatformServiceFeeRate(address poolManager_, uint256 platformServiceFeeRate_) external override onlyGovernor {
        require(platformServiceFeeRate_ <= HUNDRED_PERCENT, "MG:SPSFR:RATE_GT_100");
        platformServiceFeeRate[poolManager_] = platformServiceFeeRate_;
        emit PlatformServiceFeeRateSet(poolManager_, platformServiceFeeRate_);
    }

    /**************************************************************************************************************************************/
    /*** Contract Control Functions                                                                                                     ***/
    /**************************************************************************************************************************************/

    function setTimelockWindow(address contract_, bytes32 functionId_, uint128 delay_, uint128 duration_) public override onlyGovernor {
        timelockParametersOf[contract_][functionId_] = TimelockParameters(delay_, duration_);
        emit TimelockWindowSet(contract_, functionId_, delay_, duration_);
    }

    function setTimelockWindows(
        address            contract_,
        bytes32[] calldata functionIds_,
        uint128[] calldata delays_,
        uint128[] calldata durations_
    )
        public override onlyGovernor
    {
        for (uint256 i_; i_ < functionIds_.length; ++i_) {
            _setTimelockWindow(contract_, functionIds_[i_], delays_[i_], durations_[i_]);
        }
    }

    function transferOwnedPoolManager(address fromPoolDelegate_, address toPoolDelegate_) external override {
        PoolDelegate storage fromDelegate_ = poolDelegates[fromPoolDelegate_];
        PoolDelegate storage toDelegate_   = poolDelegates[toPoolDelegate_];

        require(fromDelegate_.ownedPoolManager == msg.sender, "MG:TOPM:NO_AUTH");
        require(toDelegate_.isPoolDelegate,                   "MG:TOPM:NOT_PD");
        require(toDelegate_.ownedPoolManager == address(0),   "MG:TOPM:ALREADY_OWNS");

        fromDelegate_.ownedPoolManager = address(0);
        toDelegate_.ownedPoolManager   = msg.sender;

        emit PoolManagerOwnershipTransferred(fromPoolDelegate_, toPoolDelegate_, msg.sender);
    }

    /**************************************************************************************************************************************/
    /*** Schedule Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_)
        public override view returns (bool isValid_)
    {
        ScheduledCall      storage scheduledCall_      = scheduledCalls[caller_][contract_][functionId_];
        TimelockParameters storage timelockParameters_ = timelockParametersOf[contract_][functionId_];

        uint256 timestamp_ = scheduledCall_.timestamp;
        uint128 delay_     = timelockParameters_.delay;
        uint128 duration_  = timelockParameters_.duration;

        if (duration_ == uint128(0)) {
            delay_    = defaultTimelockParameters.delay;
            duration_ = defaultTimelockParameters.duration;
        }

        isValid_ =
            (block.timestamp >= timestamp_ + delay_) &&
            (block.timestamp <= timestamp_ + delay_ + duration_) &&
            (keccak256(abi.encode(callData_)) == scheduledCall_.dataHash);
    }

    function scheduleCall(address contract_, bytes32 functionId_, bytes calldata callData_) external override {
        bytes32 dataHash_ = keccak256(abi.encode(callData_));

        scheduledCalls[msg.sender][contract_][functionId_] = ScheduledCall(block.timestamp, dataHash_);

        emit CallScheduled(msg.sender, contract_, functionId_, dataHash_, block.timestamp);
    }

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external override {
        _unscheduleCall(caller_, msg.sender, functionId_, callData_);
    }

    function unscheduleCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_)
        external override onlyGovernor
    {
        _unscheduleCall(caller_, contract_, functionId_, callData_);
    }

    function _unscheduleCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) internal {
        bytes32 dataHash_ = keccak256(abi.encode(callData_));

        require(dataHash_ == scheduledCalls[caller_][contract_][functionId_].dataHash, "MG:UC:CALLDATA_MISMATCH");

        delete scheduledCalls[caller_][contract_][functionId_];

        emit CallUnscheduled(caller_, contract_, functionId_, dataHash_, block.timestamp);
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function canDeploy(address caller_) public override view returns (bool canDeploy_) {
        canDeploy_ = canDeployFrom(msg.sender, caller_);
    }

    function canDeployFrom(address factory_, address caller_) public override view returns (bool canDeployFrom_) {
        // Simply check if the caller can deploy at the factory. If not, since a PoolManager is often deployed in the same transaction as
        // the LoanManagers it deploys, check if `factory_` is a LoanManagerFactory and the caller is a PoolManager.
        canDeployFrom_ = _canDeployFrom[factory_][caller_] || (isInstanceOf["LOAN_MANAGER_FACTORY"][factory_] && _isPoolManager(caller_));
    }

    function getLatestPrice(address asset_) external override view returns (uint256 latestPrice_) {
        // If governor has overridden price because of oracle outage, return overridden price.
        if (manualOverridePrice[asset_] != 0) return manualOverridePrice[asset_];

        address oracle_ = oracleFor[asset_];

        require(oracle_ != address(0), "MG:GLP:ZERO_ORACLE");

        (
            uint80 roundId_,
            int256 price_,
            ,
            uint256 updatedAt_,
            uint80 answeredInRound_
        ) = IChainlinkAggregatorV3Like(oracle_).latestRoundData();

        require(updatedAt_ != 0,              "MG:GLP:ROUND_NOT_COMPLETE");
        require(answeredInRound_ >= roundId_, "MG:GLP:STALE_DATA");
        require(price_ > int256(0),           "MG:GLP:ZERO_PRICE");

        latestPrice_ = uint256(price_);
    }

    function governor() external view override returns (address governor_) {
        governor_ = admin();
    }

    // NOTE: This function is deprecated.
    // NOTE: This is only used by the LiquidatorFactory to determine if the factory of it's caller is a FixedTermLoanManagerFactory.
    // NOTE: Original liquidatorFactory checks isFactory("LOAN_MANAGER", IMapleProxied(msg.sender).factory());
    function isFactory(bytes32 factoryId_, address factory_) external view override returns (bool isFactory_) {
        // NOTE: Key is not used as this function is deprecated and narrowed.
        factoryId_;

        // Revert if caller is not LiquidatorFactory, the only allowed caller of this deprecated function.
        require(isInstanceOf["LIQUIDATOR_FACTORY"][msg.sender], "MG:IF:NOT_LIQ_FACTORY");

        // Determine if the `factory_` is a `FixedTermLoanManagerFactory`.
        isFactory_ = isInstanceOf["FT_LOAN_MANAGER_FACTORY"][factory_];
    }

    function isFunctionPaused(bytes4 sig_) external view override returns (bool functionIsPaused_) {
        functionIsPaused_ = isFunctionPaused(msg.sender, sig_);
    }

    function isFunctionPaused(address contract_, bytes4 sig_) public view override returns (bool functionIsPaused_) {
        functionIsPaused_ = (protocolPaused || isContractPaused[contract_]) && !isFunctionUnpaused[contract_][sig_];
    }

    function isPoolDelegate(address account_) external view override returns (bool isPoolDelegate_) {
        isPoolDelegate_ = poolDelegates[account_].isPoolDelegate;
    }

    // NOTE: This function is deprecated.
    // NOTE: This is only used by FixedTermLoanManagerFactory, PoolManagerFactory, and WithdrawalManagerFactory, so it must return true for
    //       any caller that is either:
    //       - An actual PoolDeployer contract (in the case of a PoolManagerFactory or WithdrawalManagerFactory), or
    //       - A PoolManager contract (in the case of a FixedTermLoanManagerFactory)
    function isPoolDeployer(address caller_) external view override returns (bool isPoolDeployer_) {
        // Revert if caller is not FixedTermLoanManagerFactory, PoolManagerFactory, or WithdrawalManagerFactory,
        // the only allowed callers of this deprecated function.
        require(
            isInstanceOf["FT_LOAN_MANAGER_FACTORY"][msg.sender] ||
            isInstanceOf["POOL_MANAGER_FACTORY"][msg.sender] ||
            isInstanceOf["WITHDRAWAL_MANAGER_FACTORY"][msg.sender],
            "MG:IPD:INV_FACTORY"
        );

        // This demonstrates that canDeploy() is a full replacement for isPoolDeployer().
        isPoolDeployer_ = canDeploy(caller_);
    }

    function ownedPoolManager(address account_) external view override returns (address poolManager_) {
        poolManager_ = poolDelegates[account_].ownedPoolManager;
    }

    /**************************************************************************************************************************************/
    /*** Helper Functions                                                                                                               ***/
    /**************************************************************************************************************************************/

    function _isPoolManager(address contract_) internal view returns (bool isPoolManager_) {
        address factory_ = IProxyLike(contract_).factory();

        isPoolManager_ = (isInstanceOf["POOL_MANAGER_FACTORY"][factory_]) && IProxyFactoryLike(factory_).isInstance(contract_);
    }

    function _revertIfNotGovernor() internal view {
        require(msg.sender == admin(), "MG:NOT_GOV");
    }

    function _revertIfNotGovernorOrSecurityAdmin() internal view {
        require(msg.sender == admin() || msg.sender == securityAdmin, "MG:NOT_GOV_OR_SA");
    }

    function _setAddress(bytes32 slot_, address value_) private {
        assembly {
            sstore(slot_, value_)
        }
    }

    function _setTimelockWindow(address contract_, bytes32 functionId_, uint128 delay_, uint128 duration_) internal {
        timelockParametersOf[contract_][functionId_] = TimelockParameters(delay_, duration_);
        emit TimelockWindowSet(contract_, functionId_, delay_, duration_);
    }

}