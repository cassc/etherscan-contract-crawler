// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/**
 * @title CoreAuth
 * @notice Contains core authorization logic
 */
contract CoreAuth {
    error NotGovernance(address);
    error NotPendingGovernance(address);
    error NullAddress();

    event GovernanceTransferRequested(address indexed previousGovernance, address indexed newGovernance);
    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);
    event GuardianUpdated(address indexed previousGuardian, address indexed newGuardian);
    event FundManagerUpdated(address indexed previousFundManager, address indexed newFundManager);

    /**
     * @notice Governance
     */
    address public governance;

    /**
     * @notice PendingGovernance - used for transferring governance in a 2 step process
     */
    address public pendingGovernance;

    /**
     * @notice Guardian - has authority to pause the safe module execution
     */
    address public guardian;

    /**
     * @notice FundManager - responsible for funding keeper bots and target for payable execution fees
     */
    address public fundManager;

    constructor(address _governance, address _guardian, address _fundManager) {
        _notNull(_governance);
        _notNull(_guardian);
        _notNull(_fundManager);
        governance = _governance;
        guardian = _guardian;
        fundManager = _fundManager;
    }

    /**
     * @notice Guardian setter
     */
    function setGuardian(address _newGuardian) external {
        _notNull(_newGuardian);
        _onlyGov();
        emit GuardianUpdated(guardian, _newGuardian);
        guardian = _newGuardian;
    }

    /**
     * @notice FundManager setter
     */
    function setFundManager(address _newFundManager) external {
        _notNull(_newFundManager);
        _onlyGov();
        emit FundManagerUpdated(fundManager, _newFundManager);
        fundManager = _newFundManager;
    }

    /**
     * @notice Governance setter
     */
    function setGovernance(address _newGovernance) external {
        _notNull(_newGovernance);
        _onlyGov();
        emit GovernanceTransferRequested(governance, _newGovernance);
        pendingGovernance = _newGovernance;
    }

    /**
     * @notice Governance accepter
     */
    function acceptGovernance() external {
        if (msg.sender != pendingGovernance) {
            revert NotPendingGovernance(msg.sender);
        }
        emit GovernanceTransferred(governance, msg.sender);
        governance = msg.sender;
        delete pendingGovernance;
    }

    /**
     * @notice helper function to check if msg.sender is governance
     */
    function _onlyGov() internal view {
        if (msg.sender != governance) revert NotGovernance(msg.sender);
    }

    /**
     * @notice helper function to check if address is null
     */
    function _notNull(address addr) internal pure {
        if (addr == address(0)) revert NullAddress();
    }
}

interface IAddressProviderService {
    /// @notice Returns the address of the AddressProvider
    function addressProviderTarget() external view returns (address);
}

/**
 * @title AddressProvider
 * @notice Stores addresses of external contracts and core components
 */
