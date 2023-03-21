pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { LiquidStakingManager } from "./LiquidStakingManager.sol";
import { GiantPoolBase } from "./GiantPoolBase.sol";
import { UpgradeableBeacon } from "../proxy/UpgradeableBeacon.sol";
import { IGiantSavETHVaultPool } from "../interfaces/IGiantSavETHVaultPool.sol";
import { IGiantMevAndFeesPool } from "../interfaces/IGiantMevAndFeesPool.sol";

/// @notice Contract for deploying a new Liquid Staking Derivative Network (LSDN)
contract LSDNFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    /// @notice Emitted when a new liquid staking manager is deployed
    event LSDNDeployed(address indexed LiquidStakingManager);

    /// @notice Beacon for any liquid staking manager proxies
    address public liquidStakingManagerBeacon;

    /// @notice Address of the liquid staking manager implementation that is cloned on each deployment
    address public liquidStakingManagerImplementation;

    /// @notice Address of the factory that will deploy a syndicate for the network after the first knot is created
    address public syndicateFactory;

    /// @notice Address of the factory for deploying LP tokens in exchange for ETH supplied to stake a KNOT
    address public lpTokenFactory;

    /// @notice Address of the factory for deploying smart wallets used by node runners during staking
    address public smartWalletFactory;

    /// @notice Address of brand NFT
    address public brand;

    /// @notice Address of the contract that can deploy new instances of SavETHVault
    address public savETHVaultDeployer;

    /// @notice Address of the contract that can deploy new instances of StakingFundsVault
    address public stakingFundsVaultDeployer;

    /// @notice Address of the contract that can deploy new instances of optional gatekeepers for controlling which knots can join the LSDN house
    address public optionalGatekeeperDeployer;

    /// @notice Address of associated giant protected staking pool
    GiantPoolBase public giantSavETHPool;

    /// @notice Address of giant fees and mev pool
    GiantPoolBase public giantFeesAndMev;

    /// @notice Establishes whether a given liquid staking manager address was deployed by this factory
    mapping(address => bool) public isLiquidStakingManager;

    /// @notice Establishes whether a given savETH vault belongs to a LSD network deployed by the factory
    mapping(address => bool) public isSavETHVault;

    /// @notice Establishes whether a given Staking funds vault belongs to a LSD network deployed by the factory
    mapping(address => bool) public isStakingFundsVault;

    /// @notice Initialization parameters required to deploy the LSDN factory
    struct InitParams {
        address _liquidStakingManagerImplementation;
        address _syndicateFactory;
        address _lpTokenFactory;
        address _smartWalletFactory;
        address _brand;
        address _savETHVaultDeployer;
        address _stakingFundsVaultDeployer;
        address _optionalGatekeeperDeployer;
        address _giantSavETHImplementation;
        address _giantFeesAndMevImplementation;
        address _giantLPDeployer;
        address _upgradeManager;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice External one time function for initializing the factory
    function init(InitParams memory _params) external initializer {
        _init(_params);
        _transferOwnership(_params._upgradeManager);
    }

    /// @dev Owner based upgrades
    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /// @dev Internal initialization logic that can be called from mock harness contracts
    function _init(InitParams memory _params) internal {
        require(_params._liquidStakingManagerImplementation != address(0), "Zero Address");
        require(_params._syndicateFactory != address(0), "Zero Address");
        require(_params._lpTokenFactory != address(0), "Zero Address");
        require(_params._smartWalletFactory != address(0), "Zero Address");
        require(_params._brand != address(0), "Zero Address");
        require(_params._savETHVaultDeployer != address(0), "Zero Address");
        require(_params._stakingFundsVaultDeployer != address(0), "Zero Address");
        require(_params._optionalGatekeeperDeployer != address(0), "Zero Address");

        liquidStakingManagerImplementation = _params._liquidStakingManagerImplementation;
        syndicateFactory = _params._syndicateFactory;
        lpTokenFactory = _params._lpTokenFactory;
        smartWalletFactory = _params._smartWalletFactory;
        brand = _params._brand;
        savETHVaultDeployer = _params._savETHVaultDeployer;
        stakingFundsVaultDeployer = _params._stakingFundsVaultDeployer;
        optionalGatekeeperDeployer = _params._optionalGatekeeperDeployer;

        liquidStakingManagerBeacon = address(new UpgradeableBeacon(
                liquidStakingManagerImplementation,
                _params._upgradeManager
            ));

        ERC1967Proxy giantFeesAndMevProxy = new ERC1967Proxy(
            _params._giantFeesAndMevImplementation,
            abi.encodeCall(
                IGiantMevAndFeesPool(_params._giantFeesAndMevImplementation).init,
                (LSDNFactory(address(this)), _params._giantLPDeployer, _params._upgradeManager)
            )
        );
        giantFeesAndMev = GiantPoolBase(address(giantFeesAndMevProxy));

        ERC1967Proxy giantSavETHProxy = new ERC1967Proxy(
            _params._giantSavETHImplementation,
            abi.encodeCall(
                IGiantSavETHVaultPool(_params._giantSavETHImplementation).init,
                (LSDNFactory(address(this)), _params._giantLPDeployer, address(giantFeesAndMev), _params._upgradeManager)
            )
        );
        giantSavETHPool = GiantPoolBase(address(giantSavETHProxy));

    }

    /// @notice Deploys a new LSDN and the liquid staking manger required to manage the network
    /// @param _dao Address of the entity that will govern the liquid staking network
    /// @param _stakehouseTicker Liquid staking derivative network ticker (between 3-5 chars)
    function deployNewLiquidStakingDerivativeNetwork(
        address _dao,
        uint256 _optionalCommission,
        bool _deployOptionalHouseGatekeeper,
        string calldata _stakehouseTicker
    ) public returns (address) {
        // Clone a new liquid staking manager instance
        address newInstance = _deployNewInstance(_dao, _optionalCommission, _deployOptionalHouseGatekeeper, _stakehouseTicker);

        _registerLSDInstance(newInstance);

        emit LSDNDeployed(newInstance);

        return newInstance;
    }

    /// @dev deploy a new beacon based liquid staking manager instance
    function _deployNewInstance(
        address _dao,
        uint256 _optionalCommission,
        bool _deployOptionalHouseGatekeeper,
        string calldata _stakehouseTicker
    ) internal returns (address) {
        return address(new BeaconProxy(
                liquidStakingManagerBeacon,
                abi.encodeCall(
                    LiquidStakingManager(payable(liquidStakingManagerImplementation)).init,
                    (
                        _dao,
                        syndicateFactory,
                        smartWalletFactory,
                        lpTokenFactory,
                        brand,
                        savETHVaultDeployer,
                        stakingFundsVaultDeployer,
                        optionalGatekeeperDeployer,
                        _optionalCommission,
                        _deployOptionalHouseGatekeeper,
                        _stakehouseTicker
                    )
                )
            ));
    }

    /// @dev Register the core contracts of an LSD network that were deployed by the factory
    function _registerLSDInstance(address _newInstance) internal {
        LiquidStakingManager lsdInstance = LiquidStakingManager(payable(_newInstance));

        // Record that the manager was deployed by this contract
        isLiquidStakingManager[_newInstance] = true;
        isSavETHVault[address(lsdInstance.savETHVault())] = true;
        isStakingFundsVault[address(lsdInstance.stakingFundsVault())] = true;
    }
}