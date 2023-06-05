// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import {SafeERC20Upgradeable as SafeERC20} from "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Owned} from "../utils/Owned.sol";
import {IVault, VaultInitParams, VaultFees, IERC4626, IERC20} from "../interfaces/vault/IVault.sol";
import {IMultiRewardStaking} from "../interfaces/IMultiRewardStaking.sol";
import {IMultiRewardEscrow} from "../interfaces/IMultiRewardEscrow.sol";
import {IDeploymentController, ICloneRegistry} from "../interfaces/vault/IDeploymentController.sol";
import {ITemplateRegistry, Template} from "../interfaces/vault/ITemplateRegistry.sol";
import {IPermissionRegistry, Permission} from "../interfaces/vault/IPermissionRegistry.sol";
import {IVaultRegistry, VaultMetadata} from "../interfaces/vault/IVaultRegistry.sol";
import {IAdminProxy} from "../interfaces/vault/IAdminProxy.sol";
import {IStrategy} from "../interfaces/vault/IStrategy.sol";
import {IAdapter} from "../interfaces/vault/IAdapter.sol";
import {IPausable} from "../interfaces/IPausable.sol";
import {DeploymentArgs} from "../interfaces/vault/IVaultController.sol";

/**
 * @title   VaultController
 * @author  RedVeil
 * @notice  Admin contract for the vault ecosystem.
 *
 * Deploys Vaults, Adapter, Strategies and Staking contracts.
 * Calls admin functions on deployed contracts.
 */
