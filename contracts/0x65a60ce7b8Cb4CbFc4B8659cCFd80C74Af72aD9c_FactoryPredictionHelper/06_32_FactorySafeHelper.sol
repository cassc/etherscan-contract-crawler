// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFactorySafeHelper.sol";
import "./interfaces/IGnosisSafe.sol";
import "./interfaces/IGnosisSafeProxyFactory.sol";
import "./interfaces/IGnosisSafeModuleProxyFactory.sol";
import "./interfaces/IWyvernProxyRegistry.sol";

contract FactorySafeHelper is IFactorySafeHelper {
    IGnosisSafeProxyFactory public immutable GNOSIS_SAFE_PROXY_FACTORY;
    IGnosisSafeModuleProxyFactory
        public immutable GNOSIS_SAFE_MODULE_PROXY_FACTORY;

    address public immutable ORACLE;
    address public immutable GNOSIS_SAFE_TEMPLATE_ADDRESS;
    address public immutable GNOSIS_SAFE_FALLBACK_HANDLER;
    address public immutable REALITY_MODULE_TEMPLATE_ADDRESS;
    address public immutable WYVERN_PROXY_REGISTRY;
    address public immutable SZNS_DAO;
    uint256 public immutable REALITIO_TEMPLATE_ID;

    uint256 public immutable DAO_MODULE_BOND;
    uint32 public immutable DAO_MODULE_EXPIRATION;
    uint32 public immutable DAO_MODULE_TIMEOUT;

    constructor(
        address proxyFactoryAddress,
        address moduleProxyFactoryAddress,
        address realitioAddress,
        address safeTemplateAddress,
        address safeFallbackHandler,
        address realityModuleTemplateAddress,
        address wyvernProxyRegistry,
        address sznsDao,
        uint256 realitioTemplateId,
        uint256 bond,
        uint32 expiration,
        uint32 timeout
    ) {
        GNOSIS_SAFE_PROXY_FACTORY = IGnosisSafeProxyFactory(
            proxyFactoryAddress
        );
        GNOSIS_SAFE_MODULE_PROXY_FACTORY = IGnosisSafeModuleProxyFactory(
            moduleProxyFactoryAddress
        );
        ORACLE = realitioAddress;

        GNOSIS_SAFE_TEMPLATE_ADDRESS = safeTemplateAddress;
        GNOSIS_SAFE_FALLBACK_HANDLER = safeFallbackHandler;
        REALITY_MODULE_TEMPLATE_ADDRESS = realityModuleTemplateAddress;
        WYVERN_PROXY_REGISTRY = wyvernProxyRegistry;
        SZNS_DAO = sznsDao;
        REALITIO_TEMPLATE_ID = realitioTemplateId;

        DAO_MODULE_BOND = bond;
        DAO_MODULE_EXPIRATION = expiration;
        DAO_MODULE_TIMEOUT = timeout;
    }

    function createAndSetupSafe(bytes32 salt)
        external
        override
        returns (address safeAddress, address realityModule)
    {
        salt = keccak256(abi.encode(salt, msg.sender, address(this)));
        // Deploy safe
        IGnosisSafe safe = GNOSIS_SAFE_PROXY_FACTORY.createProxyWithNonce(
            GNOSIS_SAFE_TEMPLATE_ADDRESS,
            "",
            uint256(salt)
        );
        safeAddress = address(safe);
        // Deploy reality module
        realityModule = GNOSIS_SAFE_MODULE_PROXY_FACTORY.deployModule(
            REALITY_MODULE_TEMPLATE_ADDRESS,
            abi.encodeWithSignature(
                "setUp(bytes)",
                abi.encode(
                    safeAddress,
                    safeAddress,
                    safeAddress,
                    ORACLE,
                    DAO_MODULE_TIMEOUT,
                    0, // cooldown, hard-coded to 0
                    DAO_MODULE_EXPIRATION,
                    DAO_MODULE_BOND,
                    REALITIO_TEMPLATE_ID,
                    SZNS_DAO
                )
            ),
            0 // salt
        );
        // Initialize safe
        address[] memory owners = new address[](1);
        owners[0] = 0x000000000000000000000000000000000000dEaD;
        safe.setup(
            owners, // owners
            1, // threshold
            address(this), // to
            abi.encodeCall( // data
                this.initSafe,
                (realityModule, WYVERN_PROXY_REGISTRY)
            ),
            GNOSIS_SAFE_FALLBACK_HANDLER, // fallbackHandler
            address(0), // paymentToken
            0, // payment
            payable(0) // paymentReceiver
        );
    }

    function initSafe(
        address realityModuleAddress,
        address wyvernProxyRegistryAddress
    ) external {
        IGnosisSafe(address(this)).enableModule(realityModuleAddress);
        IWyvernProxyRegistry(wyvernProxyRegistryAddress).registerProxy();
    }
}