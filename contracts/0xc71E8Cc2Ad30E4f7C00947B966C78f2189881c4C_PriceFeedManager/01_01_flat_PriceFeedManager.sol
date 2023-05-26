// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/// @notice chainlink aggregator interface
interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface IAddressProviderService {
    /// @notice Returns the address of the AddressProvider
    function addressProviderTarget() external view returns (address);
}

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

/**
 * @title AddressProviderService
 * @notice Provides a base contract for services that require access to the AddressProvider
 * @dev This contract is designed to be inheritable by other contracts
 *  Provides quick and easy access to all contracts in Console Ecosystem
 */
abstract contract AddressProviderService is IAddressProviderService {
    error InvalidAddressProvider();
    error NotGovernance(address);
    error InvalidAddress();

    AddressProvider public immutable addressProvider;
    address public immutable strategyRegistry;
    address public immutable subscriptionRegistry;
    address public immutable subAccountRegistry;
    address public immutable walletAdapterRegistry;
    address public immutable walletRegistry;

    constructor(address _addressProvider) {
        if (_addressProvider == address(0)) revert InvalidAddressProvider();
        addressProvider = AddressProvider(_addressProvider);
        strategyRegistry = addressProvider.strategyRegistry();
        _notNull(strategyRegistry);
        subscriptionRegistry = addressProvider.subscriptionRegistry();
        _notNull(subscriptionRegistry);
        subAccountRegistry = addressProvider.subAccountRegistry();
        _notNull(subAccountRegistry);
        walletAdapterRegistry = addressProvider.walletAdapterRegistry();
        _notNull(walletAdapterRegistry);
        walletRegistry = addressProvider.walletRegistry();
        _notNull(walletRegistry);
    }

    /**
     * @inheritdoc IAddressProviderService
     */
    function addressProviderTarget() external view override returns (address) {
        return address(addressProvider);
    }

    /**
     * @notice Checks if msg.sender is governance
     */
    function _onlyGov() internal view {
        if (msg.sender != addressProvider.governance()) {
            revert NotGovernance(msg.sender);
        }
    }

    function _notNull(address _addr) internal pure {
        if (_addr == address(0)) revert InvalidAddress();
    }
}

/**
 * @title PriceFeedManager
 *   @notice Manages multiple tokens and their chainlink price feeds, for token price conversions
 */