contract VaultController is Owned {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    bytes32 public immutable VAULT = "Vault";
    bytes32 public immutable ADAPTER = "Adapter";
    bytes32 public immutable STRATEGY = "Strategy";
    bytes32 public immutable STAKING = "Staking";
    bytes4 internal immutable DEPLOY_SIG =
        bytes4(keccak256("deploy(bytes32,bytes32,bytes)"));

    /**
     * @notice Constructor of this contract.
     * @param _owner Owner of the contract. Controls management functions.
     * @param _adminProxy `AdminProxy` ownes contracts in the vault ecosystem.
     * @param _deploymentController `DeploymentController` with auxiliary deployment contracts.
     * @param _vaultRegistry `VaultRegistry` to safe vault metadata.
     * @param _permissionRegistry `permissionRegistry` to add endorsements and rejections.
     * @param _escrow `MultiRewardEscrow` To escrow rewards of staking contracts.
     */
    constructor(
        address _owner,
        IAdminProxy _adminProxy,
        IDeploymentController _deploymentController,
        IVaultRegistry _vaultRegistry,
        IPermissionRegistry _permissionRegistry,
        IMultiRewardEscrow _escrow
    ) Owned(_owner) {
        adminProxy = _adminProxy;
        vaultRegistry = _vaultRegistry;
        permissionRegistry = _permissionRegistry;
        escrow = _escrow;

        _setDeploymentController(_deploymentController);

        activeTemplateId[STAKING] = "MultiRewardStaking";
        activeTemplateId[VAULT] = "V1";
    }

    /*//////////////////////////////////////////////////////////////
                          VAULT DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    event VaultDeployed(
        address indexed vault,
        address indexed staking,
        address indexed adapter
    );

    error InvalidConfig();

    /**
     * @notice Deploy a new Vault. Optionally with an Adapter and Staking. Caller must be owner.
     * @param vaultData Vault init params.
     * @param adapterData Encoded adapter init data.
     * @param strategyData Encoded strategy init data.
     * @param deployStaking Should we deploy a staking contract for the vault?
     * @param rewardsData Encoded data to add a rewards to the staking contract
     * @param metadata Vault metadata for the `VaultRegistry` (Will be used by the frontend for additional informations)
     * @param initialDeposit Initial deposit to the vault. If 0, no deposit will be made.
     * @dev This function is the one stop solution to create a new vault with all necessary admin functions or auxiliery contracts.
     * @dev If `rewardsData` is not empty `deployStaking` must be true
     */
    function deployVault(
        VaultInitParams memory vaultData,
        DeploymentArgs memory adapterData,
        DeploymentArgs memory strategyData,
        bool deployStaking,
        bytes memory rewardsData,
        VaultMetadata memory metadata,
        uint256 initialDeposit
    ) external canCreate returns (address vault) {
        IDeploymentController _deploymentController = deploymentController;

        _verifyToken(address(vaultData.asset));
        if (
            address(vaultData.adapter) != address(0) &&
            (adapterData.id > 0 ||
                !cloneRegistry.cloneExists(address(vaultData.adapter)))
        ) revert InvalidConfig();

        if (adapterData.id > 0)
            vaultData.adapter = IERC4626(
                _deployAdapter(
                    vaultData.asset,
                    adapterData,
                    strategyData,
                    _deploymentController
                )
            );

        vault = _deployVault(vaultData, _deploymentController);

        address staking;
        if (deployStaking)
            staking = _deployStaking(
                IERC20(address(vault)),
                _deploymentController
            );

        _registerCreatedVault(vault, staking, metadata);

        if (rewardsData.length > 0) {
            if (!deployStaking) revert InvalidConfig();
            _handleVaultStakingRewards(vault, rewardsData);
        }

        emit VaultDeployed(vault, staking, address(vaultData.adapter));

        _handleInitialDeposit(
            initialDeposit,
            IERC20(vaultData.asset),
            IERC4626(vault)
        );
    }

    /// @notice Deploys a new vault contract using the `activeTemplateId`.
    function _deployVault(
        VaultInitParams memory vaultData,
        IDeploymentController _deploymentController
    ) internal returns (address vault) {
        vaultData.owner = address(adminProxy);

        (, bytes memory returnData) = adminProxy.execute(
            address(_deploymentController),
            abi.encodeWithSelector(
                DEPLOY_SIG,
                VAULT,
                activeTemplateId[VAULT],
                abi.encodeWithSelector(IVault.initialize.selector, vaultData)
            )
        );

        vault = abi.decode(returnData, (address));
    }

    /// @notice Registers newly created vault metadata.
    function _registerCreatedVault(
        address vault,
        address staking,
        VaultMetadata memory metadata
    ) internal {
        metadata.vault = vault;
        metadata.staking = staking;
        metadata.creator = msg.sender;

        _registerVault(vault, metadata);
    }

    /// @notice Prepares and calls `addStakingRewardsTokens` for the newly created staking contract.
    function _handleVaultStakingRewards(
        address vault,
        bytes memory rewardsData
    ) internal {
        address[] memory vaultContracts = new address[](1);
        bytes[] memory rewardsDatas = new bytes[](1);

        vaultContracts[0] = vault;
        rewardsDatas[0] = rewardsData;

        addStakingRewardsTokens(vaultContracts, rewardsDatas);
    }

    function _handleInitialDeposit(
        uint256 initialDeposit,
        IERC20 asset,
        IERC4626 target
    ) internal {
        if (initialDeposit > 0) {
            asset.safeTransferFrom(msg.sender, address(this), initialDeposit);
            asset.approve(address(target), initialDeposit);
            target.deposit(initialDeposit, msg.sender);
        }
    }

    /*//////////////////////////////////////////////////////////////
                      ADAPTER DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploy a new Adapter with our without a strategy. Caller must be owner.
     * @param asset Asset which will be used by the adapter.
     * @param adapterData Encoded adapter init data.
     * @param strategyData Encoded strategy init data.
     */
    function deployAdapter(
        IERC20 asset,
        DeploymentArgs memory adapterData,
        DeploymentArgs memory strategyData,
        uint256 initialDeposit
    ) external canCreate returns (address adapter) {
        _verifyToken(address(asset));

        adapter = _deployAdapter(
            asset,
            adapterData,
            strategyData,
            deploymentController
        );

        _handleInitialDeposit(initialDeposit, asset, IERC4626(adapter));
    }

    /**
     * @notice Deploys an adapter and optionally a strategy.
     * @dev Adds the newly deployed strategy to the adapter.
     */
    function _deployAdapter(
        IERC20 asset,
        DeploymentArgs memory adapterData,
        DeploymentArgs memory strategyData,
        IDeploymentController _deploymentController
    ) internal returns (address) {
        address strategy;
        bytes4[8] memory requiredSigs;
        if (strategyData.id > 0) {
            strategy = _deployStrategy(strategyData, _deploymentController);
            requiredSigs = templateRegistry
                .getTemplate(STRATEGY, strategyData.id)
                .requiredSigs;
        }

        return
            __deployAdapter(
                adapterData,
                abi.encode(
                    asset,
                    address(adminProxy),
                    IStrategy(strategy),
                    harvestCooldown,
                    requiredSigs,
                    strategyData.data
                ),
                _deploymentController
            );
    }

    /// @notice Deploys an adapter and sets the management fee via `AdminProxy`
    function __deployAdapter(
        DeploymentArgs memory adapterData,
        bytes memory baseAdapterData,
        IDeploymentController _deploymentController
    ) internal returns (address adapter) {
        (, bytes memory returnData) = adminProxy.execute(
            address(_deploymentController),
            abi.encodeWithSelector(
                DEPLOY_SIG,
                ADAPTER,
                adapterData.id,
                _encodeAdapterData(adapterData, baseAdapterData)
            )
        );

        adapter = abi.decode(returnData, (address));

        adminProxy.execute(
            adapter,
            abi.encodeWithSelector(
                IAdapter.setPerformanceFee.selector,
                performanceFee
            )
        );
    }

    /// @notice Encodes adapter init call. Was moved into its own function to fix "stack too deep" error.
    function _encodeAdapterData(
        DeploymentArgs memory adapterData,
        bytes memory baseAdapterData
    ) internal returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IAdapter.initialize.selector,
                baseAdapterData,
                templateRegistry.getTemplate(ADAPTER, adapterData.id).registry,
                adapterData.data
            );
    }

    /// @notice Deploys a new strategy contract.
    function _deployStrategy(
        DeploymentArgs memory strategyData,
        IDeploymentController _deploymentController
    ) internal returns (address strategy) {
        (, bytes memory returnData) = adminProxy.execute(
            address(_deploymentController),
            abi.encodeWithSelector(DEPLOY_SIG, STRATEGY, strategyData.id, "")
        );

        strategy = abi.decode(returnData, (address));
    }

    /*//////////////////////////////////////////////////////////////
                    STAKING DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploy a new staking contract. Caller must be owner.
     * @param asset The staking token for the new contract.
     * @dev Deploys `MultiRewardsStaking` based on the latest templateTemplateKey.
     */
    function deployStaking(IERC20 asset) external canCreate returns (address) {
        _verifyToken(address(asset));
        return _deployStaking(asset, deploymentController);
    }

    /// @notice Deploys a new staking contract using the activeTemplateId.
    function _deployStaking(
        IERC20 asset,
        IDeploymentController _deploymentController
    ) internal returns (address staking) {
        (, bytes memory returnData) = adminProxy.execute(
            address(_deploymentController),
            abi.encodeWithSelector(
                DEPLOY_SIG,
                STAKING,
                activeTemplateId[STAKING],
                abi.encodeWithSelector(
                    IMultiRewardStaking.initialize.selector,
                    asset,
                    escrow,
                    adminProxy
                )
            )
        );

        staking = abi.decode(returnData, (address));
    }

    /*//////////////////////////////////////////////////////////////
                    VAULT MANAGEMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    error DoesntExist(address adapter);

    /**
     * @notice Propose a new Adapter. Caller must be creator of the vaults.
     * @param vaults Vaults to propose the new adapter for.
     * @param newAdapter New adapters to propose.
     */
    function proposeVaultAdapters(
        address[] calldata vaults,
        IERC4626[] calldata newAdapter
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, newAdapter.length);

        ICloneRegistry _cloneRegistry = cloneRegistry;
        for (uint8 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);
            if (!_cloneRegistry.cloneExists(address(newAdapter[i])))
                revert DoesntExist(address(newAdapter[i]));

            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(
                    IVault.proposeAdapter.selector,
                    newAdapter[i]
                )
            );
        }
    }

    /**
     * @notice Change adapter of a vault to the previously proposed adapter.
     * @param vaults Addresses of the vaults to change
     */
    function changeVaultAdapters(address[] calldata vaults) external {
        uint8 len = uint8(vaults.length);
        for (uint8 i = 0; i < len; i++) {
            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(IVault.changeAdapter.selector)
            );
        }
    }

    /**
     * @notice Sets new fees per vault. Caller must be creator of the vaults.
     * @param vaults Addresses of the vaults to change
     * @param fees New fee structures for these vaults
     * @dev Value is in 1e18, e.g. 100% = 1e18 - 1 BPS = 1e12
     */
    function proposeVaultFees(
        address[] calldata vaults,
        VaultFees[] calldata fees
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, fees.length);

        for (uint8 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);

            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(IVault.proposeFees.selector, fees[i])
            );
        }
    }

    /**
     * @notice Change adapter of a vault to the previously proposed adapter.
     * @param vaults Addresses of the vaults
     */
    function changeVaultFees(address[] calldata vaults) external {
        uint8 len = uint8(vaults.length);
        for (uint8 i = 0; i < len; i++) {
            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(IVault.changeFees.selector)
            );
        }
    }

    /**
     * @notice Sets new Quit Periods for Vaults. Caller must be creator of the vaults.
     * @param vaults Addresses of the vaults to change
     * @param quitPeriods QuitPeriod in seconds
     * @dev Minimum value is 1 day max is 7 days.
     * @dev Cant be called if recently a new fee or adapter has been proposed
     */
    function setVaultQuitPeriods(
        address[] calldata vaults,
        uint256[] calldata quitPeriods
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, quitPeriods.length);

        for (uint8 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);

            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(
                    IVault.setQuitPeriod.selector,
                    quitPeriods[i]
                )
            );
        }
    }

    /**
     * @notice Sets new Fee Recipients for Vaults. Caller must be creator of the vaults.
     * @param vaults Addresses of the vaults to change
     * @param feeRecipients fee recipient for this vault
     * @dev address must not be 0
     */
    function setVaultFeeRecipients(
        address[] calldata vaults,
        address[] calldata feeRecipients
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, feeRecipients.length);

        for (uint8 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);

            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(
                    IVault.setFeeRecipient.selector,
                    feeRecipients[i]
                )
            );
        }
    }

    /**
     * @notice Sets new DepositLimit for Vaults. Caller must be creator of the vaults.
     * @param vaults Addresses of the vaults to change
     * @param depositLimits Maximum amount of assets that can be deposited.
     */
    function setVaultDepositLimits(
        address[] calldata vaults,
        uint256[] calldata depositLimits
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, depositLimits.length);

        for (uint8 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);

            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(
                    IVault.setDepositLimit.selector,
                    depositLimits[i]
                )
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                          REGISTER VAULT
    //////////////////////////////////////////////////////////////*/

    IVaultRegistry public vaultRegistry;

    /// @notice Call the `VaultRegistry` to register a vault via `AdminProxy`
    function _registerVault(
        address vault,
        VaultMetadata memory metadata
    ) internal {
        adminProxy.execute(
            address(vaultRegistry),
            abi.encodeWithSelector(
                IVaultRegistry.registerVault.selector,
                metadata
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                    ENDORSEMENT / REJECTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set permissions for an array of target. Caller must be owner.
     * @param targets `AdminProxy`
     * @param newPermissions An array of permissions to set for the targets.
     * @dev See `PermissionRegistry` for more details
     */
    function setPermissions(
        address[] calldata targets,
        Permission[] calldata newPermissions
    ) external onlyOwner {
        // No need to check matching array length since its already done in the permissionRegistry
        adminProxy.execute(
            address(permissionRegistry),
            abi.encodeWithSelector(
                IPermissionRegistry.setPermissions.selector,
                targets,
                newPermissions
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                      STAKING MANAGEMENT LOGIC
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Adds a new rewardToken which can be earned via staking. Caller must be creator of the Vault or owner.
     * @param vaults Vaults of which the staking contracts should be targeted
     * @param rewardTokenData Token that can be earned by staking.
     * @dev `rewardToken` - Token that can be earned by staking.
     * @dev `rewardsPerSecond` - The rate in which `rewardToken` will be accrued.
     * @dev `amount` - Initial funding amount for this reward.
     * @dev `useEscrow Bool` - if the rewards should be escrowed on claim.
     * @dev `escrowPercentage` - The percentage of the reward that gets escrowed in 1e18. (1e18 = 100%, 1e14 = 1 BPS)
     * @dev `escrowDuration` - The duration of the escrow.
     * @dev `offset` - A cliff after claim before the escrow starts.
     * @dev See `MultiRewardsStaking` for more details.
     */
    function addStakingRewardsTokens(
        address[] memory vaults,
        bytes[] memory rewardTokenData
    ) public {
        _verifyEqualArrayLength(vaults.length, rewardTokenData.length);
        address staking;
        uint8 len = uint8(vaults.length);
        for (uint256 i = 0; i < len; i++) {
            (
                address rewardsToken,
                uint160 rewardsPerSecond,
                uint256 amount,
                bool useEscrow,
                uint224 escrowDuration,
                uint24 escrowPercentage,
                uint256 offset
            ) = abi.decode(
                    rewardTokenData[i],
                    (address, uint160, uint256, bool, uint224, uint24, uint256)
                );
            _verifyToken(rewardsToken);
            staking = _verifyCreatorOrOwner(vaults[i]).staking;

            adminProxy.execute(
                rewardsToken,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    staking,
                    type(uint256).max
                )
            );

            IERC20(rewardsToken).approve(staking, type(uint256).max);
            IERC20(rewardsToken).transferFrom(
                msg.sender,
                address(adminProxy),
                amount
            );

            adminProxy.execute(
                staking,
                abi.encodeWithSelector(
                    IMultiRewardStaking.addRewardToken.selector,
                    rewardsToken,
                    rewardsPerSecond,
                    amount,
                    useEscrow,
                    escrowDuration,
                    escrowPercentage,
                    offset
                )
            );
        }
    }

    /**
     * @notice Changes rewards speed for a rewardToken. This works only for rewards that accrue over time. Caller must be creator of the Vault.
     * @param vaults Vaults of which the staking contracts should be targeted
     * @param rewardTokens Token that can be earned by staking.
     * @param rewardsSpeeds The rate in which `rewardToken` will be accrued.
     * @dev See `MultiRewardsStaking` for more details.
     */
    function changeStakingRewardsSpeeds(
        address[] calldata vaults,
        IERC20[] calldata rewardTokens,
        uint160[] calldata rewardsSpeeds
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, rewardTokens.length);
        _verifyEqualArrayLength(len, rewardsSpeeds.length);

        address staking;
        for (uint256 i = 0; i < len; i++) {
            staking = _verifyCreator(vaults[i]).staking;

            adminProxy.execute(
                staking,
                abi.encodeWithSelector(
                    IMultiRewardStaking.changeRewardSpeed.selector,
                    rewardTokens[i],
                    rewardsSpeeds[i]
                )
            );
        }
    }

    /**
     * @notice Funds rewards for a rewardToken.
     * @param vaults Vaults of which the staking contracts should be targeted
     * @param rewardTokens Token that can be earned by staking.
     * @param amounts The amount of rewardToken that will fund this reward.
     * @dev See `MultiRewardStaking` for more details.
     */
    function fundStakingRewards(
        address[] calldata vaults,
        IERC20[] calldata rewardTokens,
        uint256[] calldata amounts
    ) external {
        uint8 len = uint8(vaults.length);

        _verifyEqualArrayLength(len, rewardTokens.length);
        _verifyEqualArrayLength(len, amounts.length);

        address staking;
        for (uint256 i = 0; i < len; i++) {
            staking = vaultRegistry.getVault(vaults[i]).staking;

            rewardTokens[i].transferFrom(msg.sender, address(this), amounts[i]);
            IMultiRewardStaking(staking).fundReward(
                rewardTokens[i],
                amounts[i]
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                      ESCROW MANAGEMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    IMultiRewardEscrow public escrow;

    /**
     * @notice Set fees for multiple tokens. Caller must be the owner.
     * @param tokens Array of tokens.
     * @param fees Array of fees for `tokens` in 1e18. (1e18 = 100%, 1e14 = 1 BPS)
     * @dev See `MultiRewardEscrow` for more details.
     * @dev We dont need to verify array length here since its done already in `MultiRewardEscrow`
     */
    function setEscrowTokenFees(
        IERC20[] calldata tokens,
        uint256[] calldata fees
    ) external onlyOwner {
        adminProxy.execute(
            address(escrow),
            abi.encodeWithSelector(
                IMultiRewardEscrow.setFees.selector,
                tokens,
                fees
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                          TEMPLATE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds a new templateCategory to the registry. Caller must be owner.
     * @param templateCategories A new category of templates.
     * @dev See `TemplateRegistry` for more details.
     */
    function addTemplateCategories(
        bytes32[] calldata templateCategories
    ) external onlyOwner {
        address _deploymentController = address(deploymentController);
        uint8 len = uint8(templateCategories.length);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                _deploymentController,
                abi.encodeWithSelector(
                    IDeploymentController.addTemplateCategory.selector,
                    templateCategories[i]
                )
            );
        }
    }

    /**
     * @notice Toggles the endorsement of a templates. Caller must be owner.
     * @param templateCategories TemplateCategory of the template to endorse.
     * @param templateIds TemplateId of the template to endorse.
     * @dev See `TemplateRegistry` for more details.
     */
    function toggleTemplateEndorsements(
        bytes32[] calldata templateCategories,
        bytes32[] calldata templateIds
    ) external onlyOwner {
        uint8 len = uint8(templateCategories.length);
        _verifyEqualArrayLength(len, templateIds.length);

        address _deploymentController = address(deploymentController);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                address(_deploymentController),
                abi.encodeWithSelector(
                    ITemplateRegistry.toggleTemplateEndorsement.selector,
                    templateCategories[i],
                    templateIds[i]
                )
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                          PAUSING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Pause Deposits and withdraw all funds from the underlying protocol. Caller must be owner.
    function pauseAdapters(address[] calldata vaults) external onlyOwner {
        uint8 len = uint8(vaults.length);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                IVault(vaults[i]).adapter(),
                abi.encodeWithSelector(IPausable.pause.selector)
            );
        }
    }

    /// @notice Unpause Deposits and deposit all funds into the underlying protocol. Caller must be owner.
    function unpauseAdapters(address[] calldata vaults) external onlyOwner {
        uint8 len = uint8(vaults.length);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                IVault(vaults[i]).adapter(),
                abi.encodeWithSelector(IPausable.unpause.selector)
            );
        }
    }

    /// @notice Pause deposits. Caller must be owner or creator of the Vault.
    function pauseVaults(address[] calldata vaults) external {
        uint8 len = uint8(vaults.length);
        for (uint256 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);
            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(IPausable.pause.selector)
            );
        }
    }

    /// @notice Unpause deposits. Caller must be owner or creator of the Vault.
    function unpauseVaults(address[] calldata vaults) external {
        uint8 len = uint8(vaults.length);
        for (uint256 i = 0; i < len; i++) {
            _verifyCreator(vaults[i]);
            adminProxy.execute(
                vaults[i],
                abi.encodeWithSelector(IPausable.unpause.selector)
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                       VERIFICATION LOGIC
    //////////////////////////////////////////////////////////////*/

    error NotSubmitterNorOwner(address caller);
    error NotSubmitter(address caller);
    error NotAllowed(address subject);
    error ArrayLengthMismatch();

    /// @notice Verify that the caller is the creator of the vault or owner of `VaultController` (admin rights).
    function _verifyCreatorOrOwner(
        address vault
    ) internal returns (VaultMetadata memory metadata) {
        metadata = vaultRegistry.getVault(vault);
        if (msg.sender != metadata.creator && msg.sender != owner)
            revert NotSubmitterNorOwner(msg.sender);
    }

    /// @notice Verify that the caller is the creator of the vault.
    function _verifyCreator(
        address vault
    ) internal view returns (VaultMetadata memory metadata) {
        metadata = vaultRegistry.getVault(vault);
        if (msg.sender != metadata.creator) revert NotSubmitter(msg.sender);
    }

    /// @notice Verify that the token is not rejected nor a clone.
    function _verifyToken(address token) internal view {
        if (
            (
                permissionRegistry.endorsed(address(0))
                    ? !permissionRegistry.endorsed(token)
                    : permissionRegistry.rejected(token)
            ) ||
            cloneRegistry.cloneExists(token) ||
            token == address(0)
        ) revert NotAllowed(token);
    }

    /// @notice Verify that the array lengths are equal.
    function _verifyEqualArrayLength(
        uint256 length1,
        uint256 length2
    ) internal pure {
        if (length1 != length2) revert ArrayLengthMismatch();
    }

    modifier canCreate() {
        if (
            permissionRegistry.endorsed(address(1))
                ? !permissionRegistry.endorsed(msg.sender)
                : permissionRegistry.rejected(msg.sender)
        ) revert NotAllowed(msg.sender);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    IAdminProxy public adminProxy;

    /**
     * @notice Nominates a new owner of `AdminProxy`. Caller must be owner.
     * @dev Must be called if the `VaultController` gets swapped out or upgraded
     */
    function nominateNewAdminProxyOwner(address newOwner) external onlyOwner {
        adminProxy.nominateNewOwner(newOwner);
    }

    /**
     * @notice Accepts ownership of `AdminProxy`. Caller must be nominated owner.
     * @dev Must be called after construction
     */
    function acceptAdminProxyOwnership() external {
        adminProxy.acceptOwnership();
    }

    /*//////////////////////////////////////////////////////////////
                          MANAGEMENT FEE LOGIC
    //////////////////////////////////////////////////////////////*/

    uint256 public performanceFee;

    event PerformanceFeeChanged(uint256 oldFee, uint256 newFee);

    error InvalidPerformanceFee(uint256 fee);

    /**
     * @notice Set a new performanceFee for all new adapters. Caller must be owner.
     * @param newFee performance fee in 1e18.
     * @dev Fees can be 0 but never more than 2e17 (1e18 = 100%, 1e14 = 1 BPS)
     * @dev Can be retroactively applied to existing adapters.
     */
    function setPerformanceFee(uint256 newFee) external onlyOwner {
        // Dont take more than 20% performanceFee
        if (newFee > 2e17) revert InvalidPerformanceFee(newFee);

        emit PerformanceFeeChanged(performanceFee, newFee);

        performanceFee = newFee;
    }

    /**
     * @notice Set a new performanceFee for existing adapters. Caller must be owner.
     * @param adapters array of adapters to set the management fee for.
     */
    function setAdapterPerformanceFees(
        address[] calldata adapters
    ) external onlyOwner {
        uint8 len = uint8(adapters.length);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                adapters[i],
                abi.encodeWithSelector(
                    IAdapter.setPerformanceFee.selector,
                    performanceFee
                )
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                          HARVEST COOLDOWN LOGIC
    //////////////////////////////////////////////////////////////*/

    uint256 public harvestCooldown;

    event HarvestCooldownChanged(uint256 oldCooldown, uint256 newCooldown);

    error InvalidHarvestCooldown(uint256 cooldown);

    /**
     * @notice Set a new harvestCooldown for all new adapters. Caller must be owner.
     * @param newCooldown Time in seconds that must pass before a harvest can be called again.
     * @dev Cant be longer than 1 day.
     * @dev Can be retroactively applied to existing adapters.
     */
    function setHarvestCooldown(uint256 newCooldown) external onlyOwner {
        // Dont wait more than X seconds
        if (newCooldown > 1 days) revert InvalidHarvestCooldown(newCooldown);

        emit HarvestCooldownChanged(harvestCooldown, newCooldown);

        harvestCooldown = newCooldown;
    }

    /**
     * @notice Set a new harvestCooldown for existing adapters. Caller must be owner.
     * @param adapters Array of adapters to set the cooldown for.
     */
    function setAdapterHarvestCooldowns(
        address[] calldata adapters
    ) external onlyOwner {
        uint8 len = uint8(adapters.length);
        for (uint256 i = 0; i < len; i++) {
            adminProxy.execute(
                adapters[i],
                abi.encodeWithSelector(
                    IAdapter.setHarvestCooldown.selector,
                    harvestCooldown
                )
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                      DEPLYOMENT CONTROLLER LOGIC
    //////////////////////////////////////////////////////////////*/

    IDeploymentController public deploymentController;
    ICloneRegistry public cloneRegistry;
    ITemplateRegistry public templateRegistry;
    IPermissionRegistry public permissionRegistry;

    event DeploymentControllerChanged(
        address oldController,
        address newController
    );

    error InvalidDeploymentController(address deploymentController);

    /**
     * @notice Sets a new `DeploymentController` and saves its auxilary contracts. Caller must be owner.
     * @param _deploymentController New DeploymentController.
     */
    function setDeploymentController(
        IDeploymentController _deploymentController
    ) external onlyOwner {
        _setDeploymentController(_deploymentController);
    }

    function _setDeploymentController(
        IDeploymentController _deploymentController
    ) internal {
        if (
            address(_deploymentController) == address(0) ||
            address(deploymentController) == address(_deploymentController)
        ) revert InvalidDeploymentController(address(_deploymentController));

        emit DeploymentControllerChanged(
            address(deploymentController),
            address(_deploymentController)
        );

        // Dont try to change ownership on construction
        if (address(deploymentController) != address(0))
            _transferDependencyOwnership(address(_deploymentController));

        deploymentController = _deploymentController;
        cloneRegistry = _deploymentController.cloneRegistry();
        templateRegistry = _deploymentController.templateRegistry();
    }

    function _transferDependencyOwnership(
        address _deploymentController
    ) internal {
        adminProxy.execute(
            address(deploymentController),
            abi.encodeWithSelector(
                IDeploymentController.nominateNewDependencyOwner.selector,
                _deploymentController
            )
        );

        adminProxy.execute(
            _deploymentController,
            abi.encodeWithSelector(
                IDeploymentController.acceptDependencyOwnership.selector,
                ""
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                      TEMPLATE KEY LOGIC
    //////////////////////////////////////////////////////////////*/

    mapping(bytes32 => bytes32) public activeTemplateId;

    event ActiveTemplateIdChanged(bytes32 oldKey, bytes32 newKey);

    error SameKey(bytes32 templateKey);

    /**
     * @notice Set a templateId which shall be used for deploying certain contracts. Caller must be owner.
     * @param templateCategory TemplateCategory to set an active key for.
     * @param templateId TemplateId that should be used when creating a new contract of `templateCategory`
     * @dev Currently `Vault` and `Staking` use a template set via `activeTemplateId`.
     * @dev If this contract should deploy Vaults of a second generation this can be set via the `activeTemplateId`.
     */
    function setActiveTemplateId(
        bytes32 templateCategory,
        bytes32 templateId
    ) external onlyOwner {
        bytes32 oldTemplateId = activeTemplateId[templateCategory];
        if (oldTemplateId == templateId) revert SameKey(templateId);

        emit ActiveTemplateIdChanged(oldTemplateId, templateId);

        activeTemplateId[templateCategory] = templateId;
    }
}