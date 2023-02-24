// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable not-rely-on-time, max-states-count

// inheritance
import "./lib/BaseInstaller.sol";
import "../interface/installer/IGameFiInstallerV1.sol";

// libs
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// external interfaces
import "../interface/core/IGameFiCoreV2.sol";
import "../interface/module/shop/IGameFiShopV1.sol";
import "../interface/module/marketplace/IGameFiMarketplaceV1.sol";
import "../interface/module/router/IZOARouterV1.sol";
import "../interface/module/multiTransactor/IMultiTransactorV2.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

contract GameFiInstallerV1 is BaseInstaller, IGameFiInstallerV1 {
    using AddressUpgradeable for address;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    modifier onlyAdminOrOperator() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(OPERATOR_ROLE, _msgSender()),
            "GameFiInstallerV1: caller is not the admin/operator"
        );
        _;
    }

    modifier onlyOperator() {
        _checkRole(OPERATOR_ROLE, _msgSender());
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() external initializer {
        __BaseInstaller_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function deployEnvironment(InstallerV1Settings memory envSettings)
        external
        onlyAdminOrOperator
        returns (uint256 environmentId, Environment memory environment)
    {
        // create new env
        (, uint256 envId) = _createEnv(envSettings.envName, envSettings.envTag);

        // deploy gameFiCore
        (EnvInstance memory gameFiCoreInst, ) = _createInstance(
            envId,
            _ENVTYPE_GAMEFI_CORE,
            envSettings.gameFiCoreImpl,
            envSettings.gameFiCoreInitializeData
        );

        // deploy shops
        (EnvInstance memory gameFiShopsInst, ) = _createInstance(
            envId,
            _ENVTYPE_GAMEFI_SHOPS,
            envSettings.gameFiShopsImpl,
            abi.encodeWithSelector(IGameFiShopV1.initialize.selector, gameFiCoreInst.instanceContract)
        );

        // deploy marketplace
        (EnvInstance memory gameFiMarketplaceInst, ) = _createInstance(
            envId,
            _ENVTYPE_GAMEFI_MARKETPLACE,
            envSettings.gameFiMarketplaceImpl,
            abi.encodeWithSelector(IGameFiMarketplaceV1.initialize.selector, gameFiCoreInst.instanceContract)
        );

        // deploy router
        _createInstance(
            envId,
            _ENVTYPE_GAMEFI_ROUTER,
            envSettings.gameFiRouterImpl,
            // TODO сделать самостоятельный ввод инициализаторов
            abi.encodeWithSelector(
                IZOARouterV1.initialize.selector,
                gameFiCoreInst.instanceContract,
                gameFiShopsInst.instanceContract,
                gameFiMarketplaceInst.instanceContract,
                uint256(0),
                uint256(1)
            )
        );

        // deploy multitransactor
        (EnvInstance memory multitransactorInst, ) = _createInstance(
            envId,
            _ENVTYPE_GAMEFI_MULTITRANSACTOR,
            envSettings.multitransactorImpl,
            abi.encodeWithSelector(IMultiTransactorV2.initialize.selector)
        );

        // setup gameFiCore
        {
            // create avatar property
            gameFiCoreInst.instanceContract.functionCall(envSettings.createPropertyAvatarData);

            // create name property
            gameFiCoreInst.instanceContract.functionCall(envSettings.createPropertyNameData);

            // create avatar collection
            gameFiCoreInst.instanceContract.functionCall(envSettings.createCollectionAvatarsData);

            // create boxes collection
            gameFiCoreInst.instanceContract.functionCall(envSettings.createCollectionBoxesData);

            // setup ownership
            IAccessControlEnumerableUpgradeable(gameFiCoreInst.instanceContract).grantRole(
                bytes32(0),
                envSettings.envAdmin
            );
            IAccessControlEnumerableUpgradeable(gameFiCoreInst.instanceContract).grantRole(
                keccak256("OPERATOR_ROLE"),
                envSettings.envOperator
            );
            IAccessControlEnumerableUpgradeable(gameFiCoreInst.instanceContract).grantRole(
                keccak256("OPERATOR_ROLE"),
                multitransactorInst.instanceContract
            );

            IAccessControlEnumerableUpgradeable(gameFiCoreInst.instanceContract).grantRole(bytes32(0), msg.sender);
            IAccessControlEnumerableUpgradeable(gameFiCoreInst.instanceContract).grantRole(
                keccak256("OPERATOR_ROLE"),
                msg.sender
            );

            IAccessControlEnumerableUpgradeable(gameFiCoreInst.instanceContract).renounceRole(
                bytes32(0),
                address(this)
            );

            IAccessControlEnumerableUpgradeable(multitransactorInst.instanceContract).grantRole(
                keccak256("TRANSACTOR_ROLE"),
                envSettings.envOperator
            );
            IAccessControlEnumerableUpgradeable(multitransactorInst.instanceContract).grantRole(
                keccak256("TRANSACTOR_ROLE"),
                msg.sender
            );
            IAccessControlEnumerableUpgradeable(multitransactorInst.instanceContract).grantRole(bytes32(0), msg.sender);
            IAccessControlEnumerableUpgradeable(multitransactorInst.instanceContract).renounceRole(
                bytes32(0),
                address(this)
            );
        }
    }
}