contract PriceFeedManager is AddressProviderService {
    error NotUSDPriceFeed(address feed);
    error InvalidPriceFeed(address feed);
    error InvalidERC20Decimals(address token);
    error InvalidPriceFromRound(uint80 roundId);
    error InvalidWETHAddress();
    error PriceFeedStale();
    error TokenPriceFeedNotFound(address token);

    struct PriceFeedData {
        uint8 _tokenDecimals;
        address _address;
        uint64 _staleFeedThreshold;
    }

    /// @notice default stale threshold to price feeds on being added
    uint64 public constant DEFAULT_STALE_FEED_THRESHOLD = 90000;
    /// @notice address of ETH
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @notice address of WETH
    address public immutable WETH;

    /// @notice mapping of token address to data of price feed (_address, _staleFeedThreshold, _tokenDecimals)
    mapping(address token => PriceFeedData priceFeedData) public tokenPriceFeeds;

    constructor(address _addressProvider, address _weth) AddressProviderService(_addressProvider) {
        if (_weth == address(0)) revert InvalidWETHAddress();
        WETH = _weth;
    }

    /**
     * @notice Returns the pride feed data associated with a given token address
     * @param token address of token to get price feed data for
     * @return priceFeedData data of the price feed
     */
    function getPriceFeedData(address token) public view returns (PriceFeedData memory priceFeedData) {
        priceFeedData = tokenPriceFeeds[token];

        if (priceFeedData._address == address(0)) {
            revert TokenPriceFeedNotFound(token);
        }
    }

    /**
     * @notice Governance function to set the price feed for a token address
     * @param token address of a valid ERC20 token or native ETH
     * @param priceFeed address of a valid chainlink USD price feed
     * @param optionalStaleFeedThreshold optional stale feed threshold to set, defaults to 90000
     */
    function setTokenPriceFeed(address token, address priceFeed, uint64 optionalStaleFeedThreshold) external {
        _onlyGov();
        uint8 tokenDecimals = 0;

        try IAggregatorV3(priceFeed).decimals() returns (uint8 _decimals) {
            if (_decimals != 8) revert NotUSDPriceFeed(priceFeed);
        } catch {
            revert InvalidPriceFeed(priceFeed);
        }

        if (token != ETH) {
            try IERC20Metadata(token).decimals() returns (uint8 _decimals) {
                if (_decimals > 18) revert InvalidERC20Decimals(token);

                tokenDecimals = _decimals;
            } catch {
                revert InvalidERC20Decimals(token);
            }
        } else {
            tokenDecimals = 18;
        }

        if (optionalStaleFeedThreshold == 0) {
            optionalStaleFeedThreshold = DEFAULT_STALE_FEED_THRESHOLD;
        }

        try IAggregatorV3(priceFeed).latestRoundData() returns (
            uint80 roundId, int256 price, uint256, uint256 updatedAt, uint80 answeredInRound
        ) {
            _validateRound(roundId, answeredInRound, price, updatedAt, optionalStaleFeedThreshold);
        } catch {
            revert InvalidPriceFeed(priceFeed);
        }

        PriceFeedData storage priceFeedData = tokenPriceFeeds[token];
        priceFeedData._address = priceFeed;
        priceFeedData._staleFeedThreshold = optionalStaleFeedThreshold;
        priceFeedData._tokenDecimals = tokenDecimals;
    }

    /**
     * @notice Governance function to set the stake feed threshold of a given token
     * @param token address of token to modify stale feed threshold for
     * @param _staleFeedThreshold the stale feed threshold to set
     */
    function setTokenPriceFeedStaleThreshold(address token, uint64 _staleFeedThreshold) external {
        _onlyGov();

        PriceFeedData storage priceFeedData = tokenPriceFeeds[token];

        if (priceFeedData._address == address(0)) {
            revert TokenPriceFeedNotFound(token);
        }

        priceFeedData._staleFeedThreshold = _staleFeedThreshold;
    }

    /**
     * @notice Returns the token price given the token address
     * @param token address of token
     * @return price of token
     */
    function getTokenPrice(address token) external view returns (uint256 price) {
        (price,) = _getTokenData(token);
    }

    /**
     * @notice Returns the price of a token, in terms of another given token, provided both are added
     * @param amount amount of tokens in tokenX
     * @param tokenX address of token to convert from
     * @param tokenY address of token to convert to
     * @return price of tokenX amount in tokenY
     */
    function getTokenXPriceInY(uint256 amount, address tokenX, address tokenY) external view returns (uint256) {
        if ((tokenX == ETH || tokenX == WETH) && (tokenY == ETH || tokenY == WETH)) {
            return amount;
        }

        (uint256 tokenXPrice, uint8 tokenXDecimals) = _getTokenData(tokenX);
        (uint256 tokenYPrice, uint8 tokenYDecimals) = _getTokenData(tokenY);

        /// NOTE: returned price is adjusted to decimals of `tokenY`
        //  Representing decimal adjustment returning final amount in Y decimals
        //     (((     8      +     X       +       Y        )    -        8)   -      X)
        return (((tokenXPrice * amount * (10 ** tokenYDecimals)) / tokenYPrice) / (10 ** tokenXDecimals));
    }

    /**
     * @notice Internal helper to get the price and decimals of a token
     * @param token address of token
     * @return price of token
     * @return decimals of token
     */
    function _getTokenData(address token) internal view returns (uint256, uint8) {
        PriceFeedData memory priceFeedData = getPriceFeedData(token);

        (uint80 roundId, int256 _price,, uint256 updatedAt, uint80 answeredInRound) =
            IAggregatorV3(priceFeedData._address).latestRoundData();

        _validateRound(roundId, answeredInRound, _price, updatedAt, priceFeedData._staleFeedThreshold);

        return (uint256(_price), priceFeedData._tokenDecimals);
    }

    /**
     * @notice Internal helper to validate the latest round data of a chainlink price feed
     * @param roundId round id
     * @param answeredInRound round where latest returned data was answered
     * @param _latestPrice latest price from price feed
     * @param _lastUpdatedAt latest updated timestamp
     * @param _staleFeedThreshold stale feed threshold set for token
     */
    function _validateRound(
        uint80 roundId,
        uint80 answeredInRound,
        int256 _latestPrice,
        uint256 _lastUpdatedAt,
        uint256 _staleFeedThreshold
    ) internal view {
        if (_latestPrice <= 0) revert InvalidPriceFromRound(roundId);

        if (_lastUpdatedAt == 0) revert PriceFeedStale();

        if ((answeredInRound < roundId) || (block.timestamp - _lastUpdatedAt > _staleFeedThreshold)) {
            revert PriceFeedStale();
        }
    }
}