contract AddressProvider is CoreAuth {
    enum RegistryKey {
        STRATEGY,
        SUBSCRIPTION,
        SUBACCOUNT,
        WALLET_ADAPTER,
        WALLET
    }

    error AddressProviderUnsupported();
    error AlreadyInitialised();
    error RegistryKeyNotFound(uint8);

    event RegistryInitialised(address indexed registry, uint8 indexed registryKey);

    constructor(address _governance, address _guardian, address _fundManager)
        CoreAuth(_governance, _guardian, _fundManager)
    {}

    /**
     * @dev External contract addresses for Gnosis Safe deployments
     *     Can be updated by governance
     */
    address public gnosisProxyFactory;
    address public gnosisSafeSingleton;
    address public gnosisFallbackHandler;
    address public gnosisMultiSend;

    /**
     * @dev Registry contracts containing state
     *     Cannot be updated
     */
    address public strategyRegistry;
    address public subscriptionRegistry;
    address public subAccountRegistry;
    address public walletAdapterRegistry;
    address public walletRegistry;

    /**
     * @dev Contract addresses for core components
     *     Can be updated by governance
     */
    address public botManager;
    address public brahRouter;
    address public priceFeedManager;
    address public safeDeployer;

    function setGnosisProxyFactory(address _gnosisProxyFactory) external {
        _notNull(_gnosisProxyFactory);
        _onlyGov();
        gnosisProxyFactory = (_gnosisProxyFactory);
    }

    function setGnosisSafeSingleton(address _gnosisSafeSingleton) external {
        _notNull(_gnosisSafeSingleton);
        _onlyGov();
        gnosisSafeSingleton = (_gnosisSafeSingleton);
    }

    /// @dev Fallback handler can be null
    function setGnosisSafeFallbackHandler(address _gnosisFallbackHandler) external {
        _onlyGov();
        gnosisFallbackHandler = (_gnosisFallbackHandler);
    }

    function setGnosisMultiSend(address _gnosisMultiSend) external {
        _notNull(_gnosisMultiSend);
        _onlyGov();
        gnosisMultiSend = (_gnosisMultiSend);
    }

    /**
     * @dev CAUTION! Changing BotManager will break existing tasks
     *     and wont allow deletion of previously created tasks
     */
    function setBotManager(address _botManager) external {
        _onlyGov();
        _supportsAddressProvider(_botManager);
        botManager = (_botManager);
    }

    /**
     * @dev CAUTION! Changing PriceFeedManager will require adding price
     *      feeds for all existing tokens
     */
    function setPriceFeedManager(address _priceFeedManager) external {
        _onlyGov();
        _supportsAddressProvider(_priceFeedManager);
        priceFeedManager = _priceFeedManager;
    }

    /**
     * @dev CAUTION! Changing BrahRouter will require all existing wallets
     *     to re register new BrahRouter as a safe module
     */
    function setBrahRouter(address _brahRouter) external {
        _onlyGov();
        _supportsAddressProvider(_brahRouter);
        brahRouter = (_brahRouter);
    }

    /**
     * @dev CAUTION! Changing SafeDeployer will loose any existing
     *     reserve subAccounts present
     */
    function setSafeDeployer(address _safeDeployer) external {
        _onlyGov();
        _supportsAddressProvider(_safeDeployer);
        safeDeployer = (_safeDeployer);
    }

    /**
     * @notice Initialises a registry contract
     * @dev Ensures that the registry contract is not already initialised
     *  CAUTION! Does not check if registry contract is valid or supports AddressProviderService
     *  This is to enable the registry contract to be initialised before their deployment
     * @param key RegistryKey
     * @param _newAddress Address of the registry contract
     */
    function initRegistry(RegistryKey key, address _newAddress) external {
        _onlyGov();
        if (key == RegistryKey.STRATEGY) {
            _firstInit(address(strategyRegistry));
            strategyRegistry = (_newAddress);
        } else if (key == RegistryKey.SUBSCRIPTION) {
            _firstInit(address(subscriptionRegistry));
            subscriptionRegistry = (_newAddress);
        } else if (key == RegistryKey.SUBACCOUNT) {
            _firstInit(address(subAccountRegistry));
            subAccountRegistry = (_newAddress);
        } else if (key == RegistryKey.WALLET_ADAPTER) {
            _firstInit(address(walletAdapterRegistry));
            walletAdapterRegistry = (_newAddress);
        } else if (key == RegistryKey.WALLET) {
            _firstInit(address(walletRegistry));
            walletRegistry = (_newAddress);
        } else {
            revert RegistryKeyNotFound(uint8(key));
        }

        emit RegistryInitialised(_newAddress, uint8(key));
    }

    /**
     * @notice Ensures that the new address supports the AddressProviderService interface
     * and is pointing to this AddressProvider
     */
    function _supportsAddressProvider(address _newAddress) internal view {
        if (IAddressProviderService(_newAddress).addressProviderTarget() != address(this)) {
            revert AddressProviderUnsupported();
        }
    }

    /**
     * @notice Ensures that the registry is not already initialised
     */
    function _firstInit(address _existingAddress) internal pure {
        if (_existingAddress != address(0)) revert AlreadyInitialised();
    }
}